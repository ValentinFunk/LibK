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

function self:UInt8  (n) self.Data [#self.Data + 1] = string_char (GLib.BitConverter.UInt8ToUInt8s  (n)) end
function self:UInt16 (n) self.Data [#self.Data + 1] = string_char (GLib.BitConverter.UInt16ToUInt8s (n)) end
function self:UInt32 (n) self.Data [#self.Data + 1] = string_char (GLib.BitConverter.UInt32ToUInt8s (n)) end
function self:UInt64 (n) self.Data [#self.Data + 1] = string_char (GLib.BitConverter.UInt64ToUInt8s (n)) end
function self:Int8   (n) self.Data [#self.Data + 1] = string_char (GLib.BitConverter.Int8ToUInt8s   (n)) end
function self:Int16  (n) self.Data [#self.Data + 1] = string_char (GLib.BitConverter.Int16ToUInt8s  (n)) end
function self:Int32  (n) self.Data [#self.Data + 1] = string_char (GLib.BitConverter.Int32ToUInt8s  (n)) end
function self:Int64  (n) self.Data [#self.Data + 1] = string_char (GLib.BitConverter.Int64ToUInt8s  (n)) end

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