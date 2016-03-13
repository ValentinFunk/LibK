local isstring      = isstring
local tonumber      = tonumber
local type          = type

local string_byte   = string.byte
local string_char   = string.char
local string_format = string.format
local string_gsub   = string.gsub
local string_sub    = string.sub
local table_concat  = table.concat

function GLib.String.ConsoleEscape (str)
	if not isstring (str) then
		ErrorNoHalt ("GLib.String.ConsoleEscape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	
	str = string_gsub (str, "\\", "\\\\")
	str = string_gsub (str, "\r", "\\r")
	str = string_gsub (str, "\n", "\\n")
	str = string_gsub (str, "\t", "\\t")
	str = string_gsub (str, "\"", "\\q")
	str = string_gsub (str, "\'", "\\s")
	
	return str
end

function GLib.String.Escape (str)
	if not isstring (str) then
		ErrorNoHalt ("GLib.String.Escape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	
	str = string_gsub (str, "\\", "\\\\")
	str = string_gsub (str, "\r", "\\r")
	str = string_gsub (str, "\n", "\\n")
	str = string_gsub (str, "\t", "\\t")
	str = string_gsub (str, "\"", "\\\"")
	str = string_gsub (str, "\'", "\\\'")
	
	return str
end

local escapeNonprintableMap =
{
	["\\"] = "\\\\",
	["\""] = "\\\""
}

for i = 0, 31 do
	escapeNonprintableMap [string_char (i)] = string_format ("\\x%02x", i)
end
for i = 127, 255 do
	escapeNonprintableMap [string_char (i)] = string_format ("\\x%02x", i)
end

function GLib.String.EscapeNonprintable (str)
	if not isstring (str) then
		ErrorNoHalt ("GLib.String.EscapeNonprintable: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	
	str = string_gsub (str, ".", escapeNonprintableMap)
	
	return str
end

function GLib.String.EscapeWhitespace (str)
	if not isstring (str) then
		ErrorNoHalt ("GLib.String.EscapeNewlines: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	
	str = string_gsub (str, "\r", "\\r")
	str = string_gsub (str, "\n", "\\n")
	str = string_gsub (str, "\t", "\\t")
	
	return str
end

local unescapeMap =
{
	["\\"] = "\\",
	["\""] = "\"",
	["\'"] = "\'",
	["a" ] = "\a",
	["b" ] = "\b",
	["f" ] = "\f",
	["n" ] = "\n",
	["r" ] = "\r",
	["t" ] = "\t",
	["v" ] = "\v",
	["z" ] = "\z",
}

function GLib.String.Unescape (str)
	local output = {}
	local i = 1
	while i <= #str do
		local c = string_sub (str, i, i)
		i = i + 1
		
		if c == "\\" then
			c = string_sub (str, i, i)
			i = i + 1
			
			if unescapeMap [c] then
				output [#output + 1] = unescapeMap [c]
			elseif c == "x" then
				output [#output + 1] = string_char (tonumber (string_sub (str, i, i + 1), 16))
				i = i + 2
			elseif "0" <= c and c <= "9" then
				local n = c
				
				c = string_sub (str, i, i)
				if "0" <= c and c <= "9" then
					n = n .. c
					i = i + 1
				end
				c = string_sub (str, i, i)
				if "0" <= c and c <= "9" then
					n = n .. c
					i = i + 1
				end
				
				output [#output + 1] = string_char (tonumber (n))
			else
				output [#output + 1] = c
			end
		else
			output [#output + 1] = c
		end
	end
	
	return table_concat (output)
end