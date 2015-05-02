GLib.Unicode = GLib.Unicode or {}
GLib.Unicode.Characters  = {}
local characterNames     = {}
local decompositionMap   = {}
local lowercaseMap       = {}
local uppercaseMap       = {}
local titlecaseMap       = {}
local transliterationMap = {}

function GLib.Unicode.AddTransliteration (character, transliteration)
	if not transliterationMap [character] then
		transliterationMap [character] = {}
	end
	table.insert (transliterationMap [character], transliteration)
end

function GLib.Unicode.CharacterHasDecomposition (...)
	return decompositionMap [GLib.UTF8.NextChar (...)] ~= nil
end

function GLib.Unicode.CharacterHasTransliteration (...)
	return transliterationMap [GLib.UTF8.NextChar (...)] ~= nil
end

function GLib.Unicode.CodePointHasDecomposition (codePoint)
	return decompositionMap [GLib.UTF8.Char (codePoint)] ~= nil
end

function GLib.Unicode.CodePointHasTransliteration (codePoint)
	return transliterationMap [GLib.UTF8.Char (codePoint)] ~= nil
end

function GLib.Unicode.DecomposeCharacter (...)
	local char = GLib.UTF8.NextChar (...)
	local decomposed = decompositionMap [char]
	if not decomposed then return char end
	
	local recursiveDecomposition = ""
	for c in GLib.UTF8.Iterator (decomposed) do
		recursiveDecomposition = recursiveDecomposition .. GLib.Unicode.DecomposeCharacter (c)
	end
	return recursiveDecomposition
end

function GLib.Unicode.DecomposeCodePoint (codePoint)
	return GLib.Unicode.DecomposeCharacter (GLib.UTF8.Char (codePoint))
end

function GLib.Unicode.GetCharacterCategory (...)
	local codePoint = GLib.UTF8.Byte (...)
	return GLib.Unicode.GetCodePointCategory (codePoint)
end

function GLib.Unicode.GetCharacterName (...)
	local codePoint = GLib.UTF8.Byte (...)
	if characterNames [codePoint] then
		return characterNames [codePoint]
	end
	if codePoint < 0x010000 then
		return string.format ("CHARACTER 0x%04x", codePoint)
	else
		return string.format ("CHARACTER 0x%06x", codePoint)
	end
end

function GLib.Unicode.GetCharacterNameTable ()
	return characterNames
end

function GLib.Unicode.GetCodePointCategory (codePoint)
	GLib.Error ("GLib.Unicode.GetCodePointCategory : Did unicodecategorytable.lua fail to load?")
end

function GLib.Unicode.GetCodePointName (codePoint)
	if characterNames [codePoint] then
		return characterNames [codePoint]
	end
	if codePoint < 0x010000 then
		return string.format ("CHARACTER 0x%04x", codePoint)
	else
		return string.format ("CHARACTER 0x%06x", codePoint)
	end
end

function GLib.Unicode.GetDecompositionMap ()
	return decompositionMap
end

function GLib.Unicode.GetTransliterationTable ()
	return transliterationMap
end

function GLib.Unicode.IsCharacterNamed (...)
	local codePoint = GLib.UTF8.Byte (...)
	return characterNames [codePoint] and true or false
end

function GLib.Unicode.IsCodePointNamed (codePoint)
	return characterNames [codePoint] and true or false
end

local combiningCategories =
{
	[GLib.UnicodeCategory.NonSpacingMark]       = true,
	[GLib.UnicodeCategory.SpacingCombiningMark] = true,
	[GLib.UnicodeCategory.EnclosingMark]        = true
}

function GLib.Unicode.IsCombiningCategory (unicodeCategory)
	return combiningCategories [unicodeCategory] or false
end

function GLib.Unicode.IsCombiningCharacter (...)
	return combiningCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsCombiningCodePoint (codePoint)
	return combiningCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.IsControl (...)
	return GLib.Unicode.GetCharacterCategory (...) == GLib.UnicodeCategory.Control
end

function GLib.Unicode.IsControlCategory (unicodeCategory)
	return unicodeCategory == GLib.UnicodeCategory.Control
end

function GLib.Unicode.IsControlCodePoint (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint) == GLib.UnicodeCategory.Control
end

function GLib.Unicode.IsDigit (...)
	return GLib.Unicode.GetCharacterCategory (...) == GLib.UnicodeCategory.DecimalDigitNumber
end

function GLib.Unicode.IsDigitCodePoint (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint) == GLib.UnicodeCategory.DecimalDigitNumber
end

