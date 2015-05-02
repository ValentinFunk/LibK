local self = {}
GLib.Databases.IDatabase = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:Connect (hostname, port, username, password, databaseName, callback)
	GLib.Error ("IDatabase:Connect : Not implemented.")
end

function self:Disconnect (callback)
	GLib.Error ("IDatabase:Connect : Not implemented.")
end

function self:EscapeString (str)
	GLib.Error ("IDatabase:EscapeString : Not implemented.")
end

function self:GetDatabaseListQuery ()
	GLib.Error ("IDatabase:GetDatabaseListQuery : Not implemented.")
end

function self:GetTableListQuery ()
	GLib.Error ("IDatabase:GetDatabaseListQuery : Not implemented.")
end

function self:IsConnected ()
	GLib.Error ("IDatabase:IsConnected : Not implemented.")
end

function self:Query (query, callback)
	GLib.Error ("IDatabase:Query : Not implemented.")
end