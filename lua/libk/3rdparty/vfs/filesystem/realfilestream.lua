local self = {}
VFS.RealFileStream = VFS.MakeConstructor (self, VFS.IFileStream)

function self:ctor (realFile, openFlags)
	self.File = realFile
	self.OpenFlags = openFlags
	self.ContentsChanged = false
	
	if bit.band (self.OpenFlags, VFS.OpenFlags.Overwrite) ~= 0 then
		self.Contents = ""
		self.Length = 0
		self.ContentsChanged = true
	else
		local f = file.Open (self:GetPath (), "rb", self.File:GetFileSystemPath ())
		if f then
			self.Contents = f:Read (f:Size ()) or ""
			self.Length = #self.Contents
			f:Close ()
		else
			self.Contents = ""
			self.Length   = 0
			self.ContentsChanged = true
		end
	end
	self.File:SetSize (self.Length)
end

function self:CanWrite ()
	return bit.band (self.OpenFlags, VFS.OpenFlags.Write) ~= 0
end

function self:Close ()
	self:Flush ()
end

function self:Flush ()
	if not self.ContentsChanged then return end
	if self.File:GetPath ():lower ():sub (1, 5) == "data/" and
	   self.File:GetPath ():lower ():sub (-4) == ".txt" then
		local f = file.Open (self.File:GetPath ():sub (6), "wb", "DATA")
		if not f then return end
		
		f:Write (self.Contents)
		f:Flush ()
		f:Close ()
		
		self.ContentsChanged = false
		
		self.File:UpdateModificationTime (true)
		self.File:UpdateSize (true)
		
		self.File:DispatchEvent ("Updated", VFS.UpdateFlags.Size + VFS.UpdateFlags.ModificationTime)
		if self.File:GetParentFolder () then
			self.File:GetParentFolder ():DispatchEvent ("NodeUpdated", self.File, VFS.UpdateFlags.Size + VFS.UpdateFlags.ModificationTime)
		end
	end
end

function self:GetDisplayPath ()
	return self.File:GetDisplayPath ()
end

function self:GetFile ()
	return self.File
end

function self:GetLength ()
	return self.Length
end

function self:GetPath ()
	return self.File:GetPath ()
end

function self:Read (size, callback)
	self.Contents = self.Contents or file.Read (self.File:GetPath (), self.File:GetFileSystemPath ()) or ""
	local startPos = self:GetPos ()
	self:Seek (startPos + size)
	callback (VFS.ReturnCode.Success, string.sub (self.Contents, startPos + 1, startPos + size))
end

function self:Write (size, data, callback)
	if not self:CanWrite () then callback (VFS.ReturnCode.AccessDenied) return end
	if size == 0 then callback (VFS.ReturnCode.Success) return end
	
	self.Contents = self.Contents or file.Read (self.File:GetPath (), self.File:GetFileSystemPath ()) or ""
	if data:len () < size then data = data .. string.rep ("\0", size - data:len ()) end
	if data:len () > size then data = data:sub (1, size) end
	self.Contents = self.Contents:sub (1, self:GetPos ()) .. data .. self.Contents:sub (self:GetPos () + size + 1)
	if self:GetPos () + size > self.Length then self.Length = self:GetPos () + size end
	self:Seek (self:GetPos () + size)
	self.ContentsChanged = true
	callback (VFS.ReturnCode.Success)
end