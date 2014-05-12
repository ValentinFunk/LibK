local self = {}
GAuth.Protocol.Register ("PermissionBlock", self)
GAuth.Protocol.PermissionBlockRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)

function self:ctor (systemName, permissionBlock, request)
	self.SystemName = systemName
	self.PermissionBlock = permissionBlock
	self.Session = request
end

function self:Close ()
	if self.Session then self.Session:Close () end

	if self.Closing then return end
	self.Closing = true
end

function self:DequeuePacket ()
	local outBuffer = self.Session:DequeuePacket ()
	if outBuffer then
		self:ResetTimeout ()
	end
	return outBuffer
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:UInt32 (GAuth.PermissionBlockNetworkerManager:GetSystemId (self.SystemName) or 0xFFFFFFFF)
	outBuffer:String (self.PermissionBlock:GetName ())
	outBuffer:UInt32 (self.Session:GetTypeId ())
	self.Session:GenerateInitialPacket (outBuffer)
end

function self:HandlePacket (inBuffer)
	self.Session:HandlePacket (inBuffer)
end

function self:HandleTimeOut ()
	self.Session:HandleTimeOut ()
end

function self:HasQueuedPackets ()
	return self.Session:HasQueuedPackets ()
end

function self:IsClosing ()
	if self.Closing then return true end
	if self.Session then return self.Session:IsClosing () end
	return false
end

function self:ResetTimeout ()
	self.Session:ResetTimeout ()
end

function self:SetId (id)
	self.Session:SetId (id)
end

function self:ToString ()
	return self.SystemName .. ".PermissionBlock:" .. self:GetId () .. ":" .. (self.Session and self.Session:ToString () or "none")
end