-- MySQL1.8
local self = {}
GLib.Databases.MySqlDatabase = GLib.MakeConstructor (self, GLib.Databases.IDatabase)

local loaded = false

function self:ctor ()
	self.Database = nil
	
	if not loaded then
		require ("mysql")
		loaded = true
	end
end

function self:Connect (server, port, username, password, databaseName, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	if self:IsConnected () then
		self:Disconnect ()
		return self:Connect (server, port, username, password, databaseName)
	end
	
	local database, error = mysql.connect (server, username, password, databaseName, port)
	if database == 0 then return false, error end
	
	self.Database = database
	
	return true
end

function self:Disconnect (callback)
	if callback then GLib.CallSelfAsSync () return end
	
	if not self:IsConnected () then return true end
	
	local success, error = mysql.disconnect (self.Database)
	if not success then return false, error end
	
	self.Database = nil
	
	return true
end

function self:EscapeString (string)
	if not self:IsConnected () then return "" end
	
	local string, error = mysql.escape (self.Database, string)
	
	return string or ""
end

function self:GetDatabaseListQuery ()
	return "SHOW DATABASES"
end

function self:GetTableListQuery (database)
	if database then
		return "SHOW TABLES IN " .. database
	else
		return "SHOW TABLES"
	end
end

function self:IsConnected ()
	return self.Database ~= nil
end

function self:Query (query, callback)
	if callback then GLib.CallSelfAsSync () return end
	
	if not self:IsConnected () then
		return false, "Not connected to the database."
	end
	
	local result, success, error = mysql.query (self.Database, query)
	if not success then return false, error end
	
	return true, result
end