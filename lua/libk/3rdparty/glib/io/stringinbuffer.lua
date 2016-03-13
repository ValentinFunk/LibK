local self = {}
GLib.StringInBuffer = GLib.MakeConstructor (self, GLib.InBuffer)

local math_max    = math.max

local string_byte = string.byte
local string_find = string.find
local string_sub  = string.sub

function self:ctor (data)
	self.Data = data or ""
	self.Position = 1
end

-- Position
function self:GetBytesRemaining ()
	return math_max (0, #self.Data - self.Position + 1)
end

function self:GetPosition ()
	return self.Position
end

function self:GetSize ()
	return #self.Data
end

function self:IsEndOfStream ()
	return self.Position > #self.Data
end

function self:Pin ()
	return self
end

function self:SeekRelative (relativeSeekPos)
	self.Position = self.Position + relativeSeekPos
end

function self:SeekAbsolute (seekPos)
	self.Position = seekPos
end

function self:UInt8 ()
	local uint80 = string_byte (self.Data, self.Position, self.Position)
	self.Position = self.Position + 1
	return GLib.BitConverter.UInt8sToUInt8 (uint80 or 0)
end

function self:UInt16 ()
	local uint80, uint81 = string_byte (self.Data, self.Position, self.Position + 1)
	self.Position = self.Position + 2
	return GLib.BitConverter.UInt8sToUInt16 (uint80 or 0, uint81 or 0)
end

function self:UInt32 ()
	local uint80, uint81, uint82, uint83 = string_byte (self.Data, self.Position, self.Position + 3)
	self.Position = self.Position + 4
	return GLib.BitConverter.UInt8sToUInt32 (uint80 or 0, uint81 or 0, uint82 or 0, uint83 or 0)
end

function self:UInt64 ()
	local uint80, uint81, uint82, uint83, uint84, uint85, uint86, uint87 = string_byte (self.Data, self.Position, self.Position + 7)
	self.Position = self.Position + 8
	return GLib.BitConverter.UInt8sToUInt64 (uint80 or 0, uint81 or 0, uint82 or 0, uint83 or 0, uint84 or 0, uint85 or 0, uint86 or 0, uint87 or 0)
end

function self:Int8 ()
	local uint80 = string_byte (self.Data, self.Position, self.Position)
	self.Position = self.Position + 1
	return GLib.BitConverter.UInt8sToInt8 (uint80 or 0)
end

function self:Int16 ()
	local uint80, uint81 = string_byte (self.Data, self.Position, self.Position + 1)
	self.Position = self.Position + 2
	return GLib.BitConverter.UInt8sToInt16 (uint80 or 0, uint81 or 0)
end

function self:Int32 ()
	local uint80, uint81, uint82, uint83 = string_byte (self.Data, self.Position, self.Position + 3)
	self.Position = self.Position + 4
	return GLib.BitConverter.UInt8sToInt32 (uint80 or 0, uint81 or 0, uint82 or 0, uint83 or 0)
end

function self:Int64 ()
	local uint80, uint81, uint82, uint83, uint84, uint85, uint86, uint87 = string_byte (self.Data, self.Position, self.Position + 7)
	self.Position = self.Position + 8
	return GLib.BitConverter.UInt8sToInt64 (uint80 or 0, uint81 or 0, uint82 or 0, uint83 or 0, uint84 or 0, uint85 or 0, uint86 or 0, uint87 or 0)
end

function self:Bytes (length)
	local str = string_sub (self.Data, self.Position, self.Position + length - 1)
	self.Position = self.Position + length
	return str
end

function self:String ()
	return self:StringN16 ()
end

function self:StringZ ()
	local terminatorPosition = string_find (self.Data, "\0", self.Position, true)
	if terminatorPosition then
		local str = string_sub (self.Data, self.Position, terminatorPosition - 1)
		self.Position = terminatorPosition + 1
		return str
	else
		local str = string_sub (self.Data, self.Position)
		self.Position = #self.Data
		return str
	end
end

function self:LongString ()
	return self:StringN32 ()
end