local self = {}
GLib.Net.Layer5.ConnectionChannel = GLib.MakeConstructor (self, GLib.Net.Layer5.Channel)

--[[
	Events:
		ConnectionActivityStateChanged (Connection connection, hasUndispatchedPackets)
			Fired when a connection's undispatched packet count decreases to 0 or increases to 1.
		ConnectionCreated (Connection connection)
			Fired when a connection has been created.
		ConnectionOpened (Connection connection)
			Fired when a connection has been opened.
		ConnectionClosed (Connection connection)
			Fired when a connection has been closed.
		ConnectionTimeoutChanged (Connection connection, timeout)
			Fired when a connection's timeout period has changed.
]]

function GLib.Net.Layer5.ConnectionChannel.ctor (channelName, handler, innerChannel)
	if type (channelName) ~= "string" then
		innerChannel = channelName
		channelName  = innerChannel:GetName ()
	end
	
	innerChannel = innerChannel or GLib.Net.Layer3.GetChannel (channelName)
	innerChannel = innerChannel or GLib.Net.Layer3.RegisterChannel (channelName)
	
	return GLib.Net.Layer5.ConnectionChannel.__ictor (channelName, handler, innerChannel)
end

function self:ctor (channelName, handler, innerChannel)
	-- Identity
	self.InnerChannel = innerChannel
	
	self.SingleEndpointChannels = {}
	
	-- Handlers
	self.OpenHandler   = handler or GLib.NullCallback
	self.PacketHandler = GLib.NullCallback
	
	self.InnerChannel:SetHandler (
		function (sourceId, inBuffer)
			if not self.SingleEndpointChannels [sourceId] then
				self:CreateSingleEndpointChannel (sourceId)
			end
			self.SingleEndpointChannels [sourceId]:HandlePacket (inBuffer)
		end
	)
	
	GLib.PlayerMonitor:AddEventListener ("PlayerDisconnected", "ConnectionChannel." .. self:GetName (),
		function (_, ply, userId)
			if not self.SingleEndpointChannels [userId] then return end
			
			self.SingleEndpointChannels [userId]:CloseConnections (GLib.Net.ConnectionClosureReason.CarrierLost)
			self:UnhookSingleEndpointConnectionChannel (self.SingleEndpointChannels [userId])
			self.SingleEndpointChannels [userId]:dtor ()
			self.SingleEndpointChannels [userId] = nil
		end
	)
	
	self:AddEventListener ("NameChanged",
		function (_, oldName, name)
			for _, singleEndpointConnectionChannel in pairs (self.SingleEndpointChannels) do
				singleEndpointConnectionChannel:SetName (name)
			end
		end
	)
	
	self:Register ()
end

function self:dtor ()
	for _, singleEndpointChannel in pairs (self.SingleEndpointChannels) do
		singleEndpointChannel:dtor ()
	end
	
	GLib.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "ConnectionChannel." .. self:GetName ())
	
	self:Unregister ()
end

function self:GetInnerChannel ()
	return self.InnerChannel
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

-- State
function self:IsOpen ()
	return self.InnerChannel:IsOpen ()
end

function self:SetOpen (open)
	self.InnerChannel:SetOpen (open)
	return self
end

-- Packets
function self:Connect (destinationId, packet)
	if not self.SingleEndpointChannels [destinationId] then
		self:CreateSingleEndpointChannel (destinationId)
	end
	return self.SingleEndpointChannels [destinationId]:DispatchPacket (packet)
end

function self:DispatchPacket (destinationId, packet)
	return self:Connect (destinationId, packet)
end

function self:GetMTU ()
	return self.InnerChannel:GetMTU () - 13
end

function self:IsDestinationRoutable (destinationId)
	return self.InnerChannel:IsDestinationRoutable (destinationId)
end

-- Handlers
function self:GetHandler ()
	return self:GetOpenHandler ()
end

function self:GetOpenHandler ()
	return self.OpenHandler
end

function self:GetPacketHandler ()
	return self.PacketHandler
