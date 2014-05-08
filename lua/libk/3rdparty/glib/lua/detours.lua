function GLib.Lua.Detour (functionName, detourFunction)
	if type (functionName) == "table" then
		for _, v in ipairs (functionName) do
			GLib.Lua.Detour (v, detourFunction)
		end
		return
	end
	
	local originalFunction, table, tableName, functionName = GLib.Lua.GetTableValue (functionName)
	
	GLib.Lua.BackupTableMember (tableName, functionName, originalFunction)
	
	local backupTable = GLib.Lua.GetBackupTable (tableName)
	table [functionName] = function (...)
		return detourFunction (backupTable [functionName], ...)
	end
end

function GLib.Lua.Undetour (functionName)
	if type (functionName) == "table" then
		for _, v in ipairs (functionName) do
			GLib.Lua.Undetour (v)
		end
		return
	end
	
	local _, table, tableName, functionName = GLib.Lua.GetTableValue (functionName)
	table [functionName] = GLib.Lua.GetBackup (tableName, functionName) or table [functionName]
end