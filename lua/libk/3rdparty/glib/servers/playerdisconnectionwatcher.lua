local self = {}
GLib.PlayerDisconnectionWatcher = GLib.MakeConstructor (self)

--[[
	Events:
		PlayerDisconnected (Player ply, userId)
			Fired when a player has disconnected.
]]

function self:ctor ()
	self.DisconnectionEvents = {}
	
	GLib.PlayerMonitor:AddEventListener ("PlayerDisconnected", "GLib.PlayerDisconnectionWatcher",
		function (_, ply, userId)
			if not self.DisconnectionEvents [userId] then return end
			
			self.DisconnectionEvents [userId]:Dispatch ()
			
			self:DispatchEvent ("PlayerDisconnected", ply, userId)
		end
	)
	
	GLib.EventProvider (self)
end

function self:dtor ()
	GLib.PlayerMonitor:RemoveEventListener ("PlayerDisconnected", "GLib.PlayerDisconnectionWatcher")
end

function self:GetDisconnectionEvent (userId)
	if not self.DisconnectionEvents [userId] then
		if not GLib.PlayerMonitor:IsUserPresent (userId) then return nil end
		
		self.DisconnectionEvents [userId] = GLib.Event ()
		self.DisconnectionEvents [userId]:AddListener (
			function ()
				self.DisconnectionEvents [userId] = nil
			end
		)
	end
	
	return self.DisconnectionEvents [userId]
end

function self:__call (userId)
	return GLib.PlayerDisconnectionWatcher2 (userId)
end

GLib.PlayerDisconnectionWatcher = GLib.PlayerDisconnectionWatcher ()