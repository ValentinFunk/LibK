local self = {}
VFS.VFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.VNode)

function self:ctor (name, parentFolder)	
	self.Children = {}
	self.LowercaseChildren = {}
end

function self:CreateDirectNode (authId, name, isFolder, callback)
	callback = callback or VFS.NullCallback

	local lowercaseName = name:lower ()
	if self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName]) then
		if self.Children [name]:IsFolder () == isFolder then callback (VFS.ReturnCode.Success, self.Children [name])
		elseif self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName] then callback (VFS.ReturnCode.Success, self.LowercaseChildren [lowercaseName])
		elseif isFolder then callback (VFS.ReturnCode.NotAFolder)
		else callback (VFS.ReturnCode.NotAFile) end
		return
	end
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, (isFolder and "Create Folder" or "Write")) then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.Children [name] = (isFolder and VFS.VFolder or VFS.VFile) (name, self)
	if self:IsCaseInsensitive () then self.LowercaseChildren [lowercaseName] = self.Children [name] end
	self:DispatchEvent ("NodeCreated", self.Children [name])
	
	callback (VFS.ReturnCode.Success, self.Children [name])
end

function self:DeleteDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	local lowercaseName = name
	local node = self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName] or nil)
	if not node then callback (VFS.ReturnCode.Success) return end
	if not node:GetPermissionBlock ():IsAuthorized (authId, "Delete") then callback (VFS.ReturnCode.AccessDenied) return end
	if not node:CanDelete () then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.Children [name] = nil
	self.LowercaseChildren [lowercaseName] = nil
	self:DispatchEvent ("NodeDeleted", node)
	node:DispatchEvent ("Deleted")
	
	callback (VFS.ReturnCode.Success)
end

function self:EnumerateChildren (authId, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "View Folder") then callback (VFS.ReturnCode.AccessDenied) return end
	
	for _, node in pairs (self.Children) do
		callback (VFS.ReturnCode.Success, node)
	end
	callback (VFS.ReturnCode.Finished)
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "View Folder") then callback (VFS.ReturnCode.AccessDenied) return end
	
	local lowercaseName = name:lower ()
	if self.Children [name] then
		callback (VFS.ReturnCode.Success, self.Children [name])
	elseif self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName] then
		callback (VFS.ReturnCode.Success, self.LowercaseChildren [lowercaseName])
	else
		callback (VFS.ReturnCode.NotFound)
	end
end

function self:GetDirectChildSynchronous (name)
	return self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [name:lower ()] or nil)
end

function self:IsCaseSensitive ()
	return false
end

function self:Mount (name, node, displayName)
	if not node then return end
	
	self.Children [name] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (name, node, self)
	self.Children [name]:SetDisplayName (displayName)
	if self:IsCaseInsensitive () then self.LowercaseChildren [name:lower ()] = self.Children [name] end
	self:DispatchEvent ("NodeCreated", self.Children [name])
	
	return self.Children [name]
end

function self:RenameChild (authId, name, newName, callback)
	callback = callback or VFS.NullCallback
	
	name = VFS.SanitizeNodeName (name)
	newName = VFS.SanitizeNodeName (newName)
	if not name then callback (VFS.ReturnCode.AccessDenied) return end
	if not newName then callback (VFS.ReturnCode.AccessDenied) return end
	
	local lowercaseName = name:lower ()
	local node = self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName] or nil)
	if not node then callback (VFS.ReturnCode.NotFound) return end
	
	if not node:GetPermissionBlock ():IsAuthorized (authId, "Rename") then callback (VFS.ReturnCode.AccessDenied) return end
	
	if self.Children [newName] then callback (VFS.ReturnCode.AlreadyExists) return end
	if self:IsCaseInsensitive () and self.LowercaseChildren [newName:lower ()] then callback (VFS.ReturnCode.AlreadyExists) return end
	self.Children [newName] = self.Children [name]
	self.Children [name] = nil
	if self:IsCaseInsensitive () then
		self.LowercaseChildren [newName:lower ()] = self.Children [newName]
		self.LowercaseChildren [lowercaseName] = nil
	end
	node:Rename (authId, newName)
	self:DispatchEvent ("NodeRenamed", node, name, newName)
	
	callback (VFS.ReturnCode.Success)
end

function self:UnhookPermissionBlock ()
	VFS.PermissionBlockNetworker:UnhookBlock (self:GetPermissionBlock ())
	for _, node in pairs (self.Children) do
		node:UnhookPermissionBlock ()
	end
end