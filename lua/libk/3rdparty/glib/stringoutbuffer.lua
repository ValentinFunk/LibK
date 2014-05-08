local self = {}
GLib.StringOutBuffer = GLib.MakeConstructor (self)

function self:ctor ()
	self.Data = {}
end

function self:Clear ()
	self.Data = {}
end

function self:GetSize ()
	return #self:GetString ()
end

function self:GetString ()
	if #self.Data > 1 then
		self.Data = { table.concat (self.Data) }
	end
	return self.Data [1] or ""
end

function self:UInt8 (n)
	self.Data [#self.Data + 1] = string.char (n)
end

function self:UInt16 (n)
	self.Data [#self.Data + 1] = string.char (n % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 256))
end

function self:UInt32 (n)
	self.Data [#self.Data + 1] = string.char (n % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 256) % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 65536) % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 16777216) % 256)
end

function self:UInt64 (n)
	self.Data [#self.Data + 1] = string.char (n % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 256) % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 65536) % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 16777216) % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 4294967296) % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 1099511627776) % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 281474976710656) % 256)
	self.Data [#self.Data + 1] = string.char (math.floor (n / 72057594037927936) % 256)
end

function self:ULEB128 (n)
	if n ~= n then n = 0 end
	if n < 0 then n = -n end
	if n >= 4294967296 then n = 4294967295 end
	
	while n > 0 do
		if n >= 0x80 then
			self:UInt8 (0x80 + bit.band (n, 0x7F))
			n = math.floor (n / 0x80)
		else
			self:UInt8 (bit.band (n, 0x7F))
		end
	end
end

function self:Int8 (n)
	if n < 0 then n = n + 256 end
	self:UInt8 (n)
end

function self:Int16 (n)
	if n < 0 then n = n + 65536 end
	self:UInt16 (n)
end

function self:Int32 (n)
	if n < 0 then n = n + 4294967296 end
	self:UInt32 (n)
end

function self:Int64 (n)
	self:UInt32 (n % 4294967296)
	self:Int32 (math.floor (n / 4294967296))
end

function self:Float (f)
	local n = GLib.BitConverter.FloatToUInt32 (f)
	self:UInt32 (n)
end

function self:Double (f)
	local low, high = GLib.BitConverter.DoubleToUInt32s (f)
	self:UInt32 (low)
	self:UInt32 (high)
end

function self:Vector (v)
	self:Float (v.x)
	self:Float (v.y)
	self:Float (v.z)
end

function self:Char (char)
	self.Data [#self.Data + 1] = string.sub (char, 1, 1)
end

function self:Bytes (data, length)
	length = length or #data
	self.Data [#self.Data + 1] = string.sub (data, 1, length)
end

function self:String (data)
	data = data or ""
	self:UInt16 (data:len ())
	self.Data [#self.Data + 1] = data
end

function self:LongString (data)
	self:UInt32 (data:len ())
	self.Data [#self.Data + 1] = data
end

function self:StringZ (data)
	data = data or ""
	self.Data [#self.Data + 1] = data
	self.Data [#self.Data + 1] = "\0"
end

function self:Boolean (b)
	self:UInt8 (b and 1 or 0)
end

self.__len      = self.GetSize
self.__tostring = self.GetString