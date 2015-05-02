local self = {}
GLib.Networking.NetworkableHost = GLib.MakeConstructor (self)

--[[
	Events:
		ConnectionCreated (ConnectionNetworkable connectionNetworkable)
			Fired when a connection has been created.
		CustomPacketReceived (destinationId, InBuffer packet)
			Fired when a custom packet has been received.
		DispatchPacket (destinationId, OutBuffer packet)
			Fired when a packet needs to be dispatched.
]]

function self:ctor ()
	self.Debug = false
	
	-- Channel
	self.Channel = nil
	
	-- Hosting
	self.HostId = nil
	
	-- Subscribers
	self.SubscriberSet = nil
	
	-- Networkables
	self.NetworkableCount        = 0
	-- self.NetworkableIds          = GLib.WeakKeyTable ()
	-- self.NetworkablesById        = {}
	-- self.WeakNetworkablesById    = GLib.WeakValueTable ()
	-- self.NetworkableRefCounts    = {}
	-- self.HostingWeakNetworkables = {}
	self:ClearNetworkables () -- This will initialize the fields above
	
	-- Weak networkable checking
	self.WeakNetworkableCheckInterval = 5
	self.LastWeakNetworkableCheckTime = 0
	
	-- Connections
	self.ConnectionRunner = nil
	
	GLib.EventProvider (self)
end

function self:dtor ()
	self:ClearNetworkables ()
end

function self:SetDebug (debug)
	self.Debug = debug
	return self
end

-- Channel
function self:GetChannel ()
	return self.Channel
end

function self:SetChannel (channel)
	if self.Channel == channel then return self end
	
	self.Channel = channel
	if self.Channel then
		self.Channel:SetHandler (
			function (sourceId, inBuffer)
				self:HandlePacket (sourceId, inBuffer)
			end
		)
	end
	
	return self
end

-- Hosting
function self:GetHostId ()
	return self.HostId
end

function self:IsHost (remoteId)
	return self.HostId == remoteId
end

function self:IsHosting (networkable)
	if networkable and networkable.IsHosting then
		if networkable:IsHosting () ~= nil then
			return networkable:IsHosting ()
		end
	end
	
	return self.HostId == GLib.GetLocalId ()
end

function self:SetHostId (hostId)
	if self.HostId == hostId then return self end
	
	self.HostId = hostId
	return self
end

-- Subscribers
function self:GetSubscriberSet ()
	return self.SubscriberSet
end

function self:SetSubscriberSet (subscriberSet)
	if self.SubscriberSet == subscriberSet then return self end
	
	self.SubscriberSet = subscriberSet
	
	return self
end

-- Packets
function self:DispatchCustomPacket (destinationId, packet)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (GLib.Networking.NetworkableHostMessageType.Custom)
	outBuffer:OutBuffer (packet)
	
	return self:DispatchPacket (destinationId, outBuffer)
end

function self:DispatchPacket (destinationId, packet, object)
	self:CheckWeakNetworkables ()
	
	destinationId = destinationId or self.SubscriberSet
	destinationId = destinationId or GLib.GetEveryoneId ()
	
	local networkableId = self:GetNetworkableId (object)
	if not object then networkableId = 0 end
	
	if not networkableId then
		GLib.Error ("NetworkableHost:DispatchPacket : object is not registered with this NetworkableHost!")
		return
	end
	
	-- Build packet
	packet:PrependUInt32 (networkableId)
	
	if self.Debug then print ("NetworkableHost:DispatchPacket : Networkable ID " .. string.format ("0x%08x", networkableId) .. " (" .. GLib.Lua.ToCompactLuaString (object) .. ")") end
	
	-- Dispatch
	if self.Channel then
		self.Channel:DispatchPacket (destinationId, packet)
	else
		self:DispatchEvent ("DispatchPacket", destinationId, packet)
	end
end

