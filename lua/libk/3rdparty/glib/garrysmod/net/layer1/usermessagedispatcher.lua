local self = {}
GLib.Net.Layer1.UsermessageDispatcher = GLib.MakeConstructor (self, GLib.OutBuffer)

function self:ctor ()
end

function self:Dispatch (ply, channelName, packet)
	umsg.Start (channelName, ply)
		for i = 1, #packet.Data do
			local data = packet.Data [i]
			local typeId = packet.Types [i]
			
			self [GLib.Net.DataType [typeId]] (self, data)
		end
	umsg.End ()
end

function self:UInt8 (n)
	if n >= 0x80 then n = n - 0x0100 end
	umsg.Char (n)
end

function self:UInt16 (n)
	if n >= 0x8000 then n = n - 0x00010000 end
	umsg.Short (n)
end

function self:UInt32 (n)
	if n >= 0x80000000 then n = n - 4294967296 end
	umsg.Long (n)
end

function self:Int8 (n)
	umsg.Char (n)
end

function self:Int16 (n)
	umsg.Short (n)
end

function self:Int32 (n)
	umsg.Long (n)
end

function self:Float (f)
	umsg.Float (f)
end

-- We don't use umsg.Vector because that doesn't actually send the vector as 3 floats

function self:String (data)
	-- umsg.String can mix up uppercase / lowercase characters.
	self:StringN8 (data)
end

function self:LongString (data)
	self:StringN32 (data)
end

GLib.Net.Layer1.UsermessageDispatcher = GLib.Net.Layer1.UsermessageDispatcher ()