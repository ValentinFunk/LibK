local self = {}
GAuth.Protocol.PermissionBlock.OwnerChangeRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.OwnerChange", GAuth.Protocol.PermissionBlock.OwnerChangeRequest)

function self:ctor (permissionBlock, authId, ownerId, callback)
	self.Callback = callback or GAuth.NullCallback
	self.PermissionBlock = permissionBlock
	self.OwnerId = ownerId
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.OwnerId)
end

function self:HandlePacket (inBuffer)
	self.Callback (inBuffer:UInt8 ())
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (GAuth.ReturnCode.TimedOut)
end

function self:ToString ()
	return "OwnerChange {" .. self.PermissionBlock:GetName () .. "}"
end