local self = VFS.FileTypes:Register ("GPU")
self:AddExtension ("txt")

function self:IsEnabled ()
	return ZGPU_OpenEditor and true or false
end

function self:IsMatchingPath (path)
	path = VFS.Path (path)
	return path:GetSegment (1):lower () == "gpuchip"
end

function self:Open (node)
	if not ZGPU_Editor then
		ZGPU_OpenEditor ()
	end
	RunConsoleCommand ("tool_wire_gpu")
	ZGPU_Editor:LoadFile (node:GetPath ())
	ZGPU_Editor:SetVisible (true)
	ZGPU_Editor:MoveToFront ()
end