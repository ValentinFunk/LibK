local self = {}
GAuth.Protocol.PermissionBlock.InheritPermissionsChangeResponse = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlock.InheritPermissionsChange", GAuth.Protocol.PermissionBlock.InheritPermissionsChangeResponse)

function self:ctor (permissionBlock)
	self.PermissionBlock = permissionBlock
end

function self:HandleInitialPacket (inBuffer)
	local inheritPermissions = inBuffer:Boolean ()
	
	self.PermissionBlock:SetInheritPermissions (self:GetRemoteEndPoint ():GetRemoteId (), inheritPermissions,
		function (returnCode)
			local outBuffer = self:CreatePacket ()
			outBuffer:UInt8 (returnCode)
			self:QueuePacket (outBuffer)
			self:Close ()
		end
	)
end

function self:ToString ()
	return "InheritPermissionsChange {" .. self.PermissionBlock:GetName () .. "}"
end