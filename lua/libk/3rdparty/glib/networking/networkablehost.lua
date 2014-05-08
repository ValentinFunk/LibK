local self = {}
GLib.Networking.NetworkableHost = GLib.MakeConstructor (self)

function self:ctor ()
	self.Networkables = {}
end

function self:RegisterNetworkable (id, networkable)
	if self.Networkables [id] then
		self:UnregisterNetworkable (id)
	end
	
	self.Networkables [id] = networkable
	self:HookNetworkable (self.Networkables [id], id)
end

function self:UnregisterNetworkable (id)
	self:UnhookNetworkable (self.Networkables [id], id)
	self.Networkables [id] = nil
end

-- Internal, do not call
function self:HookNetworkable (networkable, id)
	if not networkable then return end
	
	networkable:AddEventListener ("NetworkMessage", self:GetHashCode (),
		function (_, sourceNetworkable, subscriberSet, addressBuffer, outBuffer)
			outBuffer:PrependString (addressBuffer:GetString ())
			GLib.Net.DispatchPacket (subscriberSet or "Everyone", id, outBuffer)
		end
	)
	
	GLib.Net.RegisterChannel (id,
		function (sourceId, inBuffer)
			local address = inBuffer:String ()
			local addressBuffer = GLib.StringInBuffer (address)
			
			networkable:HandleChildMessage (sourceId, addressBuffer, inBuffer)
		end
	)
end

function self:UnhookNetworkable (networkable, id)
	if not networkable then return end
	
	networkable:RemoveEventListener ("NetworkMessage", self:GetHashCode ())
end