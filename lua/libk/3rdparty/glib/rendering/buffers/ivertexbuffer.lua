local self = {}
GLib.Rendering.Buffers.IVertexBuffer = GLib.MakeConstructor (self, GLib.Rendering.Buffers.IGraphicsBuffer)

function self:ctor ()
	self.VertexLayout = nil
end

function self:GetVertexLayout ()
	return self.VertexLayout
end