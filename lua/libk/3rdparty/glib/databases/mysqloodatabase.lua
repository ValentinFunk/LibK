-- MySQLOO
local self = {}
GLib.Databases.MySqlOODatabase = GLib.MakeConstructor (self, GLib.Databases.IDatabase)

local loaded = false

function self:ctor ()
	self.Database = nil
	
	if not loaded then
		require ("mysqloo")
		loaded = true
	end
end

function self:Connect (server, port, username, password, databaseName, callback)
	if not callback then return I (GLib.CallSelfAsAsync ()) end
	
	if self:IsConnected () then
		self:Disconnect (
			function ()
				self:Connect (server, port, username, password, databaseName, callback)
			end
		)
		return
	end
	
	self.Database = mysqloo.connect (server, username, password, databaseName, port)
	
	function self.Database:onConnected ()
		callback (true)
	end
	
	function self.Database:onConnectionFailed (error)
		callback (false, error)
	end
	
	self.Database:connect ()
end

function self:Disconnect (callback)
	if callback then GLib.CallSelfAsSync () return end
	
	self.Database = nil
	
	return true
end

function self:EscapeString (string)
	if not self:IsConnected () then return "" end
	return self.Database:escape (string)
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
	if not callback then return I (GLib.CallSelfAsAsync ()) end
	
	if not self:IsConnected () then
		callback (false, "Not connected to database.")
		return
	end
	
	local q = self.Database:query (query)
	
	function q:onSuccess ()
		callback (true, self:getData ())
	end
	
	function q:onFailure (error)
		callback (false, error)
	end
	
	function q:onAborted ()
		callback (false, "Query aborted.")
	end
	
	q:start ()
end