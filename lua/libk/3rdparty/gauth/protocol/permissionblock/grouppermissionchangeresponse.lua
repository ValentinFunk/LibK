local self = {}
GAuth.Protocol.PermissionBlock.GroupPermissionChangeResponse = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.GroupPermissionChange", GAuth.Protocol.PermissionBlock.GroupPermissionChangeResponse)

function self:ctor (permissionBlock)
	self.PermissionBlock = permissionBlock
end

function self:HandleInitialPacket (inBuffer)
	local groupId = inBuffer:String ()
	local actionId = inBuffer:String ()
	local access = inBuffer:UInt8 ()
	
	self.PermissionBlock:SetGroupPermission (self:GetRemoteEndPoint ():GetRemoteId (), groupId, actionId, access,
		function (returnCode)
			local outBuffer = self:CreatePacket ()
			outBuffer:UInt8 (returnCode)
			self:QueuePacket (outBuffer)
			self:Close ()
		end
	)
end

function self:ToString ()
	return "GroupPermissionChange {" .. self.PermissionBlock:GetName () .. "}"
end