local self = {}
GLib.Net.Layer5.SingleEndpointConnectionChannel = GLib.MakeConstructor (self, GLib.Net.ISingleEndpointChannel)

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

function self:ctor (innerChannel)
	-- Identity
	self.InnerChannel = innerChannel
	self.Name = nil
	
	-- Packets
	self.Connections = {}
	
	-- Handlers
	self.OpenHandler   = handler or GLib.NullCallback
	self.PacketHandler = GLib.NullCallback
	
	self.InnerChannel:SetHandler (
		function (sourceId, inBuffer)
			self:HandlePacket (inBuffer)
		end
	)
end

function self:dtor ()
	self:CloseConnections ()
end

-- Identity
function self:GetInnerChannel ()
	return self.InnerChannel
end

function self:GetName ()
	return self.Name or self.InnerChannel:GetName ()
end

function self:GetRemoteId ()
	return self.InnerChannel:GetRemoteId ()
end

function self:SetRemoteId (remoteId)
	self.InnerChannel:SetRemoteId (remoteId)
	return self
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
function self:CloseConnections (closureReason)
	for _, connection in pairs (self.Connections) do
		connection:Close (closureReason)
	end
end

function self:Connect (packet)
	-- New connection
	local connection = GLib.Net.Connection (self:GetRemoteId (), self:GenerateConnectionId (), self)
	connection:SetInitiator (GLib.Net.ConnectionEndpoint.Local)
	
	-- Register connection
	self:RegisterConnection (connection)
	
	-- Write packet
	if packet then
		connection:Write (packet)
	end
	
	return connection
end

function self:DispatchPacket (packet)
	return self:Connect (packet)
end

function self:GetMTU ()
	return self.InnerChannel:GetMTU () - 13
end

function self:HandlePacket (inBuffer)
	local connectionId = inBuffer:UInt32 ()
	
	local connection = self.Connections [connectionId]
	
	if not connection then
		-- New connection
		connection = GLib.Net.Connection (self:GetRemoteId (), connectionId, self)
		connection:SetInitiator (GLib.Net.ConnectionEndpoint.Remote)
		
		-- Register connection
		self:RegisterConnection (connection)
	end
	
	connection:HandlePacket (inBuffer)
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
	self.OpenHandler = openHandler
	return self
end

function self:SetPacketHandler (packetHandler)
	self.PacketHandler = packetHandler
	return self
end

-- Internal, do not call
function self:GenerateConnectionId ()
	local connectionId = math.random (0, 0xFFFFFFFF)
	
	while self.Connections [connectionId] do
		connectionId = (connectionId + 1) % 4294967296
	end
	
	return connectionId
end

function self:RegisterConnection (connection)
	-- Add connection to list
	self.Connections [connection:GetId ()] = connection
	
	-- Set connection handlers
	connection:SetOpenHandler   (self:GetOpenHandler   () or GLib.NullCallback)
	connection:SetPacketHandler (self:GetPacketHandler () or GLib.NullCallback)
	
	-- Hook events
	self:HookConnection (connection)
	
	-- Dispatch event
	self:DispatchEvent ("ConnectionCreated", connection)
end

function self:HookConnection (connection)
	if not connection then return end
	
	connection:AddEventListener ("ActivityStateChanged", "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, hasUndispatchedPackets)
			self:DispatchEvent ("ConnectionActivityStateChanged", connection, hasUndispatchedPackets)
		end
	)
	connection:AddEventListener ("Closed", "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, closureReason)
			self:DispatchEvent ("ConnectionClosed", connection, closureReason)
			
			-- Unregister connection
			self:UnhookConnection (connection)
			self.Connections [connection:GetId ()] = nil
		end
	)
	connection:AddEventListener ("DispatchPacket", "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, packet)
			packet:PrependUInt32 (connection:GetId ())
			self.InnerChannel:DispatchPacket (packet)
		end
	)
	connection:AddEventListener ("Opened", "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_)
			self:DispatchEvent ("ConnectionOpened", connection)
		end
	)
	connection:AddEventListener ("TimeoutChanged", "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode (),
		function (_, timeout)
			self:DispatchEvent ("ConnectionTimeoutChanged", connection, timeout)
		end
	)
end

function self:UnhookConnection (connection)
	if not connection then return end
	
	connection:RemoveEventListener ("ActivityStateChanged", "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
	connection:RemoveEventListener ("Closed",               "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
	connection:RemoveEventListener ("DispatchPacket",       "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
	connection:RemoveEventListener ("Opened",               "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
	connection:RemoveEventListener ("TimeoutChanged",       "SingleEndpointConnectionChannel." .. self:GetName () .. "." .. self:GetHashCode ())
end