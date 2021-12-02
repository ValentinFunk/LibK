/*---------------------------------------------------------------------------
In large part ripped from DarkRP
MySQL and SQLite connectivity
---------------------------------------------------------------------------*/

/*
	Makes all database operations block
*/
function LibK.SetBlocking( bShouldBlock )
	LibK.databaseShouldBlock = bShouldBlock
end

hook.Add( "LibK_DatabaseConnectionFailed", "LibKHook", function ( DB, name, msg )
	DB.ConnectionPromise:Reject( tostring( msg ) )
end )

DATABASES = DATABASES or {}
function LibK.getDatabaseConnection( config, name )
	local DB = {}

	if config.UseMysql then
		local succ, err = pcall( require, "mysqloo" )
		if not succ then
			KLog( 1, "[LibK] FATAL: Couldn't load mysqloo, make sure it is correctly installed! errror was: " .. err )
			if err == "Couldn't load module library!" then
				hook.Call( "LibK_DatabaseConnectionFailed", nil, DB, name, "MySQLOO Error: libmysql.dll is not installed properly" )
			else
				hook.Call( "LibK_DatabaseConnectionFailed", nil, DB, name, "MySQLOO is not installed properly" )
			end
		else
			if (mysqloo.VERSION != "9" || !mysqloo.MINOR_VERSION || tonumber(mysqloo.MINOR_VERSION) < 3) then
				KLog( 1, "[LibK] FATAL: You are using an outdated mysqloo version\nDownload the latest mysqloo9 from here: bit.ly/mysqloo" )
				hook.Call( "LibK_DatabaseConnectionFailed", nil, DB, name, "You are using an outdated mysqloo version\nDownload the latest mysqloo9 from here: bit.ly/mysqloo" )
			else
				KLog( 4, "[LibK] MysqlOO is correctly installed." )
			end
		end
	end

	DB.CONNECTED_TO_MYSQL = false
	DB.MySQLDB = nil

	function DB.Log( ... )
		KLog( 4, ... )
	end

	function DB.SetBlocking( bBlocking )
		DB.shouldBlock = bBlocking
	end

	local QueuedQueries
	function DB.Begin()
		if not DB.CONNECTED_TO_MYSQL then
			sql.Begin()
		else
			if QueuedQueries then
				debug.Trace()
				error("Transaction ongoing!")
			end
			QueuedQueries = {}
		end
	end

	function DB.Commit(onFinished)
		if not DB.CONNECTED_TO_MYSQL then
			sql.Commit()
			if onFinished then onFinished() end
		else
			if not QueuedQueries then
				error("No queued queries! Call DB.Begin() first!")
			end

			if #QueuedQueries == 0 then
				QueuedQueries = nil
				return
			end

			-- Copy the table so other scripts can create their own queue
			local queue = table.Copy(QueuedQueries)
			QueuedQueries = nil

			-- Handle queued queries in order
			local queuePos = 0
			local call

			-- Recursion invariant: queuePos > 0 and queue[queuePos] <= #queue
			call = function(...)
				queuePos = queuePos + 1

				if queue[queuePos].callback then
					queue[queuePos].callback(...)
				end

				-- Base case, end of the queue
				if queuePos + 1 > #queue then
					if onFinished then onFinished() end -- All queries have finished
					return
				end

				-- Recursion
				local nextQuery = queue[queuePos + 1]
				DB.Query(nextQuery.query, call, nextQuery.onError)
			end

			DB.Query(queue[1].query, call, queue[1].onError)
		end
	end

	function DB.QueueQuery(sqlText, callback, errorCallback)
		if DB.CONNECTED_TO_MYSQL then
			table.insert(QueuedQueries, {query = sqlText, callback = callback, onError = errorCallback})
		end
		-- SQLite is instantaneous, simply running the query is equal to queueing it
		DB.Query(sqlText, callback, errorCallback)
	end

	function DB.Query(sqlText, callback, errorCallback, blocking)
		if LibK.LogSQL then
			file.Append("sqlqueries.txt", "\n"..os.date().. "\t"..(sqlText or ""))
		end
		if DB.CONNECTED_TO_MYSQL then
			local query = DB.MySQLDB:query(sqlText)
			local data
			query.onData = function(Q, D)
				data = data or {}
				data[#data + 1] = D
			end

			query.onError = function(Q, E)
				local isDisconnected = string.find(E, 'Lost connection to MySQL server during query')
				if DB.MySQLDB:status() == mysqloo.DATABASE_CONNECTING then
					KLogf( 4, "[INFO] Database is reconnecting! Query %s has been queued", sqlText )
					table.insert(DB.cachedQueries, {sqlText, callback, false})
					return
				end
				if (DB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED) or isDisconnected then
					KLogf( 4, "[INFO] Connection to the database lost, reconnecting! Query %s has been queued (%s)", sqlText, isDisconnected and E or 'db:status() == DATABASE_NOT_CONNECTED' )
					table.insert(DB.cachedQueries, {sqlText, callback, false})
					DB.ConnectToMySQL(config.Host, config.User, config.Password, config.Database, config.Port )
					return
				end

				DB.Log("MySQL Error: ".. E)
				ErrorNoHalt(E .. " (" .. sqlText .. ")\n")
				if errorCallback then
					errorCallback( 0, "MySQL Error: " .. E )
				end
			end

			query.onSuccess = function()
				if callback then callback(data, query:lastInsert()) end
			end
			query:start()
			if blocking or DB.shouldBlock or LibK.databaseShouldBlock then
				query:wait( )
			end
			return
		end

		local lastError = sql.LastError()
		local Result = sql.Query(sqlText)
		if Result == false then
			DB.Log("MySQL Error: ".. sql.LastError())
			ErrorNoHalt(sql.LastError() .. " (" .. sqlText .. ")\n")
			if errorCallback then
				return errorCallback( 0, "SQLite Error: " .. sql.LastError() )
			end
		end

		local rowid = sql.Query("SELECT last_insert_rowid() as id")
		if callback then callback(Result, rowid[1].id) end
		return Result
	end

	function DB.DoQuery( sqlText, blocking )
		local def = Deferred( )
		DB.Query( sqlText, function( data, lastInsertId )
			def:Resolve( data, lastInsertId )
		end, function( err )
			-- This has to be async for handlers to attach
			LibK.GLib.Threading.Thread():Start( function()
				def:Reject( 0, err )
			end )
		end, blocking )
		return def:Promise( )
	end

	function DB.QueryValue(sqlText, callback, errorCallback)
		if DB.CONNECTED_TO_MYSQL then
			local query = DB.MySQLDB:query(sqlText)
			local data
			query.onData = function(Q, D)
				data = D
			end
			query.onSuccess = function()
				for k,v in pairs(data or {}) do
					callback(v)
					return
				end
				callback()
			end
			query.onError = function(Q, E)
				if (DB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED) then
					table.insert(DB.cachedQueries, {sqlText, callback, true})
					return
				end

				if errorCallback then
					errorCallback()
				end

				DB.Log("MySQL Error: ".. E)
				ErrorNoHalt(E .. " (" .. sqlText .. ")\n")
			end

			query:start()
			return
		end

		local lastError = sql.LastError()
		local val = sql.QueryValue(sqlText)
		if sql.LastError() and sql.LastError() ~= lastError then
			error("SQLite error: " .. lastError)
		end

		if callback then callback(val) end
		return val
	end

	function DB.ConnectToMySQL(host, username, password, database_name, database_port)
		DB.CONNECTED_TO_MYSQL = true
		
		if not mysqloo then
			KLogf( 1, "MySQL Error: MySQLOO modules aren't installed properly!" )
			return
		end

		if (mysqloo.VERSION != "9" || !mysqloo.MINOR_VERSION || tonumber(mysqloo.MINOR_VERSION) < 3) then
			KLog( 1, "[LibK] FATAL: You are using an outdated mysqloo version\nDownload the latest mysqloo9 from here: bit.ly/mysqloo" )
			return
		end

		local databaseObject = mysqloo.connect(host, username, password, database_name, database_port)
		LibK.mysqloolib.ConvertDatabase(databaseObject) -- Sets metatable to include convenience methods

		if timer.Exists("libk_check_mysql_status") then timer.Destroy("libk_check_mysql_status") end

		databaseObject.onConnectionFailed = function(_, msg)
			KLogf( 1, "[LibK] Connection failed to %s(%s@%s:%s): %s", name, username, host, database_port, msg )
			hook.Call( "LibK_DatabaseConnectionFailed", nil, DB, name, tostring( msg ) )
		end

		databaseObject.onConnected = function()
			DB.Log( Format( "[LibK] Connected to %s(%s@%s:%s)", name, username, host, database_port ) )
			DB.cachedQueries = DB.cachedQueries or {}
			if #DB.cachedQueries > 0 then
				KLogf( 4, "[INFO] Connection to the database %s has been reestablished, running %i queued queries", name, #DB.cachedQueries )
				for _, v in pairs(DB.cachedQueries) do
					if v[3] then
						DB.QueryValue(v[1], v[2])
					else
						DB.Query(v[1], v[2])
					end
				end
				DB.cachedQueries = {}
				return
			end

			timer.Create("libk_check_mysql_status", 60, 0, function()
				--if (DB.MySQLDB and DB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED) then
				--	DB.ConnectToMySQL(config.Host, config.User, config.Password, config.Database, config.Port )
				--end
			end)
			DB.IsConnected = true
			hook.Call("LibK_DatabaseInitialized", nil, DB, name )

			-- Don't resolve the initial connection promise
			-- on reconnect.
			if getPromiseState(DB.ConnectionPromise) == 'pending' then
				DB.ConnectionPromise:Resolve()
			end
		end
		databaseObject:connect()

		DB.MySQLDB = databaseObject
	end

	function DB.SQLStr(str)
		if not DB.CONNECTED_TO_MYSQL then
			return sql.SQLStr(str)
		end

		return "\"" .. DB.MySQLDB:escape(tostring(str)) .. "\""
	end

	function DB.DisableForeignKeyChecks( bDisable )
		if DB.CONNECTED_TO_MYSQL then
			return DB.DoQuery( "SET FOREIGN_KEY_CHECKS = " .. ( bDisable and "0" or "1" ) )
		else
			return DB.DoQuery( "PRAGMA foreign_keys = " .. ( bDisable and "OFF" or "ON" ) )
		end
	end

	function DB.TableExists( name )
		return Promise.Resolve()
		:Then( function()
			if DB.CONNECTED_TO_MYSQL then
				return DB.DoQuery( "SHOW TABLES LIKE '" .. name .. "'")
			else
				return DB.DoQuery( "SELECT name FROM sqlite_master WHERE type='table' AND name='" .. name .. "'" )
			end
		end )
		:Then( function( result )
			return result != nil
		end )
	end

	function DB.FieldExistsInTable( tableName, fieldName )
		if DB.CONNECTED_TO_MYSQL then
			if DB.SQLStr( tableName ) != '"' .. tableName .. '"' then
				return Promise.Reject( "Possible SQL Injection through table name" )
			end
			return DB.DoQuery( Format( [[SHOW COLUMNS FROM  `%s` LIKE %s]] , tableName, DB.SQLStr( fieldName ) ) )
			:Then( function( results )
				if results and #results > 0 then
					return results[1].Field == fieldName
				end
			end )
		else
			return DB.DoQuery( Format( 'PRAGMA table_info(%s)', tableName ) )
			:Then( function( fields )
				for k, v in pairs( fields ) do
					if v.name == fieldName then
						return true
					end
				end
				return false
			end )
		end
	end

	function DB.Transaction()
		if DB.CONNECTED_TO_MYSQL then
			return LibK.TransactionMysql:new(DB)
		else
			return LibK.TransactionSqlite:new(DB)
		end
	end

	DATABASES[name] = DB
	
	DB.ConnectionPromise = Deferred()
	
	if config.UseMysql then
		KLogf( 4, "Connecting to %s@%s db: %s", config.User, config.Host, config.Database )
		DB.ConnectToMySQL(config.Host, config.User, config.Password, config.Database, config.Port )
	else
		-- Enable FK
		DB.DisableForeignKeyChecks( false ):Then( function()
			DB.IsConnected = true
			DB.ConnectionPromise:Resolve()
			-- Run hooks
			hook.Call("LibK_DatabaseInitialized", nil, DB, name )
		end, function (errid, err)
			err = tostring(errid) .. ',' .. tostring(err)
			KLogf( 1, "[LibK] Failed to enable foreign key checks on your db. PLEASE FORCE UPDATE YOUR GMOD SERVER TO THE NEWEST VERION! (%s)", err )
			hook.Add( "PlayerInitialSpawn", "MakeSureTheySeeIt", function (ply)
				timer.Simple( 5, function() 
					ply:ChatPrint( "[LibK] Addon loading failed: Your server is running a buggy gmod version (SQLite issue). Please update your server to the newest version!" )
				end )
			end )
			hook.Call( "LibK_DatabaseConnectionFailed", nil, DB, name, "Your gmod server is outdated! Please force update the server (Foreign key checks failed: " .. err .. ")" )
		end )
	end

	return DB
end
