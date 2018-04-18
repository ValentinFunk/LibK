--LibK Fonts
--Segoe UI 8
resource.AddFile( "resource/fonts/segoeui.ttf" )
resource.AddFile( "resource/fonts/segoeuil.ttf" )
resource.AddFile( "resource/fonts/segoeuisl.ttf" )
resource.AddFile( "resource/fonts/seguisb.ttf" )

--Used to ensure something runs after Initialize
LibK.InitializePromise = Deferred( )
hook.Add( "Initialize", "LibK_Initialize", function( )
	LibK.InitializePromise:Resolve( )
end )

LibK.InitPostEntityPromise = Deferred( )
hook.Add( "InitPostEntity", "LibK_InitPostEntity", function( )
	LibK.InitPostEntityPromise:Resolve( )
end )
hook.Add( "OnReloaded", "LibK_InitPostEntity", function()
	if getPromiseState(LibK.InitPostEntityPromise) == "pending" then
		LibK.InitPostEntityPromise:Resolve( )
	end
	if getPromiseState(LibK.InitializePromise) == "pending" then
		LibK.InitializePromise:Resolve( )
	end
end )

/*
	Main function all plugins should use to initialize LibK Database/Model use.
	pluginName is a unique identifier for the plugin
	pluginTable is a table that contains all models the plugin uses
	sqlInfo is an optional table containing a sql configuration overwrites the default libK configuration
    it is not recomended that you use sqlInfo, it breaks constraints if you want to use LibK.Player(kPlayer)
*/
function LibK.SetupDatabase( pluginName, pluginTable, sqlInfo, manualInitialize )
	sqlInfo = sqlInfo or LibK.SQL --Fall back to LibK DB if plugin doesnt want a seperate connection

	function pluginTable.DBInitialize( )
		pluginTable.DB = LibK.getDatabaseConnection( sqlInfo, pluginName )
	end
	if not manualInitialize then
		LibK.InitializePromise:Done( function( )
			pluginTable.DBInitialize( )
		end )

		hook.Add( "OnReloaded", "LibK_Initialize" .. pluginName, pluginTable.DBInitialize )
	end

	function pluginTable.initModels( )
		local promises = {}
		for name, class in pairs( pluginTable ) do
			if type( class ) != "table" or not class.name then
				continue
			end

			if not class.initializeTable then
				continue
			end

			local promise = class:initializeTable( )
			:Done( function( )
				KLogf( 4, "[%s]Initialized Model %s", pluginName, name )
			end )
			:Fail( function( errid, err )
				KLogf( 2, "[%s]Failed to initialize Model %s(%i: %s)", pluginName, name, errid, err )
			end )
			table.insert( promises, promise )
		end
		return WhenAllFinished( promises )
	end

	hook.Add( "LibK_DatabaseInitialized", "LibKORMGenerateModeltables" .. pluginName, function( database, dbName )
		if dbName != pluginName then
			return
		end
		KLogf( 4, "[%s] Database Connected, Init Models", pluginName )
		pluginTable.initModels( )
		:Always( function( )
			if pluginTable.onDatabaseConnected then
				pluginTable.onDatabaseConnected( )
			end
		end )
	end )

	hook.Add( "LibK_DatabaseConnectionFailed", "LibKFetchError" .. pluginName, function( database, dbName, msg )
		if dbName != pluginName then
			return
		end

		KLogf( 4, "[%s] Database Connection Failed", pluginName )
		if pluginTable.onDatabaseConnectionFailed then
			pluginTable.onDatabaseConnectionFailed( msg )
		end
	end )
end

LibK.SetupDatabase( "LibK", LibK )
