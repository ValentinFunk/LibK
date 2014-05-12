if not CLIENT then return end

local commandQueue = {}
local nextRunItem = 1

local function QueueConsoleCommand (...)
	commandQueue [#commandQueue + 1] = {...}
	
	if #commandQueue == 1 then
		timer.Create ("VFS.Adaptors.E2FileList", 0.1, 0, function ()
			for i = 1, 10 do
				RunConsoleCommand (unpack (commandQueue [nextRunItem]))
			
				nextRunItem = nextRunItem + 1
				if nextRunItem > #commandQueue then
					commandQueue = {}
					nextRunItem = 1
					timer.Destroy ("VFS.Adaptors.E2FileList")
					break
				end
			end
		end)
	end
end

local upload_buffer = {}
local upload_chunk_size = 200

local function upload_callback ()
	if not upload_buffer or not upload_buffer.data then return end
	
	local chunk_size = math.Clamp (string.len (upload_buffer.data), 0, upload_chunk_size)
	
	local transmittedString = string.sub (upload_buffer.data, 1, chunk_size)
	local i = 0
	while transmittedString:sub (-1, -1) == "%" or
	transmittedString:sub (-1, -1) == "." do
		i = i + 1
		transmittedString = string.sub (upload_buffer.data, 1, chunk_size + i)
	end
	QueueConsoleCommand ("wire_expression2_file_chunk", transmittedString)
	upload_buffer.data = string.sub (upload_buffer.data, transmittedString:len () + 1, string.len (upload_buffer.data))
	
	if upload_buffer.chunk >= upload_buffer.chunks then
		QueueConsoleCommand ("wire_expression2_file_finish")
		timer.Remove ("wire_expression2_file_upload")
		return
	end
	
	upload_buffer.chunk = upload_buffer.chunk + 1
end

local function wire_expression2_request_file (filePath)
	if filePath:sub (-5, -1) == "\\.txt" then filePath = filePath:sub (1, -6) end
	VFS.Debug ("[VFS] expression2_files: request_file: " .. filePath)
	VFS.Root:GetChild (GAuth.GetLocalId (), filePath,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if node:IsFile () then
					node:Open (GAuth.GetLocalId (), VFS.OpenFlags.Read,
						function (returnCode, filestream)
							if returnCode == VFS.ReturnCode.Success then
								filestream:Read (filestream:GetLength (),
									function (returnCode, data)
										if returnCode == VFS.ReturnCode.Success then
											
											local encoded = E2Lib.encode (data)
											
											upload_buffer = {
												chunk = 1,
												chunks = math.ceil (string.len (encoded) / upload_chunk_size),
												data = encoded
											}
											
											QueueConsoleCommand ("wire_expression2_file_begin", "1", string.len (data))
											
											timer.Create ("wire_expression2_file_upload", 1 / 60, upload_buffer.chunks, upload_callback)
										else
											filestream:Close ()
											VFS.Debug ("[VFS] expression2_files: Cannot read " .. filePath .. " (" .. VFS.ReturnCode [returnCode] .. ")")
											QueueConsoleCommand ("wire_expression2_file_begin", "0")
										end
									end
								)
							else
								VFS.Debug ("[VFS] expression2_files: Cannot open " .. filePath .. " (" .. VFS.ReturnCode [returnCode] .. ")")
								QueueConsoleCommand ("wire_expression2_file_begin", "0")
							end
						end
					)
				else
					VFS.Debug ("[VFS] expression2_files: " .. filePath .. " is not a file!")
					QueueConsoleCommand ("wire_expression2_file_begin", "0")
				end
			else
				VFS.Debug ("[VFS] expression2_files: Error when resolving " .. filePath .. " (" .. VFS.ReturnCode [returnCode] .. ")")
				QueueConsoleCommand ("wire_expression2_file_begin", "0")
			end
		end
	)
end

local function InstallFileSystemOverride ()
	if not usermessage.GetTable () ["wire_expression2_request_file"] then
		GLib.CallDelayed (InstallFileSystemOverride)
		return
	end
	usermessage.GetTable () ["wire_expression2_request_file"] =
	{
		Function = function (umsg)
			local filePath = umsg:ReadString ()
			GLib.CallDelayed (
				function ()
					wire_expression2_request_file (filePath)
				end
			)
		end,
		PreArgs = {}
	}
	usermessage.GetTable () ["wire_expression2_request_file_sp"] = usermessage.GetTable () ["wire_expression2_request_file"]

	usermessage.GetTable () ["wire_expression2_request_list"] = 
	{
		Function = function (umsg)
			local folderPath = umsg:ReadString () or ""
			VFS.Debug ("[VFS] expression2_files: request_list: " .. folderPath)
			VFS.Root:GetChild (GAuth.GetLocalId (), folderPath,
				function (returnCode, node)
					if returnCode == VFS.ReturnCode.Success then
						node:EnumerateChildren (GAuth.GetLocalId (),
							function (returnCode, node)
								if returnCode == VFS.ReturnCode.Success then
									if node:IsFolder () then
										QueueConsoleCommand ("wire_expression2_file_list", "1", E2Lib.encode (node:GetDisplayName () .. "/"))
									else
										QueueConsoleCommand ("wire_expression2_file_list", "1", E2Lib.encode (node:GetDisplayName ()))
									end
								elseif returnCode == VFS.ReturnCode.Finished then
									QueueConsoleCommand ("wire_expression2_file_list", "0")
								else
									VFS.Debug ("[VFS] expression2_files: Error when enumerating contents of " .. folderPath .. " (" .. VFS.ReturnCode [returnCode] .. ")")
									QueueConsoleCommand ("wire_expression2_file_list", "0")
								end
							end
						)
					else
						VFS.Debug ("[VFS] expression2_files: Error when resolving folder " .. folderPath .. " (" .. VFS.ReturnCode [returnCode] .. ")")
						QueueConsoleCommand ("wire_expression2_file_list", "0")
					end
				end
			)
		end,
		PreArgs = {}
	}
end

timer.Simple (1, InstallFileSystemOverride)