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
LibK.AddCSLuaDir = addCSLua

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

local addonsInitialized = {}
local waitingPromises = {}

function LibK.ResetAddonsCache( )
	addonsInitialized = {}
end

local function WhenAddonsLoaded( addonsRequired )
	local def = Deferred()
	
	--Check if requirements are already loaded
	local addonMissing = false
	for _, addonName in pairs( addonsRequired ) do
		if not table.HasValue( addonsInitialized, addonName ) then
			addonMissing = true
		end
	end
	if not addonMissing then
		return Promise.Resolve( )
	end
	
	--Queue for when requirements are loaded
	table.insert( waitingPromises, {
		addonsRequired = addonsRequired,
		promise = def
	} )
	
	return def:Promise( )
end
LibK.WhenAddonsLoaded = WhenAddonsLoaded

local function onAddonInitialized( name )
	table.insert( addonsInitialized, name )
	for k, v in pairs( waitingPromises ) do
		local addonMissing = false
		for _, addonName in pairs( v.addonsRequired ) do
			if not table.HasValue( addonsInitialized, addonName ) then
				addonMissing = true
			end
		end
		if not addonMissing then
			waitingPromises[k] = nil
			v.promise:Resolve( )
		end
	end
end

function onAddonInitializationFailed( name )
	for k, v in pairs( waitingPromises ) do
		if table.HasValue( v.addonsRequired, name ) then
			v.promise:Reject( -1, "Parent addon " .. name .. " failed to initialize" )
		end
	end
end

local function doLoadAddon( addonTable )
	local promise = Promise.Resolve( )
	
	if addonTable.requires then
		promise = WhenAddonsLoaded( addonTable.requires )
		if promise._state != "done" then
			KLogf( 4, "Addon %s will be loaded once requirements (%s) are loaded", addonTable.addonName, table.concat( addonTable.requires, "," ) )
		end
	end
	
	promise:Done( function( )
		if addonTable.loadAfterGamemode and not GAMEMODE then
			hook.Add( "InitPostEntity", "LibKInit" .. addonTable.addonName, function( )
				loadAddon( addonTable )
				onAddonInitialized( addonTable.addonName )
			end )
			KLog( 4, LibK.consoleHeader( 80, "*", "Addon ".. addonTable.addonName .. " will be loaded after gamemode init" ) )
		else
			loadAddon( addonTable )
			onAddonInitialized( addonTable.addonName )
		end
	end )
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

	if SERVER then
		--AddCSLuaFile Stuff
		addCSLua( luaroot .. "/client" )
		addCSLua( luaroot .. "/shared" )

		LibK.updateAddon( addonTable )
		:Fail( function( err )
			ErrorNoHalt( err )
			KLogf( 1, "[%s] Update Failed, aborting load!", addonTable.addonName )
		end )
		:Done( function( )
			KLogf( 4, "[%s] Update finished", addonTable.addonName )
			doLoadAddon( addonTable )
		end )
	else
		doLoadAddon( addonTable )
	end
end