local self = {}
VFS.Protocol.NodeDeletionNotification = VFS.MakeConstructor (self, VFS.Protocol.Session)
VFS.Protocol.RegisterNotification ("NodeDeletionNotification", VFS.Protocol.NodeDeletionNotification)

function self:ctor (folder, childNode)
	self.FolderPath = folder and folder:GetPath ()
	self.ChildName = childNode and childNode:GetName ()
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.FolderPath)
	outBuffer:String (self.ChildName)
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	self.ChildName = inBuffer:String ()
	
	local folder = self:GetRemoteEndPoint ():GetRoot ():GetChildSynchronous (self.FolderPath)
	folder = folder and folder:GetInner ()
	if not folder then return end
	if not folder:IsNetNode () then return end
	local deletedNode = folder.Children [self.ChildName] or (folder:IsCaseInsensitive () and folder.LowercaseChildren [self.ChildName:lower ()] or nil)
	if not deletedNode then return end
	folder.Children [self.ChildName] = nil
	folder.LowercaseChildren [self.ChildName:lower ()] = nil
	folder:DispatchEvent ("NodeDeleted", deletedNode)
	deletedNode:DispatchEvent ("Deleted")
end