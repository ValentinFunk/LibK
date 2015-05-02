local self = {}
GLib.Net.Layer1.PinnedNetInBuffer = GLib.MakeConstructor (self, GLib.Net.InBuffer)

function self:ctor (netInBuffer, position, data)
	self.PositionOffset = position - 1
	self.InBuffer = GLib.StringInBuffer (data)
end

function self:GetBytesRemaining ()
	return self.InBuffer:GetBytesRemaining ()
end

function self:GetPosition ()
	return self.InBuffer:GetPosition () + self.PositionOffset
end

function self:GetSize ()
	return self.InBuffer:GetSize () + self.PositionOffset
end

function self:IsEndOfStream ()
	return self.InBuffer:IsEndOfStream ()
end

function self:Pin ()
	return self
end

function self:UInt8 ()
	return self.InBuffer:UInt8 ()
end

function self:UInt16 ()
	return self.InBuffer:UInt16 ()
end

function self:UInt32 ()
	return self.InBuffer:UInt32 ()
end

function self:Int8 ()
	return self.InBuffer:Int8 ()
end

function self:Int16 ()
	return self.InBuffer:Int16 ()
end

function self:Int32 ()
	return self.InBuffer:Int32 ()
end

function self:Bytes (length)
	return self.InBuffer:Bytes (length)
end

function self:String ()
	return self:StringN16 ()
end

function self:LongString ()
	return self:StringN32 ()
end