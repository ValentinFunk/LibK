GLib.String = {}

function GLib.String.ConsoleEscape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.ConsoleEscape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	str = str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\q")
		:gsub ("\'", "\\s")
	return str
end

function GLib.String.DumpHex (str)
	local charsPerLine = 16
	local lines = {}
	local i = 1
	
	while i < #str do
		local line = string.sub (str, i, i + charsPerLine - 1)
		local left = ""
		local right = ""
		
		for j = 1, #line do
			local char = string.byte (line, j)
			left  = left .. string.format ("%02x ", char)
			
			if char >= 32 and char <= 127 then
				right = right .. string.sub (line, j, j)
			else
				right = right .. "."
			end
		end
		
		if #left < 3 * charsPerLine then
		    left = left .. string.rep (" ", 3 * charsPerLine - #left)
		end
		
		lines [#lines + 1] = left .. "| " .. right
		
	    i = i + charsPerLine
	end
	
	return table.concat (lines, "\n")
end

function GLib.String.Escape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.Escape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	str = str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\\"")
		:gsub ("\'", "\\\'")
	return str
end

function GLib.String.EscapeNonprintable (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.EscapeNonprintable: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	str = str:gsub (".",
		function (c)
			c = string.byte (c)
			if c < string.byte (" ") then return string.format ("\\x%02x", c) end
			if c >= 127 then return string.format ("\\x%02x", c) end
		end
	)
	return str
end

function GLib.String.EscapeWhitespace (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GLib.String.EscapeNewlines: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	str = str
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
	return str
end