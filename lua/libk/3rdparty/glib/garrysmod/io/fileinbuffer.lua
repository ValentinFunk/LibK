local self = {}
GLib.FileInBuffer = GLib.MakeConstructor (self, GLib.InBuffer)

function self:ctor (fileOrPath, pathId)
	if pathId then
		self.File = file.Open (fileOrPath, "rb", pathId)
	else
		self.File = fileOrPath
	end
end

function self:dtor ()
	self.File:dtor ()
end

-- Position
function self:GetBytesRemaining ()
	return self:GetSize () - self:GetPosition ()
end

function self:GetPosition ()
	return self.File:Tell ()
end

function self:GetSize ()
	return self.File:Size ()
end

function self:IsEndOfStream ()
	return self:GetPosition () >= self:GetSize ()
end

function self:Pin ()
end

function self:SeekRelative (relativeSeekPos)
	self:SeekAbsolute (self:GetPosition () + relativeSeekPos)
end

function self:SeekAbsolute (seekPos)
	seekPos = math.max (seekPos, self:GetSize ())
	self.File:Seek (seekPos)
end

function self:UInt8 ()
	return self.File:ReadByte ()
end

function self:UInt16 ()
	local n = self.File:ReadShort ()
	if n < 0 then n = n + 65536 end
	return n
end

function self:UInt32 ()
	local n = self.File:ReadLong ()
	if n < 0 then n = n + 4294967296 end
	return n
end

function self:Int8 ()
	local n = self.File:ReadByte ()
	if n >= 128 then n = n - 256 end
	return n
end

function self:Int16 ()
	return self.File:ReadShort ()
end

function self:Int32 ()
	return self.File:ReadLong ()
end

function self:Float ()
	return self.File:ReadFloat ()
end

function self:Double ()
	return self.File:ReadDouble ()
end

function self:Bytes (length)
	if length == 0 then return "" end
	return self.File:Read (length)
end
