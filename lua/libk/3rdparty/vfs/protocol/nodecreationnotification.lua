local self = {}
VFS.Protocol.NodeCreationNotification = VFS.MakeConstructor (self, VFS.Protocol.Session)
VFS.Protocol.RegisterNotification ("NodeCreationNotification", VFS.Protocol.NodeCreationNotification)

function self:ctor (folder, childNode)
	self.FolderPath = folder and folder:GetPath ()
	self.ChildNode = childNode
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.FolderPath)
	self:SerializeNode (self.ChildNode, outBuffer)
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	
	local folder = self:GetRemoteEndPoint ():GetRoot ():GetChildSynchronous (self.FolderPath)
	folder = folder and folder:GetInner ()
	if not folder then return end
	if not folder:IsNetNode () then return end
	folder:DeserializeNode (inBuffer)
end