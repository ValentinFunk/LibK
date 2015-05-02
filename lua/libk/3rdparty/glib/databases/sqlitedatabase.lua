-- SQLite
local self = {}
GLib.Databases.SqliteDatabase = GLib.MakeConstructor (self, GLib.Databases.IDatabase)

function self:ctor ()
end

function self:Connect (server, port, username, password, databaseName, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	return true
end

function self:Disconnect (callback)
	if callback then GLib.CallSelfAsSync () return end
	
	return true
end

function self:EscapeString (string)
	return sql.SQLStr (string, true)
end

function self:GetDatabaseListQuery ()
	return ""
end

function self:GetTableListQuery (database)
	return "SELECT * FROM sqlite_master WHERE type = \"table\""
end

function self:IsConnected ()
	return true
end

function self:Query (query, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	local result = sql.Query (query)
	if result == false then
		return false, sql.LastError ()
	else
		return true, result
	end
end