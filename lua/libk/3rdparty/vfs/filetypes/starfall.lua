local self = VFS.FileTypes:Register ("Starfall")
self:AddExtension ("txt")

function self:IsEnabled ()
	return SF and SF.Editor and true or false
end

function self:IsMatchingPath (path)
	path = VFS.Path (path)
	return path:GetSegment (1):lower () == "starfall"
end

function self:Open (node)
	if not SF.Editor.editor then
		SF.Editor.init ()
	end
	RunConsoleCommand ("tool_wire_starfall_processor")
	SF.Editor.open ()
	SF.Editor.editor:LoadFile (node:GetPath ())
end