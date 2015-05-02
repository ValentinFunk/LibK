GLib.UTF8 = {}

local math_floor    = math.floor
local string_byte   = string.byte
local string_char   = string.char
local string_len    = string.len
local string_lower  = string.lower
local string_find   = string.find
local string_format = string.format
local string_gsub   = string.gsub
local string_sub    = string.sub
local string_upper  = string.upper
local table_concat  = table.concat

function GLib.UTF8.Byte (char, offset)
	if char == "" then return -1 end
	offset = offset or 1
	
	local byte = string_byte (char, offset)
	local length = 1
	if byte >= 128 then
		-- multi-byte sequence
		if byte >= 240 then
			-- 4 byte sequence
			length = 4
			if #char < 4 then return -1, length end
			byte = (byte % 8) * 262144
			byte = byte + (string_byte (char, offset + 1) % 64) * 4096
			byte = byte + (string_byte (char, offset + 2) % 64) * 64
			byte = byte + (string_byte (char, offset + 3) % 64)
		elseif byte >= 224 then
			-- 3 byte sequence
			length = 3
			if #char < 3 then return -1, length end
			byte = (byte % 16) * 4096
			byte = byte + (string_byte (char, offset + 1) % 64) * 64
			byte = byte + (string_byte (char, offset + 2) % 64)
		elseif byte >= 192 then
			-- 2 byte sequence
			length = 2
			if #char < 2 then return -1, length end
			byte = (byte % 32) * 64
			byte = byte + (string_byte (char, offset + 1) % 64)
		else
			-- this is a continuation byte
			-- invalid sequence
			byte = -1
		end
	else
		-- single byte sequence
	end
	return byte, length
end

function GLib.UTF8.Char (byte)
	local utf8 = ""
	if byte < 0 then
		utf8 = ""
	elseif byte <= 127 then
		utf8 = string_char (byte)
	elseif byte < 2048 then
		utf8 = string_format ("%c%c",     192 + math_floor (byte / 64),     128 + (byte % 64))
	elseif byte < 65536 then
		utf8 = string_format ("%c%c%c",   224 + math_floor (byte / 4096),   128 + (math_floor (byte / 64) % 64),   128 + (byte % 64))
	elseif byte < 2097152 then
		utf8 = string_format ("%c%c%c%c", 240 + math_floor (byte / 262144), 128 + (math_floor (byte / 4096) % 64), 128 + (math_floor (byte / 64) % 64), 128 + (byte % 64))
	end
	return utf8
end

function GLib.UTF8.CharacterToOffset (str, char)
	local offset = 1
	local iterator = GLib.UTF8.Iterator (str)
	local c
	for i = 1, char - 1 do
		c = iterator ()
		if not c then break end
		offset = offset + #c
	end
	return offset
end

