local self = {}
VFS.Protocol.Register ("NodeCreation", self)
VFS.Protocol.NodeCreationRequest = VFS.MakeConstructor (self, VFS.Protocol.Session)

function self:ctor (folder, childName, isFolder, callback)
	self.Callback = callback or VFS.NullCallback
	self.Folder = folder
	self.ChildName = childName
	self.IsFolder = isFolder
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Folder:GetPath ())
	outBuffer:String (self.ChildName)
	outBuffer:Boolean (self.IsFolder)
end

function self:HandlePacket (inBuffer)
	local returnCode = inBuffer:UInt8 ()
	if returnCode == VFS.ReturnCode.Success then
		self.Callback (returnCode, inBuffer)
	else
		self.Callback (returnCode)
	end
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (VFS.ReturnCode.TimedOut)
end