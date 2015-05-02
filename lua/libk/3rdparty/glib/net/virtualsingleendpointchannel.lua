local self = {}
GLib.Net.VirtualSingleEndpointChannel = GLib.MakeConstructor (self, GLib.Net.ISingleEndpointChannel)

--[[
	Events:
		DispatchPacket (OutBuffer packet)
			Fired when a packet needs to be dispatched.
]]

function self:ctor ()
	self.MTU = math.huge
end

-- Packets
function self:DispatchPacket (packet)
	self:DispatchEvent ("DispatchPacket", packet)
end

function self:GetMTU ()
	return self.MTU
end

function self:SetMTU (mtu)
	self.MTU = mtu
	return self
end

-- Handlers
function self:HandlePacket (inBuffer)
	return self:GetHandler () (self:GetRemoteId (), inBuffer)
end