function GLib.UTF8.ChunkSplit (str, chunkSize)
	local chunks = {}
	
	local chunkStart = 1
	while chunkStart <= #str do
		if #chunks > 1e5 then
			GLib.Error ("UTF8.ChunkSplit : 100,000 chunks??")
			break
		end
		
		local chunkEnd = GLib.UTF8.GetSequenceStart (str, chunkStart + chunkSize)
		
		if chunkStart >= chunkEnd then
			chunkEnd = chunkStart + GLib.UTF8.SequenceLength (str, chunkStart)
		end
		
		chunks [#chunks + 1] = string_sub (str, chunkStart, chunkEnd - 1)
		chunkStart = chunkEnd
	end
	
	return chunks
end

function GLib.UTF8.ContainsSequences (str, offset)
	return string_find (str, "[\192-\255]", offset) and true or false
end

function GLib.UTF8.Decompose (str)
	local map        = {}
	local inverseMap = {}
	local t          = {}
	
	local outputOffset = 1
	for c, offset in GLib.UTF8.Iterator (str) do
		local decomposition = GLib.Unicode.DecomposeCharacter (c)
		t [#t + 1] = decomposition
		
		map [offset] = outputOffset
		inverseMap [outputOffset] = offset
		outputOffset = outputOffset + #decomposition
	end
	
	map [#str + 1] = outputOffset
	inverseMap [outputOffset] = #str + 1
	
	return table.concat (t), map, inverseMap
end

function GLib.UTF8.GetGraphemeStart (str, offset)
	return GLib.UTF8.GetSequenceStart (str, offset)
end

function GLib.UTF8.GetSequenceStart (str, offset)
	if offset <= 0 then return 1 end
	if offset > #str then return #str + 1 end
	
	local startOffset = offset
	while startOffset >= 1 do
		byte = string_byte (str, startOffset)
		
		-- Either a single byte sequence or
		-- an improperly started multi byte sequence, in which case it's treated as one byte long
		if byte <= 127 then return offset end
		
		-- Start of multibyte sequence
		if byte >= 192 then return startOffset end
		
		startOffset = startOffset - 1
	end
	return startOffset
end

function GLib.UTF8.GraphemeIterator (str, offset)
	return GLib.UTF8.Iterator (str, offset)
end

function GLib.UTF8.Iterator (str, offset)
	offset = offset or 1
	if offset <= 0 then offset = 1 end
	
	return function ()
		if offset > #str then return nil, #str + 1 end
		
		-- Inline expansion of GLib.UTF8.SequenceLength (str, offset)
		local length
		local byte = string_byte (str, offset)
		if not byte then length = 0
		elseif byte >= 240 then length = 4
		elseif byte >= 224 then length = 3
		elseif byte >= 192 then length = 2
		else length = 1 end
		
		local character = string_sub (str, offset, offset + length - 1)
		local lastOffset = offset
		offset = offset + length
		return character, lastOffset
	end
end

function GLib.UTF8.Length (str)
	local _, length = string_gsub (str, "[^\128-\191]", "")
	return length
end

local function MatchesTransliterationCharacter (character, substring, offset, firstCharacterMatch)
	local substringCharacter = GLib.UTF8.NextChar (substring, offset)
	
	if GLib.Unicode.ToLower (character) == GLib.Unicode.ToLower (substringCharacter) then
		-- Exact match found
		return #substringCharacter
	end
	
	-- Some types of characters should not match any ASCII characters
	local unicodeCategory = GLib.Unicode.GetCharacterCategory (character)
	if not firstCharacterMatch then
		if GLib.Unicode.IsCombiningCategory (unicodeCategory) then return 0 end
		if GLib.Unicode.IsControlCategory   (unicodeCategory) then return 0 end
		if GLib.Unicode.IsSeparatorCategory (unicodeCategory) then return 0 end
	end
	
	local transliterations = GLib.Unicode.GetTransliterationTable () [character]
	if transliterations then
		-- Try each possible transliteration
		for _, transliteration in ipairs (transliterations) do
			local totalMatchLength = 0
			local fail = false
			
			-- Attempt to match each character of the transliteration against the substring
			for c in GLib.UTF8.Iterator (transliteration) do
				-- Check if the end of the substring has been reached (success)
				if offset + totalMatchLength > #substring then break end
				
				local matchLength = MatchesTransliterationCharacter (c, substring, offset + totalMatchLength)
				
				if matchLength then
					-- Character match succeeded, advance
					totalMatchLength = totalMatchLength + matchLength
				else
					-- Character match failed
					fail = true
					break
				end
			end
			
			if not fail then
				return totalMatchLength
			end
		end
	end
	
	-- Absorb unmatchable non-ASCII characters
	if substringCharacter == " " then return 1 end
	if not firstCharacterMatch and
	   #character > 1 and
	   not GLib.Unicode.IsLetterCategory (unicodeCategory) then
		return 0
	end
	
	return nil
end

function GLib.UTF8.MatchTransliteration (str, substring, strOffset)
	local str, strMap, strInverseMap = GLib.UTF8.Decompose (str)
	local substring = GLib.UTF8.Decompose (substring)
	
	-- Try to start matching the substring against each character of the string
	strOffset = strMap [strOffset]
	for _, startOffset in GLib.UTF8.Iterator (str, strOffset) do
		local stringIterator  = GLib.UTF8.Iterator (str, startOffset)
		local stringCharacter, stringCharacterOffset = stringIterator ()
		local substringOffset = 1
		
		-- Advance through the string and substring whilst matches characters
		local firstCharacterMatch = true
		while substringOffset <= #substring do
			-- Check if the end of the string has been reached
			if not stringCharacter then break end
			
			-- Attempt to match the character(s)
			local matchLength = MatchesTransliterationCharacter (stringCharacter, substring, substringOffset, firstCharacterMatch)
			firstCharacterMatch = false
			
			-- Check if the match failed
			if not matchLength then break end
			
			-- Advance
			substringOffset = substringOffset + matchLength
			stringCharacter, stringCharacterOffset = stringIterator ()
		end
		
		if substringOffset > #substring then
			-- Match succeeded
			
			-- Fixup offsets
			while not strInverseMap [startOffset] do
				startOffset = startOffset - 1
			end
			while not strInverseMap [stringCharacterOffset] do
				stringCharacterOffset = stringCharacterOffset + 1
			end
			
			return true, strInverseMap [startOffset], strInverseMap [stringCharacterOffset] - 1
		end
	end
	
	return false, nil, nil
end

function GLib.UTF8.NextChar (str, offset)
	offset = offset or 1
	if offset <= 0 then offset = 1 end
	
	-- Inline expansion of GLib.UTF8.SequenceLength (str, offset)
	local length
	local byte = string_byte (str, offset)
	if not byte then length = 0
	elseif byte >= 240 then length = 4
	elseif byte >= 224 then length = 3
	elseif byte >= 192 then length = 2
	else length = 1 end
	
	return string_sub (str, offset, offset + length - 1), offset + length
end

local lineBreaks =
{
	["\r"] = true,
	["\n"] = true
}
local function GetWordType (grapheme)
	local codePoint = GLib.UTF8.Byte (grapheme)
	if string_sub (grapheme, 1, 1) == "_" or GLib.Unicode.IsLetterOrDigitCodePoint (codePoint) then
		return GLib.WordType.Alphanumeric
	elseif lineBreaks [string_sub (grapheme, 1, 1)] then
		return GLib.WordType.LineBreak
	elseif GLib.Unicode.IsWhitespaceCodePoint (codePoint) then
		return GLib.WordType.Whitespace
	end
	return GLib.WordType.Other
end

function GLib.UTF8.NextWordBoundary (str, offset)
	local iterator = GLib.UTF8.GraphemeIterator (str, offset)
	
	local leftGrapheme, leftOffset = iterator ()
	local leftWordType = leftGrapheme and GetWordType (leftGrapheme) or GLib.WordType.None
	local rightGrapheme
	local rightOffset
	local rightWordType
	while true do
		rightGrapheme, rightOffset = iterator ()
		if not rightGrapheme then return rightOffset, leftWordType, GLib.WordType.None end
		rightWordType = GetWordType (rightGrapheme)
		
		if leftWordType ~= rightWordType then
			return rightOffset, leftWordType, rightWordType
		end
		
		leftGrapheme = rightGrapheme
		leftOffset   = rightOffset
		leftWordType = rightWordType
	end
end

-- This isn't used anywhere
-- Behaviour is subject to change
function GLib.UTF8.PreviousChar (str, offset)
	offset = offset or (#str + 1)
	if offset <= 1 then return "", 0 end
	local startOffset = GLib.UTF8.GetSequenceStart (str, offset - 1)
	local length = GLib.UTF8.SequenceLength (str, startOffset)
	return string_sub (str, startOffset, startOffset + length - 1), startOffset
end

function GLib.UTF8.PreviousWordBoundary (str, offset)
	local iterator = GLib.UTF8.ReverseGraphemeIterator (str, offset)
	
	local rightGrapheme, rightOffset = iterator ()
	local rightWordType = rightGrapheme and GetWordType (rightGrapheme) or GLib.WordType.None
	local leftGrapheme
	local leftOffset
	local leftWordType
	while true do
		leftGrapheme, leftOffset = iterator ()
		if not leftGrapheme then return rightOffset, GLib.WordType.None, rightWordType end
		leftWordType = GetWordType (leftGrapheme)
		
		if leftWordType ~= rightWordType then
			return rightOffset, leftWordType, rightWordType
		end
		
		rightGrapheme = leftGrapheme
		rightOffset   = leftOffset
		rightWordType = leftWordType
	end
end

function GLib.UTF8.ReverseGraphemeIterator (str, offset)
	return GLib.UTF8.ReverseIterator (str, offset)
end

function GLib.UTF8.ReverseIterator (str, offset)
	offset = offset or (#str + 1)
	
	return function ()
		if offset <= 1 then return nil, nil end
		
		offset = GLib.UTF8.GetSequenceStart (str, offset - 1)
		
		-- Inline expansion of GLib.UTF8.SequenceLength (str, offset)
		local length
		local byte = string_byte (str, offset)
		if not byte then length = 0
		elseif byte >= 240 then length = 4
		elseif byte >= 224 then length = 3
		elseif byte >= 192 then length = 2
		else length = 1 end
		
		return string_sub (str, offset, offset + length - 1), offset
	end
end

function GLib.UTF8.SequenceLength (str, offset)
	local byte = string_byte (str, offset)
	if not byte then return 0
	elseif byte >= 240 then return 4
	elseif byte >= 224 then return 3
	elseif byte >= 192 then return 2
	else return 1 end
end

function GLib.UTF8.SplitAt (str, char)
	local c, offset = nil, 1
	local offsetChar = 1 -- character index corresponding to offset
	while c ~= "" do
		if offsetChar >= char then
			return string_sub (str, 1, offset - 1), string_sub (str, offset)
		end
		c, offset = GLib.UTF8.NextChar (str, offset)
		offsetChar = offsetChar + 1
	end
	return str
end

function GLib.UTF8.StripCombiningCharacters (str)
	return GLib.UTF8.TransformUnicodeString (str,
		function (c)
			if GLib.Unicode.IsCombiningCharacter (c) then return nil end
			return c
		end
	)
end

function GLib.UTF8.Sub (str, startCharacter, endCharacter)
	return GLib.UTF8.SubOffset (str, 1, startCharacter, endCharacter)
end

function GLib.UTF8.SubOffset (str, offset, startCharacter, endCharacter)
	if not str then return "" end
	
	if offset < 1 then offset = 1 end
	local charactersSkipped = offset - 1
	
	if startCharacter > #str - charactersSkipped then return "" end
	if endCharacter then
		if endCharacter < startCharacter then return "" end
		if endCharacter > #str - charactersSkipped then endCharacter = nil end
	end

	local iterator = GLib.UTF8.Iterator (str, offset)
	
	local nextCharacter = 1
	while nextCharacter < startCharacter do
		iterator ()
		nextCharacter = nextCharacter + 1
	end
	
	local _, startOffset = iterator ()
	if not startOffset then return "" end
	nextCharacter = nextCharacter + 1
	if not endCharacter then
		return string_sub (str, startOffset)
	end
	
	while nextCharacter <= endCharacter do
		iterator ()
		nextCharacter = nextCharacter + 1
	end
	
	local _, endOffset = iterator ()
	if endOffset then
		return string_sub (str, startOffset, endOffset - 1)
	else
		return string_sub (str, startOffset)
	end
end

function GLib.UTF8.FromLatin1 (str)
	local out = {}
	
	for i = 1, #str do
		out [#out + 1] = GLib.UTF8.Char (string_byte (str, i))
	end
	
	return table_concat (out)
end

function GLib.UTF8.ToLatin1 (str)
	str = GLib.UTF8.Decompose (str)
	
	return GLib.UTF8.TransformUnicodeString (str,
		function (c)
			codePoint = GLib.UTF8.Byte (c)
			if codePoint == -1 or codePoint > 255 then
				return "?"
			end
			return string_char (codePoint)
		end
	)
end

function GLib.UTF8.ToLower (str)
	if not GLib.UTF8.ContainsSequences (str) then return string_lower (str) end
	return GLib.UTF8.TransformString (str, GLib.Unicode.ToLower)
end

function GLib.UTF8.ToUpper (str)
	if not GLib.UTF8.ContainsSequences (str) then return string_upper (str) end
	return GLib.UTF8.TransformString (str, GLib.Unicode.ToUpper)
end

function GLib.UTF8.TransformString (str, f)
	local transformed = GLib.StringBuilder ()
	for c in GLib.UTF8.Iterator (str) do
		c = f (c)
		if c then transformed = transformed .. c end
	end
	return transformed:ToString ()
end

function GLib.UTF8.TransformUnicodeString (str, f)
	if not GLib.UTF8.ContainsSequences (str) then return str end
	
	local transformed = GLib.StringBuilder ()
	for c in GLib.UTF8.Iterator (str) do
		c = f (c)
		if c then transformed = transformed .. c end
	end
	return transformed:ToString ()
end

function GLib.UTF8.Transliterate (str)
	local transliterationTable = GLib.Unicode.GetTransliterationTable ()
	return GLib.UTF8.TransformString (str,
		function (c)
			if transliterationTable [c] and transliterationTable [c] [1] then
				return transliterationTable [c] [1]
			end
			return c
		end
	)
end

function GLib.UTF8.WordIterator (str, offset)
	offset = offset or 1
	return function ()
		local wordBoundaryOffset, leftWordType, rightWordType = GLib.UTF8.NextWordBoundary (str, offset)
		local word = string_sub (str, offset, wordBoundaryOffset - 1)
		if word == "" then word = nil end
		offset = wordBoundaryOffset
		return word, leftWordType
	end
end