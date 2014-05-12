local self = {}
GAuth.Protocol.PermissionBlock.OwnerChangeNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.OwnerChangeNotification", GAuth.Protocol.PermissionBlock.OwnerChangeNotification)

function self:ctor (permissionBlock, ownerId)
	self.PermissionBlock = permissionBlock
	self.OwnerId = ownerId
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.OwnerId)
end

function self:HandleInitialPacket (inBuffer)
	self.OwnerId = inBuffer:String ()
	
	self.PermissionBlock:DispatchEvent ("NotifyOwnerChanged", self.OwnerId)
end

function self:ToString ()
	return "OwnerChange {" .. self.PermissionBlock:GetName () .. "}"
end