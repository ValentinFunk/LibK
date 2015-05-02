local self = {}
GLib.Net.Connection = GLib.MakeConstructor (self, GLib.Net.ISingleEndpointChannel)

--[[
	Events:
		ActivityStateChanged (hasUndispatchedPackets)
			Fired when the connection's undispatched packet count decreases to 0 or increases to 1.
		Closed (ConnectionClosureReason closureReason)
			Fired when the connection has been closed.
		DispatchPacket (OutBuffer packet)
			Fired when a packet needs to be dispatched.
		Opened (remoteId, InBuffer inBuffer)
			Fired when the first packet has been received.
		TimeoutChanged (timeout)
			Fired when the timeout period has changed.
]]

function self:ctor (remoteId, id, channel)
	-- Identity
	self.Channel  = channel
	self.Id       = id
	self.RemoteId = remoteId
	
	-- State
	self.State         = GLib.Net.ConnectionState.Opening
	self.Initiator     = nil
	
	-- Closure
	self.ClosureReason = nil
	self.CloseEvent = nil
	
	-- Packets
	self.OpenPacketSent = false
	
	self.NextInboundPacketId  = 0
	self.NextOutboundPacketId = 0
	
	self.InboundPackets = {}
	self.OutboundQueue  = {}
	
	-- Synchronous reading
	self.LastAvailablePacket = nil
	self.PacketAvailableEvent = nil
	
	-- Handlers
	self.OpenHandler   = GLib.NullCallback
	self.PacketHandler = GLib.NullCallback
	
	-- Timeouts
	self.Timeout     = 30
	self.TimeoutTime = math.huge
	
	GLib.EventProvider (self)
	
	self:AddEventListener ("Closed",
		function ()
			if self.PacketAvailableEvent then
				self.PacketAvailableEvent:Fire ()
			end
		end
	)
end

-- Identity
function self:GetChannel ()
	return self.Channel
end

function self:GetId ()
	return self.Id
end

function self:GetRemoteId ()
	return self.RemoteId
end

function self:SetChannel (channel)
	self.Channel = channel
	return self
end

function self:SetId (id)
	self.Id = id
	return self
end

function self:SetRemoteId (remoteId)
	self.RemoteId = remoteId
	return self
end

-- State
function self:Close (reason)
	if self:IsClosed () then return end
	
	reason = reason or GLib.Net.ConnectionClosureReason.LocalClosure
	
	local hasUndispatchedPackets = self:HasUndispatchedPackets ()
	if reason == GLib.Net.ConnectionClosureReason.LocalClosure then
		self.State = GLib.Net.ConnectionState.Closing
	else
		-- Close the connection immediately
		self:ClearOutboundQueue ()
		
		hasUndispatchedPackets = self:HasUndispatchedPackets ()
		
		self.State = GLib.Net.ConnectionState.Closed
	end
	
	self.ClosureReason = reason
	
	if self:HasUndispatchedPackets () ~= hasUndispatchedPackets then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
	
	if self:IsClosed () then
		self:DispatchEvent ("Closed", self.ClosureReason)
		
		if self.CloseEvent then
			self.CloseEvent:Fire ()
		end
	end
end

function self:GetInitiator ()
	return self.Initiator
end

function self:IsLocallyInitiated ()
	return self.Initiator == GLib.Net.ConnectionEndpoint.Local
end

function self:IsRemotelyInitiated ()
	return self.Initiator == GLib.Net.ConnectionEndpoint.Remote
end

function self:IsClosed ()
	return self.State == GLib.Net.ConnectionState.Closed
end

function self:IsClosing ()
	return self.State == GLib.Net.ConnectionState.Closing
end

function self:IsOpen ()
	return self.State == GLib.Net.ConnectionState.Open
end

function self:IsOpening ()
	if self.State == GLib.Net.ConnectionState.Opening then return true end
	if self:IsLocallyInitiated () and not self.OpenPacketSent then return true end
	
	return false
