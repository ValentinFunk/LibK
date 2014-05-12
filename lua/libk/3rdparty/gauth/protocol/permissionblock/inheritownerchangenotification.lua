local self = {}
GAuth.Protocol.PermissionBlock.InheritOwnerChangeNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.InheritOwnerChangeNotification", GAuth.Protocol.PermissionBlock.InheritOwnerChangeNotification)

function self:ctor (permissionBlock, inheritOwner)
	self.PermissionBlock = permissionBlock
	self.InheritOwner = inheritOwner
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:Boolean (self.InheritOwner)
end

function self:HandleInitialPacket (inBuffer)
	self.InheritOwner = inBuffer:Boolean ()
	
	self.PermissionBlock:DispatchEvent ("NotifyInheritOwnerChanged", self.InheritOwner)
end

function self:ToString ()
	return "InheritOwnerChange {" .. self.PermissionBlock:GetName () .. "}"
end