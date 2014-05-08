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