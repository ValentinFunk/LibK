LibK.addonsLoaded = {}

local function loadShared( luaroot )
	local files = file.Find( luaroot .."/shared/*.lua", "LUA" )
	table.sort( files )
	if #files > 0 then
		for _, file in pairs( files ) do
			KLogf( 4, "  -> Loading %s", file )
			include( luaroot .."/shared/" .. file )
			if SERVER then
				AddCSLuaFile( luaroot .."/shared/" .. file )
			end
		end
	end
end

local function loadServer( luaroot )
	--Server modules
	local files = file.Find( luaroot .."/server/*.lua", "LUA" )
	if #files > 0 then
		for _, file in ipairs( files ) do
			KLogf( 4, "  -> Loading %s", file )
			include( luaroot .."/server/" .. file )
		end
	end
end

local function loadClient( luaroot )
	local files = file.Find( luaroot .."/client/*.lua", "LUA" )
	if #files > 0 then
		for _, file in ipairs( files ) do
			KLogf( 4, "  -> Loading %s", file )
			include( luaroot .."/client/" .. file )
		end
	end
end

local function loadAddon( addonTable )
	local luaroot = addonTable.luaroot
	local name = addonTable.addonName
	local author = addonTable.author
	
	KLog( 4, LibK.consoleHeader( 80, "=", "Loading addon ".. name ) )
	
	KLogf( 4, "=> Loading SHARED" )
	loadShared( luaroot )
	
	if SERVER then
		KLogf( 4, "=> Loading SERVER" )
		loadServer( luaroot )
	end
	
	if CLIENT then
		KLogf( 4, "=> Loading CLIENT" )
		loadClient( luaroot )
	end
	
	KLog( 4, LibK.consoleHeader( 80, "=", name .. " by ".. author .. " loaded" ) .. "\n" )
end

function LibK.InitializeAddon( addonTable )
	local luaroot = addonTable.luaroot
	local name = addonTable.addonName
	local author = addonTable.author
	
	table.insert( LibK.addonsLoaded, addonTable )

	if addonTable.loadAfterGamemode and not GAMEMODE then
		hook.Add( "InitPostEntity", "LibKInit" .. name, function( )
			loadAddon( addonTable )
		end )
		KLog( 4, LibK.consoleHeader( 80, "*", "Addon ".. name .. " will be loaded after gamemode init" ) )
	else
		loadAddon( addonTable )
	end
	
	if SERVER then
		local folder = luaroot .. "/shared"
		local files = file.Find( folder .. "/" .. "*.lua", "LUA" )
		for _, file in ipairs( files ) do
			AddCSLuaFile( folder .. "/" .. file )
		end

		folder = luaroot .."/client"
		files = file.Find( folder .. "/" .. "*.lua", "LUA" )
		for _, file in ipairs( files ) do
			AddCSLuaFile( folder .. "/" .. file )
		end
	end
end