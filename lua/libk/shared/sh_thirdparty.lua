include( "sh_util.lua" )

local function isolatedInclude( file )
	local path = virtualLua .. "/" .. file
	local result = CompileFile( virtualLua .. "/" .. file )
	print( "result:", result )
	if not result then 
		if not norec then
			include( virtualMain .. "/" .. file, true )
		end
		return 
	end
	result( )
end

function LibK.createIsolatedEnvironment( tableName, virtualLua, virtualMain )
	local env = {}
	setmetatable( env, { __index = _G } ) --allow access to globals
	LibK[tableName] = {}
	env[tableName] = LibK[tableName] --isolated bit
	--redirect includes
	env.virtualLua = virtualLua
	env.virtualMain = virtualMain
	env.include = isolatedInclude
	env._env = env
	setfenv( isolatedInclude, env )
	env._include = include
	return env
end

function LibK.loadThirdparty( tableName, virtualLua, virtualMain, mainFile )
	local env = LibK.createIsolatedEnvironment( tableName, virtualLua, virtualMain )
	local loadFunction = function( )
		include( mainFile )
	end
	setfenv( loadFunction, env )
	
	KLogf( 5, LibK.consoleHeader( 80, "*", "Loading thirdparty addon " .. tableName ) )
	loadFunction( )
	KLogf( 5, LibK.consoleHeader( 80, "*", tableName .. " loading finished" ) )
end

LibK.loadThirdparty( "GLib", "libk/3rdparty", "glib", "glib.lua" )
