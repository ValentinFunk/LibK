local self = {}
VFS.NetFileStream = VFS.MakeConstructor (self, VFS.IFileStream)

function self:ctor (fileOpenRequest, netFile, length)
	self.File = netFile
	self.Session = fileOpenRequest
	
	self.Length = length
	
	self.Contents = ""
end

function self:Close ()
	self.Closed = true
	
	self.Session:CloseStream ()
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
	self.Session:Read (self:GetPos (), size, callback)
end

function self:Write (size, data, callback)
	self.Session:Write (self:GetPos (), size, data, callback)
end