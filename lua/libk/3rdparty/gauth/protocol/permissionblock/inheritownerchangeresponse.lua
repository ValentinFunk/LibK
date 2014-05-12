local self = {}
GAuth.Protocol.PermissionBlock.InheritOwnerChangeResponse = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.InheritOwnerChange", GAuth.Protocol.PermissionBlock.InheritOwnerChangeResponse)

function self:ctor (permissionBlock)
	self.PermissionBlock = permissionBlock
end

function self:HandleInitialPacket (inBuffer)
	local inheritOwner = inBuffer:Boolean ()
	
	self.PermissionBlock:SetInheritOwner (self:GetRemoteEndPoint ():GetRemoteId (), inheritOwner,
		function (returnCode)
			local outBuffer = self:CreatePacket ()
			outBuffer:UInt8 (returnCode)
			self:QueuePacket (outBuffer)
			self:Close ()
		end
	)
end

function self:ToString ()
	return "InheritOwnerChange {" .. self.PermissionBlock:GetName () .. "}"
end