function self:HandlePacket (sourceId, inBuffer)
	self:CheckWeakNetworkables ()
	
	local networkableId = inBuffer:UInt32 ()
	
	if networkableId == 0 then
		-- Message destined for this NetworkableHost
		local messageType = inBuffer:UInt8 ()
		
		if messageType == GLib.Networking.NetworkableHostMessageType.NetworkableDestroyed then
			local networkableId = inBuffer:UInt32 ()
			local networkable = self:GetNetworkableById (networkableId)
			
			if networkableId == 0           then return end -- Nope, we're not unregistering ourself.
			if not networkable              then return end -- Nothing to unregister.
			if self:IsHosting (networkable) then return end -- We don't work for you.
			
			if self.Debug then print ("NetworkableHost:HandlePacket : Remote end of networkable " .. GLib.Lua.ToCompactLuaString (networkable) .. " destroyed.") end
			self:UnregisterNetworkable (networkableId)
			
			if networkable.HandleRemoteDestruction then
				networkable:HandleRemoteDestruction ()
			end
		elseif messageType == GLib.Networking.NetworkableHostMessageType.Custom then
			self:DispatchEvent ("CustomPacketReceived", sourceId, inBuffer)
		end
	else
		local networkable = self:GetNetworkableById (networkableId)
		if not networkable then
			if self.Debug then print ("NetworkableHost:HandlePacket : Unknown networkable ID " .. string.format ("0x%08x", networkableId)) end
			return
		end
		
		if self.Debug then print ("NetworkableHost:HandlePacket : Networkable ID " .. string.format ("0x%08x", networkableId) .. " (" .. GLib.Lua.ToCompactLuaString (networkable) .. ")") end
		
		return networkable:HandlePacket (sourceId, inBuffer)
	end
end

-- Objects
function self:ClearNetworkables ()
	if self.NetworkableIds then
		for networkable, _ in pairs (self.NetworkableIds) do
			-- Clear the Networkable's NetworkableHost
			if networkable.SetNetworkableHost then
				networkable:SetNetworkableHost (nil)
			end
			
			-- Unhook networkable
			self:UnhookNetworkable (networkable)
		end
	end
	
	self.NetworkableCount        = 0
	self.NetworkableIds          = GLib.WeakKeyTable ()
	self.NetworkablesById        = {}
	self.WeakNetworkablesById    = GLib.WeakValueTable ()
	self.NetworkableRefCounts    = {}
	self.HostingWeakNetworkables = {}
end

function self:GetNetworkableById (id)
	return self.NetworkablesById [id] or self.WeakNetworkablesById [id]
end

function self:GetNetworkableCount ()
	return self.NetworkableCount
end

function self:GetNetworkableEnumerator ()
	return GLib.KeyEnumerator (self.NetworkableIds)
end

function self:GetNetworkableId (networkable)
	return self.NetworkableIds [networkable]
end

function self:IsNetworkableRegistered (networkable)
	return self.NetworkableIds [networkable] ~= nil
end

function self:RegisterNetworkable (networkable, networkableId, weakReference)
	self:CheckWeakNetworkables ()
	
	if networkableId == 0 then
		-- Reserved ID, not allowed
		GLib.Error ("NetworkableHost:RegisterNetworkable : Cannot register Networkable with reserver ID 0!")
		return
	end
	
	if not self.NetworkableIds [networkable] then
		-- New networkable
		networkableId = networkableId or self:GenerateNetworkableId ()
		
		self.NetworkableCount = self.NetworkableCount + 1
		self.NetworkableIds [networkable] = networkableId
		self.NetworkableRefCounts [networkableId] = 0
		
		if weakReference == nil then weakReference = true end
		
		if weakReference then
			self.WeakNetworkablesById [networkableId] = networkable
			if self:IsHosting (networkable) then
				self.HostingWeakNetworkables [networkableId] = true
			end
		else
			self.NetworkablesById [networkableId] = networkable
		end
		
		-- Set the Networkable's NetworkableHost
		if networkable.SetNetworkableHost then
			networkable:SetNetworkableHost (self)
		end
		
		-- Hook networkable
		self:HookNetworkable (networkable)
	else
		networkableId = self.NetworkableIds [networkable]
	end
	
	-- Increment reference count
	self.NetworkableRefCounts [networkableId] = self.NetworkableRefCounts [networkableId] + 1
end

function self:RegisterStrongNetworkable (networkable, networkableId)
	return self:RegisterNetworkable (networkable, networkableId, false)
end

function self:RegisterWeakNetworkable (networkable, networkableId)
	return self:RegisterNetworkable (networkable, networkableId, true)
end

