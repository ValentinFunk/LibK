local self = {}
GAuth.Protocol.PermissionBlock.GroupEntryAdditionResponse = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.GroupEntryAddition", GAuth.Protocol.PermissionBlock.GroupEntryAdditionResponse)

function self:ctor (permissionBlock)
	self.PermissionBlock = permissionBlock
end

function self:HandleInitialPacket (inBuffer)
	local groupId = inBuffer:String ()
	
	self.PermissionBlock:AddGroupEntry (self:GetRemoteEndPoint ():GetRemoteId (), groupId,
		function (returnCode)
			local outBuffer = self:CreatePacket ()
			outBuffer:UInt8 (returnCode)
			self:QueuePacket (outBuffer)
			self:Close ()
		end
	)
end

function self:ToString ()
	return "GroupEntryAddition {" .. self.PermissionBlock:GetName () .. "}"
end