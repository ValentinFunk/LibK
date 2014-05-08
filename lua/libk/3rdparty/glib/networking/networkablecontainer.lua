local self = {}
GLib.NetworkableContainer = GLib.MakeConstructor (self, GLib.Networkable)

function self:ctor ()
end

function self:GetChildNetworkable (address)
	GLib.Error ("NetworkableContainer:GetChildNetworkable : Not implemented.")
end

function self:GetChildNetworkableAddress (childNetworkable)
	GLib.Error ("NetworkableContainer:GetChildNetworkableAddress : Not implemented.")
end

function self:GetChildNetworkableRecursive (addressBuffer)
	local networkable = self
	local address = addressBuffer:String ()
	while networkable do
		if address == "" then
			return networkable
		end
		
		if networkable:IsNetworkableContainer () then
			networkable = networkable:GetChildNetworkable (address)
			
			if not networkable then
				GLib.Error ("NetworkableContainer:GetChildNetworkable : Child networkable not found (" .. address .. ").")
			end
		else
			GLib.Error ("NetworkableContainer:GetChildNetworkableRecursive : " .. address .. " is not a NetworkableContainer.")
			break
		end
		
		address = addressBuffer:String ()
	end
	
	return networkable
end

function self:HandleChildMessage (sourceId, addressBuffer, inBuffer)
	local networkable = self:GetChildNetworkableRecursive (addressBuffer)
	if not networkable then
		GLib.Error ("NetworkableContainer:HandleChildMessage : Cannot find child networkable.")
		return
	end
	networkable:HandleMessage (sourceId, inBuffer)
end

function self:IsNetworkableContainer ()
	return true
end

function self:NetworkChildMessage (childNetworkable, sourceNetworkable, subscriberSet, addressBuffer, outBuffer)
	subscriberSet = subscriberSet or self:GetSubscriberSet ()
	addressBuffer:PrependString (tostring (self:GetChildNetworkableAddress (childNetworkable)))
	self:DispatchEvent ("NetworkMessage", sourceNetworkable, subscriberSet or self:GetSubscriberSet (), addressBuffer, outBuffer)
end

-- Internal, do not call
function self:HookNetworkable (childNetworkable)
	if not childNetworkable then return end
	if type (childNetworkable) ~= "table" then return end
	
	childNetworkable:AddEventListener ("NetworkMessage", tostring (self),
		function (_, sourceNetworkable, subscriberSet, addressBuffer, outBuffer)
			self:NetworkChildMessage (childNetworkable, sourceNetworkable, subscriberSet, addressBuffer, outBuffer)
		end
	)
end

function self:UnhookNetworkable (childNetworkable)
	if not childNetworkable then return end
	if type (childNetworkable) ~= "table" then return end
	
	childNetworkable:RemoveEventListener ("NetworkMessage", tostring (self))
end