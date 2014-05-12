local PANEL = {}
Gooey.ToolbarSeparator = Gooey.MakeConstructor (PANEL, Gooey.ToolbarItem)

function PANEL:ctor (...)
	self:Init ()
	
	self:SetWidth (3)
end

function PANEL:Init ()
end

function PANEL:Paint (renderContext)
	surface.SetDrawColor (GLib.Colors.Gray)
	surface.DrawLine (1, 2, 1, self.Height - 2)
end