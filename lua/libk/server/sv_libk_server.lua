--LibK Fonts
--Segoe UI 8
resource.AddFile( "resource/fonts/segui.ttf" )
resource.AddFile( "resource/fonts/seguil.ttf" )
resource.AddFile( "resource/fonts/seguisl.ttf" )
resource.AddFile( "resource/fonts/seguisb.ttf" )
resource.AddFile( "resource/fonts/CAMBRIA.TTC" )
/*
	Main function all plugins should use to initialize LibK Database/Model use.
	pluginName is a unique identifier for the plugin
	pluginTable is a table that contains all models the plugin uses
	sqlInfo is an optional table containing a sql configuration overwrites the default libK configuration
*/
function LibK.SetupDatabase( pluginName, pluginTable, sqlInfo )
	sqlInfo = sqlInfo or LibK.SQL --Fall back to LibK DB if plugin doesnt want a seperate connection
	
	function pluginTable.DBInitialize( )
		pluginTable.DB = LibK.getDatabaseConnection( sqlInfo, pluginName )
	end
	hook.Add( "Initialize", "LibK_Initialize" .. pluginName, pluginTable.DBInitialize )
	hook.Add( "OnReloaded", "LibK_Initialize" .. pluginName, pluginTable.DBInitialize )

	function pluginTable.initModels( )
		for name, class in pairs( pluginTable ) do
			if type( class ) != "table" or not class.name then
				continue
			end
			
			if not class.initializeTable then 
				continue
			end
			class:initializeTable( )
			:Done( function( )
				KLogf( 4, "[%s]Initialized Model %s", pluginName, name ) 
			end )
			:Fail( function( errid, err )
				KLogf( 2, "[%s]Failed to initialize Model %s(%i: %s)", pluginName, name, errid, err )
			end )
		end
	end

	hook.Add( "LibK_DatabaseInitialized", "LibKORMGenerateModeltables" .. pluginName, function( database, dbName )
		if dbName != pluginName then
			return
		end
		KLogf( 4, "[%s] Database Connected, Init Models", pluginName )
		pluginTable.initModels( )
		
		if pluginTable.onDatabaseConnected then
			pluginTable.onDatabaseConnected( )
		end
	end )
end

LibK.SetupDatabase( "LibK", LibK )