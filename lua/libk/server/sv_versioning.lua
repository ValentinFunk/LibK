/*
	LibK addon versioning:
	Semver is used. LibK compares the addon's version to the version of the current installed version.
	When the minor version is changed libk looks for an update script. 
	
	Special case: addon has just been installed. The current version script will be excuted without
	and upgrade scripts in between. This is to handle the case where an older version addon is upgraded to use the versioning system.		
	
	- major version > stored major: Iteratively apply all minor version updates
	- minor version > stored minor: Iteratively apply minor version updates
	
	Limitations: Do not have mroe than 50 versions in between updates.
	Patch versions are ignored, upgrade scripts should always have a patch of 0
*/

function LibK.storeAddonVersion( addonTable, version )
	if not file.IsDir( "libk", "DATA" ) then
		file.CreateDir( "libk" )
	end
	file.Write( "libk/" .. util.CRC( addonTable.addonName ) .. ".txt", tostring( version ) )
end

function LibK.getStoredAddonVersion( addonTable )
	local version = file.Read( "libk/" .. util.CRC( addonTable.addonName ) .. ".txt" )
	return LibK.version( version or '0.0.0' )
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
	:Done( function( )
		KLogf( 5, "\tUpdated to %s", version )
		LibK.storeAddonVersion( addonTable, version )
	end )
end

function LibK.updateAddon( addonTable )
	local version = LibK.getStoredAddonVersion( addonTable )
	local newVersion = LibK.version( addonTable.version or '0.0.0' )
	KLogf( 4, "Compare %s: %s to %s", addonTable.addonName, version, newVersion )
	
	if version >= newVersion then 
		KLogf( 4, "\t Up to date, nothing to do" )
		return Promise.Resolve( )
	end
	
	local head = Format( "Updating %s: %s - %s", addonTable.addonName, version, newVersion )
	KLog( 4, LibK.consoleHeader( 80, "=", head ) )

	local promises = {}
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
				local promise = Promise.Resolve( )
				:Then( function( )
					KLogf( 5, "\tRunning update %s - %s", currentVersion, versionToCheck )
					return LibK.performUpdate( addonTable, versionToCheck )
				end )
				table.insert( promises, promise )
				currentVersion = versionToCheck
			end
		end
	end
	
	local chainedPromise = Promise.Resolve( )
	for k, v in ipairs( promises ) do
		chainedPromise = chainedPromise:Then( function( )
			return v
		end )
	end
	
	chainedPromise:Done( function()
		if #promises == 0 then
			KLog( 4, " -> Nothing to do" )
			LibK.storeAddonVersion( addonTable, newVersion )
		end
		local head = Format( "All Done", addonTable.addonName, version, newVersion )
		KLog( 4, LibK.consoleHeader( 80, "=", head ) )
	end )
	
	return chainedPromise
end