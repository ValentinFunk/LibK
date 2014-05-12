local self = {}
VFS.MountedFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.MountedNode)

function self:ctor (nameOverride, mountedNode, parentFolder)
	self.Children = {}
	self.LowercaseChildren = {}
	
	self.MountedNode:AddEventListener ("NodeCreated",
		function (_, node)
			if self.Children [node:GetName ()] then return end
			if self:IsCaseInsensitive () and self.LowercaseChildren [node:GetName ():lower ()] then return end
			self.Children [node:GetName ()] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (nil, node, self)
			if self:IsCaseInsensitive () then self.LowercaseChildren [node:GetName ():lower ()] = self.Children [node:GetName ()] end
			self:DispatchEvent ("NodeCreated", self.Children [node:GetName ()])
		end
	)
	
	self.MountedNode:AddEventListener ("NodeDeleted",
		function (_, node)
			local deletedNode = self.Children [node:GetName ()]
			if not deletedNode then return end
			self.Children [node:GetName ()] = nil
			self.LowercaseChildren [node:GetName ():lower ()] = nil
			self:DispatchEvent ("NodeDeleted", deletedNode)
		end
	)
	
	self.MountedNode:AddEventListener ("NodePermissionsChanged",
		function (_, node)
			if self:IsCaseSensitive () then
				if not self.Children [node:GetName ()] then return end
				self:DispatchEvent ("NodePermissionsChanged", self.Children [node:GetName ()])
			else
				if not self.LowercaseChildren [node:GetName ():lower ()] then return end
				self:DispatchEvent ("NodePermissionsChanged", self.LowercaseChildren [node:GetName ():lower ()])
			end
		end
	)
	
	self.MountedNode:AddEventListener ("NodeRenamed",
		function (_, node, oldName, newName)
			if not self.Children [oldName] then return end
			self.Children [newName] = self.Children [oldName]
			self.Children [oldName] = nil
			if self:IsCaseInsensitive () then
				self.LowercaseChildren [oldName] = nil
				self.LowercaseChildren [newName] = self.Children [newName]
			end
			self:DispatchEvent ("NodeRenamed", self.Children [newName], oldName, newName)
		end
	)
	
	self.MountedNode:AddEventListener ("NodeUpdated",
		function (_, node, updateFlags)
			local updatedNode = self.Children [node:GetName ()]
			if not updatedNode then return end
			self:DispatchEvent ("NodeUpdated", updatedNode, updateFlags)
		end
	)
end

function self:CreateDirectNode (authId, name, isFolder, callback)
	callback = callback or VFS.NullCallback

	local lowercaseName = name:lower ()
	if self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName]) then
		if self.Children [name] and self.Children [name]:IsFolder () == isFolder then callback (VFS.ReturnCode.Success, self.Children [name])
		elseif self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName]:IsFolder () == isFolder then callback (VFS.ReturnCode.Success, self.LowercaseChildren [lowercaseName])
		elseif isFolder then callback (VFS.ReturnCode.NotAFolder)
		else callback (VFS.ReturnCode.NotAFile) end
		return
	end
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, (isFolder and "Create Folder" or "Write")) then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.MountedNode:CreateDirectNode (authId, name, isFolder,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if self:IsCaseSensitive () then
					if not self.Children [node:GetName ()] then
						self.Children [node:GetName ()] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (nil, node, self)
						self:DispatchEvent ("NodeCreated", self.Children [node:GetName ()])
					end
					callback (VFS.ReturnCode.Success, self.Children [node:GetName ()])
				else
					if not self.LowercaseChildren [node:GetName ():lower ()] then
						self.Children [node:GetName ()] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (nil, node, self)
						self.LowercaseChildren [node:GetName ():lower ()] = self.Children [node:GetName ()]
						self:DispatchEvent ("NodeCreated", self.LowercaseChildren [node:GetName ():lower ()])
					end
					callback (VFS.ReturnCode.Success, self.LowercaseChildren [node:GetName ():lower ()])
				end
			else
				callback (returnCode)
			end
		end
	)
end

function self:DeleteDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	self.MountedNode:DeleteDirectChild (authId, name, callback)
end

function self:EnumerateChildren (authId, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "View Folder") then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.MountedNode:EnumerateChildren (authId,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if self:IsCaseSensitive () then
					if not self.Children [node:GetName ()] then
						self.Children [node:GetName ()] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (nil, node, self)
						self:DispatchEvent ("NodeCreated", self.Children [node:GetName ()])
					end
					callback (VFS.ReturnCode.Success, self.Children [node:GetName ()])
				else
					if not self.LowercaseChildren [node:GetName ():lower ()] then
						self.Children [node:GetName ()] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (nil, node, self)
						self.LowercaseChildren [node:GetName ():lower ()] = self.Children [node:GetName ()]
						self:DispatchEvent ("NodeCreated", self.LowercaseChildren [node:GetName ():lower ()])
					end
					callback (VFS.ReturnCode.Success, self.LowercaseChildren [node:GetName ():lower ()])
				end
			else
				callback (returnCode, node)
			end
		end
	)
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "View Folder") then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.MountedNode:GetDirectChild (authId, name,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if self:IsCaseSensitive () then
					if not self.Children [node:GetName ()] then
						self.Children [node:GetName ()] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (nil, node, self)
						self:DispatchEvent ("NodeCreated", self.Children [node:GetName ()])
					end
					callback (VFS.ReturnCode.Success, self.Children [node:GetName ()])
				else
					if not self.LowercaseChildren [node:GetName ():lower ()] then
						self.Children [node:GetName ()] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (nil, node, self)
						self.LowercaseChildren [node:GetName ():lower ()] = self.Children [node:GetName ()]
						self:DispatchEvent ("NodeCreated", self.LowercaseChildren [node:GetName ():lower ()])
					end
					callback (VFS.ReturnCode.Success, self.LowercaseChildren [node:GetName ():lower ()])
				end
			else
				callback (returnCode)
			end
		end
	)
end

function self:GetDirectChildSynchronous (name)
	if self:IsCaseInsensitive () then return self.LowercaseChildren [name:lower ()] end
	return self.Children [name]
end

function self:IsCaseSensitive ()
	return self.MountedNode:IsCaseSensitive ()
end

function self:RenameChild (authId, name, newName, callback)
	callback = callback or VFS.NullCallback
	
	name = VFS.SanitizeNodeName (name)
	newName = VFS.SanitizeNodeName (newName)
	if not name then callback (VFS.ReturnCode.AccessDenied) return end
	if not newName then callback (VFS.ReturnCode.AccessDenied) return end
	
	local lowercaseName = name:lower ()
	local node = self:IsCaseSensitive () and self.Children [name] or self.LowercaseChildren [lowercaseName]
	if not node then callback (VFS.ReturnCode.NotFound) return end
	
	if not node:GetPermissionBlock ():IsAuthorized (authId, "Rename") then callback (VFS.ReturnCode.AccessDenied) return end
	
	if self.Children [newName] then callback (VFS.ReturnCode.AlreadyExists) return end
	if self:IsCaseInsensitive () and self.LowercaseChildren [newName:lower ()] then callback (VFS.ReturnCode.AlreadyExists) return end
	
	local oldName = node:GetName ()
	node:Rename (authId, newName, callback)
	
	-- NodeRenamed event is hooked at the top of this file
	-- and the event handler updates the child table.
end

function self:UnhookPermissionBlock ()
	VFS.PermissionBlockNetworker:UnhookBlock (self:GetPermissionBlock ())
	for _, node in pairs (self.Children) do
		node:UnhookPermissionBlock ()
	end
end