end

function self:SetInitiator (initiator)
	self.Initiator = initiator
	return self
end

function self:Wait (callback)
	if self:IsClosed () then
		if callback then callback () end
		return
	end
	
	self.CloseEvent = self.CloseEvent or GLib.Threading.Event ()
	
	if callback then
		self.CloseEvent:Wait (callback)
	else
		GLib.GetCurrentThread ():WaitForSingleObject (self.CloseEvent)
	end
end

-- Packets
function self:ClearOutboundQueue ()
	local hasUndispatchedPackets = self:HasUndispatchedPackets ()
	
	self.OutboundQueue = {}
	
	if self:HasUndispatchedPackets () ~= hasUndispatchedPackets then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
end

function self:DispatchNextPacket ()
	if not self:HasUndispatchedPackets () then return end
	
	self:DispatchEvent ("DispatchPacket", self:GenerateNextPacket ())
	
	-- Close the channel if our last packet has been dispatched
	if self:IsClosing () and #self.OutboundQueue == 0 then
		-- Close the connection
		self.State = GLib.Net.ConnectionState.Closed
		self:DispatchEvent ("Closed", GLib.Net.ConnectionClosureReason.LocalClosure)
		
		if self.CloseEvent then
			self.CloseEvent:Fire ()
		end
	end
end

function self:DispatchPacket (packet)
	self:Write (packet)
end

function self:Flush ()
	while self:HasUndispatchedPackets () do
		self:DispatchNextPacket ()
	end
end

function self:GetMTU ()
	return self.Channel:GetMTU ()
end

function self:HandlePacket (inBuffer)
	return self:ProcessInboundPacket (inBuffer)
end

function self:HasUndispatchedPackets ()
	return #self.OutboundQueue > 0 or (self:IsOpening () and self:IsLocallyInitiated ()) or self:IsClosing ()
end

function self:Read ()
	if self:IsClosed () then return nil end
	
	self.PacketAvailableEvent = self.PacketAvailableEvent or GLib.Threading.Event ()
	
	GLib.GetCurrentThread ():WaitForSingleObject (self.PacketAvailableEvent)
	
	local packet = self.LastAvailablePacket
	self.LastAvailablePacket = nil
	return packet
end


