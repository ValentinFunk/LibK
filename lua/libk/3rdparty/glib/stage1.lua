if GLib then return end
GLib = {}

function GLib.AddCSLuaFile (path) end
function GLib.AddCSLuaFolder (folder) end
function GLib.AddCSLuaFolderRecursive (folder) end
function GLib.AddCSLuaPackFile (path) end
function GLib.AddCSLuaPackFolder (folder) end
function GLib.AddCSLuaPackFolderRecursive (folder) end
function GLib.AddCSLuaPackSystem (systemTableName) end

if SERVER then
	GLib.AddCSLuaFile = AddCSLuaFile

	function GLib.AddCSLuaFolder (folder, recursive)
		GLib.Debug ("GLib : Adding " .. folder .. "/* to lua pack...")
		GLib.EnumerateLuaFolder (folder, "LUA", GLib.AddCSLuaFile, recursive)
	end

	function GLib.AddCSLuaFolderRecursive (folder)
		GLib.Debug ("GLib : Adding " .. folder .. "/* to lua pack...")
		GLib.EnumerateLuaFolder (folder, "LUA", GLib.AddCSLuaFile, true)
	end

	function GLib.AddCSLuaPackFile (path, pathId)
		GLib.Loader.PackFileManager:Write (
			path,
			GLib.Loader.Read (path, pathId or "LUA")
		)
	end

	function GLib.AddCSLuaPackFolder (folder, recursive)
		local startTime = SysTime ()
		GLib.EnumerateLuaFolder (folder, "LUA", GLib.AddCSLuaPackFile, recursive)
		if SysTime () - startTime > 0.5 then
			MsgN ("GLib : Adding " .. folder .. "/* to virtual lua pack... done (" .. GLib.Loader.PackFileManager:GetFileCount () .. " total files, " .. GLib.FormatDuration (SysTime () - startTime) .. ")")
		end
		GLib.Debug ("GLib : Adding " .. folder .. "/* to virtual lua pack... done (" .. GLib.Loader.PackFileManager:GetFileCount () .. " total files, " .. GLib.FormatDuration (SysTime () - startTime) .. ")")
	end

	function GLib.AddCSLuaPackFolderRecursive (folder)
		local startTime = SysTime ()
		GLib.EnumerateLuaFolder (folder, "LUA", GLib.AddCSLuaPackFile, true)
		if SysTime () - startTime > 0.5 then
			MsgN ("GLib : Adding " .. folder .. "/* to virtual lua pack... done (" .. GLib.Loader.PackFileManager:GetFileCount () .. " total files, " .. GLib.FormatDuration (SysTime () - startTime) .. ")")
		end
		GLib.Debug ("GLib : Adding " .. folder .. "/* to virtual lua pack... done (" .. GLib.Loader.PackFileManager:GetFileCount () .. " total files, " .. GLib.FormatDuration (SysTime () - startTime) .. ")")
	end

	function GLib.AddCSLuaPackSystem (systemTableName)
		GLib.Loader.PackFileManager:CreatePackFileSystem (systemTableName)
		GLib.Loader.PackFileManager:SetCurrentPackFileSystem (systemTableName)
		GLib.Loader.PackFileManager:AddSystemTable (systemTableName)
	end

	function GLib.AddReloadCommand (includePath, systemName, systemTableName)
		includePath = includePath or (systemName .. "/" .. systemName .. ".lua")


		return reload
	end
end

function GLib.AddReloadCommand (includePath, systemName, systemTableName)
	includePath = includePath or (systemName .. "/" .. systemName .. ".lua")

	local function reload ()
		local startTime = SysTime ()
		GLib.UnloadSystem (systemTableName)

		if GLib then GLib.Loader.Include (includePath)
		else include (includePath) end

		GLib.Debug (systemName .. "_reload took " .. tostring ((SysTime () - startTime) * 1000) .. " ms.")
	end

	if SERVER then
		concommand.Add (systemName .. "_reload_sv",
			function (ply, _, arg)
				if ply and ply:IsValid () and not ply:IsSuperAdmin () then return end

				reload ()
			end
		)
		concommand.Add (systemName .. "_reload_sh",
			function (ply, _, arg)
				if ply and ply:IsValid () and not ply:IsSuperAdmin () then return end

				reload ()

				for _, ply in ipairs (player.GetAll ()) do
					ply:ConCommand (systemName .. "_reload")
				end
			end
		)
	elseif CLIENT then
		concommand.Add (systemName .. "_reload",
			function (ply, _, arg)
				reload ()
			end
		)
	end

	return reload
