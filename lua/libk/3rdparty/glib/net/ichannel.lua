local self = {}
GLib.Net.IChannel = GLib.MakeConstructor (self)

--[[
	Events:
		NameChanged (oldName, name)
			Fired when this channel's name has been changed.
		Registered ()
			Fired when this channel has been registered.
		Unregistered ()
			Fired when this channel has been unregistered.
]]

function self:ctor (channelName, handler)
	-- Identity
	self.Name = channelName
	
	-- Registration
	self.Registered = false
	
	-- State
	self.Open = false
	
	-- Handlers
	self.Handler = handler or GLib.NullCallback
	
	GLib.EventProvider (self)
end

function self:dtor ()
	if self:IsRegistered () then
		self:Unregister ()
	end
end

-- Identity
function self:GetName ()
	return self.Name
end

function self:SetName (name)
	if self.Name == name then return self end
	
	local lastName = self.Name
	self.Name = name
	self:DispatchEvent ("NameChanged", lastName, self.Name)
	
	return self
end

-- Registration
function self:IsRegistered ()
	return self.Registered
end

function self:Register ()
	GLib.Error ("IChannel:Register : Not implemented.")
end

function self:Unregister ()
	GLib.Error ("IChannel:Unregister : Not implemented.")
end

function self:SetRegistered (registered)
	if self.Registered == registered then return self end
	
	self.Registered = registered
	self:DispatchEvent (self.Registered and "Registered" or "Unregistered")
	
	return self
end

-- State
function self:IsOpen (destinationId)
	return self.Open
end

function self:SetOpen (open)
	self.Open = open
	return self
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	GLib.Error ("IChannel:DispatchPacket : Not implemented.")
end

function self:GetMTU ()
	GLib.Error ("IChannel:GetMTU : Not implemented.")
end

function self:HandlePacket (sourceId, inBuffer)
	return self:GetHandler () (sourceId, inBuffer)
end

function self:IsDestinationRoutable (destinationId)
	GLib.Error ("IChannel:IsDestinationRoutable : Not implemented.")
end

-- Handlers
function self:GetHandler ()
	return self.Handler
end

function self:SetHandler (handler)
	self.Handler = handler
	return self
end