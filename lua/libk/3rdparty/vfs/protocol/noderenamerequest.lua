local self = {}
VFS.Protocol.Register ("NodeRename", self)
VFS.Protocol.NodeRenameRequest = VFS.MakeConstructor (self, VFS.Protocol.Session)

function self:ctor (folder, oldName, newName, callback)
	self.Callback = callback or VFS.NullCallback
	self.Folder = folder
	self.OldName = oldName
	self.NewName = newName
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Folder:GetPath ())
	outBuffer:String (self.OldName)
	outBuffer:String (self.NewName)
end

function self:HandlePacket (inBuffer)
	local returnCode = inBuffer:UInt8 ()
	self.Callback (returnCode)
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (VFS.ReturnCode.TimedOut)
end