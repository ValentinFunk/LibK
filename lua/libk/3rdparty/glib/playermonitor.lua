local self = {}
GLib.PlayerMonitor = GLib.MakeConstructor (self)

function self:ctor (systemName)
	self.SystemName = systemName

	self.Players = {} -- Map of Steam Ids to player data
	self.EntitiesToUserIds = SERVER and GLib.WeakKeyTable () or {} -- Map of Players to Steam Ids
	self.QueuedPlayers = {}  -- Array of new Players to be processed
	GLib.EventProvider (self)
	
	hook.Add (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", self.SystemName .. ".PlayerConnected", function (ply)
		if type (ply) == "Player" then
			self.QueuedPlayers [ply] = true
		end
	end)

	hook.Add ("Think", self.SystemName .. ".PlayerConnected", function ()
		-- Check for new players
		for _, ply in ipairs (player.GetAll ()) do
			local steamId = self:GetPlayerSteamId (ply)
			if steamId then
				if not self.QueuedPlayers [ply] and not self.EntitiesToUserIds [ply] then
					self.QueuedPlayers [ply] = true
				end
			end
		end
		
		-- Process new players
		for ply, _ in pairs (self.QueuedPlayers) do
			local steamId = self:GetPlayerSteamId (ply)
			if steamId and
			   steamId ~= "STEAM_ID_PENDING" and 
			   ply:Name () ~= "unconnected" then
				self.QueuedPlayers [ply] = nil
				
				local isLocalPlayer = CLIENT and ply == LocalPlayer () or false
				self.Players [steamId] = self.Players [steamId] or {}
				self.Players [steamId].Players = self.Players [steamId].Players or GLib.WeakTable ()
				self.Players [steamId].Players [ply:EntIndex ()] = ply
				self.Players [steamId].Name    = ply:Name ()
				
				self.EntitiesToUserIds [ply] = steamId
				self:DispatchEvent ("PlayerConnected", ply, steamId, isLocalPlayer)
				if isLocalPlayer then
					self:DispatchEvent ("LocalPlayerConnected", ply, steamId)
				end
			end
		end
	end)

	hook.Add ("EntityRemoved", self.SystemName .. ".PlayerDisconnected", function (ply)
		local steamId = self:GetPlayerSteamId (ply)
		if not steamId then return end
		
		if SERVER then
			if self.Players [steamId] then
				self.Players [steamId].Players [ply:EntIndex ()] = nil
				if not self:GetUserEntity (steamId) then
					self.Players [steamId] = nil
				end
			end
			self.EntitiesToUserIds [ply] = nil
		end
		self:DispatchEvent ("PlayerDisconnected", ply, steamId)
	end)

	for _, ply in ipairs (player.GetAll ()) do
		self.QueuedPlayers [ply] = true
	end

	if type (_G [systemName]) == "table" and
	   type (_G [systemName].AddEventListener) == "function" then
		_G [systemName]:AddEventListener ("Unloaded", function ()
			self:dtor ()
		end)
	end
end

function self:dtor ()
	hook.Remove (CLIENT and "OnEntityCreated" or "PlayerInitialSpawn", self.SystemName .. ".PlayerConnected")
	hook.Remove ("Think", self.SystemName .. ".PlayerConnected")
	hook.Remove ("EntityRemoved", self.SystemName .. ".PlayerDisconnected")
end

--[[
	PlayerMonitor:GetPlayerEnumerator
		Returns: ()->(userId, Player player)
		
		Enumerates connected players.
]]
function self:GetPlayerEnumerator ()
	local next, tbl, key = pairs (self.Players)
	return function ()
		key = next (tbl, key)
		if not key then return nil, nil end
		
		return key, self:GetUserEntity (key)
	end
end

function self:GetPlayerSteamId (ply)
	if self.EntitiesToUserIds [ply] then return self.EntitiesToUserIds [ply] end

	return GLib.GetPlayerId (ply)
end

function self:GetUserEntity (userId)
	local userEntry = self.Players [userId]
	if not userEntry then return nil end
	
	for _, ply in pairs (userEntry.Players) do
		if ply:IsValid () then
			return ply
		end
	end
	return nil
end

function self:GetUserEntities (userId)
	local userEntry = self.Players [userId]
	if not userEntry then return nil end
	
	local userEntities = {}
	for _, ply in pairs (userEntry.Players) do
		if ply:IsValid () then
			userEntities [#userEntities + 1] = ply
		end
	end
	return userEntities
end

--[[
	PlayerMonitor:GetUserEnumerator ()
		Returns: ()->userId userEnumerator
		
		Enumerates user ids.
]]
function self:GetUserEnumerator ()
	local next, tbl, key = pairs (self.Players)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:GetUserName (userId)
	local userEntry = self.Players [userId]
	if not userEntry then return userId end
	
	for _, ply in pairs (userEntry.Players) do
		if ply:IsValid () then
			return ply:Name ()
		end
	end
	
	return userEntry.Name
end