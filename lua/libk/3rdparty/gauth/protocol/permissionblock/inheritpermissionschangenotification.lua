local self = {}
GAuth.Protocol.PermissionBlock.InheritPermissionsChangeNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.InheritPermissionsChangeNotification", GAuth.Protocol.PermissionBlock.InheritPermissionsChangeNotification)

function self:ctor (permissionBlock, inheritPermissions)
	self.PermissionBlock = permissionBlock
	self.InheritPermissions = inheritPermissions
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:Boolean (self.InheritPermissions)
end

function self:HandleInitialPacket (inBuffer)
	self.InheritPermissions = inBuffer:Boolean ()
	
	self.PermissionBlock:DispatchEvent ("NotifyInheritPermissionsChanged", self.InheritPermissions)
end

function self:ToString ()
	return "InheritPermissionsChange {" .. self.PermissionBlock:GetName () .. "}"
end