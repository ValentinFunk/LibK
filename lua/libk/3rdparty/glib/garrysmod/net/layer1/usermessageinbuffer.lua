local self = {}
GLib.Net.Layer1.UsermessageInBuffer = GLib.MakeConstructor (self, GLib.Net.InBuffer)

function self:ctor (umsg)
	self.Usermessage = umsg
	
	-- Work out what our position really is
	self.Position = 1
	self.Usermessage:Reset ()
	self:StringZ () -- The usermessage name
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

function self:Pin ()
	return GLib.Net.Layer1.PinnedUsermessageInBuffer (self)
end

function self:UInt8 ()
	self.Position = self.Position + 1
	
	local n = self.Usermessage:ReadChar ()
	if n < 0 then n = n + 0x0100 end
	return n
end

function self:UInt16 ()
	self.Position = self.Position + 2
	
	local n = self.Usermessage:ReadShort ()
	if n < 0 then n = n + 0x00010000 end
	return n
end

function self:UInt32 ()
	self.Position = self.Position + 4
	
	local n = self.Usermessage:ReadLong ()
	if n < 0 then n = n + 4294967296 end
	return n
end

function self:Int8 ()
	self.Position = self.Position + 1
	return self.Usermessage:ReadChar ()
end

function self:Int16 ()
	self.Position = self.Position + 2
	return self.Usermessage:ReadShort ()
end

function self:Int32 ()
	self.Position = self.Position + 4
	return self.Usermessage:ReadLong ()
end

function self:Float ()
	self.Position = self.Position + 4
	return self.Usermessage:ReadFloat ()
end

function self:String ()
	return self:StringN8 ()
end

function self:LongString ()
	return self:StringN32 ()
end

function self:ToStringInBuffer ()
	local outBuffer = GLib.StringOutBuffer ()
	
	-- Copy buffer
	self.Usermessage:Reset ()
	for i = 1, 256 do
		outBuffer:Int8 (self.Usermessage:ReadChar ())
	end
	
	-- Reset position
	self.Usermessage:Reset ()
	for i = 1, self.Position - 1 do
		self.Usermessage:ReadChar ()
	end
	
	return GLib.StringInBuffer (outBuffer:GetString ())
end