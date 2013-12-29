DatabaseModel = {}

local function DBQuery( db, ... )
	local args = {...}
	if LibK.LogSQL then
		file.Append("sqlqueries.txt", "\n"..os.date().. "\t"..(args[1] or ""))
	end
	if not DATABASES[db] then
		KLogf( 2, "Odd Error in DB, invalid database %s", db )
		debug.Trace( )
	end
	return DATABASES[db].Query( ... )
end

local function escape( db, str )
	if not db or not str then
		KLogf( 2, "Odd Error in DB Escape, connection dead? %s, %s", not db and "No DB" or "DB", not str and "NO String" or "String" )
		debug.Trace( )
	end
	if not DATABASES[db] then
		KLogf( 2, "Odd Error in DB, invalid database %s", db )
	end
	return DATABASES[db].SQLStr( str )
end

local function initializeTable( class )
	local def = Deferred( )
	
	local model = class.static.model
	if not class.DB then
		def:Reject( -1, Format( "Model %s does not have a database", class.name ) )
		return def:Promise( )
	end
	local database = DATABASES[class.DB]
	if not database then
		def:Reject( -2, "Database " .. class.DB .. " has not been initialized" )
		return def:Promise( )
	end
	
	local query = string.format( "CREATE TABLE IF NOT EXISTS `%s` (", model.tableName )
	local fieldsPart = {}
	for fieldname, fieldtype in pairs( model.fields ) do
		table.insert( fieldsPart, 
			string.format( "`%s` %s",
				fieldname,
				DatabaseModel.generateSQLForType( fieldtype, { myql = database.CONNECTED_TO_MYSQL } ) 
			)
		)
	end
	table.insert( fieldsPart, "PRIMARY KEY (`" .. ( model.overrideKey or "id" ) .. "` ASC)" )
		
	local fieldsPart = table.concat( fieldsPart, ", " )
	local sqlStr = query .. fieldsPart .. ")"
	
	DBQuery( class.DB, sqlStr, function( )
		def:Resolve( )
	end, 
	function( )
		def:Reject( 0, "SQL Error" )
	end )
	
	return def:Promise( )
end