local letterCategories =
{
	[GLib.UnicodeCategory.UppercaseLetter] = true,
	[GLib.UnicodeCategory.LowercaseLetter] = true,
	[GLib.UnicodeCategory.TitlecaseLetter] = true,
	[GLib.UnicodeCategory.ModifierLetter ] = true,
	[GLib.UnicodeCategory.OtherLetter    ] = true
}
function GLib.Unicode.IsLetter (...)
	return letterCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsLetterCategory (unicodeCategory)
	return letterCategories [unicodeCategory] or false
end

function GLib.Unicode.IsLetterCodePoint (codePoint)
	return letterCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.IsLetterOrDigit (...)
	local unicodeCategory = GLib.Unicode.GetCharacterCategory (...)
	return letterCategories [unicodeCategory] or unicodeCategory == GLib.UnicodeCategory.DecimalDigitNumber or false
end

function GLib.Unicode.IsLetterOrDigitCategory (unicodeCategory)
	return letterCategories [unicodeCategory] or unicodeCategory == GLib.UnicodeCategory.DecimalDigitNumber or false
end

function GLib.Unicode.IsLetterOrDigitCodePoint (codePoint)
	local unicodeCategory = GLib.Unicode.GetCodePointCategory (codePoint)
	return letterCategories [unicodeCategory] or unicodeCategory == GLib.UnicodeCategory.DecimalDigitNumber or false
end

function GLib.Unicode.IsLower (...)
	return GLib.Unicode.GetCharacterCategory (...) == GLib.UnicodeCategory.LowercaseLetter
end

function GLib.Unicode.IsLowerCodePoint (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint) == GLib.UnicodeCategory.LowercaseLetter
end

local numberCategories =
{
	[GLib.UnicodeCategory.DecimalDigitNumber] = true,
	[GLib.UnicodeCategory.LetterNumber      ] = true,
	[GLib.UnicodeCategory.OtherNumber       ] = true
}
function GLib.Unicode.IsNumber (...)
	return numberCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsNumberCategory (unicodeCategory)
	return numberCategories [unicodeCategory] or false
end

function GLib.Unicode.IsNumberCodePoint (codePoint)
	return numberCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

local punctuationCategories =
{
	[GLib.UnicodeCategory.ConnectorPunctuation   ] = true,
	[GLib.UnicodeCategory.DashPunctuation        ] = true,
	[GLib.UnicodeCategory.OpenPunctuation        ] = true,
	[GLib.UnicodeCategory.ClosePunctuation       ] = true,
	[GLib.UnicodeCategory.InitialQuotePunctuation] = true,
	[GLib.UnicodeCategory.FinalQuotePunctuation  ] = true,
	[GLib.UnicodeCategory.OtherPunctuation       ] = true
}
function GLib.Unicode.IsPunctuation (...)
	return punctuationCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsPunctuationCategory (unicodeCategory)
	return punctuationCategories [unicodeCategory] or false
end

local separatorCategories =
{
	[GLib.UnicodeCategory.SpaceSeparator    ] = true,
	[GLib.UnicodeCategory.LineSeparator     ] = true,
	[GLib.UnicodeCategory.ParagraphSeparator] = true
}
function GLib.Unicode.IsSeparator (...)
	return separatorCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsSeparatorCategory (unicodeCategory)
	return separatorCategories [unicodeCategory] or false
end

function GLib.Unicode.IsSeparatorCodePoint (codePoint)
	return separatorCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

local symbolCategories =
{
	[GLib.UnicodeCategory.MathSymbol    ] = true,
	[GLib.UnicodeCategory.CurrencySymbol] = true,
	[GLib.UnicodeCategory.ModifierSymbol] = true,
	[GLib.UnicodeCategory.OtherSymbol   ] = true
}
function GLib.Unicode.IsSymbol (...)
	return symbolCategories [GLib.Unicode.GetCharacterCategory (...)] or false
end

function GLib.Unicode.IsSymbolCategory (unicodeCategory)
	return symbolCategories [unicodeCategory] or false
end

function GLib.Unicode.IsSymbolCodePoint (codePoint)
	return symbolCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.IsUpper (...)
	return GLib.Unicode.GetCharacterCategory (...) == GLib.UnicodeCategory.UppercaseLetter
end

function GLib.Unicode.IsUpperCodePoint (codePoint)
	return GLib.Unicode.GetCodePointCategory (codePoint) == GLib.UnicodeCategory.UppercaseLetter
end

