local self = VFS.FileTypes:Register ("Expression 2")
self:AddExtension ("txt")

function self:IsEnabled ()
	return initE2Editor and true or false
end

function self:IsMatchingPath (path)
	path = VFS.Path (path)
	return path:GetSegment (1):lower () == "expression2"
end

function self:Open (node)
	if not wire_expression2_editor then
		initE2Editor ()
	end
	RunConsoleCommand ("tool_wire_expression2")
	wire_expression2_editor:LoadFile (node:GetPath ())
	wire_expression2_editor:SetVisible (true)
	wire_expression2_editor:MoveToFront ()
end