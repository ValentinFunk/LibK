local PANEL = {}

function PANEL:Init ()
	self:SetSize (15, 15)
end

function PANEL:Paint (w, h)
	surface.SetDrawColor (GLib.Colors.Silver)
	surface.DrawRect (0, 0, w, h)
end

Gooey.Register ("GScrollBarCorner", PANEL, "GPanel")