function self:UnregisterNetworkable (networkableOrNetworkableId)
	local networkable
	local networkableId
	if type (networkableOrNetworkableId) == "number" then
		networkableId = networkableOrNetworkableId
		networkable = self:GetNetworkableById (networkableId)
	else
		networkable = networkableOrNetworkableId
		networkableId = self:GetNetworkableId (networkable)
	end
	
	if not networkable   then return end
	if not networkableId then return end
	
	-- Decrement reference count
	self.NetworkableRefCounts [networkableId] = self.NetworkableRefCounts [networkableId] - 1
	
	if self.NetworkableRefCounts [networkableId] == 0 then
		local hosting = self:IsHosting (networkable)
		
		-- Unregister networkable
		self.NetworkableCount = self.NetworkableCount - 1
		self.NetworkableIds [networkable] = nil
		self.NetworkablesById [networkableId] = nil
		self.WeakNetworkablesById [networkableId] = nil
		self.NetworkableRefCounts [networkableId] = nil
		self.HostingWeakNetworkables [networkableId] = nil
		
		if hosting then
			-- Notify the remote end that the networkable has been destroyed
			self:DispatchNetworkableDestroyed (networkableId)
		end
		
		-- Clear the Networkable's NetworkableHost
		if networkable.SetNetworkableHost then
			networkable:SetNetworkableHost (nil)
		end
		
		-- Unhook networkable
		self:UnhookNetworkable (networkable)
	end
end

-- Connections
function self:CreateConnection (remoteId, initiator, networkableId)
	local connection = GLib.Net.Connection (remoteId)
	connection:SetInitiator (initiator)
	local connectionNetworkable = GLib.Networking.ConnectionNetworkable (connection)
	
	-- Neither endpoints are hosting, and the connection is unregistered on both sides when it closes anyway.
	connectionNetworkable:SetHosting (false)
	
	self:RegisterStrongNetworkable (connectionNetworkable, networkableId)
	connection:SetId (self:GetNetworkableId (connectionNetworkable))
	
	if self.ConnectionRunner then
		self.ConnectionRunner:RegisterConnection (connection)
	end
	
	-- Connection termination handler
	connectionNetworkable:AddEventListener ("Closed",
		function ()
			self:UnregisterNetworkable (connectionNetworkable)
		end
	)
	
	self:DispatchEvent ("ConnectionCreated", connection, connectionNetworkable)
	
	return connection
end

function self:GetConnectionRunner ()
	return self.ConnectionRunner
end

function self:SetConnectionRunner (connectionRunner)
	self.ConnectionRunner = connectionRunner
	return self
end

-- Internal, do not call
function self:GenerateNetworkableId ()
	local networkableId = math.random (1, 0xFFFFFFFF)
	
	while networkableId == 0 or
	      self:GetNetworkableById (networkableId) do
		networkableId = (networkableId + 1) % 4294967296
	end
	
	return networkableId
end

function self:CheckWeakNetworkables ()
	if SysTime () - self.LastWeakNetworkableCheckTime < self.WeakNetworkableCheckInterval then return end
	self.LastWeakNetworkableCheckTime = SysTime ()
	
	for networkableId, _ in pairs (self.NetworkableRefCounts) do
		if not self.NetworkablesById [networkableId] and
		   not self.WeakNetworkablesById [networkableId] then
			-- Weak networkable got garbage collected
			self.NetworkableRefCounts [networkableId] = nil
			self.NetworkableCount = self.NetworkableCount - 1
			
			if self.HostingWeakNetworkables [networkableId] then
			   self.HostingWeakNetworkables [networkableId] = nil
				self:DispatchNetworkableDestroyed (networkableId)
			end
		end
	end
end

-- Notifies the remote end that a networkable has been detroyed
function self:DispatchNetworkableDestroyed (networkableId)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt8 (GLib.Networking.NetworkableHostMessageType.NetworkableDestroyed)
	outBuffer:UInt32 (networkableId)
	
	if self.Debug then print ("NetworkableHost:DispatchNetworkableDestroyed : " .. networkableId) end
	
	self:DispatchPacket (nil, outBuffer)
end

function self:HookNetworkable (networkable)
	if not networkable then return end
	if not networkable.AddEventListener then return end
	
	networkable:AddEventListener ("DispatchPacket", "NetworkableHost." .. self:GetHashCode (),
		function (_, destinationId, packet)
			self:DispatchPacket (destinationId, packet, networkable)
		end
	)
end

function self:UnhookNetworkable (networkable)
	if not networkable then return end
	if not networkable.RemoveEventListener then return end
	
	networkable:RemoveEventListener ("DispatchPacket", "NetworkableHost." .. self:GetHashCode ())
end