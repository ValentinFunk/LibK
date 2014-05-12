local PANEL = {}

function PANEL:Init ()
end

function PANEL:GetLineHeight ()
	surface.SetFont (self:GetFont ())
	local _, lineHeight = surface.GetTextSize ("W")
	return lineHeight
end

function PANEL:UpdateColours (skin)
	if self.TextColor then return end
	
	local ret = DLabel.UpdateColours (self, skin)
	self:SetTextColor (self:GetTextStyleColor ())
	return ret
end

Gooey.Register ("GLabel", PANEL, "DLabel")