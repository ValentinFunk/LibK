local self = {}
VFS.Protocol.Register ("NodeDeletion", self)
VFS.Protocol.NodeDeletionRequest = VFS.MakeConstructor (self, VFS.Protocol.Session)

function self:ctor (folder, childName, isFolder, callback)
	self.Callback = callback or VFS.NullCallback
	self.Folder = folder
	self.ChildName = childName
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Folder:GetPath ())
	outBuffer:String (self.ChildName)
end

function self:HandlePacket (inBuffer)
	local returnCode = inBuffer:UInt8 ()
	self.Callback (returnCode)
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (VFS.ReturnCode.TimedOut)
end