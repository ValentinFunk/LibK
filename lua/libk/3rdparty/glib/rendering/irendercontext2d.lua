local self = {}
GLib.Rendering.IRenderContext2d = GLib.MakeConstructor (self, GLib.Rendering.IBaseRenderContext2d)

function self:ctor ()
	self.AntiAliasing = false
	
	self.Font = nil
	self.TextColor = GLib.Colors.Black
end

function self:GetAntiAliasing ()
	return self.AntiAliasing
end

function self:SetAntiAliasing (antiAliasing)
	if self.AntiAliasing == antiAliasing then return self end
	
	self.AntiAliasing = antiAliasing
	return self
end

function self:GetFont ()
	return self.Font
end

function self:GetTextColor ()
	return self.TextColor
end

function self:SetFont (font)
	if self.Font == font then return self end
	
	self.Font = font
	return self
end

function self:SetTextColor (textColor)
	if self.TextColor == textColor then return self end
	
	self.TextColor = textColor
	return self
end

function self:DrawText (text, position, horizontalAlignment, verticalAlignment)
	GLib.Error ("IRenderContext2d:DrawText : Not implemented.")
end

function self:DrawText2 (text, position, size, horizontalAlignment, verticalAlignment)
	GLib.Error ("IRenderContext2d:DrawText2  : Not implemented.")
end

function self:GetTextSize (text)
	GLib.Error ("IRenderContext2d:GetTextSize : Not implemented.")
end