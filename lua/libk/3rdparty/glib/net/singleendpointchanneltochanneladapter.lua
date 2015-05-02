local self = {}
GLib.Net.SingleEndpointChannelToChannelAdapter = GLib.MakeConstructor (self, GLib.Net.IChannel)

function self:ctor (singleEndpointChannel)
	self.Channel = singleEndpointChannel
	
	self.Channel:SetHandler (
		function (sourceId, inBuffer)
			self:GetHandler () (sourceId, inBuffer)
		end
	)
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	if destinationId == GLib.GetEveryoneId () then destinationId = self.Channel:GetRemoteId () end
	if destinationId ~= self.Channel:GetRemoteId () then return end
	return self.Channel:DispatchPacket (packet)
end

function self:GetMTU ()
	return self.Channel:GetMTU ()
end

function self:HandlePacket (sourceId, inBuffer)
	return self.Channel:HandlePacket (inBuffer)
end

function self:IsDestinationRoutable (destinationId)
	return self.Channel:IsDestinationRoutable (destinationId)
end