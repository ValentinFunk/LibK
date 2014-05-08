local self = {}
GLib.Net.UsermessageInBuffer = GLib.MakeConstructor (self)

function self:ctor (umsg)
	self.Usermessage = umsg
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
	return self.Usermessage:ReadChar () + 128
end

function self:UInt16 ()
	return self.Usermessage:ReadShort () + 32768
end

function self:UInt32 ()
	return self.Usermessage:ReadLong () + 2147483648
end

function self:UInt64 ()
	local n = self.Usermessage:ReadLong () + 2147483648
	return (self.Usermessage:ReadLong () + 2147483648) * 4294967296 + n
end

function self:Int8 ()
	return self.Usermessage:ReadChar ()
end

function self:Int16 ()
	return self.Usermessage:ReadShort ()
end

function self:Int32 ()
	return self.Usermessage:ReadLong ()
end

function self:Int64 ()
	local n = self.Usermessage:ReadLong () + 2147483648
	return self.Usermessage:ReadLong () * 4294967296 + n
end

function self:Float ()
	return self.Usermessage:ReadFloat ()
end

function self:Double ()
	return self.Usermessage:ReadFloat ()
end

function self:Vector ()
	return self.Usermessage:ReadVector ()
end

function self:Char ()
	return string.char (self:UInt8 ())
end

function self:Bytes (length)
	local data = ""
	for i = 1, length do
		data = data .. self:Char ()
	end
	return data
end

function self:String ()
	local length = self:UInt8 ()
	return self:Bytes (length)
end

function self:Boolean ()
	return self.Usermessage:ReadChar () ~= 0
end