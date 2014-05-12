local self = {}
GAuth.Protocol.PermissionBlock.InheritOwnerChangeRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.InheritOwnerChange", GAuth.Protocol.PermissionBlock.InheritOwnerChangeRequest)

function self:ctor (permissionBlock, authId, inheritOwner, callback)
	self.Callback = callback or GAuth.NullCallback
	self.PermissionBlock = permissionBlock
	self.InheritOwner = inheritOwner
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:Boolean (self.InheritOwner)
end

function self:HandlePacket (inBuffer)
	self.Callback (inBuffer:UInt8 ())
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (GAuth.ReturnCode.TimedOut)
end

function self:ToString ()
	return "InheritOwnerChange {" .. self.PermissionBlock:GetName () .. "}"
end