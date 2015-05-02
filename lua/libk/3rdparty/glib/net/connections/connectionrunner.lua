local self = {}
GLib.Net.ConnectionRunner = GLib.MakeConstructor (self)

function self:ctor ()
	self.Channels = GLib.WeakKeyTable ()
	
	self.ConnectionsByRemoteEndpoint = {}
	self.ActiveConnections  = GLib.WeakKeyTable () -- Connections with undispatched packets.
	self.TimeoutConnections = GLib.WeakKeyTable () -- Connections with timeouts.
	
	
	hook.Add ("Tick", "GLib.Net.ConnectionRunner." .. self:GetHashCode (),
		function ()
			-- Outbound packets
			for connection, _ in pairs (self.ActiveConnections) do
				connection:DispatchNextPacket ()
			end
			
			-- Check timeouts
			for connection, _ in pairs (self.TimeoutConnections) do
				if connection:HasTimedOut () then
					connection:Close (GLib.Net.ConnectionClosureReason.Timeout)
				end
			end
		end
	)
	
	GLib.PlayerMonitor:AddEventListener ("PlayerDisconnected", "GLib.Net.ConnectionRunner." .. self:GetHashCode (),
		function (_, ply, userId)
			if not self.ConnectionsByRemoteEndpoint [userId] then return end
			
			for connection, _ in pairs (self.ConnectionsByRemoteEndpoint [userId]) do
				connection:Close (GLib.Net.ConnectionClosureReason.CarrierLost)
			end
			
			self.ConnectionsByRemoteEndpoint [userId] = nil
		end
	)
end

function self:dtor ()
	hook.Remove ("Tick", "GLib.Net.ConnectionRunner." .. self:GetHashCode ())
	
	GLib.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "GLib.Net.ConnectionRunner." .. self:GetHashCode ())
end

function self:RegisterChannel (channel)
	if self.Channels [channel] then return end
	
	self.Channels [channel] = true
	
	self:HookChannel (channel)
end

function self:UnregisterChannel (channel)
	if not self.Channels [channel] then return end
	
	self.Channels [channel] = nil
	
	self:UnhookChannel (channel)
end

function self:RegisterConnection (connection)
	self:HookConnection (connection)
	
	self.ConnectionsByRemoteEndpoint [connection:GetRemoteId ()] = self.ConnectionsByRemoteEndpoint [connection:GetRemoteId ()] or GLib.WeakKeyTable ()
	self.ConnectionsByRemoteEndpoint [connection:GetRemoteId ()] [connection] = true
	
	self:UpdateConnectionState (connection)
end

function self:UnregisterConnection (connection)
	self:UnhookConnection (connection)
	
	-- Unregister connection
	self.ConnectionsByRemoteEndpoint [connection:GetRemoteId ()] [connection] = nil
	if not next (self.ConnectionsByRemoteEndpoint [connection:GetRemoteId ()]) then
		self.ConnectionsByRemoteEndpoint [connection:GetRemoteId ()] = nil
	end
	
	self:UpdateConnectionState (connection)
end

-- Internal, do not call
function self:HookChannel (channel)
	if not channel then return end
	
	channel:AddEventListener ("ConnectionCreated", "GLib.Net.ConnectionRunner",
		function (_, connection)
			self:RegisterConnection (connection)
		end
	)
end

function self:UnhookChannel (channel)
	if not channel then return end
	
	channel:RemoveEventListener ("ConnectionCreated", "GLib.Net.ConnectionRunner")
end

function self:HookConnection (connection)
	if not connection then return end
	
	connection:AddEventListener ("ActivityStateChanged", "GLib.Net.ConnectionRunner",
		function (_, hasUndispatchedPackets)
			self:UpdateConnectionState (connection)
		end
	)
	
	connection:AddEventListener ("Closed", "GLib.Net.ConnectionRunner",
		function (_, closureReason)
			self:UnregisterConnection (connection)
		end
	)
	
	connection:AddEventListener ("TimeoutChanged", "GLib.Net.ConnectionRunner",
		function (_, hasUndispatchedPackets)
			self:UpdateConnectionState (connection)
		end
	)
end

function self:UnhookConnection (connection)
	if not connection then return end
	
	connection:RemoveEventListener ("ActivityStateChanged", "GLib.Net.ConnectionRunner")
	connection:RemoveEventListener ("Closed",               "GLib.Net.ConnectionRunner")
	connection:RemoveEventListener ("TimeoutChanged",       "GLib.Net.ConnectionRunner")
end

function self:UpdateConnectionState (connection)
	local active = connection:HasUndispatchedPackets () and not connection:IsClosed ()
	local canTimeout = connection:GetTimeoutTime () < math.huge and not connection:IsClosed ()
	
	if active then
		self.ActiveConnections [connection] = true
	else
		self.ActiveConnections [connection] = nil
	end
	if canTimeout then
		self.TimeoutConnections [connection] = true
	else
		self.TimeoutConnections [connection] = nil
	end
end