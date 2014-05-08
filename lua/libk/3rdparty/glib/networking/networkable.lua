local self = {}
GLib.Networkable = GLib.MakeConstructor (self, GLib.Serialization.ISerializable)

--[[
	Events:
		NetworkMessage (Networkable sourceNetworkable, SubscriberSet subsriberSet, OutBuffer addressBuffer, OutBuffer outBuffer)
			Fired when a network message needs to be sent.
]]

function self:ctor ()
	self.Authoritative = SERVER and true or false
	self.SubscriberSet = nil
	
	GLib.EventProvider (self)
end

function self:CreateSubscriberSet ()
	self.SubscriberSet = GLib.SubscriberSet ()
end

function self:GetSubscriberSet ()
	return self.SubscriberSet
end

-- Handles a message that was caused to be sent by the NetworkMessage event.
function self:HandleMessage (sourceId, inBuffer)
	GLib.Error ("Networkable:HandleMessage : Not implemented.")
end

function self:IsAuthoritative ()
	return self.Authoritative
end

function self:IsClient ()
	return not self:IsAuthoritative ()
end

function self:IsNetworkableContainer ()
	return false
end

function self:NetworkMessage (outBuffer)
	local addressBuffer = GLib.Net.OutBuffer ()
	addressBuffer:String ("")
	
	if type (outBuffer) == "string" then
		local messageType = outBuffer
		outBuffer = GLib.Net.OutBuffer ()
		outBuffer:String (messageType)
	end
	
	self:DispatchEvent ("NetworkMessage", self, self:GetSubscriberSet (), addressBuffer, outBuffer)
end