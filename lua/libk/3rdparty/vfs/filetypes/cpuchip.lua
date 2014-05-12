local self = VFS.FileTypes:Register ("CPU")
self:AddExtension ("txt")

function self:IsEnabled ()
	return ZCPU_OpenEditor and true or false
end

function self:IsMatchingPath (path)
	path = VFS.Path (path)
	return path:GetSegment (1):lower () == "cpuchip"
end

function self:Open (node)
	if not ZCPU_Editor then
		ZCPU_OpenEditor ()
	end
	RunConsoleCommand ("tool_wire_cpu")
	ZCPU_Editor:LoadFile (node:GetPath ())
	ZCPU_Editor:SetVisible (true)
	ZCPU_Editor:MoveToFront ()
end