local self = {}
GAuth.Protocol.PermissionBlock.GroupPermissionChangeNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.GroupPermissionChangeNotification", GAuth.Protocol.PermissionBlock.GroupPermissionChangeNotification)

function self:ctor (permissionBlock, groupId, actionId, access)
	self.PermissionBlock = permissionBlock
	self.GroupId = groupId
	self.ActionId = actionId
	self.Access = access
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
	outBuffer:String (self.ActionId)
	outBuffer:UInt8 (self.Access)
end

function self:HandleInitialPacket (inBuffer)
	self.GroupId = inBuffer:String ()
	self.ActionId = inBuffer:String ()
	self.Access = inBuffer:UInt8 ()
	
	self.PermissionBlock:DispatchEvent ("NotifyGroupPermissionChanged", self.GroupId, self.ActionId, self.Access)
end

function self:ToString ()
	return "GroupPermissionChange {" .. self.PermissionBlock:GetName () .. "}"
end