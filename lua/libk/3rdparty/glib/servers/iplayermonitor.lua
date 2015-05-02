local self = {}
GLib.IPlayerMonitor = GLib.MakeConstructor (self)

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
	GLib.EventProvider (self)
end

function self:AddPlayerExistenceListener (nameOrCallback, callback)
	GLib.Error ("IPlayerMonitor:AddPlayerExistenceListener : Not implemented.")
end

function self:RemovePlayerExistenceListener (nameOrCallback)
	GLib.Error ("IPlayerMonitor:RemovePlayerExistenceListener : Not implemented.")
end

-- Enumerates connected players.
-- Returns: () -> (userId, Player player)
function self:GetPlayerEnumerator ()
	GLib.Error ("IPlayerMonitor:GetPlayerEnumerator : Not implemented.")
end

function self:GetUserEntity (userId)
	GLib.Error ("IPlayerMonitor:GetUserEntity : Not implemented.")
end

function self:GetUserEntities (userId)
	GLib.Error ("IPlayerMonitor:GetUserEntities : Not implemented.")
end

-- Enumerates user ids.
-- Returns: () -> userId
function self:GetUserEnumerator ()
	GLib.Error ("IPlayerMonitor:GetUserEnumerator : Not implemented.")
end

function self:GetUserName (userId)
	GLib.Error ("IPlayerMonitor:GetUserName : Not implemented.")
end

function self:IsUserPresent (userId)
	GLib.Error ("IPlayerMonitor:IsUserPresent : Not implemented.")
end