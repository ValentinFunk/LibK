local self = {}
GLib.Net.Layer5.OrderedChannel = GLib.MakeConstructor (self, GLib.Net.EndpointChannelMultiplexer)

function GLib.Net.Layer5.OrderedChannel.ctor (channelName, handler, innerChannel)
	if type (channelName) ~= "string" then
		innerChannel = channelName
		channelName  = innerChannel:GetName ()
	end
	
	innerChannel = innerChannel or GLib.Net.Layer3.GetChannel (channelName)
	innerChannel = innerChannel or GLib.Net.Layer3.RegisterChannel (channelName)
	
	return GLib.Net.Layer5.OrderedChannel.__ictor (channelName, handler, innerChannel)
end

function self:ctor (channelName, handler, innerChannel)
	self:Register ()
end

function self:dtor ()
	self:Unregister ()
end

-- Registration
function self:Register ()
	if self:IsRegistered () then return end
	
	GLib.Net.Layer5.RegisterChannel (self)
	self:SetRegistered (true)
end

function self:Unregister ()
	if not self:IsRegistered () then return end
	
	GLib.Net.Layer5.UnregisterChannel (self)
	self:SetRegistered (false)
end

-- Packets
function self:GetMTU ()
	return self.InnerChannel:GetMTU () - 4
end

function self:IsDestinationRoutable (destinationId)
	return self.InnerChannel:IsDestinationRoutable (destinationId)
end

-- Internal, do not call
function self:CreateSingleEndpointChannel (remoteId)
	if self.SingleEndpointChannels [remoteId] then return self.SingleEndpointChannels [remoteId] end
	
	local singleEndpointChannel = GLib.Net.SingleEndpointChannel (self:GetInnerChannel (), remoteId)
	local singleEndpointOrderedChannel = GLib.Net.Layer5.SingleEndpointOrderedChannel (singleEndpointChannel)
	self.SingleEndpointChannels [remoteId] = singleEndpointOrderedChannel
	singleEndpointOrderedChannel:SetName (self:GetName ())
	singleEndpointOrderedChannel:SetHandler (self:GetHandler ())
	
	return self.SingleEndpointChannels [remoteId]
end