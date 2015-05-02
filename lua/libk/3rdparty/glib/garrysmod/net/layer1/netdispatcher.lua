local self = {}
GLib.Net.Layer1.NetDispatcher = GLib.MakeConstructor (self, GLib.OutBuffer)

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
	if n >= 2147483648 then n = n - 4294967296 end -- Garry is special.
	net.WriteInt (n, 32)
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

function self:Float (f)
	net.WriteFloat (f)
end

function self:Double (f)
	net.WriteDouble (f)
end

function self:Bytes (data, length)
	length = length or #data
	length = math.min (length, #data)
	net.WriteData (data, length)
end

function self:String (data)
	self:StringN16 (data)
end

function self:LongString (data)
	self:StringN32 (data)
end

GLib.Net.Layer1.NetDispatcher = GLib.Net.Layer1.NetDispatcher ()