end
GLib.AddReloadCommand ("glib/glib.lua", "glib", "GLib")

function GLib.Debug (message)
	-- ErrorNoHalt (message .. "\n")
end

function GLib.EnumerateDelayed (tbl, callback, finishCallback)
	if not callback then return end

	local next, tbl, key = pairs (tbl)
	local value = nil
	local function timerCallback ()
		local startTime = SysTime ()
		while SysTime () - startTime < 0.001 do
			key, value = next (tbl, key)
			if not key and finishCallback then finishCallback () return end
			callback (key, value)
			if not key then return end
		end

		GLib.CallDelayed (timerCallback)
	end
	timerCallback ()
end

function GLib.EnumerateFolder (folder, pathId, callback, recursive)
	if not callback then return end

	local files, folders = GLib.Loader.Find (folder .. "/*", pathId)
	for _, fileName in pairs (files) do
		callback (folder .. "/" .. fileName, pathId)
	end
	if recursive then
		for _, childFolder in pairs (folders) do
			if childFolder ~= "." and childFolder ~= ".." then
				GLib.EnumerateFolder (folder .. "/" .. childFolder, pathId, callback, recursive)
			end
		end
	end
end

function GLib.EnumerateFolderRecursive (folder, pathId, callback)
	GLib.EnumerateFolder (folder, pathId, callback, true)
end

function GLib.EnumerateLuaFolder (folder, pathId, callback, recursive)
	GLib.EnumerateFolder (folder, pathId or "LUA",
		function (path, pathId)
			if path:sub (-4):lower () ~= ".lua" then return end
			callback (path, pathId)
		end,
		recursive
	)
end

function GLib.EnumerateLuaFolderRecursive (folder, pathId, callback)
	GLib.EnumerateLuaFolder (folder, pathId, callback, true)
end

function GLib.Error (message)
	message = tostring (message)

	local fullMessage = " \n\t" .. message .. "\n\t\t" .. string.gsub (GLib.StackTrace (nil, 1), "\n", "\n\t\t") .. "\n"

	ErrorNoHalt (fullMessage)
end

function GLib.FindUpValue (func, name)
	local i = 1
	local a, b = true, nil
	while a ~= nil do
		a, b = debug.getupvalue (func, i)
		if a == name then return b end
		i = i + 1
	end
end

local string_format = string.format
local timeUnits = { "ns", "µs", "ms", "s", "ks", "Ms", "Gs", "Ts", "Ps", "Es", "Zs", "Ys" }
function GLib.FormatDuration (duration)
	duration = duration * 1000000000

	local unitIndex = 1
	while duration >= 1000 and timeUnits [unitIndex + 1] do
		duration = duration / 1000
		unitIndex = unitIndex + 1
	end
	return string_format ("%.2f %s", duration, timeUnits [unitIndex])
end

local sizeUnits = { "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB" }
function GLib.FormatFileSize (size)
	local unitIndex = 1
	while size >= 1024 and sizeUnits [unitIndex + 1] do
		size = size / 1024
		unitIndex = unitIndex + 1
	end
	return string_format ("%.2f %s", size, sizeUnits [unitIndex])
end

function GLib.GetStackDepth ()
	local i = 0
	while debug.getinfo (i) do
		i = i + 1
	end
	return i
end

