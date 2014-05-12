local self = {}
GAuth.Protocol.PermissionBlock.GroupEntryRemovalResponse = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.GroupEntryRemoval", GAuth.Protocol.PermissionBlock.GroupEntryRemovalResponse)

function self:ctor (permissionBlock)
	self.PermissionBlock = permissionBlock
end

function self:HandleInitialPacket (inBuffer)
	local groupId = inBuffer:String ()
	
	self.PermissionBlock:RemoveGroupEntry (self:GetRemoteEndPoint ():GetRemoteId (), groupId,
		function (returnCode)
			local outBuffer = self:CreatePacket ()
			outBuffer:UInt8 (returnCode)
			self:QueuePacket (outBuffer)
			self:Close ()
		end
	)
end

function self:ToString ()
	return "GroupEntryRemoval {" .. self.PermissionBlock:GetName () .. "}"
end