local whitespaceCategories =
{
	[GLib.UnicodeCategory.SpaceSeparator    ] = true,
	[GLib.UnicodeCategory.LineSeparator     ] = true,
	[GLib.UnicodeCategory.ParagraphSeparator] = true
}
local whitespaceCodePoints =
{
	[0x0009] = true,
	[0x000A] = true,
	[0x000B] = true,
	[0x000C] = true,
	[0x000D] = true,
	[0x0085] = true,
	[0x00A0] = true
}
function GLib.Unicode.IsWhitespace (...)
	local codePoint = GLib.UTF8.Byte (...)
	return whitespaceCodePoints [codePoint] or whitespaceCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.IsWhitespaceCodePoint (codePoint)
	return whitespaceCodePoints [codePoint] or whitespaceCategories [GLib.Unicode.GetCodePointCategory (codePoint)] or false
end

function GLib.Unicode.ToLower (...)
	local char = GLib.UTF8.NextChar (...)
	return lowercaseMap [char] or char
end

function GLib.Unicode.ToLowerCodePoint (codePoint)
	local char = GLib.UTF8.Char (codePoint)
	return lowercaseMap [char] or char
end

function GLib.Unicode.ToTitle (...)
	local char = GLib.UTF8.NextChar (...)
	return titlecaseMap [char] or char
end

function GLib.Unicode.ToTitleCodePoint (codePoint)
	local char = GLib.UTF8.Char (codePoint)
	return titlecaseMap [char] or char
end

function GLib.Unicode.ToUpper (str, offset)
	local char = GLib.UTF8.NextChar (str, offset)
	return uppercaseMap [char] or char
end

function GLib.Unicode.ToUpperCodePoint (codePoint)
	local char = GLib.UTF8.Char (codePoint)
	return uppercaseMap [char] or char
end

-- unicodedata.txt parser
GLib.Unicode.DataLines = nil
GLib.Unicode.StartTime = SysTime ()

local function ParseUnicodeData (unicodeData)
	GLib.Unicode.DataLines = string.Split (string.Trim (unicodeData), "\n")
	local dataLines = GLib.Unicode.DataLines
	local i = 1
	local lastCodePoint = 0
	timer.Create ("GLib.Unicode.ParseData", 0.001, 0,
		function ()
			local startTime = SysTime ()
			while SysTime () - startTime < 0.005 do
				--  1. Code point
				--  2. Character name
				--  3. Generate category
				--  4. Canonical combining classes
				--  5. Bidirectional category
				--  6. Character decomposition mapping
				--  7. Decimal digit value
				--  8. Digit value
				--  9. Numeric value
				-- 10. Mirrored
				-- 11. Unicode 1.0 name
				-- 12. ISO 10646 comment field
				-- 13. Uppercase mapping
				-- 14. Lowercase mapping
				-- 15. Titlecase mapping
				
				local line = dataLines [i]
				line = string.gsub (line, "#.*$", "")
				line = string.Trim (line)
				
				if line ~= "" then
					local bits = string.Split (line, ";")
					local codePoint = tonumber ("0x" .. (bits [1] or "0")) or 0
					
					lastCodePoint = codePoint
					
					characterNames [codePoint] = bits [2]
					
					-- Decomposition
					if bits [6] and bits [6] ~= "" then
						local decompositionBits = string.Split (bits [6], " ")
						local decomposition = ""
						for i = 1, #decompositionBits do
							local codePoint = tonumber ("0x" .. decompositionBits [i])
							if codePoint then
								decomposition = decomposition .. GLib.UTF8.Char (codePoint)
							end
						end
						decompositionMap [GLib.UTF8.Char (codePoint)] = decomposition
					end
					
					-- Uppercase
					if bits [13] and bits [13] ~= "" then
						if bits [13]:find (" ") then print (bits [13]) end
						uppercaseMap [GLib.UTF8.Char (codePoint)] = GLib.UTF8.Char (tonumber ("0x" .. bits [13]))
					end
					
					-- Lowercase
					if bits [14] and bits [14] ~= "" then
						if bits [14]:find (" ") then print (bits [14]) end
						lowercaseMap [GLib.UTF8.Char (codePoint)] = GLib.UTF8.Char (tonumber ("0x" .. bits [14]))
					end
					
					-- Titlecase
					if bits [15] and bits [15] ~= "" then
						if bits [15]:find (" ") then print (bits [15]) end
						titlecaseMap [GLib.UTF8.Char (codePoint)] = GLib.UTF8.Char (tonumber ("0x" .. bits [15]))
					end
				end
				
				i = i + 1
				if i > #dataLines then
					timer.Destroy ("GLib.Unicode.ParseData")
					GLib.Unicode.DataLines = nil
					
					GLib.Unicode.EndTime   = SysTime ()
					GLib.Unicode.DeltaTime = GLib.Unicode.EndTime - GLib.Unicode.StartTime
					
					break
				end
			end
		end
	)
