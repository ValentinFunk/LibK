local self = {}
GLib.StringInBuffer = GLib.MakeConstructor (self, GLib.InBuffer)

local math_max    = math.max

local string_byte = string.byte
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

function self:SeekTo (seekPos)
	self.Position = seekPos
end

function self:UInt8 ()
	local n = string_byte (self.Data, self.Position) or 0
	self.Position = self.Position + 1
	return n
end

function self:UInt16 ()
	local n = string_byte (self.Data, self.Position) or 0
	n = n + (string_byte (self.Data, self.Position + 1) or 0) * 256
	self.Position = self.Position + 2
	return n
end

function self:UInt32 ()
	local n = string_byte (self.Data, self.Position) or 0
	n = n + (string_byte (self.Data, self.Position + 1) or 0) * 256
	n = n + (string_byte (self.Data, self.Position + 2) or 0) * 65536
	n = n + (string_byte (self.Data, self.Position + 3) or 0) * 16777216
	self.Position = self.Position + 4
	return n
end

function self:UInt64 ()
	local n = string_byte (self.Data, self.Position) or 0
	n = n + (string_byte (self.Data, self.Position + 1) or 0) * 256
	n = n + (string_byte (self.Data, self.Position + 2) or 0) * 65536
	n = n + (string_byte (self.Data, self.Position + 3) or 0) * 16777216
	n = n + (string_byte (self.Data, self.Position + 4) or 0) * 4294967296
	n = n + (string_byte (self.Data, self.Position + 5) or 0) * 1099511627776
	n = n + (string_byte (self.Data, self.Position + 6) or 0) * 281474976710656
	n = n + (string_byte (self.Data, self.Position + 7) or 0) * 72057594037927936
	self.Position = self.Position + 8
	return n
end

function self:Int8 ()
	local n = self:UInt8 ()
	if n >= 128 then n = n - 256 end
	return n
end

function self:Int16 ()
	local n = self:UInt16 ()
	if n >= 32768 then n = n - 65536 end
	return n
end

function self:Int32 ()
	local n = self:UInt32 ()
	if n >= 2147483648 then n = n - 4294967296 end
	return n
end

function self:Char ()
	local char = string_sub (self.Data, self.Position, self.Position)
	self.Position = self.Position + 1
	return char
end

function self:Bytes (length)
	local str = string_sub (self.Data, self.Position, self.Position + length - 1)
	self.Position = self.Position + length
	return str
end

function self:String ()
	return self:StringN16 ()
end

function self:LongString ()
	return self:StringN32 ()
end