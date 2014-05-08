local self = {}
GLib.Interfaces.ICurrencySystem = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:AddUserBalance (userId, deltaBalance, callback)
	GLib.Error ("ICurrencySystem:AddUserBalance : Not implemented.")
end

function self:GetUserBalance (userId, callback)
	GLib.Error ("ICurrencySystem:GetUserBalance : Not implemented.")
end

function self:SetUserBalance (userId, balance, callback)
	GLib.Error ("ICurrencySystem:SetUserBalance : Not implemented.")
end

function self:SubtractUserBalance (userId, deltaBalance, callback)
	GLib.Error ("ICurrencySystem:SubtractUserBalance : Not implemented.")
end