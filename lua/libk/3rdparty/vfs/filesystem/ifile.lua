local self = {}
VFS.IFile = VFS.MakeConstructor (self, VFS.INode)

function self:ctor ()
end

function self:GetExtension ()
	return string.match (self:GetName (), "%.([^%.]*)$")
end

function self:GetName ()
	VFS.Error ("IFile:GetName : Not implemented")
	return "[File]"
end

function self:GetNodeType ()
	return VFS.NodeType.File
end

--[[
	IFile:GetSize ()
		Returns: int fileSizeInBytes
		
		Returns the size of the file in bytes, or -1 if unavailable
]]
function self:GetSize ()
	return -1
end

--[[
	IFile:Open (authId, OpenFlags, function (returnCode, IFileStream))
]]
function self:Open (authId, openFlags, callback)
	VFS.Error ("IFile:Open : Not implemented")
	return callback (VFS.ReturnCode.AccessDenied)
end