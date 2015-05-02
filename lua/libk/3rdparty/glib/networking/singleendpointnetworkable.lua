local self = {}
GLib.Networking.SingleEndpointNetworkable = GLib.MakeConstructor (self, GLib.Networking.Networkable)

function self:ctor ()	
	-- Remote endpoint
	self.RemoteId = nil
end

-- Remote endpoint
function self:GetRemoteId ()
	return self.RemoteId
end

function self:SetRemoteId (remoteId)
	if self.RemoteId == remoteId then return self end
	
	self.RemoteId = remoteId
	
	return self
end

-- Packets
function self:DispatchPacket (destinationIdOrPacket, packet)
	local destinationId = destinationIdOrPacket
	
	if istable (destinationId) then
		destinationId = self:GetRemoteId () or self.SubscriberSet
		packet        = destinationIdOrPacket
	end
	
	self:DispatchEvent ("DispatchPacket", destinationId, packet)
end