if CLIENT then return end

concommand.Add ("vfs_adv_duplicator_open",
	function (ply, _, args)
		if not ply or not ply:IsValid () then return end
		if not args [1] or args [1] == "" then return end
		
		local tool = ply:GetActiveWeapon ()
		if not dupeshare.CurrentToolIsDuplicator (tool) then return end
		
		VFS.Root:OpenFile (GLib.GetPlayerId (ply), args [1], VFS.OpenFlags.Read,
			function (returnCode, fileStream)
				if returnCode ~= VFS.ReturnCode.Success then return end
				if not ply:IsValid () then fileStream:Close () return end
				fileStream:Read (fileStream:GetLength (),
					function (returnCode, data)
						if returnCode == VFS.ReturnCode.Progress then return end
						fileStream:Close ()
						if returnCode == VFS.ReturnCode.Success then
							if not ply:IsValid () then return end
							local tool = ply:GetActiveWeapon ()
							if not dupeshare.CurrentToolIsDuplicator (tool) then return end
							
							local toolObject = tool:GetTable ():GetToolObject ()
							toolObject:ClearClipBoard ()
							toolObject:SetPercentText ("Loading")
							local oldFileExists = file.Exists
							local oldFileRead = file.Read
							file.Exists = function () return true end
							file.Read = function () return data end
							
							pcall (AdvDupe.LoadDupeTableFromFile, toolObject:GetOwner (), args [1])
							file.Exists = oldFileExists
							file.Read = oldFileRead
						end
					end
				)
			end
		)
	end
)