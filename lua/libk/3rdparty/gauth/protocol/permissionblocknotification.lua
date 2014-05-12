local self = {}
GAuth.Protocol.PermissionBlockNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("PermissionBlockNotification", GAuth.Protocol.PermissionBlockNotification)

function self:ctor (systemName, permissionBlock, permissionBlockNotifications)
	self.SystemName = systemName
	self.PermissionBlock = permissionBlock
	if permissionBlockNotifications then
		if #permissionBlockNotifications > 0 then
			self.Sessions = permissionBlockNotifications
			self.SessionCount = #permissionBlockNotifications
		else
			self.Sessions = { permissionBlockNotifications }
			self.SessionCount = 1
		end
	else
		self.Sessions = {}
		self.SessionCount = 0
	end
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:UInt32 (GAuth.PermissionBlockNetworkerManager:GetSystemId (self.SystemName) or 0xFFFFFFFF)
	outBuffer:String (self.PermissionBlock:GetName ())
	outBuffer:UInt16 (self.SessionCount)
	for _, session in ipairs (self.Sessions) do
		outBuffer:UInt32 (session:GetTypeId ())
		session:GenerateInitialPacket (outBuffer)
	end
end

function self:HandleInitialPacket (inBuffer)
	local systemId = inBuffer:UInt32 ()
	local permissionBlockId = inBuffer:String ()
	local networker = GAuth.PermissionBlockNetworkerManager:GetNetworker (systemId)
	if not networker then
		ErrorNoHalt ("GAuth.PermissionBlockNotification: Unknown networker " .. tostring (systemId) .. "\n")
		return
	end
	self.Sessions = networker:HandleNotification (self:GetRemoteEndPoint (), permissionBlockId, inBuffer) or self.Sessions
	self.SessionCount = #self.Sessions
end

function self:ToString ()
	if #self.Sessions == 0 then
		return self.SystemName .. ".PermissionBlock:None"
	elseif #self.Sessions == 1 then
		return self.SystemName .. ".PermissionBlock:" .. self.Sessions [1]:ToString ()
	else
		return self.SystemName .. ".PermissionBlock:" .. self.Sessions [1]:ToString () .. "+"
	end
end