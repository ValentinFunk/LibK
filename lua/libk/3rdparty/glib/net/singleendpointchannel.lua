local self = {}
GLib.Net.SingleEndpointChannel = GLib.MakeConstructor (self, GLib.Net.ISingleEndpointChannel)

function self:ctor (channel, remoteId, handler)
	-- Identity
	self.Channel = channel
	self.Name = nil
	self.RemoteId = remoteId
	
	-- State
	self.Open = nil
	
	-- Handlers
	self:SetHandler (handler or GLib.NullCallback)
end

-- Identity
function self:GetName ()
	return self.Channel:GetName ()
end

function self:SetName (name)
	return self
end

-- State
function self:IsOpen ()
	return self.Channel:IsOpen (self:GetRemoteId ())
end

function self:SetOpen ()
	return self
end

-- Packets
function self:DispatchPacket (packet)
	return self.Channel:DispatchPacket (self:GetRemoteId (), packet)
end

function self:GetMTU ()
	return self.Channel:GetMTU ()
end

function self:HandlePacket (inBuffer)
	self:GetHandler () (self:GetRemoteId (), inBuffer)
end