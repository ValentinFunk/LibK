local self = {}
VFS.MemoryFileStream = VFS.MakeConstructor (self, VFS.IFileStream)

function self:ctor (data)
	self.Path = nil
	self.DisplayPath = nil
	
	self.Data = data
end

function self:Flush ()
end

function self:GetDisplayPath ()
	return self.DisplayPath or self:GetPath ()
end

function self:GetLength ()
	return #self.Data
end

function self:GetPath ()
	return self.Path
end

function self:Read (size, callback)
	local startPos = self:GetPos ()
	self:Seek (startPos + size)
	callback (VFS.ReturnCode.Success, string.sub (self.Data, startPos + 1, startPos + size))
end

function self:SetDisplayPath (displayPath)
	self.DisplayPath = displayPath
end

function self:SetPath (path)
	self.Path = path
end