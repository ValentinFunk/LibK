LibK.addonsLoaded = {}

local function addCSLua( luaroot )
	local files, folders = file.Find( luaroot .. "/*", "LUA" )
	for _, file in pairs( files ) do
		AddCSLuaFile( luaroot .. "/" .. file )
	end
	
	for _, folder in pairs( folders ) do
		addCSLua( luaroot .. "/" .. folder )
	end
end

local function loadFolder( luaroot, spaces )
	spaces = spaces or 4
	local files = file.Find( luaroot .."/*.lua", "LUA" )
	if #files > 0 then
		for _, file in ipairs( files ) do
			KLogf( 4, "%s-> Loading %s", string.rep( " ", spaces ), file )
			include( luaroot .. "/" .. file )
		end
	end
	
	local files, folders = file.Find( luaroot .. "/*", "LUA" )
	for _, folder in ipairs( folders ) do
		KLogf( 4, "%s=> Loading Folder %s", string.rep( " ", spaces ), folder )
		loadFolder( luaroot .. "/" .. folder, spaces + 2 )
	end
end

local function loadAddon( addonTable )
	local luaroot = addonTable.luaroot
	local name = addonTable.addonName
	local author = addonTable.author
	
	KLog( 4, LibK.consoleHeader( 80, "=", "Loading addon ".. name ) )
	
	KLogf( 4, "=> Loading SHARED" )
	loadFolder( luaroot .. "/shared" )
	
	if SERVER then
		KLogf( 4, "=> Loading SERVER" )
		loadFolder( luaroot .. "/server" )
	end
	
	if CLIENT then
		KLogf( 4, "=> Loading CLIENT" )
		loadFolder( luaroot .. "/client" )
	end
	
	KLog( 4, LibK.consoleHeader( 80, "=", name .. " by ".. author .. " loaded" ) .. "\n" )
end

function LibK.InitializeAddon( addonTable )
	local luaroot = addonTable.luaroot
	local name = addonTable.addonName
	local author = addonTable.author
	
	if addonTable.restrictGamemodes and not table.HasValue( addonTable.restrictGamemodes, engine.ActiveGamemode( ) ) then
		KLog( 4, LibK.consoleHeader( 80, "=", "Skipping addon " .. name .. " (incompatible with gamemode " .. engine.ActiveGamemode( ) .. " )" ) )
		return
	end
	
	table.insert( LibK.addonsLoaded, addonTable )

	if addonTable.loadAfterGamemode and not GAMEMODE then
		hook.Add( "InitPostEntity", "LibKInit" .. name, function( )
			loadAddon( addonTable )
		end )
		KLog( 4, LibK.consoleHeader( 80, "*", "Addon ".. name .. " will be loaded after gamemode init" ) )
	else
		loadAddon( addonTable )
	end
	
	--AddCSLuaFile Stuff
	if SERVER then
		addCSLua( luaroot .. "/client" )
		addCSLua( luaroot .. "/shared" )
	end
end