local MODELS = {}
function DatabaseModel:included( class )
	MODELS[class.name] = class --Save model for later lookups
	
	class.static.initializeTable = initializeTable
	
	if not class.static.model.fields.id and not class.static.model.overrideKey then
		class.static.model.fields.id = "id"
	end
	
	function class.static.getSelectForField( fieldname, alias, tableNameOverride )
		tableNameOverride = tableNameOverride or class.static.model.tableName
		if class.static.model.fields[fieldname] == "createdTime" or 
			class.static.model.fields[fieldname] == "updatedTime" or
			class.static.model.fields[fieldname] == "time" then
			
			local db = DATABASES[class.DB]
			if db.CONNECTED_TO_MYSQL then
				return string.format( "UNIX_TIMESTAMP( `%s`.`%s` ) AS `%s.%s`",
					tableNameOverride,
					fieldname, 
					alias,
					fieldname 
				)
			else
				return string.format( "strftime( '%%s', `%s`.`%s` ) AS `%s.%s`",
					tableNameOverride,
					fieldname, 
					alias,
					fieldname 
				)
			end
		else
			return string.format( "`%s`.`%s` AS `%s.%s`", tableNameOverride, fieldname, alias, fieldname )
		end
	end
	
	function class.static.generateAliasedFields( alias, tableNameOverride )
		local aliasedFields = {}
		for fieldname, fieldtype in pairs( class.static.model.fields ) do
			--table.field AS alias.field
			table.insert( aliasedFields, class.static.getSelectForField( fieldname, alias, tableNameOverride ) )
		end
		return aliasedFields
	end
	
	function class.static.getAll( )
		return class.static.getDbEntries( "WHERE 1 = 1" )
	end
	
	--Create Magic Functions
	function class.static.findAllDbByField( field, value, recursive, extra ) 
		local model = class.static.model
		if not value then 
			error( "Invalid argument #2 to " .. class.name .. ":findAllDbByField( field, value ), value expected, got nil", 2 )
		end
		
		return class.static.getDbEntries( string.format( " WHERE `%s`.`%s` = %s",
			model.tableName,
			field, 
			DatabaseModel.prepareForSQL( class.DB, model.fields[field], value ),
			extra
		), recursive, extra )
	end
	
	function class.static.getDbEntries( whereQuery, recursive, extra )
		local def = Deferred( )
		
		extra = extra or "" --For example LIMIT, ORDER BY, etc.
		local model = class.static.model
		
		recursive = recursive or 1
		
		--Generate the Select fields(SELECT fields ...)
		local fieldsToSelect = class.static.generateAliasedFields( model.tableName )
		if recursive > 0 then
			for relName, info in pairs( model.belongsTo or {} ) do
				local targetClass = getClass(info.class)
				if not targetClass then
					def:Reject( 0, "Target class invalid for relationship " .. relName )
					return
				end
				table.Add( fieldsToSelect, targetClass.static.generateAliasedFields( relName, relName ) )
			end
		end
		fieldsToSelect = table.concat( fieldsToSelect, "," )
		
		local query = { string.format( "SELECT %s FROM `%s`",
			fieldsToSelect,
			model.tableName
		) }
		
		if recursive > 0 then
			for relName, info in pairs( model.belongsTo or {} ) do
				local targetClass = getClass(info.class)
				table.insert( query, 
					string.format( " LEFT JOIN `%s` AS `%s` ON `%s`.`%s` = `%s`.`%s` ",
						targetClass.static.model.tableName,
						relName,
						relName,
						info.overrideKey or "id",
						model.tableName,
						info.foreignKey
					)
				)
			end
		end
		
		table.insert( query, whereQuery )
		table.insert( query, " " .. extra )
		
		local sqlStr = table.concat( query, " " )
		DBQuery( class.DB, sqlStr, function( data )
			if not data or #data < 1 then
				def:Resolve( {} ) --Nothing found, but query was very valid
				return
			end
			
			local relationshipPromises = {}
			local instances = {}
			for k, row in pairs( data ) do
				local constructor = class
				
				--handle classname field that overrides this entries retrieved model class(useful for inheritance etc.)
				for fieldname, fieldtype in pairs( model.fields ) do
					if fieldtype == "classname" then
						constructor = getClass(row[model.tableName .. "." .. fieldname])
						if not constructor then 
							error( "Invalid class " .. row[model.tableName .. "." .. fieldname] .. " for " .. class.name .. " id " .. row.id )
						end
					end
				end
				
				--Create and load instance
				local instance = constructor:new( row.id )
				table.insert( instances, instance )
				
				--load fields
				local objPattern = "^(" .. model.tableName .. "%.)"
				for name, value in pairs( row ) do
					if string.match( name, objPattern ) then
						local startPos, endPos = string.find( name, objPattern )
						local fieldName = string.sub( name, endPos + 1, #name )
						instance:loadFieldFromDb( fieldName, value )
					end
				end
				
				--Handle joined Tables
				for relName, info in pairs( model.belongsTo or {} ) do
					local targetClass = getClass(info.class)
					local constructor = targetClass
					local targetClassModel = targetClass.static.model
					
					--Check for override class
					for fieldname, fieldtype in pairs( targetClassModel.fields ) do
						if fieldtype == "classname" then
							constructor = getClass( row[fieldname] )
							if not constructor then 
								error( "Invalid class " .. row[fieldname] .. " for " .. class.name .. " id " .. row.id )
							end
						end
					end
					
					local obj --The instance is created later so that if no matching record was found the relationship's  field is empty
					local objPattern = "^(" .. relName .. "%.)"
					for name, value in pairs( row ) do
						if string.match( name, objPattern ) then
							if not obj then
								--SQLite gives us the field even if it is NULL everywhere so check if 
								--we have at least an id before constructing the object
								if value == "NULL" then
									continue
								end
								obj = constructor:new( row.id )
							end
							local startPos, endPos = string.find( name, objPattern )
							local fieldName = string.sub( name, endPos + 1, #name )
							obj:loadFieldFromDb( fieldName, value )
						end
					end
					if obj then
						instance[relName] = obj
					end
				end
				
				--Resolve HasMany/HasOne relationships
				if recursive > 0 then
					for relName, info in pairs( model.hasMany or {} ) do
						local targetClass = getClass( info.class )
						if not targetClass then
							if not targetClass then
								relDef:Reject( 0, "Target class invalid for relationship " .. relName )
								return
							end
						end
						
						--findAllByForeignKey
						local promise = targetClass.static.findAllDbByField( info.foreignKey, instance.id, recursive - 1 ) 
						:Then( function( relInstances ) 
							instance[relName] = relInstances
						end, 
						function( errid, err )
							return 0, "Failed to resolve HasMany " .. relName .. "(" .. err .. ", " .. errid .. ")"
						end )
						
						table.insert( relationshipPromises, promise )
					end
					
					for relName, info in pairs( model.hasOne or {} ) do
						local targetClass = getClass( info.class )
						if not targetClass then
							if not targetClass then
								relDef:Reject( 0, "Target class invalid for relationship " .. relName )
								return
							end
						end
						
						--findByForeignKey
						local promise = targetClass.static.findDbByField( info.foreignKey, instance.id, recursive - 1 ) 
						:Then( function( relInstance ) 
							instance[relName] = relInstance
						end, 
						function( errid, err )
							relDef:Reject( 0, "Failed to resolve HasMany " .. relName .. "(" .. err .. ", " .. errid .. ")" )
						end )
						
						table.insert( relationshipPromises, promise )
					end
				end
			end
			WhenAllFinished( relationshipPromises )
			:Then( function( )
				local callbackPromises = {}

				local id = math.random( 0, 100000000 )
				for k, v in pairs( instances ) do
					if v.postLoad then	
						local promise = v:postLoad( )
						:Then( function( )
						end,
						function( errid, err )
							return 0, "Error in postLoad Callback, Model " .. v.class.name .. " id " .. v.class.id .. " Error: " .. errid .. ": " .. err
						end )
						promise.desc = "PostLoad of model " .. v.class.name
						table.insert( callbackPromises, promise )
					end
				end
				
				local promise, def = WhenAllFinished( callbackPromises )
				promise.started = CurTime( )
				local hookName = "PromiseRunning" .. id
				hook.Add( "Think", hookName, function ()
					if promise._state == "pending" then
						if CurTime( ) > promise.started + 1 then
							print( "Taking too long for promise " .. id .. " killing it" .. class.name )
							PrintTable( callbackPromises )
							def:Resolve( )
							hook.Remove( "Think", hookName )
						end
					else
						hook.Remove( "Think", hookName )
					end
				end )
				promise:Done( function( )
				end )
				
				return promise
			end )
			:Then( function( )
				def:Resolve( instances )
			end,
			function( errid, err )
				def:Reject( errid, err )
			end )
		end, 
		function( )
			def:Reject( 0, "SQL Error" )
		end )
		
		return def:Promise( )
	end
	
	function class.static.dropTable( )
		return DATABASES[class.static.DB].DoQuery( "DROP TABLE `" .. class.static.model.tableName .. "`" ) 
	end
	
	function class.static.findDbByField( field, value, recursive, extra ) 
		if not value then 
			error( "Invalid argument #2 to " .. class.name .. ":findAllDbByField( field, value ), value expected, got nil", 2 )
		end
		
		extra = extra or ""
		KLogf( 4, "%s:findBy%s( %s )", class.name, string.upper( field[1] ) .. string.sub( field, 2, #field ), tostring( value ) )
		return class.static.findAllDbByField( field, value, recursive, extra .. " LIMIT 1" )
		:Then( function( instances )
			if instances then
				return instances[1] 
			else 
				return false 
			end 
		end )
	end
	
	for fieldname, fieldtype in pairs( class.static.model.fields ) do
		local name = "findBy" .. string.upper( fieldname[1] ) .. string.sub( fieldname, 2, #fieldname )
		class.static[name] = function( arg, extra )
			return class.static.findDbByField( fieldname, arg, extra )
		end
		
		local name = "findAllBy" .. string.upper( fieldname[1] ) .. string.sub( fieldname, 2, #fieldname )
		class.static[name] = function( arg, extra )
			return class.static.findAllDbByField( fieldname, arg, extra )
		end
	end
end

function DatabaseModel.generateSQLForType( fieldtype, options )
	local map = {
		id = "INTEGER",
		string = "VARCHAR(255) NOT NULL",
		int = "INT(11) NOT NULL",
		optKey = "INT(11)",
		table = "MEDIUMTEXT",
		bool = "BOOLEAN",
		player = "VARCHAR(255) NOT NULL",
		playerUid = "BIGINT(20) NOT NULL",
		classname = "VARCHAR(255) NOT NULL", --Use this to overwrite the type that will be created. defaults to model class, useful for subclasses
		createdTime = "TIMESTAMP NULL",
		updatedTime = "TIMESTAMP NULL",
		time = "TIMESTAMP NULL",
		text = "MEDIUMTEXT NULL"
	}
	
	--No AUTO_INCREMENT in SQLite
	if options.myql then
		map.id = "INT(11) NOT NULL AUTO_INCREMENT"
	end
	
	if not map[fieldtype] then
		error( "Invalid fieldtype " .. fieldtype .. "given!" )
	end
	return map[fieldtype]
end

--Transform data from sql into lua equivalent
function DatabaseModel:loadFieldFromDb( fieldname, data )
	local model = self.class.static.model
	
	data = data != "NULL" and data or nil
	
	local fieldtype = model.fields[fieldname]
	if fieldtype == "table" then
		local data = util.JSONToTable( data )
		if data then
			for k, v in pairs( data ) do
				self[k] = v
			end
		end
	elseif fieldtype == "bool" then
		self[fieldname] = ( data == 0 ) and false or true
	elseif fieldtype == "int" then
		self[fieldname] = tonumber( data )
	elseif fieldtype == "string" then
		self[fieldname] = tostring( data )
	elseif fieldtype == "classname" then
		--Ignore this is used only for creating the instance!
	elseif fieldtype == "player" then
		self[fieldname] = data
	elseif fieldtype == "playerUid" then
		self[fieldname] = data
	elseif fieldtype == "updatedTime" then
		self[fieldname] = data
	elseif fieldtype == "time" then
		self[fieldname] = tonumber( data )
	elseif fieldtype == "id" then
		self[fieldname] = data
	elseif fieldtype == "createdTime" then
		self[fieldname] = data
	elseif fieldtype == "text" then
		self[fieldname] = data
	elseif fieldtype == "optKey" then
		self[fieldname] = tonumber( data )
	else
		KLog( 2, "WARNING: unknown load fieldtype: " .. fieldtype .. " loading raw" ) 
	end
end

function DatabaseModel.prepareForSQL( db, fieldtype, value )
	if fieldtype == "string" then
		return escape( db, value )
	elseif fieldtype == "int" then
		return escape( db, tonumber( value ) )
	elseif fieldtype == "bool" then
		return value and 1 or 0
	elseif fieldtype == "classname" then
		return value --Class of this instance
	elseif fieldtype == "player" then
		if type( value ) == "Player" then
			return escape( db, value:SteamID( ) ) --so findByPlayer( playerObj ) works 
		elseif value then
			return escape( db, value )
		end
	elseif fieldtype == "playerUid" then
		return escape( db, value )
	elseif fieldtype == "text" then
		if value then
			return escape( db, value )
		else
			return "NULL"
		end
	elseif fieldtype == "updatedTime" then
		return os.time()
	elseif fieldtype == "time" then
		if DATABASES[db].CONNECTED_TO_MYSQL then
			return string.format( "FROM_UNIXTIME( %i )", value or 0 )
		else
			return string.format( "strftime('%s', %i)", value or 0 )
		end
	elseif fieldtype == "id" then
		return escape( db, value )
	elseif fieldtype == "optKey" then
		return escape( db, value )
	else
		KLog( 2, "WARNING: No sql prepare available for fieldtype " .. tostring( fieldtype ) .. " using raw!" )
		return escape( db, value )
	end
end

--Transform data form lua into sql equivalent
function DatabaseModel:getFieldForDb( fieldname )
	local db = self.class.static.DB
	local model = self.class.static.model
	if model.fields[fieldname] == "table" then
		local json 
		if self.saveFields or model.saveFields then --only specified fields
			local tbl = {}
			for k, v in pairs( self ) do
				if table.HasValue( self.saveFields or {}, k ) or table.HasValue( model.saveFields or {}, k ) then
					tbl[k] = v
				end
			end
			json = util.TableToJSON( tbl )
		else --everything but class/model, only one level, use saveFields if more is required
			local tbl = generateCleanTable( self, model )
			json = util.TableToJSON( tbl )
		end
		return escape( db, json )
	elseif model.fields[fieldname] == "classname" then
		return escape( db, self.class.name )
	elseif model.fields[fieldname] == "optKey" then
		if self[fieldname] then
			return DatabaseModel.prepareForSQL( db, "int", self[fieldname] )
		else
			return "NULL"
		end
	else
		if not self[fieldname] then
			ErrorNoHalt( "No value given for " .. self.class.name .. ", field " .. fieldname )
		end
		local result = DatabaseModel.prepareForSQL( db, 
			model.fields[fieldname],
			self[fieldname] )
		return result
	end
end

function DatabaseModel:remove( )
	KLog( 4, self.class.name .. ":remove( )" )
	local db = self.class.static.DB
	local model = self.class.static.model
	local def = Deferred( )
	
	if not self.id then
		def:Reject( 0, "Cannot remove non existant " .. self.class.name .. " id " .. self.id )
		return def:Promise( )
	end

	local overrideKeyValue = ( model.overrideKey and self[model.overrideKey] ) or nil
	local queryStr = Format( "DELETE FROM %s WHERE %s = %s", model.tableName, ( model.overrideKey or "id" ), escape( db, overrideKeyValue or self.id ) ) 
	DBQuery( db, queryStr, function( ) 
		self[model.overrideKey or "id"] = nil
		def:Resolve( )
	end, function( )
		def:Reject( 0, "SQL Error" )
	end )
	
	return def:Promise( )
end

function DatabaseModel:save( )
	KLog( 4, self.class.name .. ":save( )" )
	local db = self.class.static.DB

	local model = self.class.static.model
	
	local promise
	if self.preSave then
		promise = self:preSave( )
	else
		local def = Deferred( )
		def:Resolve( )
		promise = def:Promise( )
	end
	
	return promise:Then( function( )
		local def = Deferred( )
		
		if self.id then
			--Update Entry
			local query = { string.format( "UPDATE `%s` SET ", model.tableName ) } 
			local fieldsPart = {}
			for fieldname, fieldtype in pairs( model.fields ) do 
				if fieldtype == "createdTime" or fieldtype == "id" then 
					continue	
				end
				if fieldtype == "updatedTime" then 
					if DATABASES[db].CONNECTED_TO_MYSQL then
						table.insert( fieldsPart, string.format( "`%s` = NOW()", fieldname ) )
					else
						table.insert( fieldsPart, string.format( "`%s` = DATETIME('now')", fieldname ) )
					end
					continue
				end
				table.insert( fieldsPart, string.format( "`%s` = %s", fieldname, self:getFieldForDb( fieldname ) ) )
			end
			
			table.insert( query, table.concat( fieldsPart, "," ) )
			local overrideKeyValue = ( model.overrideKey and self[model.overrideKey] ) or nil
			table.insert( query, string.format( "WHERE `" .. ( model.overrideKey or "id" ) .."` = %s", escape( db, overrideKeyValue or self.id ) ) )
			local sqlStr = table.concat( query, " " )
			
			DBQuery( db, sqlStr, function( )
				def:Resolve( self )
			end,
			function( )
				def:Reject( 0, "SQL Error" )
			end )
		else
			local query = { string.format( "INSERT INTO `%s` (", model.tableName ) }
			local fieldsPart = {}
			local valuesPart = {}
			for fieldname, fieldtype in pairs( model.fields ) do
				if fieldtype == "id" then
					continue
				end
				if fieldtype == "createdTime" or fieldtype == "updatedTime" then
					table.insert( fieldsPart, string.format( "`%s`", fieldname ) )
					if DATABASES[db].CONNECTED_TO_MYSQL then
						table.insert( valuesPart, "NOW()" )
					else
						table.insert( valuesPart, "DATETIME('now')" )
					end
					continue
				end
				table.insert( fieldsPart, "`" .. fieldname .. "`" )
				table.insert( valuesPart, self:getFieldForDb( fieldname ) )
			end
			table.insert( query, table.concat( fieldsPart, "," ) )
			table.insert( query, ") VALUES (" )
			table.insert( query, table.concat( valuesPart, "," ) )
			table.insert( query, ")" )

			local sqlStr = table.concat( query, " " )
			DBQuery( db, sqlStr, function( data, lastInsertId )
				self.id = lastInsertId
				def:Resolve( self )
			end, function( )
				def:Reject( 0, "SQL Error" )
			end )
		end
		
		return def:Promise( )
	end )
end