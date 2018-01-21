--[[
	LibK addon versioning:
	Semver is used. LibK compares the addon's version to the version of the current installed version.
	When the minor version is changed libk looks for an update script.

	Special case: addon has just been installed. The current version script will be excuted without
	and upgrade scripts in between. This is to handle the case where an older version addon is upgraded to use the versioning system.

	- major version > stored major: Iteratively apply all minor version updates
	- minor version > stored minor: Iteratively apply minor version updates

	Limitations: Do not have mroe than 50 versions in between updates.
	Patch versions are ignored, upgrade scripts should always have a patch of 0
]]--

local UpdateDB = LibK.getDatabaseConnection( LibK.SQL, "Update" )

local function createVersionTable()
	return UpdateDB.DoQuery([[
		CREATE TABLE IF NOT EXISTS libk_meta_version (
			addon VARCHAR(164) NOT NULL PRIMARY KEY,
			version VARCHAR(255) NOT NULL
		)
	]])
end

local function readVersionFromDB(addonName)
	return UpdateDB.DoQuery("SELECT version FROM libk_meta_version WHERE addon = " .. UpdateDB.SQLStr(addonName))
	:Then(function(rows) 
		if not rows or not rows[1] then
			return
		end

		return rows[1].version
	end)
end

local function writeVersionToDB(addonName, version)
	addonName = UpdateDB.SQLStr( addonName )
	version = UpdateDB.SQLStr( version )
	return UpdateDB.DoQuery( Format(
		"REPLACE INTO libk_meta_version (addon, version) VALUES (%s, %s)",
		addonName,
		version
	) )
end

function LibK.getStoredAddonVersion( addonTable )
	return UpdateDB.ConnectionPromise
	:Then( createVersionTable )
	:Then( function( ) 
		return readVersionFromDB( addonTable.addonName ) 
	end )
	:Then(function( version )
		return LibK.version( version or '0.0.0' )
	end)
end

function LibK.storeAddonVersion( addonTable, version )
	return UpdateDB.ConnectionPromise
	:Then(function()
		return writeVersionToDB(addonTable.addonName, version)
	end)
end

function LibK.performUpdate( addonTable, version )
	local upgradeScriptName = addonTable.luaroot .. "/updatescripts/" .. tostring( version ) .. ".lua"
	local func = CompileFile( upgradeScriptName )
	if not func then
		KLogf( 1, "\tError compiling upgrade script %s", upgradeScriptName )
		return Promise.Reject( "LUA Error" )
	end
	local succ, err = pcall( func )
	if not succ then
		KLogf( 1, "\tError running upgrade script %s: %s", upgradeScriptName, err )
		return Promise.Reject( "LUA Error" )
	end

	return err
	:Then( function( )
		KLogf( 5, "\tUpdated to %s", version )
		return LibK.storeAddonVersion( addonTable, version )
	end )
end

function LibK.updateAddon( addonTable )
	local newVersion = LibK.version( addonTable.version or '0.0.0' )
	return LibK.getStoredAddonVersion( addonTable )
	:Then(function( version ) 
		KLogf( 4, "Compare %s: %s to %s", addonTable.addonName, version, newVersion )
		if version >= newVersion then
			KLogf( 4, "\t Up to date, nothing to do" )
			return Promise.Resolve( )
		end

		local head = Format( "Updating %s: %s - %s", addonTable.addonName, version, newVersion )
		KLog( 4, LibK.consoleHeader( 80, "=", head ) )

		local chainedPromise = Promise.Resolve( )
		local currentVersion = version
		for major = version.major, newVersion.major do
			for minor = 0, 50 do
				local versionToCheck = LibK.version( string.format( "%i.%i.0", major, minor ) )
				if versionToCheck > newVersion then
					break
				end

				if versionToCheck <= currentVersion then
					continue
				end

				local upgradeScriptName = addonTable.luaroot .. "/updatescripts/" .. tostring( versionToCheck ) .. ".lua"
				if file.Exists( upgradeScriptName, "LUA" ) then
					chainedPromise = chainedPromise:Then( function( )
						KLogf( 5, "\tRunning update %s - %s", currentVersion, versionToCheck )
						return LibK.performUpdate( addonTable, versionToCheck )
					end )
					currentVersion = versionToCheck
				end
			end
		end

		return chainedPromise
	end)
	:Then( function()
		local head = Format( "All Done", addonTable.addonName, version, newVersion )
		KLog( 4, LibK.consoleHeader( 80, "=", head ) )
		return LibK.storeAddonVersion( addonTable, newVersion )
	end )
end
