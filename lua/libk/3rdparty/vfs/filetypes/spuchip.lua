local self = VFS.FileTypes:Register ("SPU")
self:AddExtension ("txt")

function self:IsEnabled ()
	return ZSPU_OpenEditor and true or false
end

function self:IsMatchingPath (path)
	path = VFS.Path (path)
	return path:GetSegment (1):lower () == "spuchip"
end

function self:Open (node)
	if not ZSPU_Editor then
		ZSPU_OpenEditor ()
	end
	RunConsoleCommand ("tool_wire_spu")
	ZSPU_Editor:LoadFile (node:GetPath ())
	ZSPU_Editor:SetVisible (true)
	ZSPU_Editor:MoveToFront ()
end