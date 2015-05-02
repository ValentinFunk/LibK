local self = {}
GLib.StringOutBuffer = GLib.MakeConstructor (self, GLib.OutBuffer)

local bit_band     = bit.band
local bit_rshift   = bit.rshift

local math_floor   = math.floor
local math_min     = math.min

local string_char  = string.char
local string_sub   = string.sub

local table_concat = table.concat

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
		self.Data = { table_concat (self.Data) }
	end
	return self.Data [1] or ""
end

function self:UInt8 (n)
	self.Data [#self.Data + 1] = string_char (
		bit_band (           n,      0xFF)
	)
end

function self:UInt16 (n)
	self.Data [#self.Data + 1] = string_char (
		bit_band (           n,      0xFF),
		bit_band (bit_rshift(n,  8), 0xFF)
	)
end

function self:UInt32 (n)
	self.Data [#self.Data + 1] = string_char (
		bit_band (           n,      0xFF),
		bit_band (bit_rshift(n,  8), 0xFF),
		bit_band (bit_rshift(n, 16), 0xFF),
		bit_band (bit_rshift(n, 24), 0xFF)
	)
end

function self:UInt64 (n)
	self.Data [#self.Data + 1] = string_char (            n                      % 256)
	self.Data [#self.Data + 1] = string_char (math_floor (n /               256) % 256)
	self.Data [#self.Data + 1] = string_char (math_floor (n /             65536) % 256)
	self.Data [#self.Data + 1] = string_char (math_floor (n /          16777216) % 256)
	self.Data [#self.Data + 1] = string_char (math_floor (n /        4294967296) % 256)
	self.Data [#self.Data + 1] = string_char (math_floor (n /     1099511627776) % 256)
	self.Data [#self.Data + 1] = string_char (math_floor (n /   281474976710656) % 256)
	self.Data [#self.Data + 1] = string_char (math_floor (n / 72057594037927936) % 256)
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

function self:Char (char)
	self.Data [#self.Data + 1] = string_sub (char, 1, 1)
end

function self:Bytes (data, length)
	length = length or #data
	length = math_min (length, #data)
	self.Data [#self.Data + 1] = length == #data and data or string_sub (data, 1, length)
end

function self:String (data)
	self:StringN16 (data)
end

function self:LongString (data)
	self:StringN32 (data)
end

self.__len      = self.GetSize
self.__tostring = self.GetString