function GLib.Initialize (systemName, systemTable)
	if not systemTable then
		GLib.Error ("GLib.Initialize : Called incorrectly.")
	end

	setmetatable (systemTable, getmetatable (systemTable) or {})
	if systemTable ~= GLib then
		getmetatable (systemTable).__index = GLib

		for k, v in pairs (GLib) do
			if type (v) == "table" then
				-- Object static tables
				local metatable = debug.getmetatable (v)
				local ictorInvoker = metatable and metatable.__call or nil

				systemTable [k] = {}
				if v.__static then systemTable [k].__static = true end
				setmetatable (systemTable [k],
					{
						__index = v,
						__call = ictorInvoker
					}
				)
			end
		end
	end

	GLib.EventProvider (systemTable)
	systemTable:AddEventListener ("Unloaded", "GLib.Unloader",
		function ()
			if not istable (ULib) then
				hook.Remove ("ShutDown", tostring (systemName))
			end
		end
	)

	hook.Add ("ShutDown", tostring (systemName),
		function ()
			GLib.Debug ("Unloading " .. systemName .. "...")
			systemTable:DispatchEvent ("Unloaded")
		end
	)

	GLib.CallDelayed (
		function ()
			hook.Call ("GLibSystemLoaded", GAMEMODE or GM, tostring (systemName))
			hook.Call (tostring (systemName) .. "Loaded", GAMEMODE or GM)
		end
	)
end

