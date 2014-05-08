local backupTable = GLib.GetSessionVariable ("GLib", "LuaBackup", {})

function GLib.Lua.GetBackup (tableName, key)
	return GLib.Lua.GetBackupTable (tableName) [key]
end

function GLib.Lua.GetBackupTable (tableName)
	backupTable [tableName] = backupTable [tableName] or {}
	return backupTable [tableName]
end

function GLib.Lua.Backup (fullyQualifiedName)
	if type (fullyQualifiedName) == "table" then
		for _, v in ipairs (fullyQualifiedName) do
			GLib.Lua.Backup (v)
		end
		return
	end
	
	local value, table, tableName, key = GLib.Lua.GetTableValue (fullyQualifiedName)
	
	GLib.Lua.BackupTableMember (tableName, key, value)
end

function GLib.Lua.BackupTableMember (tableName, key, value)
	local backupTable = GLib.Lua.GetBackupTable (tableName)
	
	if value == nil then
		value = GLib.Lua.GetTable (tableName) [key]
	end
	
	backupTable [key] = backupTable [key] or value
end

function GLib.Lua.BackupTable (tableName, table)
	local backupTable = GLib.Lua.GetBackupTable (tableName)
	
	table = table or GLib.Lua.GetTable (tableName)
	
	for k, v in pairs (table) do
		backupTable [k] = backupTable [k] or v
	end
end