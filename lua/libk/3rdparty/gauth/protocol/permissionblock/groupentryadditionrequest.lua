local self = {}
GAuth.Protocol.PermissionBlock.GroupEntryAdditionRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.GroupEntryAddition", GAuth.Protocol.PermissionBlock.GroupEntryAdditionRequest)

function self:ctor (permissionBlock, authId, groupId, callback)
	self.Callback = callback or GAuth.NullCallback
	self.PermissionBlock = permissionBlock
	self.GroupId = groupId
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
end

function self:HandlePacket (inBuffer)
	self.Callback (inBuffer:UInt8 ())
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (GAuth.ReturnCode.TimedOut)
end

function self:ToString ()
	return "GroupEntryAddition {" .. self.PermissionBlock:GetName () .. "}"
end