local self = {}
GAuth.Protocol.PermissionBlock.GroupPermissionChangeRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.GroupPermissionChange", GAuth.Protocol.PermissionBlock.GroupPermissionChangeRequest)

function self:ctor (permissionBlock, authId, groupId, actionId, access, callback)
	self.Callback = callback or GAuth.NullCallback
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

function self:HandlePacket (inBuffer)
	self.Callback (inBuffer:UInt8 ())
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (GAuth.ReturnCode.TimedOut)
end

function self:ToString ()
	return "GroupPermissionChange {" .. self.PermissionBlock:GetName () .. "}"
end