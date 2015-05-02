local self = {}
GLib.PlayerMonitorEntry = GLib.MakeConstructor (self)

function self:ctor (ply)
	self.Player = ply
	self.Index = ply:EntIndex ()
	self.SteamId = GLib.GetPlayerId (ply)
	self.UserId = ply:UserID ()
end

function self:GetIndex ()
	return self.Index
end

function self:GetPlayer ()
	return self.Player
end

function self:GetSteamId ()
	return self.SteamId
end

function self:GetUserId ()
	return self.UserId
end