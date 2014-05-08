local self = {}
GLib.Networking.Networkable = GLib.MakeConstructor (self, GLib.Serialization.ISerializable)

--[[
	Events:
		NetworkMessage (Networkable sourceNetworkable, SubscriberSet subsriberSet, OutBuffer addressBuffer, OutBuffer outBuffer)
			Fired when a network message needs to be sent.
]]

function self:ctor ()
	self.RevisionId = 0
	self.State = GLib.Networking.NetworkableState.Unsynchronized
	self.Authoritative = SERVER and true or false
	self.SubscriberSet = nil
	
	GLib.EventProvider (self)
end

-- Revision number
function self:GetRevisionId ()
	return self.RevisionId
end

function self:IncrementRevisionId ()
	self.RevisionId = self.RevisionId + 1
	
	if self.RevisionId >= 4294967296 then
		self.RevisionId = 1
	end
end

function self:SetRevisionId (revisionId)
	self.RevisionId = revisionId
	
	if self.RevisionId >= 4294967296 then
		self.RevisionId = 1
	end
end

-- State
function self:GetNetworkableState ()
	if self:IsAuthoritative () then
		return GLib.Networking.NetworkableState.Synchronized
	end
	
	return self.State
end

-- Subscribers
function self:CreateSubscriberSet ()
	self.SubscriberSet = GLib.SubscriberSet ()
end

function self:GetSubscriberSet ()
	return self.SubscriberSet
end

-- Networking
function self:IsAuthoritative ()
	return self.Authoritative
end

function self:IsClient ()
	return not self:IsAuthoritative ()
end

function self:IsNetworkableContainer ()
	return false
end

-- Handles a message that was caused to be sent by the NetworkMessage event.
function self:HandleMessage (sourceId, inBuffer)
	GLib.Error ("Networkable:HandleMessage : Not implemented.")
end

-- Dispatches a network message associated with this Networkable
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