function GLib.IncludeDirectory (folder, recursive)
	local included = {}
	local paths = { "LUA" }
	if SERVER then paths [#paths + 1] = "LSV" end
	if CLIENT and GetConVar ("sv_allowcslua"):GetBool () then paths [#paths + 1] = "LCL" end

	local folderListList = recursive and {} or nil

	for _, path in ipairs (paths) do
		local files, folders = GLib.Loader.Find (folder .. "/*", path)
		if recursive then
			folderListList [#folderListList + 1] = folders
		end

		for _, file in ipairs (files) do
			if string.lower (string.sub (file, -4)) == ".lua" and
			   not included [string.lower (file)] then
				GLib.Loader.Include (folder .. "/" .. file)
				included [string.lower (file)] = true
			end
		end
	end
	if recursive then
		for _, folders in ipairs (folderListList) do
			for _, childFolder in ipairs (folders) do
				if childFolder ~= "." and childFolder ~= ".." and
				   not included [string.lower (childFolder)] then
					GLib.IncludeDirectory (folder .. "/" .. childFolder, recursive)
					included [string.lower (childFolder)] = true
				end
			end
		end
	end
end

function GLib.InvertTable (tbl, out)
	out = out or {}

	local keys = {}
	for key, _ in pairs (tbl) do
		keys [#keys + 1] = key
	end
	for i = 1, #keys do
		out [tbl [keys [i]]] = keys [i]
	end

	return out
end

function GLib.NullCallback ()
end

function GLib.PrettifyString (str)
	local out = ""
	for i = 1, #str do
		local char = string.sub (str, i, i)
		local byte = string.byte (char)
		if byte < 32 or byte >= 127 then
			out = out .. string.format ("\\x%02x", byte)
		else
			if char == "\\" then char = "\\\\"
			elseif char == "\r" then char = "\\r"
			elseif char == "\n" then char = "\\n"
			elseif char == "\t" then char = "\\t"
			elseif char == "\"" then char = "\\\""
			elseif char == "\'" then char = "\\\'" end

			out = out .. char
		end
	end
	return out
end

function GLib.PrintStackTrace ()
	ErrorNoHalt (GLib.StackTrace (nil, 2))
end

function GLib.StackTrace (levels, frameOffset)
	local stringBuilder = GLib.StringBuilder ()

	local frameOffset = frameOffset or 1
	local exit = false
	local i = 0
	local shown = 0
	while not exit do
		local t = debug.getinfo (i)
		if not t or shown == levels then
			exit = true
		else
			local name = t.name
			local src = t.short_src
			src = src or "<unknown>"
			if i >= frameOffset then
				shown = shown + 1
				if name then
					stringBuilder:Append (string.format ("%2d", i) .. ": " .. name .. " (" .. src .. ": " .. tostring (t.currentline) .. ")\n")
				else
					if src and t.currentline then
						stringBuilder:Append (string.format ("%2d", i) .. ": (" .. src .. ": " .. tostring (t.currentline) .. ")\n")
					else
						stringBuilder:Append (string.format ("%2d", i) .. ":\n")
						PrintTable (t)
					end
				end
			end
		end
		i = i + 1
	end
	return stringBuilder:ToString ()
end

function GLib.UnloadSystem (systemTableName)
	if not systemTableName then return end
	if type (_G [systemTableName]) == "table" and
		type (_G [systemTableName].DispatchEvent) == "function" then
		_G [systemTableName]:DispatchEvent ("Unloaded")
	end
	_G [systemTableName] = nil

	hook.Call ("GLibSystemUnloaded", GAMEMODE or GM, systemTableName)
	hook.Call (systemTableName .. "Unloaded", GAMEMODE or GM)
end

if CLIENT then
	function GLib.WaitForLocalPlayer (callback)
		if not LocalPlayer or
		   not LocalPlayer () or
		   not LocalPlayer ():IsValid () then
			GLib.CallDelayed (
				function ()
					GLib.WaitForLocalPlayer (callback)
				end
			)
			return
		end
		callback ()
	end
end

function GLib.WeakTable ()
	local tbl = {}
	setmetatable (tbl, { __mode = "kv" })
	return tbl
end

function GLib.WeakKeyTable ()
	local tbl = {}
	setmetatable (tbl, { __mode = "k" })
	return tbl
end

function GLib.WeakValueTable ()
	local tbl = {}
	setmetatable (tbl, { __mode = "v" })
	return tbl
end

-- GLib.Initialize uses this code
include ("oop/enum.lua")
include ("oop/oop.lua")
include ("timers.lua")
include ("events/eventprovider.lua")
GLib.Initialize ("GLib", GLib)

-- Now load the rest
include ("userid.lua")
include ("stringbuilder.lua")

include ("bitconverter.lua")
include ("io/inbuffer.lua")
include ("io/outbuffer.lua")
include ("io/stringinbuffer.lua")
include ("io/stringoutbuffer.lua")

include ("transfers/vnet.lua")
include ("transfers/transfers.lua")
include ("transfers/inboundtransfer.lua")
include ("transfers/outboundtransfer.lua")

include ("resources/resources.lua")
include ("resources/resource.lua")
include ("resources/resourcestate.lua")
include ("resources/resourcecache.lua")

include ("loader/loader.lua")
include ("loader/packfilesystem.lua")
include ("loader/packfilemanager.lua")
include ("loader/commands.lua")

-- This has to be done after the Loader library is loaded,
-- since GLib.EnumerateFolder calls GLib.Loader.Find.
GLib.AddCSLuaFile ("glib/glib.lua")
GLib.AddCSLuaFile ("glib/stage1.lua")
GLib.AddCSLuaFile ("glib/oop/enum.lua")
GLib.AddCSLuaFile ("glib/oop/oop.lua")
GLib.AddCSLuaFile ("glib/timers.lua")
GLib.AddCSLuaFile ("glib/userid.lua")
GLib.AddCSLuaFile ("glib/events/eventprovider.lua")
GLib.AddCSLuaFile ("glib/stringbuilder.lua")
GLib.AddCSLuaFile ("glib/bitconverter.lua")
GLib.AddCSLuaFile ("glib/io/inbuffer.lua")
GLib.AddCSLuaFile ("glib/io/outbuffer.lua")
GLib.AddCSLuaFile ("glib/io/stringinbuffer.lua")
GLib.AddCSLuaFile ("glib/io/stringoutbuffer.lua")
GLib.AddCSLuaFolderRecursive ("glib/transfers")
GLib.AddCSLuaFolderRecursive ("glib/resources")
GLib.AddCSLuaFolderRecursive ("glib/loader")

GLib.AddCSLuaFile ("glib/addons.lua")

-- Stage 2
GLib.AddCSLuaPackSystem ("GLib")
GLib.AddCSLuaPackFile ("autorun/glib.lua")
GLib.AddCSLuaPackFolderRecursive ("glib")
