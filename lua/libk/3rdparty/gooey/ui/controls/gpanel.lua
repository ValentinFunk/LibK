local PANEL = {}

function PANEL:Init ()
end

function PANEL:Paint (w, h)
	draw.RoundedBox (4, 0, 0, w, h, self:GetBackgroundColor ())
end

-- Event handlers
Gooey.CreateMouseEvents (PANEL)

function PANEL:OnKeyCodePressed (keyCode)
	return self:DispatchKeyboardAction (keyCode)
end
PANEL.OnKeyCodeTyped = PANEL.OnKeyCodePressed

Gooey.Register ("GPanel", PANEL, "DPanel")