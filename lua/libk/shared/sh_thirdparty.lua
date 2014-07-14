include( "sh_util.lua" )

local function isolatedInclude( filePath )
	KLogf( 5, "  -> " .. filePath )
	local path = virtualLua .. "/" .. filePath
	local alternativePath = virtualLua .. "/" .. virtualMain .. "/" .. filePath
	local result
	if _file.Exists( alternativePath, "LUA" ) then
		result = CompileFile( alternativePath )
	elseif _file.Exists( path, "LUA" ) then
		if table.HasValue( _filesIncluded, filePath ) then
			KLogf( 5, "  -> SKIPPED: " .. filePath )
			return
		end
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
	table.insert( _filesIncluded, virtualMain .. "/" .. filePath )
	table.insert( _filesIncluded, filePath )
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

LibK.included = {}
local included = LibK.included
function LibK.createIsolatedEnvironment( tableName, virtualLua, virtualMain )
	local dependencyLookup = {}
	setmetatable( dependencyLookup, {
		__index = function( tbl, key )
			return LibK[key] or _G[key]
		end 
	} )
	
	local env = {}
	setmetatable( env, { __index = dependencyLookup } ) --allow access to globals
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
	env._filesIncluded = included
	env._env = env
	setfenv( isolatedInclude, env )
	env._include = include
	return env
end

function LibK.loadThirdparty( tableName, author, virtualLua, virtualMain, mainFile )
	local env = LibK.createIsolatedEnvironment( tableName, virtualLua, virtualMain )
	local loadFunction = function( )
		include( mainFile )
	end
	setfenv( loadFunction, env )
	
	KLogf( 5, LibK.consoleHeader( 80, "*", "Loading " .. tableName .. " by " .. author ) )
	loadFunction( )
	LibK[tableName] = env[tableName]
	KLogf( 5, LibK.consoleHeader( 80, "*", tableName .. " loaded" ) )
end

--GLib created by !cake, used with permission.
LibK.loadThirdparty( "GLib", "!cake", "libk/3rdparty", "glib", "glib.lua" )

--Gooey by !cake
--LibK.loadThirdparty( "Gooey", "!cake", "libk/3rdparty", "gooey", "gooey.lua" )

--GAuth by !cake
--LibK.loadThirdparty( "GAuth", "!cake", "libk/3rdparty", "gauth", "gauth.lua" )

--VFS by !cake
--LibK.loadThirdparty( "VFS", "!cake", "libk/3rdparty", "vfs", "vfs.lua" )

--luadata by CapsAdmin, "fuck copyright, do what you want with this"
LibK.loadThirdparty( "luadata", "CapsAdmin", "libk/3rdparty", "", "luadata.lua" )
AddCSLuaFile( "libk/3rdparty/luadata.lua" )

--vON by Vercas et al. Usage permitted if author is credited
LibK.loadThirdparty( "von", "Vercas", "libk/3rdparty", "", "von.lua" )
AddCSLuaFile( "libk/3rdparty/von.lua" )

--Circular Queue by MDave. Licensed under the MIT License
LibK.loadThirdparty( "CircularQueue", "MDave", "libk/3rdparty", "", "circular_queue.lua" )
AddCSLuaFile( "libk/3rdparty/circular_queue.lua" )

--PNG Lib by MDave. Licensed under the MIT License
LibK.loadThirdparty( "png", "MDave", "libk/3rdparty", "", "png.lua" )
AddCSLuaFile( "libk/3rdparty/png.lua" )

