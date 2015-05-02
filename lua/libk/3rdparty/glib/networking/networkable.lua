local self = {}
GLib.Networking.Networkable = GLib.MakeConstructor (self, GLib.IDisposable)

--[[
	Events:
		DispatchPacket (destinationId, OutBuffer packet)
			Fired when a packet needs to be dispatched.
]]

function self:ctor ()
	-- NetworkableHost
	self.NetworkableHost = nil
	
	-- Subscribers
	self.SubscriberSet = nil
	
	GLib.EventProvider (self)
end

function self:dtor ()
	self:SetNetworkableHost (nil)
end

function self:IsHosting ()
	return nil
end

-- NetworkableHost
function self:GetNetworkableHost ()
	return self.NetworkableHost
end

function self:SetNetworkableHost (networkableHost)
	if self.NetworkableHost == networkableHost then return self end
	
	if self.NetworkableHost then
		self.NetworkableHost:UnregisterNetworkable (self)
	end
	
	self.NetworkableHost = networkableHost
	
	if self.NetworkableHost and
	   not self.NetworkableHost:IsNetworkableRegistered (self) then
		self.NetworkableHost:RegisterNetworkable (self)
	end
	
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
function self:DispatchPacket (destinationId, packet)
	destinationId = destinationId or self.SubscriberSet
	
	self:DispatchEvent ("DispatchPacket", destinationId, packet)
end

function self:HandlePacket (sourceId, inBuffer)
end

function self:HandleRemoteDestruction ()
	self:dtor ()
end