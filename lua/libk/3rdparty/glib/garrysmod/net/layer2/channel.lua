local self = {}
GLib.Net.Layer2.Channel = GLib.MakeConstructor (self, GLib.Net.Layer2.Channel)

function self:ctor (channelName, handler)
	self.UsermessageChannel = GLib.Net.Layer1.UsermessageChannel (channelName, handler)
	self.NetChannel         = GLib.Net.Layer1.NetChannel (channelName, handler)
	self.SplitPacketChannel = GLib.Net.Layer2.SplitPacketChannel (channelName, handler, GLib.Net.Layer1.NetChannel (channelName .. "#"))
	
	self.Queue = {}
	
	self:Register ()
end

function self:dtor ()
	self.UsermessageChannel:dtor ()
	self.NetChannel:dtor ()
	self.SplitPacketChannel:dtor ()
	
	self:Unregister ()
end

-- Registration
function self:Register ()
	if self:IsRegistered () then return end
	
	GLib.Net.Layer2.RegisterChannel (self)
	self:SetRegistered (true)
end

function self:Unregister ()
	if not self:IsRegistered () then return end
	
	GLib.Net.Layer2.UnregisterChannel (self)
	self:SetRegistered (false)
end

-- State
function self:SetOpen (open)
	self.Open = open
	
	self.UsermessageChannel:SetOpen (open)
	self.NetChannel:SetOpen (open)
	self.SplitPacketChannel:GetInnerChannel ():SetOpen (open)
	self.SplitPacketChannel:SetOpen (open)
	
	-- Flush the queue if we've been opened
	if self.Open and #self.Queue > 0 then
		for _, packet in ipairs (self.Queue) do
			self:DispatchPacket (packet.DestinationId, packet)
		end
		
		self.Queue = {}
	end
	
	return self
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	if not self:IsOpen () then
		-- Channel not open, queue up message
		self.Queue [#self.Queue + 1] = packet
		packet.DestinationId = destinationId
		
		if #self.Queue == 1024 then
			GLib.Error ("Channel:DispatchPacket : " .. self:GetName () .. " queue is growing too long!")
		end
		
		return
	end
	
	if packet:GetSize () <= self.UsermessageChannel:GetMTU () then
		return self.UsermessageChannel:DispatchPacket (destinationId, packet)
	elseif packet:GetSize () <= self.NetChannel:GetMTU () then
		return self.NetChannel:DispatchPacket (destinationId, packet)
	else
		return self.SplitPacketChannel:DispatchPacket (destinationId, packet)
	end
end

function self:GetMTU ()
	return self.SplitPacketChannel:GetMTU ()
end

-- Handlers
function self:GetHandler ()
	return self.Handler
end

function self:SetHandler (handler)
	self.Handler = handler
	
	self.UsermessageChannel:SetHandler (handler)
	self.NetChannel:SetHandler (handler)
	self.SplitPacketChannel:SetHandler (handler)
	
	return self
end