if SERVER then
	local function updateProgress (ply, progressFraction, filePath)
		if not ply or not ply:IsValid () then return end
		
		progressFraction = progressFraction or 1
		umsg.Start ("vfs_expression2_upload_progress", ply)
			umsg.Float (progressFraction)
			if progressFraction == 1 then
				umsg.String (filePath or "")
			end
		umsg.End ()
	end

	concommand.Add ("wire_expression_vfs_upload", function (player, command, args)
		local id = player:UserID ()
		local filePath = tostring (args [1] or "")
		if not concommand.GetTable () ["wire_expression_upload_begin"] then return end
		
		local buffer = VFS.FindUpValue (concommand.GetTable () ["wire_expression_upload_begin"], "buffer")
		if not buffer then updateProgress (player, nil, filePath) return end
		local uploadData = buffer [id]
		if not uploadData then updateProgress (player, nil, filePath) return end
		
		local chipOwner = uploadData.ent.player
		if not (E2Lib.isFriend (chipOwner, player) and (chipOwner == player or chipOwner:GetInfoNum ("wire_expression2_friendwrite") ~= 0)) then return end

		uploadData.text = ""
		uploadData.len = 0
		uploadData.chunk = 0
		uploadData.chunks = 1
		uploadData.ent:SetOverlayText ("Expression 2\n(transferring)")
		uploadData.ent:SetColor (GLib.Colors.Lime)
		uploadData.StartTime = SysTime ()
		
		VFS.Root:OpenFile (GLib.GetPlayerId (player), filePath, VFS.OpenFlags.Read,
			function (returnCode, fileStream)
				if returnCode == VFS.ReturnCode.Success then
					fileStream:Read (fileStream:GetLength (),
						function (returnCode, data)
							if returnCode == VFS.ReturnCode.Progress then
								local progressFraction = data
								updateProgress (player, progressFraction, filePath)
								if uploadData.ent:IsValid () then
									uploadData.ent:SetOverlayText ("Expression 2\n(transferring - " .. string.format ("%.1f%%)", progressFraction * 100))
								end
								return
							end
							if returnCode == VFS.ReturnCode.Success then
								updateProgress (player, 1, filePath)
								buffer [id] = nil
								VFS.Debug ("Upload of " .. filePath .. " took " .. (SysTime () - uploadData.StartTime) .. " s.")
								if uploadData.ent:IsValid () then
									uploadData.ent:Setup (data)
								end
							elseif uploadData.ent:IsValid () then
								updateProgress (player, nil, filePath)
								uploadData.ent:SetOverlayText ("Expression 2\n(transfer error)")
								uploadData.ent:SetColor (GLib.Colors.Red)
							else
								updateProgress (player, nil, filePath)
							end
							fileStream:Close ()
						end
					)
				elseif uploadData.ent:IsValid () then
					updateProgress (player, nil, filePath)
					uploadData.ent:SetOverlayText ("Expression 2\n(transfer error)")
					uploadData.ent:SetColor (GLib.Colors.Red)
				else
					updateProgress (player, nil, filePath)
				end
			end
		)
	end)
elseif CLIENT then
	local uploadFiles = VFS.WeakValueTable ()
	local oldTransfer = VFS.NullCallback

	local function transfer (code, existingPath)
		if not VFS.Net.IsChannelOpen ("vfs_new_session") then
			oldTransfer (code)
		elseif existingPath then
			RunConsoleCommand ("wire_expression_vfs_upload", existingPath)
		else
			if E2Macros then
				local context = E2Macros.Context ()
				context:SetProcessMode (E2Macros.ProcessMode.Expand)
				context:ProcessCode (code)
				code = table.concat (context:GetLines (), "\n")
			end
			VFS.Root:OpenFile (GAuth.GetLocalId (), GAuth.GetLocalId () ..  "/tmp/" .. VFS.GetUniqueName () .. ".txt", VFS.OpenFlags.Write,
				function (returnCode, fileStream)
					if returnCode == VFS.ReturnCode.Success then
						fileStream:Write (code:len (), code,
							function (returnCode)
								local file = fileStream:GetFile ()
								local path = fileStream:GetPath ()
								fileStream:Close ()
								
								if returnCode == VFS.ReturnCode.Success then
									uploadFiles [path] = file
									
									RunConsoleCommand ("wire_expression_vfs_upload", path)
									Expression2SetProgress (0)
								else
									file:Delete (GAuth.GetLocalId ())
								
									oldTransfer (code)
								end
							end	
						)
					else
						oldTransfer (code)
					end
				end
			)
		end
	end
	
	usermessage.Hook ("vfs_expression2_upload_progress",
		function (umsg)
			local percentage = umsg:ReadFloat ()
			if percentage == 1 then
				percentage = nil
				local path = umsg:ReadString ()
				if path ~= "" then
					if uploadFiles [path] then uploadFiles [path]:Delete (GAuth.GetLocalId ()) end
					uploadFiles [path] = nil
				end
			else
				percentage = percentage * 100
			end
			Expression2SetProgress (percentage)
		end
	)

	local FirstCheckTime = SysTime ()
	local function OverrideUpload ()
		wire_expression2_upload_old = wire_expression2_upload_old or wire_expression2_upload
		if not wire_expression2_upload_old then
			if SysTime () - FirstCheckTime < 60 then
				timer.Simple (1, OverrideUpload)
			end
			return
		end
		
		oldTransfer = VFS.FindUpValue (wire_expression2_upload_old, "transfer")
		
		function wire_expression2_upload ()
			if wire_expression2_editor == nil then initE2Editor () end

			if e2_function_data_received then
				local result = wire_expression2_validate (wire_expression2_editor:GetCode ())
				if result then
					WireLib.AddNotify (result, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
					return
				end
			else
				WireLib.AddNotify ("The Expression 2 function data has not been transferred to the client yet; uploading the E2 to the server for validation.", NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
			end

			transfer (wire_expression2_editor:GetCode (), nil)
		end
	end
	timer.Simple (1, OverrideUpload)
end