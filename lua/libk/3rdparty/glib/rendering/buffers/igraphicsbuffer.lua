local self = {}
GLib.Rendering.Buffers.IGraphicsBuffer = GLib.MakeConstructor (self)

function self:ctor ()
	self.GraphicsDevice = nil
	self.Handle = nil
	
	self.Flags = GLib.Rendering.Buffers.BufferFlags.None
	
	self.Size         = 0
	self.ElementCount = 0
	self.ElementSize  = 0
end

function self:dtor ()
end

function self:GetGraphicsDevice ()
	return self.GraphicsDevice
end

function self:GetHandle ()
	return self.Handle
end

function self:Destroy ()
	self:dtor ()
end

function self:GetFlags ()
	return self.Flags
end

function self:GetSize ()
	return self.Size
end

function self:GetElementCount ()
	return self.ElementCount
end

function self:GetElementSize ()
	return self.ElementSize
end

function self:Flush ()
	GLib.Error ("IGraphicsBuffer:Flush : Not implemented.")
end

function self:SetElements (startElement, elementCount, elements)
	GLib.Error ("IGraphicsBuffer:SetElements : Not implemented.")
end