function self:Write (packet)
	if self:IsClosing () then return end
	if self:IsClosed  () then return end
	
	local hasUndispatchedPackets = self:HasUndispatchedPackets ()
	
	self.OutboundQueue [#self.OutboundQueue + 1] = packet
	
	if self:HasUndispatchedPackets () ~= hasUndispatchedPackets then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
	
	-- Update timeout
	self:UpdateTimeout ()
end

-- Handlers
function self:GetHandler ()
	return self:GetPacketHandler ()
end

function self:GetOpenHandler ()
	return self.OpenHandler
end

function self:GetPacketHandler ()
	return self.PacketHandler
end

function self:SetHandler (handler)
	return self:SetPacketHandler (handler)
end

function self:SetOpenHandler (openHandler)
	self.OpenHandler = openHandler
	return self
end

function self:SetPacketHandler (packetHandler)
	self.PacketHandler = packetHandler
	return self
end

-- Timeouts
function self:GetTimeout ()
	return self.Timeout
end

function self:GetTimeoutTime ()
	return self.TimeoutTime
end

function self:HasTimedOut (t)
	t = t or SysTime ()
	
	return t > self.TimeoutTime
end

function self:SetTimeout (timeout)
	self.Timeout = timeout
	
	self:DispatchEvent ("TimeoutChanged", self.Timeout)
end

function self:SetTimeoutTime (timeoutTime)
	self.TimeoutTime = timeoutTime
	
	self:DispatchEvent ("TimeoutChanged", self.Timeout)
end

function self:UpdateTimeout ()
	self:SetTimeoutTime (SysTime () + self.Timeout)
end

-- Internal, do not call
function self:GenerateNextPacket (outBuffer)
	if not self:HasUndispatchedPackets () then return nil end
	
	outBuffer = outBuffer or GLib.Net.OutBuffer ()
	outBuffer:UInt32 (self.NextOutboundPacketId)
	self.NextOutboundPacketId = (self.NextOutboundPacketId + 1) % 4294967296
	
	local packetType = 0
	if #self.OutboundQueue > 0 then
		packetType = packetType + GLib.Net.ConnectionPacketType.Data
	end
	if self:IsOpening () and self:IsLocallyInitiated () then
		packetType = packetType + GLib.Net.ConnectionPacketType.Open
		self.OpenPacketSent = true
	end
	if self:IsClosing () and #self.OutboundQueue <= 1 then
		packetType = packetType + GLib.Net.ConnectionPacketType.Close
	end
	
	outBuffer:UInt8 (packetType)
	
	if #self.OutboundQueue > 0 then
		outBuffer:OutBuffer (self.OutboundQueue [1])
		table.remove (self.OutboundQueue, 1)
	end
	
	if self:IsOpening () then
		-- Open the connection
		self.State = GLib.Net.ConnectionState.Open
		self:DispatchEvent ("Opened")
	end
	
	if not self:HasUndispatchedPackets () then
		self:DispatchEvent ("ActivityStateChanged", self:HasUndispatchedPackets ())
	end
	
	-- Update timeout
	self:UpdateTimeout ()
	
	return outBuffer
end

function self:ProcessInboundPacket (inBuffer)
	if self:IsClosing () then return end
	if self:IsClosed  () then return end
	
	local packetId = inBuffer:UInt32 ()
	
	self.InboundPackets [packetId] = packetId == self.NextInboundPacketId and inBuffer or inBuffer:Pin ()
	
	-- Process sequential packets
	while self.InboundPackets [self.NextInboundPacketId] do
		self:ProcessPacket (self.NextInboundPacketId, self.InboundPackets [self.NextInboundPacketId])
		self.InboundPackets [self.NextInboundPacketId] = nil
		
		self.NextInboundPacketId = (self.NextInboundPacketId + 1) % 4294967296
	end
	
	-- Close if we've desynced
	if packetId - self.NextInboundPacketId > 32 then
		self:Close ()
	end
	
	-- Update timeout
	self:UpdateTimeout ()
end

function self:ProcessPacket (packetId, inBuffer)
	local packetType = inBuffer:UInt8 ()
	
	if bit.band (packetType, GLib.Net.ConnectionPacketType.Open) ~= 0 then
		if self:IsOpening () then
			-- Open the connection
			self.State = GLib.Net.ConnectionState.Open
			self:DispatchEvent ("Opened")
			
			self:GetOpenHandler () (self:GetRemoteId (), inBuffer, self)
		else
			-- Nope.avi
			self:Close ()
			return
		end
	end
	
	if bit.band (packetType, GLib.Net.ConnectionPacketType.Data) ~= 0 then
		if self:IsOpening () then
			-- We didn't get a packet with the Open flag.
			self:Close ()
			return
		end
		if self.PacketAvailableEvent then
			self.LastAvailablePacket = inBuffer:Pin ()
			self.PacketAvailableEvent:Fire ()
		end
		self:GetPacketHandler () (self:GetRemoteId (), inBuffer, self)
	end
	
	if bit.band (packetType, GLib.Net.ConnectionPacketType.Close) ~= 0 then
		self:Close (GLib.Net.ConnectionClosureReason.RemoteClosure)
	end
	
	-- Update timeout
	self:UpdateTimeout ()
end

function self:ToString ()
	return "Connection [" .. self:GetHashCode () .. " " .. self:GetRemoteId () .. " (" .. GLib.PlayerMonitor:GetUserName (self:GetRemoteId ()) .. ")]"
end