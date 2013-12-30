LibK.addonsLoaded = {}

function LibK.InitializeAddon( addonTable )
	local luaroot = addonTable.luaroot
	local name = addonTable.addonName
	local author = addonTable.author
	
	table.insert( LibK.addonsLoaded, addonTable )

	KLog( 4, LibK.consoleHeader( 80, "*", "Loading addon ".. name ) )
	--Shared modules
	local files = file.Find( luaroot .."/shared/*.lua", "LUA" )
	table.sort( files )
	if #files > 0 then
		KLogf( 4, "=> Loading SHARED" )
		for _, file in pairs( files ) do
			KLogf( 4, "  -> Loading %s", file )
			include( luaroot .."/shared/" .. file )
			if SERVER then
				AddCSLuaFile( luaroot .."/shared/" .. file )
			end
		end
	end

	if SERVER then
		KLogf( 4, "=> Loading SERVER" )
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

		--Server modules
		local files = file.Find( luaroot .."/server/*.lua", "LUA" )
		if #files > 0 then
			for _, file in ipairs( files ) do
				KLogf( 4, "  -> Loading %s", file )
				include( luaroot .."/server/" .. file )
			end
		end
	end

	if CLIENT then
		KLogf( 4, "=> Loading CLIENT" )
		--Client modules
		local files = file.Find( luaroot .."/client/*.lua", "LUA" )
		if #files > 0 then
			for _, file in ipairs( files ) do
				KLogf( 4, "  -> Loading %s", file )
				include( luaroot .."/client/" .. file )
			end
		end
	end
	KLog( 4, LibK.consoleHeader( 80, "*", name .. " by ".. author .. " loaded" ) )
end