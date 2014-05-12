local self = {}
GAuth.Protocol.RegisterResponse ("PermissionBlock", GAuth.MakeConstructor (self, GAuth.Protocol.Session))

function self:ctor ()
	self.SystemName = ""
	self.PermissionBlock = nil
end

function self:Close ()
	if self.Session then self.Session:Close () end

	if self.Closing then return end
	self.Closing = true
end

function self:DequeuePacket ()
	if not self.Session then return nil end
	
	local outBuffer = self.Session:DequeuePacket ()
	if outBuffer then
		self:ResetTimeout ()
	end
	return outBuffer
end

function self:HandleInitialPacket (inBuffer)
	local systemId = inBuffer:UInt32 ()
	local permissionBlockId = inBuffer:String ()
	local networker = GAuth.PermissionBlockNetworkerManager:GetNetworker (systemId)
	self.SystemName = networker:GetSystemName ()
	self.Session = networker:HandleRequest (self, permissionBlockId, inBuffer)
end

function self:HandlePacket (inBuffer)
	if not self.Session then return end
	self.Session:HandlePacket (inBuffer)
end

function self:HandleTimeOut ()
	if self.Session then self.Session:HandleTimeOut () end
end

function self:HasQueuedPackets ()
	if self.Session then return self.Session:HasQueuedPackets () end
	return false
end

function self:IsClosing ()
	if self.Closing then return true end
	if self.Session then return self.Session:IsClosing () end
	return false
end

function self:ResetTimeout ()
	if self.Session then self.Session:ResetTimeout () end
end

function self:ToString ()
	return self.SystemName .. ".PermissionBlock:" .. self:GetId () .. ":" .. (self.Session and self.Session:ToString () or "none")
end