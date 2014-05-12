local self = {}
GAuth.Protocol.PermissionBlock.GroupEntryAdditionNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.GroupEntryAdditionNotification", GAuth.Protocol.PermissionBlock.GroupEntryAdditionNotification)

function self:ctor (permissionBlock, groupId)
	self.PermissionBlock = permissionBlock
	self.GroupId = groupId
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
end

function self:HandleInitialPacket (inBuffer)
	self.GroupId = inBuffer:String ()
	
	self.PermissionBlock:DispatchEvent ("NotifyGroupEntryAdded", self.GroupId)
end

function self:ToString ()
	return "GroupEntryAddition {" .. self.PermissionBlock:GetName () .. "}"
end