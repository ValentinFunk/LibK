local self = {}
GAuth.Protocol.PermissionBlock.OwnerChangeResponse = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.OwnerChange", GAuth.Protocol.PermissionBlock.OwnerChangeResponse)

function self:ctor (permissionBlock)
	self.PermissionBlock = permissionBlock
end

function self:HandleInitialPacket (inBuffer)
	local ownerId = inBuffer:String ()
	
	self.PermissionBlock:SetOwner (self:GetRemoteEndPoint ():GetRemoteId (), ownerId,
		function (returnCode)
			local outBuffer = self:CreatePacket ()
			outBuffer:UInt8 (returnCode)
			self:QueuePacket (outBuffer)
			self:Close ()
		end
	)
end

function self:ToString ()
	return "OwnerChange {" .. self.PermissionBlock:GetName () .. "}"
end