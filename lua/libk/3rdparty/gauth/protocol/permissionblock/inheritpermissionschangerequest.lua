local self = {}
GAuth.Protocol.PermissionBlock.InheritPermissionsChangeRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.InheritPermissionsChange", GAuth.Protocol.PermissionBlock.InheritPermissionsChangeRequest)

function self:ctor (permissionBlock, authId, inheritPermissions, callback)
	self.Callback = callback or GAuth.NullCallback
	self.PermissionBlock = permissionBlock
	self.InheritPermissions = inheritPermissions
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:Boolean (self.InheritPermissions)
end

function self:HandlePacket (inBuffer)
	self.Callback (inBuffer:UInt8 ())
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (GAuth.ReturnCode.TimedOut)
end

function self:ToString ()
	return "InheritPermissionsChange {" .. self.PermissionBlock:GetName () .. "}"
end