local self = {}
GAuth.Protocol.PermissionBlock.GroupEntryRemovalNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.GroupEntryRemovalNotification", GAuth.Protocol.PermissionBlock.GroupEntryRemovalNotification)

function self:ctor (permissionBlock, groupId)
	self.PermissionBlock = permissionBlock
	self.GroupId = groupId
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
end

function self:HandleInitialPacket (inBuffer)
	self.GroupId = inBuffer:String ()
	
	self.PermissionBlock:DispatchEvent ("NotifyGroupEntryRemoved", self.GroupId)
end

function self:ToString ()
	return "GroupEntryRemoval {" .. self.PermissionBlock:GetName () .. "}"
end