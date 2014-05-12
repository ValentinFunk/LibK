local self = {}
VFS.IFileStream = VFS.MakeConstructor (self)

function self:ctor ()
	self.AuthId = ""
	self.Closed = false
	self.Position = 0
end

function self:CanWrite ()
	return false
end

function self:Close ()
	self:Flush ()
	self.Closed = true
end

function self:Flush ()
	VFS.Error ("IFileStream:Flush : Not implemented")
end

function self:GetFile ()
end

function self:GetDisplayPath ()
	return self:GetFile ():GetDisplayPath ()
end

function self:GetLength ()
	return self:GetFile ():GetSize ()
end

function self:GetPath ()
	return self:GetFile ():GetPath ()
end

function self:GetPos ()
	return self.Position
end

function self:IsClosed ()
	return self.Closed
end

--[[
	IFileStream:Read (size, function (returnCode, data))
	
		returnCode may be Success, Progress or TimedOut.
]]
function self:Read (size, callback)
	VFS.Error ("IFileStream:Read : Not implemented")
	
	callback (VFS.ReturnCode.Success, "")
end

function self:Seek (pos)
	self.Position = pos
end

--[[
	IFileStream:Write (size, data, function (returnCode))
	
		returnCode may be Success, Progress or TimedOut.
]]
function self:Write (size, data, callback)
	VFS.Error ("IFileStream:Write : Not implemented")

	callback (VFS.ReturnCode.Success)
end