end

GLib.Resources.RegisterFile ("UnicodeData", "UnicodeData", "data/glib_unicodedata.txt")

timer.Simple (1,
	function ()
		GLib.Resources.Get ("UnicodeData", "UnicodeData",
			function (success, data)
				if not success then return end
				ParseUnicodeData (data)
			end
		)
	end
)

GLib.Unicode.Characters.CombiningDotAbove               = GLib.UTF8.Char (0x0307)
GLib.Unicode.Characters.CombiningDiaeresis              = GLib.UTF8.Char (0x0308)
GLib.Unicode.Characters.EnQuad                          = GLib.UTF8.Char (0x2000)
GLib.Unicode.Characters.EmQuad                          = GLib.UTF8.Char (0x2001)
GLib.Unicode.Characters.EnSpace                         = GLib.UTF8.Char (0x2002)
GLib.Unicode.Characters.EmSpace                         = GLib.UTF8.Char (0x2003)
GLib.Unicode.Characters.ThreePerEmSpace                 = GLib.UTF8.Char (0x2004)
GLib.Unicode.Characters.FourPerEmSpace                  = GLib.UTF8.Char (0x2005)
GLib.Unicode.Characters.SixPerEmSpace                   = GLib.UTF8.Char (0x2006)
GLib.Unicode.Characters.FigureSpace                     = GLib.UTF8.Char (0x2007)
GLib.Unicode.Characters.PunctuationSpace                = GLib.UTF8.Char (0x2008)
GLib.Unicode.Characters.ThinSpace                       = GLib.UTF8.Char (0x2009)
GLib.Unicode.Characters.HairSpace                       = GLib.UTF8.Char (0x200A)
GLib.Unicode.Characters.ZeroWidthSpace                  = GLib.UTF8.Char (0x200B)
GLib.Unicode.Characters.ZeroWidthNonJoiner              = GLib.UTF8.Char (0x200C)
GLib.Unicode.Characters.ZeroWidthJoiner                 = GLib.UTF8.Char (0x200D)
GLib.Unicode.Characters.LeftToRightMark                 = GLib.UTF8.Char (0x200E)
GLib.Unicode.Characters.RightToLeftMark                 = GLib.UTF8.Char (0x200F)
GLib.Unicode.Characters.LineSeparator                   = GLib.UTF8.Char (0x2028)
GLib.Unicode.Characters.ParagraphSeparator              = GLib.UTF8.Char (0x2029)
GLib.Unicode.Characters.LeftToRightEmbedding            = GLib.UTF8.Char (0x202A)
GLib.Unicode.Characters.RightToLeftEmbedding            = GLib.UTF8.Char (0x202B)
GLib.Unicode.Characters.PopDirectionalFormatting        = GLib.UTF8.Char (0x202C)
GLib.Unicode.Characters.LeftToRightOverride             = GLib.UTF8.Char (0x202D)
GLib.Unicode.Characters.RightToLeftOverride             = GLib.UTF8.Char (0x202E)
GLib.Unicode.Characters.NarrowNoBreakSpace              = GLib.UTF8.Char (0x202F)
GLib.Unicode.Characters.WordJoiner                      = GLib.UTF8.Char (0x2060)
GLib.Unicode.Characters.InhibitSymmetricSwapping        = GLib.UTF8.Char (0x206A)
GLib.Unicode.Characters.ActivateSymmetricSwapping       = GLib.UTF8.Char (0x206B)
GLib.Unicode.Characters.InhibitArabicFormShaping        = GLib.UTF8.Char (0x206C)
GLib.Unicode.Characters.ActivateArabicFormShaping       = GLib.UTF8.Char (0x206D)
GLib.Unicode.Characters.NationalDigitShapes             = GLib.UTF8.Char (0x206E)
GLib.Unicode.Characters.NominalDigitShapes              = GLib.UTF8.Char (0x206F)
GLib.Unicode.Characters.ByteOrderMark                   = GLib.UTF8.Char (0xFEFF)
GLib.Unicode.Characters.ZeroWidthNoBreakSpace           = GLib.UTF8.Char (0xFEFF)
GLib.Unicode.Characters.InterlinearAnnotationAnchor     = GLib.UTF8.Char (0xFFF9)
GLib.Unicode.Characters.InterlinearAnnotationSeparator  = GLib.UTF8.Char (0xFFFA)
GLib.Unicode.Characters.InterlinearAnnotationTerminator = GLib.UTF8.Char (0xFFFB)