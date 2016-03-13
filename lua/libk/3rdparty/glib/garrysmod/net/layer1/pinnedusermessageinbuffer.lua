local self = {}
GLib.Net.Layer1.PinnedUsermessageInBuffer = GLib.MakeConstructor (self, GLib.Net.InBuffer)

function self:ctor (usermessageInBuffer)
	self.InBuffer = usermessageInBuffer:ToStringInBuffer ()
	self.InBuffer:SeekAbsolute (usermessageInBuffer:GetPosition ())
end

function self:GetBytesRemaining ()
	return self.InBuffer:GetBytesRemaining ()
end

function self:GetPosition ()
	return self.InBuffer:GetPosition ()
end

function self:GetSize ()
	return self.InBuffer:GetSize ()
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
	return self:StringN8 ()
end

function self:LongString ()
	return self:StringN32 ()
end