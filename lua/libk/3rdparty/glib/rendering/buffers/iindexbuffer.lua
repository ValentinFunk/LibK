local self = {}
GLib.Rendering.Buffers.IIndexBuffer = GLib.MakeConstructor (self, GLib.Rendering.Buffers.IGraphicsBuffer)

function self:ctor ()
	self.IndexType = GLib.Rendering.Buffers.BufferElementType.UInt16
end

function self:GetIndexType ()
	return self.IndexType
end