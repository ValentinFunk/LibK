local self = {}
GLib.Net.NetDispatcher = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:Dispatch (ply, channelName, packet)
	net.Start (channelName)
		for i = 1, #packet.Data do
			local data = packet.Data [i]
			local typeId = packet.Types [i]
			
			self [GLib.Net.DataType [typeId]] (self, data)
		end
	if SERVER then
		net.Send (ply)
	else
		net.SendToServer ()
	end
end

function self:UInt8 (n)
	net.WriteUInt (n, 8)
end

function self:UInt16 (n)
	net.WriteUInt (n, 16)
end

function self:UInt32 (n)
	if n >= 2147483648 then n = n - 4294967296 end
	net.WriteInt (n, 32)
end

function self:UInt64 (n)
	net.WriteUInt (n % 4294967296, 32)
	net.WriteUInt (math.floor (n / 4294967296), 32)
end

function self:Int8 (n)
	net.WriteInt (n, 8)
end

function self:Int16 (n)
	net.WriteInt (n, 16)
end

function self:Int32 (n)
	net.WriteInt (n, 32)
end

function self:Int64 (n)
	net.WriteUInt (n % 4294967296, 32)
	net.WriteInt (math.floor (n / 4294967296), 32)
end

function self:Float (f)
	net.WriteFloat (f)
end

function self:Double (f)
	net.WriteDouble (f)
end

function self:Vector (v)
	net.WriteVector (v)
end

function self:Char (char)
	self:UInt8 (string.byte (char))
end

function self:Bytes (data, length)
	length = length or #data
	net.WriteData (data, length)
end

function self:String (data)
	self:UInt16 (data:len ())
	for i = 1, data:len () do
		self:Char (data:sub (i, i))
	end
end

function self:Boolean (b)
	net.WriteBit (b)
end

GLib.Net.NetDispatcher = GLib.Net.NetDispatcher ()