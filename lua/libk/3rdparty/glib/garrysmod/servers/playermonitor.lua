local self = {}
GLib.PlayerMonitor = GLib.MakeConstructor (self, GLib.IPlayerMonitor)

--[[
	Events:
		LocalPlayerConnected (Player ply, userId)
			Fired when the local client's player entity has been created.
		PlayerConnected (Player ply, userId, isLocalPlayer)
			Fired when a player has connected and has a player entity.
		PlayerDisconnected (Player ply, userId)
			Fired when a player has disconnected.
]]

function self:ctor ()
	self.QueuedPlayers = {} -- Array of new Players to be processed
	
	self.EntriesBySteamId = {} -- Map<SteamId, Set<Entry>>
	self.EntriesByUserId  = {}
	self.NameCache = {}
	
	-- Blacklist to prevent players from being re-detected once they've disconnected
	self.DisconnectedPlayers = GLib.WeakKeyTable ()
	
	-- Players have to be queued because they might not have their steam IDs available yet.
	hook.Add (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", "GLib.PlayerMonitor.PlayerConnected",
		function (ply)
			if not ply:IsPlayer () then return end
			
			self.QueuedPlayers [ply] = true
			self:ProcessQueue ()
		end
	)
	
	hook.Add ("Tick", "GLib.PlayerMonitor.ProcessQueue",
		function ()
			self:ProcessQueue ()
		end
	)
	
	gameevent.Listen ("player_disconnect")
	hook.Add ("player_disconnect", "GLib.PlayerMonitor.PlayerDisconnected",
		function (data)
			local userId  = data.userid
			local entry = self.EntriesByUserId [userId]
			
			if not entry then return end
			
			-- Remove entry
			self.EntriesByUserId [userId] = nil
			self.EntriesBySteamId [entry:GetSteamId ()] [entry] = nil
			
			if not next (self.EntriesBySteamId [entry:GetSteamId ()]) then
				self.EntriesBySteamId [entry:GetSteamId ()] = nil
			end
			
			-- Prevent player from being detected again
			self.DisconnectedPlayers [entry:GetPlayer ()] = true
			
			-- Dispatch event
			self:DispatchEvent ("PlayerDisconnected", entry:GetPlayer (), entry:GetSteamId ())
		end
	)
	
	-- Queue existing players
	for _, ply in ipairs (player.GetAll ()) do
		self.QueuedPlayers [ply] = true
	end
	self:ProcessQueue ()
end

function self:dtor ()
	hook.Remove (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", "GLib.PlayerMonitor.PlayerConnected")
	hook.Remove ("Tick", "GLib.PlayerMonitor.ProcessQueue")
	hook.Remove ("player_disconnect", "GLib.PlayerMonitor.PlayerDisconnected")
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

-- Enumerates connected players.
-- Returns: () -> (userId, Player player)
function self:GetPlayerEnumerator ()
	local next, tbl, key = pairs (self.EntriesByUserId)
	return function ()
		key = next (tbl, key)
		if not key then return nil, nil end
		
		local entry = self.EntriesByUserId [key]
		return entry:GetSteamId (), entry:GetPlayer ()
	end
end

function self:GetUserEntity (userId)
	if userId == "STEAM_0:0:0" and
	   game.SinglePlayer () then
		userId = GLib.GetPlayerId (player.GetAll () [1])
	end
	
	if not self.EntriesBySteamId [userId] then
		-- Check the queue
		for ply, _ in pairs (self.QueuedPlayers) do
			if GLib.GetPlayerId (ply) == userId then return ply end
		end
		return nil
	end
	
	for entry, _ in pairs (self.EntriesBySteamId [userId]) do
		return entry:GetPlayer ()
	end
	
	return nil
end

function self:GetUserEntities (userId)
	if userId == "STEAM_0:0:0" and
	   game.SinglePlayer () then
		userId = GLib.GetPlayerId (player.GetAll () [1])
	end
	
	if not self.EntriesBySteamId [userId] then
		-- Check the queue
		for ply, _ in pairs (self.QueuedPlayers) do
			if GLib.GetPlayerId (ply) == userId then return ply end
		end
		return nil
	end
	
	local entities = {}
	for entry, _ in pairs (self.EntriesBySteamId [userId]) do
		entities [#entities + 1] = entry:GetPlayer ()
	end
	
	return entities
end

-- Enumerates user ids.
-- Returns: () -> userId
function self:GetUserEnumerator ()
	return GLib.KeyEnumerator (self.EntriesBySteamId)
end

function self:GetUserName (userId)
	local userEntity = self:GetUserEntity (userId)
	
	if userEntity and userEntity:IsValid () then
		self.NameCache [userId] = userEntity:Name ()
		return userEntity:Name ()
	end
	
	return self.NameCache [userId] or userId
end

function self:IsUserPresent (userId)
	if userId == "STEAM_0:0:0" and
	   game.SinglePlayer () then
		userId = GLib.GetPlayerId (player.GetAll () [1])
	end
	
	return self.EntriesBySteamId [userId] ~= nil
end

-- Internal, do not call
function self:ProcessQueue ()
	-- Check for new players.
	-- This really is needed (did tests).
	for _, ply in ipairs (player.GetAll ()) do
		if not self.DisconnectedPlayers [ply] and
		   not self.EntriesByUserId [ply:UserID ()] and
		   not self.QueuedPlayers [ply] and
		   GLib.GetPlayerId (ply) then
			self.QueuedPlayers [ply] = true
		end
	end
	
	-- Process new players
	for ply, _ in pairs (self.QueuedPlayers) do
		local userId = GLib.GetPlayerId (ply)
		if not ply:IsValid () then
			-- Player joined and left really quickly.
			self.QueuedPlayers [ply] = nil
		elseif userId and
			   userId ~= "STEAM_ID_PENDING" then
			self.QueuedPlayers [ply] = nil
			
			-- Add entry
			local entry = GLib.PlayerMonitorEntry (ply)
			self.EntriesBySteamId [userId] = self.EntriesBySteamId [userId] or {}
			self.EntriesBySteamId [userId] [entry] = true
			self.EntriesByUserId [entry:GetUserId ()] = entry
			self.NameCache [userId] = ply:Name ()
			
			-- Dispatch events
			local isLocalPlayer = CLIENT and ply == LocalPlayer () or false
			self:DispatchEvent ("PlayerConnected", ply, userId, isLocalPlayer)
			
			if isLocalPlayer then
				self:DispatchEvent ("LocalPlayerConnected", ply, userId)
			end
		end
	end
end

function self:__call (...)
	return GLib.PlayerMonitorProxy (self, ...)
end

GLib.PlayerMonitor = GLib.PlayerMonitor ()