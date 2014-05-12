local self = {}
VFS.RealFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.RealNode)

function self:ctor (path, fileSystemPath, name, parentFolder)
	self.FolderPath = self:GetPath () == "" and "" or self:GetPath () .. "/"
	
	self.Children = {}
	self.LowercaseChildren = {}
	
	self:AddEventListener ("Renamed", self.Renamed)
end

function self:CreateDirectNode (authId, name, isFolder, callback)
	callback = callback or VFS.NullCallback

	local lowercaseName = name:lower ()
	if self.Children [name] or self.LowercaseChildren [lowercaseName] or self:CheckExists (name) then
		if (self.Children [name] or self.LowercaseChildren [lowercaseName]):IsFolder () == isFolder then callback (VFS.ReturnCode.Success, self.Children [name] or self.LowercaseChildren [lowercaseName])
		elseif isFolder then callback (VFS.ReturnCode.NotAFolder)
		else callback (VFS.ReturnCode.NotAFile) end
		return
	end
	
	if self.FolderPath:lower ():sub (1, 5) ~= "data/" then callback (VFS.ReturnCode.AccessDenied) return end
	if isFolder then
		file.CreateDir (self.FolderPath:sub (6) .. name)
	else
		if name:sub (-4, -1) ~= ".txt" then
			name = name .. ".txt"
			lowercaseName = name:lower ()
		end
		file.Write (self.FolderPath:sub (6) .. name, "")
	end

	if self:CheckExists (name) then
		callback (VFS.ReturnCode.Success, self.Children [name] or self.LowercaseChildren [lowercaseName])
	else
		callback (VFS.ReturnCode.AccessDenied)
	end
end

function self:DeleteDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	local lowercaseName = name:lower ()
	local node = self.Children [name] or self.Children [lowercaseName]
	
	if not node then
		-- Check for existance, create node then delete it.
		-- RealFolder:CheckExists () will create the node and fire the NodeCreated event if necessary
		if not self:CheckExists (name) then
			callback (VFS.ReturnCode.Success)
			return
		end
	end
	node = self.Children [name] or self.Children [lowercaseName]
	if not node:CanDelete () then callback (VFS.ReturnCode.AccessDenied) return end
	
	if self.FolderPath:lower ():sub (1, 5) ~= "data/" then callback (VFS.ReturnCode.AccessDenied) return end
	
	file.Delete (self.FolderPath:sub (6) .. name, true)
	if not self:CheckExists (name) then
		callback (VFS.ReturnCode.Success)
	else
		callback (VFS.ReturnCode.AccessDenied)
	end
end

function self:EnumerateChildren (authId, callback)
	local files, folders = file.Find (self.FolderPath .. "*", self.FileSystemPath)
	
	-- 1. Produce map of items and new items
	-- 2. Check for deleted items
	-- 2. Check for new folders / files
	-- 3. Call callback
	
	-- 1. Produce item map
	local items = {}
	local new = {}
	for _, name in ipairs (folders or {}) do
		if not self.Children [name] and not self.LowercaseChildren [name:lower ()] then new [name] = VFS.NodeType.Folder end
		items [name] = VFS.NodeType.Folder
	end
	for _, name in ipairs (files or {}) do
		if not self.Children [name] and not self.LowercaseChildren [name:lower ()] then new [name] = VFS.NodeType.File end
		items [name] = VFS.NodeType.File
	end
	
	-- 2. Check for deleted items
	local deleted = {}
	for name, _ in pairs (self.Children) do
		if not items [name] then
			deleted [name] = true
		end
	end
	for name, _ in pairs (deleted) do
		local node = self.Children [name]
		self.Children [name] = nil
		self.LowercaseChildren [name:lower ()] = nil
		self:DispatchEvent ("NodeDeleted", node)
		node:DispatchEvent ("Deleted")
	end
	
	-- 3. Add new children
	VFS.EnumerateDelayed (new,
		function (name, nodeType)
			self.Children [name] = (nodeType == VFS.NodeType.Folder and VFS.RealFolder or VFS.RealFile) (self.FolderPath .. name, self.FileSystemPath, name, self)
			self.LowercaseChildren [string.lower (name)] = self.Children [name]
			self:DispatchEvent ("NodeCreated", self.Children [name])
		end,
		function ()
			-- 4. Call callback
			VFS.EnumerateDelayed (self.Children,
				function (_, node)
					callback (VFS.ReturnCode.Success, node)
				end,
				function () callback (VFS.ReturnCode.Finished) end
			)
		end
	)
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	local lowercaseName = string.lower (name)
	if self.Children [name] or
	   self.LowercaseChildren [lowercaseName] or
	   self:CheckExists (name) then
		callback (VFS.ReturnCode.Success, self.Children [name] or self.LowercaseChildren [lowercaseName])
		return
	end
	
	callback (VFS.ReturnCode.NotFound)
end

function self:GetDirectChildSynchronous (name)
	return self.Children [name] or self.LowercaseChildren [name:lower ()]
end

function self:IsCaseSensitive ()
	return false
end

function self:RenameChild (authId, name, newName, callback)
	callback = callback or VFS.NullCallback
	
	name = VFS.SanitizeNodeName (name)
	newName = VFS.SanitizeNodeName (newName)
	if not name then callback (VFS.ReturnCode.AccessDenied) return end
	if not newName then callback (VFS.ReturnCode.AccessDenied) return end
	
	local lowercaseName = name:lower ()
	local node = self.Children [name] or self.LowercaseChildren [lowercaseName]
	if not node then
		if self:CheckExists (name) then node = self.Children [name] or self.LowercaseChildren [lowercaseName] end
	end
	if not node then callback (VFS.ReturnCode.AccessDenied) return end
	
	node:Rename (authId, newName,
		function (returnCode)
			if returnCode == VFS.ReturnCode.Success then
				self.Children [name] = nil
				self.LowercaseChildren [lowercaseName] = nil
				self.Children [node:GetName ()] = node
				self.Children [node:GetName ():lower ()] = node
				self:DispatchEvent ("NodeRenamed", node, name, newName)
			end
			callback (returnCode)
		end
	)
end

-- Internal, do not call
--[[
	RealFolder:CheckExists (name)
		Returns: boolean nodeExists
		
		Checks if a child file or folder with the given name exists. If so,
		it is added to the child table and the NodeCreated event is fired.
		Otherwise, it's removed from the child table if present and
		NodeDeleted is fired.
]]
function self:CheckExists (name)
	if file.Exists (self.FolderPath .. name, self.FileSystemPath) then
		-- Add the child
		self.Children [name] = (file.IsDir (self.FolderPath .. name, self.FileSystemPath) and VFS.RealFolder or VFS.RealFile) (self.FolderPath .. name, self.FileSystemPath, name, self)
		self.LowercaseChildren [name:lower ()] = self.Children [name]
		self:DispatchEvent ("NodeCreated", self.Children [name])
		return true
	else
		-- Remove the child if we still have it
		local node = self.Children [name]
		if node then
			self.Children [name] = nil
			self.LowercaseChildren [name:lower ()] = nil
			self:DispatchEvent ("NodeDeleted", node)
			node:DispatchEvent ("Deleted")
		end
		
		return false
	end
end

-- Events
function self:Renamed ()
	self.FolderPath = self:GetPath () == "" and "" or self:GetPath () .. "/"
end