end

function self:SetHandler (handler)
	return self:SetOpenHandler (handler)
end

function self:SetOpenHandler (openHandler)
	if self.OpenHandler == openHandler then return self end
	
	self.OpenHandler = openHandler
	
	-- Update handlers for SingleEndpointConnectionChannels
	for _, singleEndpointConnectionChannel in pairs (self.SingleEndpointChannels) do
		singleEndpointConnectionChannel:SetOpenHandler (handler)
	end
	
	return self
end

function self:SetPacketHandler (packetHandler)
	if self.PacketHandler == packetHandler then return self end
	
	self.PacketHandler = packetHandler
	
	-- Update handlers for SingleEndpointConnectionChannels
	for _, singleEndpointConnectionChannel in pairs (self.SingleEndpointChannels) do
		singleEndpointConnectionChannel:SetPacketHandler (handler)
	end
	
	return self
end

-- Internal, do not call
function self:CreateSingleEndpointChannel (remoteId)
	if self.SingleEndpointChannels [remoteId] then return self.SingleEndpointChannels [remoteId] end
	
	local singleEndpointChannel = GLib.Net.SingleEndpointChannel (self:GetInnerChannel (), remoteId)
	local singleEndpointConnectionChannel = GLib.Net.Layer5.SingleEndpointConnectionChannel (singleEndpointChannel)
	self.SingleEndpointChannels [remoteId] = singleEndpointConnectionChannel
	singleEndpointConnectionChannel:SetName (self:GetName ())
	singleEndpointConnectionChannel:SetOpenHandler (self:GetOpenHandler ())
	singleEndpointConnectionChannel:SetPacketHandler (self:GetPacketHandler ())
	
	self:HookSingleEndpointConnectionChannel (singleEndpointConnectionChannel)
	
	return self.SingleEndpointChannels [remoteId]
end

function self:ProcessConnectionOutboundQueue (connection)
	local singleEndpointConnectionChannel = self.SingleEndpointChannels [connection:GetRemoteId ()]
	if not singleEndpointConnectionChannel then return end
	
	singleEndpointConnectionChannel:ProcessConnectionOutboundQueue (connection)
end

function self:HookSingleEndpointConnectionChannel (singleEndpointConnectionChannel)
	if not singleEndpointConnectionChannel then return end
	
	singleEndpointConnectionChannel:AddEventListener ("ConnectionActivityStateChanged", "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, connection, hasUndispatchedPackets)
			self:DispatchEvent ("ConnectionActivityStateChanged", connection, hasUndispatchedPackets)
		end
	)
	singleEndpointConnectionChannel:AddEventListener ("ConnectionClosed", "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, connection, closureReason)
			self:DispatchEvent ("ConnectionClosed", connection, closureReason)
		end
	)
	singleEndpointConnectionChannel:AddEventListener ("ConnectionCreated", "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, connection)
			self:DispatchEvent ("ConnectionCreated", connection)
		end
	)
	singleEndpointConnectionChannel:AddEventListener ("ConnectionOpened", "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, connection)
			self:DispatchEvent ("ConnectionOpened", connection)
		end
	)
	singleEndpointConnectionChannel:AddEventListener ("ConnectionTimeoutChanged", "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, connection, timeout)
			self:DispatchEvent ("ConnectionTimeoutChanged", connection, timeout)
		end
	)
end

function self:UnhookSingleEndpointConnectionChannel (singleEndpointConnectionChannel)
	if not singleEndpointConnectionChannel then return end
	
	singleEndpointConnectionChannel:RemoveEventListener ("ConnectionActivityStateChanged", "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
	singleEndpointConnectionChannel:RemoveEventListener ("ConnectionClosed",               "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
	singleEndpointConnectionChannel:RemoveEventListener ("ConnectionCreated",              "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
	singleEndpointConnectionChannel:RemoveEventListener ("ConnectionOpened",               "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
	singleEndpointConnectionChannel:RemoveEventListener ("ConnectionTimeoutChanged",       "ConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
end