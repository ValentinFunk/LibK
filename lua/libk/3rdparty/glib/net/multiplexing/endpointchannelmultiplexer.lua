local self = {}
GLib.Net.EndpointChannelMultiplexer = GLib.MakeConstructor (self, GLib.Net.IChannel)

--[[
	Events:
		SingleEndpointChannelCreated (ISingleEndpointChannel singleEndpointChannel)
			Fired when an ISingleEndpointChannel has been created.
		SingleEndpointChannelDestroyed (ISingleEndpointChannel singleEndpointChannel)
			Fired when an ISingleEndpointChannel has been destroyed.
]]

function GLib.Net.EndpointChannelMultiplexer.ctor (channelName, handler, innerChannel)
	if type (channelName) ~= "string" then
		innerChannel = channelName
		channelName  = innerChannel:GetName ()
	end
	
	innerChannel = innerChannel or GLib.Net.Layer5.GetChannel (channelName)
	innerChannel = innerChannel or GLib.Net.Layer5.RegisterChannel (channelName)
	
	return GLib.Net.EndpointChannelMultiplexer.__ictor (channelName, handler, innerChannel)
end

function self:ctor (channelName, handler, innerChannel)
	-- Identity
	self.InnerChannel = innerChannel
	
	self.SingleEndpointChannels = {}
	
	self.InnerChannel:SetHandler (
		function (sourceId, inBuffer)
			if not self.SingleEndpointChannels [sourceId] then
				self:CreateSingleEndpointChannel (sourceId)
			end
			self.SingleEndpointChannels [sourceId]:HandlePacket (inBuffer)
		end
	)
	
	GLib.PlayerMonitor:AddEventListener ("PlayerDisconnected", "EndpointChannelMultiplexer." .. self:GetName (),
		function (_, ply, userId)
			self:DestroySingleEndpointChannel (userId)
		end
	)
	
	self:AddEventListener ("NameChanged",
		function (_, oldName, name)
			for _, singleEndpointChannel in pairs (self.SingleEndpointChannels) do
				singleEndpointChannel:SetName (name)
			end
		end
	)
end

function self:dtor ()
	for _, singleEndpointChannel in pairs (self.SingleEndpointChannels) do
		singleEndpointChannel:dtor ()
	end
	
	GLib.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "EndpointChannelMultiplexer." .. self:GetName ())
end

function self:GetInnerChannel ()
	return self.InnerChannel
end

function self:GetSingleEndpointChannel (remoteId)
	return self.SingleEndpointChannels [remoteId]
end

-- State
function self:IsOpen ()
	return self.InnerChannel:IsOpen ()
end

function self:SetOpen (open)
	self.InnerChannel:SetOpen (open)
	return self
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	if not self.SingleEndpointChannels [destinationId] then
		self:CreateSingleEndpointChannel (destinationId)
	end
	return self.SingleEndpointChannels [destinationId]:DispatchPacket (packet)
end

function self:HandlePacket (sourceId, packet)
	if not self.SingleEndpointChannels [sourceId] then
		self:CreateSingleEndpointChannel (sourceId)
	end
	return self.SingleEndpointChannels [sourceId]:HandlePacket (packet)
end

function self:IsDestinationRoutable (destinationId)
	return self.InnerChannel:IsDestinationRoutable (destinationId)
end

-- Handlers
function self:SetHandler (handler)
	if self.Handler == handler then return self end
	
	self.Handler = handler
	
	-- Update handlers for SingleEndpointChannels
	for _, singleEndpointChannel in pairs (self.SingleEndpointChannels) do
		singleEndpointChannel:SetHandler (handler)
	end
	
	return self
end

-- Internal, do not call
function self:CreateSingleEndpointChannel (remoteId)
	if self.SingleEndpointChannels [remoteId] then return self.SingleEndpointChannels [remoteId] end
	
	local singleEndpointChannel = GLib.Net.SingleEndpointChannel (self:GetInnerChannel (), remoteId)
	self.SingleEndpointChannels [remoteId] = singleEndpointChannel
	singleEndpointChannel:SetName (self:GetName ())
	singleEndpointChannel:SetHandler (self:GetHandler ())
	
	self:DispatchEvent ("SingleEndpointChannelCreated", singleEndpointChannel)
	
	return self.SingleEndpointChannels [remoteId]
end

function self:DestroySingleEndpointChannel (remoteId)
	if not self.SingleEndpointChannels [remoteId] then return end
	
	local singleEndpointChannel = self.SingleEndpointChannels [remoteId]
	self.SingleEndpointChannels [remoteId]:dtor ()
	self.SingleEndpointChannels [remoteId] = nil
	
	self:DispatchEvent ("SingleEndpointChannelDestroyed", singleEndpointChannel)
end