local self = {}
GLib.Net.Layer1.NetInBuffer = GLib.MakeConstructor (self, GLib.Net.InBuffer)

function self:ctor (size)
	self.Position = 1
	
	self.Size = size or -1
end

function self:GetBytesRemaining ()
	if self.Size == -1 then return -1 end
	return self.Size - self.Position + 1
end

function self:GetSize ()
	return self.Size
end

function self:IsEndOfStream ()
	return false
end

function self:Pin ()
	local position = self:GetPosition ()
	local data = self:Bytes (self:GetBytesRemaining ())
	return GLib.Net.Layer1.PinnedNetInBuffer (self, position, data)
end

function self:UInt8 ()
	self.Position = self.Position + 1
	return net.ReadUInt (8)
end

function self:UInt16 ()
	self.Position = self.Position + 2
	return net.ReadUInt (16)
end

function self:UInt32 ()
	self.Position = self.Position + 4
	local n = net.ReadUInt (32)
	if n < 0 then n = n + 4294967296 end -- So special.
	return n
end

function self:Int8 ()
	self.Position = self.Position + 1
	return net.ReadInt (8)
end

function self:Int16 ()
	self.Position = self.Position + 2
	return net.ReadInt (16)
end

function self:Int32 ()
	self.Position = self.Position + 4
	return net.ReadInt (32)
end

function self:Float ()
	self.Position = self.Position + 4
	return net.ReadFloat ()
end

function self:Double ()
	self.Position = self.Position + 8
	return net.ReadDouble ()
end

function self:Bytes (length)
	self.Position = self.Position + length
	
	if length == 0 then return "" end -- Garry is special.
	local data = net.ReadData (length)
	return data
end

function self:String ()
	return self:StringN16 ()
end

function self:LongString ()
	return self:StringN32 ()
end