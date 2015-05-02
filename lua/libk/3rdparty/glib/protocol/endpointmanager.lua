local self = {}
GLib.Protocol.EndPointManager = GLib.MakeConstructor (self)

function self:ctor (systemName, endPointConstructor)
	self.SystemName = systemName
	self.EndPointConstructor = endPointConstructor or GLib.Protocol.EndPoint
	self.EndPoints = {}
end

function self:AddEndPoint (remoteId)
	if not self.EndPoints [remoteId] then
		self.EndPoints [remoteId] = self:CreateEndPoint (remoteId)
	end
	return self.EndPoints [remoteId]
end

--[[
	EndPointManager:CreateEndPoint (remoteId)
		Returns: EndPoint endPointForRemoteId
]]
function self:CreateEndPoint (remoteId)
	return self:GetEndPointConstructor () (remoteId, self:GetSystemName ())
end

function self:GetEndPoint (remoteId)
	if not self.EndPoints [remoteId] then
		self.EndPoints [remoteId] = self:CreateEndPoint (remoteId)
	end
	return self.EndPoints [remoteId]
end

function self:GetEndPointEnumerator ()
	return GLib.KeyValueEnumerator (self.EndPoints)
end

function self:GetEndPointConstructor ()
	return self.EndPointConstructor
end

function self:GetSystemName ()
	return self.SystemName
end

function self:RemoveEndPoint (endPointOrRemoteId)
	local endPoint = endPointOrRemoteId
	if type (endPointOrRemoteId) == "string" then
		endPoint = self.EndPoints [endPointOrRemoteId]
	end
	if not endPoint then return end
	endPoint:dtor ()
	self.EndPoints [endPoint:GetRemoteId ()] = nil
end