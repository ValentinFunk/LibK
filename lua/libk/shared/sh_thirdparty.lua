include( "sh_util.lua" )

local function isolatedInclude( filePath )
	print( "\t -> " .. filePath )
	local path = virtualLua .. "/" .. filePath
	local alternativePath = virtualLua .. "/" .. virtualMain .. "/" .. filePath
	local result
	if _file.Exists( alternativePath, "LUA" ) then
		result = CompileFile( alternativePath )
	elseif _file.Exists( path, "LUA" ) then
		result = CompileFile( path )
	else
		ErrorNoHalt( "Couldn't include file " .. path .. " -> " ..  alternativePath .. "\n" )
		return
	end
	if not result then
		ErrorNoHalt( "Couldn't include file " .. path .. " -> " ..  alternativePath .. ": Unknown Error\n" )
		return
	end
	setfenv( result, _env )
	result( )
end

function LibK.getFileProxy( virtualLua )
	local fileProxy = {}
	function fileProxy.Read( path, pathId )
		if pathId == "LUA" then
			if file.Exists( virtualLua .. "/" .. path, pathId ) then
				return file.Read( virtualLua .. "/" .. path, pathId )
			end
			return file.Read( path, pathid )
		else
			return file.Read( path, pathId )
		end
	end
	function fileProxy.Exists( path, pathId )
		if pathId == "LUA" then
			if file.Exists( virtualLua .. "/" .. path, pathId ) then
				return true
			end
		end
		return file.Exists( path, pathId )
	end
	function fileProxy.Find( path, pathId )
		if pathId != "LUA" then
			return file.Find( path, pathId )
		end
		
		local files, folders = file.Find( path, pathId )
		local vfiles, vfolders = file.Find( virtualLua .. "/" .. path, pathId )
		table.Add( files, vfiles )
		table.Add( folders, vfolders )
		return files, folders
	end
	setmetatable( fileProxy, { __index = file } )
	return fileProxy
end

function LibK.getAddCSLuaProxy( virtualLua )
	local function proxyAddCSLuaFile( filePath )
		local path = virtualLua .. "/" .. filePath
		if file.Exists( path, "LUA" ) then
			AddCSLuaFile( path )
			return
		end
		AddCSLuaFile( filePath )
	end
	return proxyAddCSLuaFile
end

function LibK.getCompileStringProxy( virtualLua, env )
	return function( code, identifier, handleError )
		local result = CompileString( code, identifier, handleError )
		if result then
			setfenv( result, env )
		end
		return result
	end
end

function LibK.createIsolatedEnvironment( tableName, virtualLua, virtualMain )
	local env = {}
	setmetatable( env, { __index = _G } ) --allow access to globals
	LibK[tableName] = {}
	env[tableName] = false --isolated bit
	--redirect includes
	env._G = env
	env.virtualLua = virtualLua
	env.virtualMain = virtualMain
	env.file = LibK.getFileProxy( virtualLua )
	env._file = file
	env.AddCSLuaFile = LibK.getAddCSLuaProxy( virtualLua )
	env.CompileString = LibK.getCompileStringProxy( virtualLua, env )
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
	LibK[tableName] = env[tableName]
	KLogf( 5, LibK.consoleHeader( 80, "*", tableName .. " loading finished" ) )
end

LibK.loadThirdparty( "GLib", "libk/3rdparty", "glib", "glib.lua" )
