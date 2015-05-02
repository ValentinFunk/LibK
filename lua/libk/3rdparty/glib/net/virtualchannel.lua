local self = {}
GLib.Net.VirtualChannel = GLib.MakeConstructor (self, GLib.Net.ISingleEndpointChannel)

--[[
	Events:
		DispatchPacket (destinationId, OutBuffer packet)
			Fired when a packet needs to be dispatched.
]]

function self:ctor ()
	self.MTU = math.huge
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	self:DispatchEvent ("DispatchPacket", destinationId, packet)
end

function self:GetMTU ()
	return self.MTU
end

function self:SetMTU (mtu)
	self.MTU = mtu
	return self
end

-- Handlers
function self:HandlePacket (sourceId, inBuffer)
	return self:GetHandler () (sourceId, inBuffer)
end