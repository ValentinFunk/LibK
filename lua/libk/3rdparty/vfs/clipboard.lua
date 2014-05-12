local self = {}
VFS.Clipboard = VFS.MakeConstructor (self)

function self:ctor ()
	self.FolderCount = 0
	self.FileCount = 0
	self.Folders = {}
	self.Files = {}
end

function self:Add (node)
	if node:IsFolder () then
		self.Folders [#self.Folders + 1] = node
		self.FolderCount = self.FolderCount + 1
	elseif node:IsFile () then
		self.Files [#self.Files + 1] = node
		self.FileCount = self.FileCount + 1
	end
end

function self:CanPaste (folder)
	if not folder then return false end
	if self.FolderCount == 0 and self.FileCount == 0 then return false end
	if not folder:GetPermissionBlock () then return true end
	if self.FileCount > 0 and folder:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Write") then return true end
	if self.FolderCount > 0 and folder:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Create Folder") then return true end
	return false
end

function self:Clear ()
	self.FolderCount = 0
	self.FileCount = 0
	self.Folders = {}
	self.Files = {}
end

function self:Paste (folder)
	for _, v in ipairs (self.Folders) do
		self:PasteFolder (folder, v)
	end
	for _, v in ipairs (self.Files) do
		self:PasteFile (folder, v)
	end
end

-- Internal, do not call
function self:PasteFile (destContainingFolder, sourceFile, i, callback)
	callback = callback or VFS.NullCallback
	
	local destName = sourceFile:GetName ()
	if i then
		local name = destName
		local extension = nil
		local extensionPos = destName:reverse ():find (".", 1, true)
		if extensionPos then
			extensionPos = destName:len () - extensionPos
			name = destName:sub (1, extensionPos)
			extension = destName:sub (extensionPos + 1)
		end
		destName = name .. "_copy_(" .. i .. ")" .. (extension or "")
	end
	destContainingFolder:GetChild (GAuth.GetLocalId (), destName,
		function (returnCode, node)
			if node then
				self:PasteFile (destContainingFolder, sourceFile, (i and (i + 1) or 1), callback)
			else
				destContainingFolder:OpenFile (GAuth.GetLocalId (), destName, VFS.OpenFlags.Write,
					function (returnCode, fileStream)
						if not fileStream then callback (returnCode) return end
						sourceFile:Open (GAuth.GetLocalId (), VFS.OpenFlags.Read,
							function (returnCode, sourceFileStream)
								if not sourceFileStream then fileStream:Close () callback (returnCode) return end
								sourceFileStream:Read (sourceFileStream:GetLength (),
									function (returnCode, data)
										if returnCode == VFS.ReturnCode.Progress then return end
										if not data then sourceFileStream:Close () fileStream:Close () callback (returnCode) return end
										fileStream:Write (sourceFileStream:GetLength (), data,
											function (returnCode)
												fileStream:Close ()
												sourceFileStream:Close ()
												callback (returnCode)
											end
										)
									end
								)
							end
						)
					end
				)
			end
		end
	)
end

function self:PasteFolder (destContainingFolder, sourceFolder, i, callback)
	callback = callback or VFS.NullCallback
	
	local destFolderParent = destContainingFolder
	while destFolderParent do
		if destFolderParent == sourceFolder then
			callback (VFS.ReturnCode.AccessDenied)
			return
		end
		destFolderParent = destFolderParent:GetParentFolder ()
	end
	
	local destName = sourceFolder:GetName ()
	destContainingFolder:CreateFolder (GAuth.GetLocalId (), destName,
		function (returnCode, newFolder)
			if not newFolder then callback (returnCode) return end
			local children = {}
			local i = 1
			local pasteNextChild
			local pasteNextChildDelay
			function pasteNextChildDelay (returnCode)
				GLib.CallDelayed (
					function ()
						pasteNextChild (returnCode)
					end
				)
			end
			function pasteNextChild (returnCode)
				local child = children [i]
				i = i + 1
				if not child then callback (returnCode) return end
				if child:IsFolder () then
					self:PasteFolder (newFolder, child, nil, pasteNextChildDelay)
				elseif child:IsFile () then
					self:PasteFile (newFolder, child, nil, pasteNextChildDelay)
				end
			end
			sourceFolder:EnumerateChildren (GAuth.GetLocalId (),
				function (returnCode, child)
					if returnCode == VFS.ReturnCode.Success then
						children [#children + 1] = child
					elseif returnCode == VFS.ReturnCode.EndOfBurst then
					else
						pasteNextChild (returnCode)
					end
				end
			)
		end
	)
end

VFS.Clipboard = VFS.Clipboard ()