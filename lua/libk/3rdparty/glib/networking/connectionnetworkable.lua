local self = {}
GLib.Networking.ConnectionNetworkable = GLib.MakeConstructor (self, GLib.Networking.Networkable)

--[[
	Events:
		ActivityStateChanged (hasUndispatchedPackets)
			Fired when the connection's undispatched packet count decreases to 0 or increases to 1.
		Closed (ConnectionClosureReason closureReason)
			Fired when the connection has been closed.
		DispatchPacket (remoteId, OutBuffer packet)
			Fired when a packet needs to be dispatched.
		Opened (remoteId, InBuffer inBuffer)
			Fired when the first packet has been received.
		TimeoutChanged (timeout)
			Fired when the timeout period has changed.
]]

function self:ctor (connection)
	self.Connection = connection
	
	self.Hosting = nil
	
	self:HookConnection (connection)
end

function self:dtor ()
	self:UnhookConnection (connection)
end

function self:IsHosting ()
	return self.Hosting
end

function self:SetHosting (hosting)
	self.Hosting = hosting
	return self
end

-- Identity
function self:GetRemoteId ()
	return self.Connection:GetRemoteId ()
end

function self:GetConnection ()
	return self.Connection
end

-- Connection identity
function self:GetId ()
	return self.Connection:GetId  ()
end

function self:SetId (id)
	self.Connection:SetId (id)
	return self
end

-- State
function self:Close (reason)
	return self.Connection:Close (reason)
end

function self:GetInitiator ()
	return self.Connection:GetInitiator ()
end

function self:IsLocallyInitiated ()
	return self.Connection:IsLocallyInitiated ()
end

function self:IsRemotelyInitiated ()
	return self.Connection:IsRemotelyInitiated ()
end

function self:IsClosed ()
	return self.Connection:IsClosed ()
end

function self:IsClosing ()
	return self.Connection:IsClosing ()
end

function self:IsOpen ()
	return self.Connection:IsOpen ()
end

function self:IsOpening ()
	return self.Connection:IsOpening ()
end

function self:SetInitiator (initiator)
	self.Connection:SetInitiator (initiator)
	return self
end

-- Packets
function self:ClearOutboundQueue ()
	self.Connection:ClearOutboundQueue ()
end

function self:DispatchNextPacket ()
	self.Connection:DispatchNextPacket ()
end

function self:DispatchPacket (destinationIdOrPacket, packet)
	local destinationId = destinationIdOrPacket
	if not packet then
		destinationId = self:GetRemoteId ()
		packet = destinationIdOrPacket
	end
	
	if destinationId and destinationId ~= self:GetRemoteId () then
		GLib.Error ("ConnectionNetworkable:DispatchPacket : Destination ID does not match remote ID!")
		return
	end
	self.Connection:DispatchPacket (packet)
end

function self:GetMTU ()
	return self.Connection:GetMTU ()
end

function self:HandlePacket (sourceIdOrInBuffer, inBuffer)
	local sourceId = sourceIdOrInBuffer
	if not inBuffer then
		sourceId = self:GetRemoteId ()
		inBuffer = sourceIdOrInBuffer
	end
	
	if sourceId ~= self:GetRemoteId () then return end
	return self.Connection:HandlePacket (inBuffer)
end

function self:HasUndispatchedPackets ()
	return self.Connection:HasUndispatchedPackets ()
end

function self:Read (packet)
	return self.Connection:Read (packet)
end

function self:Write (packet)
	return self.Connection:Write (packet)
end

-- Handlers
function self:GetHandler ()
	return self.Connection:GetHandler ()
end

function self:GetOpenHandler ()
	return self.Connection:GetOpenHandler ()
end

function self:GetPacketHandler ()
	return self.Connection:GetPacketHandler ()
end

function self:SetHandler (handler)
	self.Connection:SetHandler (handler)
	return self
end

function self:SetOpenHandler (openHandler)
	self.Connection:SetOpenHandler (openHandler)
	return self
end

function self:SetPacketHandler (packetHandler)
	self.Connection:SetPacketHandler (packetHandler)
	return self
end

-- Timeouts
function self:GetTimeout ()
	return self.Connection:GetTimeout ()
end

function self:GetTimeoutTime ()
	return self.Connection:GetTimeoutTime ()
end

function self:HasTimedOut (t)
	return self.Connection:HasTimedOut (t)
end

function self:SetTimeout (timeout)
	self.Connection:SetTimeout (timeout)
end

function self:SetTimeoutTime (timeoutTime)
	self.Connection:SetTimeout (timeoutTime)
end

function self:UpdateTimeout ()
	self.Connection:UpdateTimeout  ()
end

-- Internal, do not call
function self:HookConnection (connection)
	if not connection then return end
	
	connection:AddEventListener ("ActivityStateChanged", "ConnectionNetworkable",
		function (_, hasUndispatchedPackets)
			self:DispatchEvent ("ActivityStateChanged", hasUndispatchedPackets)
		end
	)
	connection:AddEventListener ("Closed", "ConnectionNetworkable",
		function (_, connectionClosureReason)
			self:DispatchEvent ("Closed", connectionClosureReason)
			self:dtor ()
		end
	)
	connection:AddEventListener ("DispatchPacket", "ConnectionNetworkable",
		function (_, packet)
			self:DispatchEvent ("DispatchPacket", self:GetRemoteId (), packet)
		end
	)
	connection:AddEventListener ("Opened", "ConnectionNetworkable",
		function (_, remoteId, inBuffer)
			self:DispatchEvent ("Opened", remoteId, inBuffer)
		end
	)
	connection:AddEventListener ("TimeoutChanged", "ConnectionNetworkable",
		function (_, timeout)
			self:DispatchEvent ("TimeoutChanged", timeout)
		end
	)
end

function self:UnhookConnection (connection)
	if not connection then return end
	
	connection:RemoveEventListener ("ActivityStateChanged", "ConnectionNetworkable")
	connection:RemoveEventListener ("Closed",               "ConnectionNetworkable")
	connection:RemoveEventListener ("DispatchPacket",       "ConnectionNetworkable")
	connection:RemoveEventListener ("Opened",               "ConnectionNetworkable")
	connection:RemoveEventListener ("TimeoutChanged",       "ConnectionNetworkable")
end