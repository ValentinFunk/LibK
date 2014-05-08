local self = {}
GLib.Net.NetInBuffer = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:GetBytesRemaining ()
	return -1
end

function self:GetSize ()
	return -1
end

function self:IsEndOfStream ()
	return false
end

function self:UInt8 ()
	return net.ReadUInt (8)
end

function self:UInt16 ()
	return net.ReadUInt (16)
end

function self:UInt32 ()
	local n = net.ReadUInt (32)
	if n < 0 then n = n + 4294967296 end
	return n
end

function self:UInt64 ()
	local n = self:UInt32 ()
	return self:UInt32 () * 4294967296 + n
end

function self:Int8 ()
	return net.ReadInt (8)
end

function self:Int16 ()
	return net.ReadInt (16)
end

function self:Int32 ()
	return net.ReadInt (32)
end

function self:Int64 ()
	local n = self:UInt32 ()
	return self:Int32 () * 4294967296 + n
end

function self:Float ()
	return net.ReadFloat ()
end

function self:Double ()
	return net.ReadDouble ()
end

function self:Vector ()
	return net.ReadVector ()
end

function self:Char ()
	return string.char (self:UInt8 ())
end

function self:Bytes (length)
	return net.ReadData (length)
end

function self:String ()
	local length = self:UInt16 ()
	local str = ""
	for i = 1, length do
		str = str .. self:Char ()
	end
	return str
end

function self:Boolean ()
	return net.ReadBit () == 1
end