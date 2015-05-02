local self = {}
GLib.PlayerDisconnectionWatcher2 = GLib.MakeConstructor (self, GLib.Invoker)

function self:ctor (userId)
	local event = GLib.PlayerDisconnectionWatcher:GetDisconnectionEvent (self.UserId)
	event:AddListener (self:GetHashCode (),
		function ()
			self:Invoke ()
		end
	)
end

function self:dtor ()
	local event = GLib.PlayerDisconnectionWatcher:GetDisconnectionEvent (self.UserId)
	if event then
		event:RemoveListener (self:GetHashCode ())
	end
end