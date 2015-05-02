-- HTTP Pack Loading
local executionTargets = SERVER and { "sv", "sh", "cl" } or { "m" }
for _, executionTarget in ipairs (executionTargets) do
	concommand.Add ("glib_download_pack_" .. executionTarget,
		function (ply, _, args)
			if not ply or not ply:IsValid () then return end
			if SERVER and not ply:IsSuperAdmin () then return end
			if #args == 0 then return end
			args = table.concat (args)
			if args == "" then return end
			
			print ("glib_download_pack_" .. executionTarget .. ": Fetching " .. args .. ".")
			http.Fetch (args,
				function (data, dataSize, headers, httpCode)
					print ("glib_download_pack_" .. executionTarget .. ": Received " .. args .. " (" .. GLib.FormatFileSize (dataSize) .. ")")
					GLib.Loader.RunSerializedPackFile (executionTarget, data, false, args)
				end,
				function (err)
					print ("glib_download_pack_" .. executionTarget .. ": HTTP fetch failed (" .. tostring (err) .. ")")
				end
			)
		end
	)
end

if CLIENT then
	-- Packing
	concommand.Add ("glib_pack",
		function (ply, _, args)
			if #args == 0 then
				print ("glib_pack <addon_directory>")
				return
			end
			
			local addonName = table.concat (args, " ")
			local addonLuaPath = "addons/" .. addonName .. "/lua"
			if string.sub (addonName, 1, 3) == "../" then
				addonName = string.sub (addonName, 4)
				addonLuaPath = addonName .. "/lua"
			end
			
			if not file.IsDir (addonLuaPath, "GAME") then
				print ("glib_pack: " .. addonLuaPath .. " not found.")
				return
			end
			
			local packFileSystem = GLib.Loader.PackFileSystem ()
			local packFileName = string.gsub (addonName, "[\\/: %-]", "_")
			packFileSystem:SetName (packFileName)
			local pathPrefix = addonLuaPath
			GLib.EnumerateFolderRecursive (addonLuaPath, "GAME",
				function (path)
					if path:sub (-4):lower () ~= ".lua" then return end
					packFileSystem:Write (
						path:sub (#pathPrefix + 1),
						file.Read (path, "GAME")
					)
				end
			)
			
			local autoruns, _ = packFileSystem:Find ("autorun/*.lua")
			for _, autorun in ipairs (autoruns) do
				local code = packFileSystem:Read ("autorun/" .. autorun) or ""
				local includedPath = code:match ("[iI]nclude[ \t]*%(\"([^\"]*)\"%)") or ""
				code = packFileSystem:Read (includedPath) or ""
				local systemName = code:match ("^if ([^ ]*) then return end")
				if systemName then
					packFileSystem:AddSystemTable (systemName)
				end
			end
			
			-- Write pack file
			file.CreateDir ("glibpack")
			local f = file.Open ("glibpack/" .. packFileName .. "_pack.txt", "wb", "DATA")
			f:Write (packFileSystem:GetSerializedPackFile ())
			f:Close ()
		end,
		function (command, arg)
			if arg:sub (1, 1) == " " then arg = arg:sub (2) end
			
			local _, addons = file.Find ("addons/*", "GAME")
			local autocomplete = {}
			for _, addonName in ipairs (addons) do
				if addonName:lower ():sub (1, arg:len ()) == arg:lower () and
				   file.IsDir ("addons/" .. addonName .. "/lua", "GAME") then
					autocomplete [#autocomplete + 1] = command .. " " .. addonName
				end
			end
			return autocomplete
		end
	)
	
	-- Pack deployment
	local executionTargets = { "cl", "sh", "sv", "m" }
	for _, executionTarget in ipairs (executionTargets) do
		concommand.Add ("glib_upload_pack_" .. executionTarget,
			function (_, _, args)
				if #args == 0 then
					print ("glib_upload_pack_" .. executionTarget .. " <pack file name>")
					return
				end
				
				local packFileName = table.concat (args, " ")
				
				-- Read pack file
				local serializedPackFile = nil
				local f = file.Open ("data/glibpack/" .. packFileName, "rb", "GAME")
				if not f then
					print ("glib_upload_pack_" .. executionTarget .. " : " .. "data/glibpack/" .. packFileName .. " not found!")
					return
				end
				
				serializedPackFile = f:Read (f:Size ())
				f:Close ()
				
				if executionTarget == "m" then
					if GetConVar ("sv_allowcslua"):GetBool () then
						GLib.Loader.RunSerializedPackFile ("m", serializedPackFile, false, packFileName)
					else
						print ("glib_upload_pack_m : sv_allowcslua is 0!")
					end
				else
					GLib.Loader.StreamPack (GLib.GetServerId (), executionTarget, util.Compress (serializedPackFile), packFileName)
				end
			end,
			function (command, arg)
				if arg:sub (1, 1) == " " then arg = arg:sub (2) end
				
				local files, _ = file.Find ("data/glibpack/*.txt", "GAME")
				local autocomplete = {}
				for _, packName in ipairs (files) do
					if packName:lower ():sub (1, arg:len ()) == arg:lower () then
						autocomplete [#autocomplete + 1] = command .. " " .. packName
					end
				end
				return autocomplete
			end
		)
	end
end