local self = {}
GLib.Net.Layer5.SingleEndpointOrderedChannel = GLib.MakeConstructor (self, GLib.Net.ISingleEndpointChannel)

function self:ctor (innerChannel)
	-- Identity
	self.InnerChannel = innerChannel
	self.Name = nil
	
	-- State
	self.Open = nil
	self.State = GLib.Net.Layer5.OrderedChannelState.Uninitialized
	
	-- Packets
	self.NextInboundPacketId  = nil
	self.NextOutboundPacketId = 0
	
	self.InboundPackets = {}
end

function self:dtor ()
	timer.Destroy (self:GetInitializationTimerName ())
	timer.Destroy (self:GetTimeoutTimerName ())
end

function self:GetInitializationTimerName ()
	return "OrderedChannel." .. self:GetName () .. "." .. self:GetRemoteId ().. ".InitialBuffering"
end

function self:GetTimeoutTimerName ()
	return "OrderedChannel." .. self:GetName () .. "." .. self:GetRemoteId ().. ".Timeout"
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
function self:GetState ()
	return self.State
end

function self:IsInitializing ()
	return self.State == GLib.Net.Layer5.OrderedChannelState.Initializing
end

function self:IsInitialized ()
	return self.State == GLib.Net.Layer5.OrderedChannelState.Initialized
end

function self:IsUninitialized ()
	return self.State == GLib.Net.Layer5.OrderedChannelState.Uninitialized
end

function self:SetState (state)
	self.State = state
	return self
end

function self:IsOpen ()
	return self.InnerChannel:IsOpen ()
end

function self:SetOpen (open)
	self.InnerChannel:SetOpen (open)
	return self
end

-- Packets
function self:DispatchPacket (packet)
	packet:PrependUInt32 (self.NextOutboundPacketId)
	self.NextOutboundPacketId = (self.NextOutboundPacketId + 1) % 4294967296
	
	return self.InnerChannel:DispatchPacket (packet)
end

function self:HandlePacket (inBuffer)
	local packetId = inBuffer:UInt32 ()
	
	if self:IsUninitialized () then
		-- Start buffering packets for 0.5 seconds
		self:SetState (GLib.Net.Layer5.OrderedChannelState.Initializing)
		self:CreateInitializationTimer ()
	elseif self:IsInitialized () then
		-- Detect a reset on the other end
		if packetId == 0 and not next (self.InboundPackets) then
			self.NextInboundPacketId = 0
		end
		
		if self.NextInboundPacketId ~= packetId and
		   (self.NextInboundPacketId - packetId) % 4294967296 < 16 then
			-- Drop packet, we received it too late
			return
		end
	end
	
	self.InboundPackets [packetId] = packetId == self.NextInboundPacketId and inBuffer or inBuffer:Pin ()
	
	if self:IsInitialized () then
		if not self:ProcessAvailablePackets () then
			self:ResetTimeoutTimer ()
		end
	end
end

-- Internal, do not call
function self:CreateInitializationTimer ()
	timer.Create (self:GetInitializationTimerName (), 0.5, 1,
		function ()
			local lowestPacketId = math.huge
			
			self:SetState (GLib.Net.Layer5.OrderedChannelState.Initialized)
			
			if not next (self.InboundPackets) then return end -- wtf
			
			-- Find the earliest packet
			-- NOTE: This does not handle packet ID overflow at all
			for packetId, _ in pairs (self.InboundPackets) do
				if packetId < lowestPacketId then
					lowestPacketId = packetId
				end
			end
			
			-- Process packets
			self.NextInboundPacketId = lowestPacketId
			self:ProcessAvailablePackets ()
		end
	)
end

function self:ProcessAvailablePackets ()
	if not self.InboundPackets [self.NextInboundPacketId] then return false end
	
	-- Process packets in order
	while self.InboundPackets [self.NextInboundPacketId] do
		self:ProcessPacket (self.NextInboundPacketId, self.InboundPackets [self.NextInboundPacketId])
		self.InboundPackets [self.NextInboundPacketId] = nil
		
		self.NextInboundPacketId = (self.NextInboundPacketId + 1) % 4294967296
	end
	
	-- Reset timeout
	if not next (self.InboundPackets) then
		timer.Destroy (self:GetTimeoutTimerName ())
	else
		self:ResetTimeoutTimer ()
	end
	
	return true
end

function self:ProcessPacket (packetId, inBuffer)
	self:GetHandler () (self:GetRemoteId (), inBuffer)
end

function self:ResetTimeoutTimer ()
	timer.Create (self:GetTimeoutTimerName (), 5, 1,
		function ()
			local lowestPacketId = math.huge
			local lowestPacketIdDifference = math.huge
			
			if not next (self.InboundPackets) then return end -- wtf
			
			-- Find the earliest packet after the last packet processed
			for packetId, _ in pairs (self.InboundPackets) do
				local packetIdDifference = packetId - self.NextInboundPacketId % 4294967296
				if packetIdDifference < lowestPacketIdDifference then
					lowestPacketId = packetId
					lowestPacketIdDifference = packetIdDifference
				end
			end
			
			-- Process packets
			self.NextInboundPacketId = lowestPacketId
			self:ProcessAvailablePackets ()
		end
	)
end