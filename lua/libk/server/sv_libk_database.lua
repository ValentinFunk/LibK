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

DATABASES = DATABASES or {}
function LibK.getDatabaseConnection( config, name )
	local DB = {}

	if config.UseMysql then
		local succ, err = pcall( require, "mysqloo" )
		if not succ then
			KLog( 1, "[LibK] FATAL: Couldn't load mysqloo, make sure it is correctly installed! errror was: " .. err ) 
		else
			KLog( 4, "[LibK] MysqlOO is correctly installed." )
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
				if (DB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED) then
					KLogf( 4, "[INFO] Connection to the database lost, reconnecting! Query %s has been queued", sqlText )
					table.insert(DB.cachedQueries, {sqlText, callback, false})
					DB.ConnectToMySQL(config.Host, config.User, config.Password, config.Database, config.Port )
					return
				end
				if DB.MySQLDB:status() == mysqloo.DATABASE_CONNECTING then
					KLogf( 4, "[INFO] Database is reconnecting! Query %s has been queued", sqlText )
					table.insert(DB.cachedQueries, {sqlText, callback, false})
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
		if sql.LastError() and sql.LastError() ~= lastError then
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
		DB.Query( sqlText, function( data )
			def:Resolve( data )
		end, function( err )
			def:Reject( 0, err )
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
		if not mysqloo then DB.Log("MySQL Error: MySQL modules aren't installed properly!") Error("MySQL modules aren't installed properly!") end
		local databaseObject = mysqloo.connect(host, username, password, database_name, database_port)

		if timer.Exists("libk_check_mysql_status") then timer.Destroy("libk_check_mysql_status") end

		databaseObject.onConnectionFailed = function(_, msg)
			KLogf( 1, "[LibK] Connection failed to %s(%s@%s:%s): %s", name, username, host, database_port, msg )
			Error("Connection failed! " ..tostring(msg))
		end

		databaseObject.onConnected = function()
			DB.Log( Format( "[LibK] Connected to %s(%s@%s:%s)", name, username, host, database_port ) )
			DB.CONNECTED_TO_MYSQL = true
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
			return DB.DoQuery( "PRAGMA foreign_key_check = " .. ( bDisable and "OFF" or "ON" ) )
		end
	end
	
	DATABASES[name] = DB
	if config.UseMysql then
		KLogf( 4, "Connecting to %s@%s db: %s", config.User, config.Host, config.Database )
		DB.ConnectToMySQL(config.Host, config.User, config.Password, config.Database, config.Port )
	else
		DB.IsConnected = true
		
		-- Enable FK
		DB.Query( "PRAGMA foreign_keys = ON;" ) 
		DB.DisableForeignKeyChecks( false )

		-- Run hooks
		hook.Call("LibK_DatabaseInitialized", nil, DB, name )
	end
	
	return DB
end