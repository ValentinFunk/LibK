local self = {}
GLib.Rendering.IRenderContext = GLib.MakeConstructor (self)

function self:ctor ()
	self.GraphicsDevice = nil
	self.GraphicsView   = nil
	
	self.RenderContext2d = nil
	self.RenderContext3d = nil
end

function self:GetGraphicsDevice ()
	return self.GraphicsDevice
end

function self:GetGraphicsView ()
	return self.GraphicsView
end

function self:GetRenderContext2d ()
	return self.RenderContext2d
end

function self:GetRenderContext3d ()
	return self.RenderContext3d
end

function self:End ()
	GLib.Error ("IRenderContext:End : Not implemented.")
end