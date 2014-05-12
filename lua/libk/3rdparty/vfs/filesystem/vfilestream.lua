local self = {}
VFS.VFileStream = VFS.MakeConstructor (self, VFS.IFileStream)

function self:ctor (vfile, openFlags)
	self.File = vfile
	self.OpenFlags = openFlags
	if bit.band (self.OpenFlags, VFS.OpenFlags.Overwrite) ~= 0 then
		self.File.Contents = ""
		self.File:SetSize (0)
	end
end

function self:CanWrite ()
	return bit.band (self.OpenFlags, VFS.OpenFlags.Write) ~= 0
end

function self:Close ()
end

function self:Flush ()
end

function self:GetDisplayPath ()
	return self.File:GetDisplayPath ()
end

function self:GetFile ()
	return self.File
end

function self:GetLength ()
	return self.File:GetSize ()
end

function self:GetPath ()
	return self.File:GetPath ()
end

function self:Read (size, callback)
	local startPos = self:GetPos ()
	self:Seek (startPos + size)
	callback (VFS.ReturnCode.Success, self.File.Contents:sub (startPos + 1, startPos + size))
end

function self:Write (size, data, callback)
	if not self:CanWrite () then callback (VFS.ReturnCode.AccessDenied) return end
	if size == 0 then callback (VFS.ReturnCode.Success) return end
	
	if data:len () < size then data = data .. string.rep ("\0", size - data:len ()) end
	if data:len () > size then data = data:sub (1, size) end
	self.File.Contents = self.File.Contents:sub (1, self:GetPos ()) .. data .. self.File.Contents:sub (self:GetPos () + size + 1)
	if self:GetPos () + size > self.File:GetSize () then
		self.File:SetSize (self:GetPos () + size)
	end
	self:Seek (self:GetPos () + size)
	self.File:SetModificationTime (os.time ())
	
	callback (VFS.ReturnCode.Success)
end