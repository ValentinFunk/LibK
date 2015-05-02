local self = {}
GLib.Rendering.IGraphicsView = GLib.MakeConstructor (self)

function self:ctor ()
	self.GraphicsDevice = nil
	self.WindowHandle = nil
end

function self:dtor ()
end

function self:Destroy ()
	self:dtor ()
end

function self:GetGraphicsDevice ()
	return self.GraphicsDevice
end

function self:GetWindowHandle ()
	return self.WindowHandle
end

function self:Begin ()
	GLib.Error ("IGraphicsView:Begin : Not implemented.")
end