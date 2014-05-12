local self = {}
VFS.Protocol.NodeRenameNotification = VFS.MakeConstructor (self, VFS.Protocol.Session)
VFS.Protocol.RegisterNotification ("NodeRenameNotification", VFS.Protocol.NodeRenameNotification)

function self:ctor (folder, oldName, newName)
	self.FolderPath = folder and folder:GetPath ()
	self.OldName = oldName
	self.NewName = newName
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.FolderPath)
	outBuffer:String (self.OldName)
	outBuffer:String (self.NewName)
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	self.OldName = inBuffer:String ()
	self.NewName = inBuffer:String ()
	
	local folder = self:GetRemoteEndPoint ():GetRoot ():GetChildSynchronous (self.FolderPath)
	folder = folder and folder:GetInner ()
	if not folder then return end
	if not folder:IsNetNode () then return end
	local renamedNode = folder:GetDirectChildSynchronous (self.OldName)
	if not renamedNode then return end
	
	renamedNode.Name = self.NewName
	folder.Children [self.NewName] = renamedNode
	folder.Children [self.OldName] = nil
	folder.LowercaseChildren [self.NewName:lower ()] = renamedNode
	folder.LowercaseChildren [self.OldName:lower ()] = nil
	
	folder:DispatchEvent ("NodeRenamed", renamedNode, self.OldName, self.NewName)
	renamedNode:DispatchEvent ("Renamed", self.OldName, self.NewName)
end