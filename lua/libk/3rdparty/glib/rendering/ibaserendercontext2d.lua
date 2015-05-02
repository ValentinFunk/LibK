local self = {}
GLib.Rendering.IBaseRenderContext2d = GLib.MakeConstructor (self)

function self:ctor ()
	self.GraphicsDevice = nil
	self.GraphicsView   = nil
	self.RenderContext  = nil
	
	self.FillColor = GLib.Colors.White
	self.LineColor = GLib.Colors.Red
	
	self.Texture = nil
end

function self:GetGraphicsDevice ()
	return self.GraphicsDevice
end

function self:GetGraphicsView ()
	return self.GraphicsView
end

function self:GetRenderContext ()
	return self.RenderContext
end
function self:GetFillColor ()
	return self.FillColor
end

function self:GetLineColor ()
	return self.LineColor
end

function self:SetFillColor (fillColor)
	if self.FillColor == fillColor then return self end
	
	self.FillColor = fillColor
	return self
end

function self:SetLineColor (lineColor)
	if self.LineColor == lineColor then return self end
	
	self.LineColor = lineColor
	return self
end

function self:GetTexture ()
	return self.Texture
end

function self:SetTexture (texture)
	if self.Texture == texture then return self end
	
	self.Texture = texture
	return self
end

function self:DrawLine (start, end_)
	GLib.Error ("IBaseRenderContext2d:DrawLine : Not implemented.")
end

function self:DrawRectangle (position, size)
	GLib.Error ("IBaseRenderContext2d:DrawRectangle : Not implemented.")
end

function self:FillRectangle (position, size)
	GLib.Error ("IBaseRenderContext2d:FillRectangle : Not implemented.")
end

function self:DrawTexturedRectangle (position, size, uv0, uv1)
	GLib.Error ("IBaseRenderContext2d:DrawTexturedRectangle : Not implemented.")
end