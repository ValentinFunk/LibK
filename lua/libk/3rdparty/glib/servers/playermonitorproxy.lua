local self = {}
GLib.PlayerMonitorProxy = GLib.MakeConstructor (self, GLib.IPlayerMonitor)

--[[
	Events:
		LocalPlayerConnected (Player ply, userId)
			Fired when the local client's player entity has been created.
		PlayerConnected (Player ply, userId, isLocalPlayer)
			Fired when a player has connected and has a player entity.
		PlayerDisconnected (Player ply, userId)
			Fired when a player has disconnected.
]]

function self:ctor (playerMonitor, playerMonitorId)
	self.PlayerMonitor = playerMonitor
	self.Id = playerMonitorId or self:GetHashCode ()
	
	self.PlayerMonitor:AddEventListener ("LocalPlayerConnected", self.Id .. ".PlayerMonitor",
		function (_, ply, userId)
			self:DispatchEvent ("LocalPlayerConnected", ply, userId)
		end
	)
	
	self.PlayerMonitor:AddEventListener ("PlayerConnected", self.Id .. ".PlayerMonitor",
		function (_, ply, userId, isLocalPlayer)
			self:DispatchEvent ("PlayerConnected", ply, userId, isLocalPlayer)
		end
	)
	
	self.PlayerMonitor:AddEventListener ("PlayerDisconnected", self.Id .. ".PlayerMonitor",
		function (_, ply, userId)
			self:DispatchEvent ("PlayerDisconnected", ply, userId)
		end
	)
	
	-- Process existing players
	GLib.CallDelayed (
		function ()
			for userId, ply in self.PlayerMonitor:GetPlayerEnumerator () do
				local isLocalPlayer = GLib.GetPlayerId (ply) == GLib.GetLocalId ()
				
				self:DispatchEvent ("PlayerConnected", ply, userId, isLocalPlayer)
				
				if isLocalPlayer then
					self:DispatchEvent ("LocalPlayerConnected", ply, userId)
				end
			end
		end
	)
	
	-- Register destructor
	if type (_G [self.Id]) == "table" and
	   type (_G [self.Id].AddEventListener) == "function" then
		_G [self.Id]:AddEventListener ("Unloaded", self.Id .. ".PlayerMonitor",
			function ()
				self:dtor ()
			end
		)
	end
end

function self:dtor ()
	self.PlayerMonitor:RemoveEventListener ("LocalPlayerConnected", self.Id .. ".PlayerMonitor")
	self.PlayerMonitor:RemoveEventListener ("PlayerConnected",      self.Id .. ".PlayerMonitor")
	self.PlayerMonitor:RemoveEventListener ("PlayerDisconnected",   self.Id .. ".PlayerMonitor")
	
	-- Unregister destructor
	if type (_G [self.Id]) == "table" and
	   type (_G [self.Id].AddEventListener) == "function" then
		_G [self.Id]:RemoveEventListener ("Unloaded", self.Id .. ".PlayerMonitor")
	end
end

function self:AddPlayerExistenceListener (nameOrCallback, callback)
	callback = callback or nameOrCallback
	
	for userId in self:GetUserEnumerator () do
		for _, ply in ipairs (self:GetUserEntities (userId)) do
			local isLocalPlayer = CLIENT and ply == LocalPlayer () or false
			callback (self, ply, userId, isLocalPlayer)
		end
	end
	
	self:AddEventListener ("PlayerConnected", nameOrCallback, callback)
end

function self:RemovePlayerExistenceListener (nameOrCallback)
	self:RemoveEventListener ("PlayerConnected", nameOrCallback)
end

function self:GetPlayerEnumerator ()
	return self.PlayerMonitor:GetPlayerEnumerator ()
end

function self:GetUserEntity (userId)
	return self.PlayerMonitor:GetUserEntity (userId)
end

function self:GetUserEntities (userId)
	return self.PlayerMonitor:GetUserEntities (userId)
end

function self:GetUserEnumerator ()
	return self.PlayerMonitor:GetUserEnumerator ()
end

function self:GetUserName (userId)
	return self.PlayerMonitor:GetUserName (userId)
end

function self:IsUserPresent (userId)
	return self.PlayerMonitor:IsUserPresent (userId)
end