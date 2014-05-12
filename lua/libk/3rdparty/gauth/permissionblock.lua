local self = {}
GAuth.PermissionBlock = GAuth.MakeConstructor (self)

--[[
	Events:
		NotifyGroupEntryAdded (groupId)
			Fire this when a group entry is added to the host PermissionBlock
		NotifyGroupEntryRemoved (groupId)
			Fire this when a group entry is removed form the host PermissionBlock
		NotifyGroupPermissionChanged (groupId, actionId, access)
			Fire this when a group entry permission is changed on the host PermissionBlock
		NotifyInheritOwnerChanged (inheritOwner)
			Fire this when owner inheritance has changed on the host PermissionBlock
		NotifyInheritPermissionsChanged (inheritPermissions)
			Fire this when permission inheritance has changed on the host PermissionBlock
		NotifyOwnerChanged (ownerId)
			Fire this when the owner of the host PermissionBlock is changed
	
		RequestAddGroupEntry (authId, groupId, callback)
			Return true to stop AddGroupEntry from running locally
		RequestRemoveGroupEntry (authId, groupId, callback)
			Return true to stop RemoveGroupEntry from running locally
		RequestSetGroupPermission (authId, groupId, actionId, access, callback)
			Return true to stop SetGroupPermission from running locally
		RequestSetInheritOwner (authId, inheritOwner, callback)
			Return true to stop SetInheritOwner from running locally
		RequestSetInheritPermissions (authId, inheritPermissions, callback)
			Return true to stop SetInheritPermissions from running locally
		RequestSetOwner (authId, ownerId, callback)
			Return true to stop SetOwner from running locally
	
		GroupEntryAdded (groupId)
			Fired when a group entry has been added
		GroupEntryRemoved (groupId)
			Fired when a group entry has been removed
		GroupPermissionChanged (groupId, actionId, access)
			Fired when a group entry permission has been changed
		InheritOwnerChanged (inheritOwner)
			Fired when owner inheritance has been changed
		InheritPermissionsChanged (inheritPermissions)
			Fired when permission inheritance has been changed
		OwnerChanged (ownerId)
			Fired when the owner has been changed
			
		PermissionsChanged ()
			Fired when permissions have changed
]]

function self:ctor ()
	self.PermissionDictionary = nil

	self.OwnerId = GAuth.GetSystemId ()
	self.GroupEntries = {}
	
	self.InheritOwner = true
	self.InheritPermissions = true
	
	self.Parent = nil
	self.ParentFunction = nil
	
	self.Name = "Unknown"
	self.NameFunction = nil
	self.DisplayName = "Unknown"
	self.DisplayNameFunction = nil
	
	GAuth.EventProvider (self)
	
	self:AddEventListener ("NotifyGroupEntryAdded",           self.NotifyGroupEntryAdded)
	self:AddEventListener ("NotifyGroupEntryRemoved",         self.NotifyGroupEntryRemoved)
	self:AddEventListener ("NotifyGroupPermissionChanged",    self.NotifyGroupPermissionChanged)	
	self:AddEventListener ("NotifyInheritOwnerChanged",       self.NotifyInheritOwnerChanged)
	self:AddEventListener ("NotifyInheritPermissionsChanged", self.NotifyInheritPermissionsChanged)
	self:AddEventListener ("NotifyOwnerChanged",              self.NotifyOwnerChanged)
end

function self:AddGroupEntry (authId, groupId, callback)
	callback = callback or GAuth.NullCallback

	if self.GroupEntries [groupId] then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Modify Permissions") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if self:DispatchEvent ("RequestAddGroupEntry", authId, groupId, callback) then return end
	
	self.GroupEntries [groupId] = {}
	self:DispatchEvent ("GroupEntryAdded", groupId)
	self:DispatchEvent ("PermissionsChanged")
	
	callback (GAuth.ReturnCode.Success)
end

function self:CopyFrom (permissionBlock)
	self.OwnerId = permissionBlock.OwnerId
	self.GroupEntries = {}
	
	self.InheritOwner = permissionBlock.InheritOwner
	self.InheritPermissions = permissionBlock.InheritPermissions
	
	self.Parent = permissionBlock.Parent
	self.ParentFunction = permissionBlock.ParentFunction
	
	self.Name = permissionBlock.Name
	self.NameFunction = permissionBlock.NameFunction
	self.DisplayName = permissionBlock.DisplayName
	self.DisplayNameFunction = permissionBlock.DisplayNameFunction
	
	for groupId, groupEntry in pairs (permissionBlock.GroupEntries) do
		self.GroupEntries [groupId] = {}
		for actionId, access in pairs (groupEntry) do
			self.GroupEntries [groupId] [actionId] = access
		end
	end
end

function self:Deserialize (inBuffer)
	if type (inBuffer) == "string" then inBuffer = GAuth.StringInBuffer (inBuffer) end

	self:SetInheritOwner (GAuth.GetSystemId (), inBuffer:Boolean ())
	self:SetInheritPermissions (GAuth.GetSystemId (), inBuffer:Boolean ())
	if not self:InheritsOwner () then
		self:SetOwner (GAuth.GetSystemId (), inBuffer:String ())
	else
		self.OwnerId = inBuffer:String ()
	end
	
	local groupId = inBuffer:String ()
	while groupId ~= "" do
		self:AddGroupEntry (GAuth.GetSystemId (), groupId)
		
		local actionId = inBuffer:String ()
		while actionId ~= "" do
			self:SetGroupPermission (GAuth.GetSystemId (), groupId, actionId, inBuffer:UInt8 ())
			actionId = inBuffer:String ()
		end
		groupId = inBuffer:String ()
	end
end

function self:GetAccess (authId, actionId, permissionBlock)
	if authId == GAuth.GetSystemId () or
		authId == GAuth.GetServerId () then
		return GAuth.Access.Allow
	end

	local parentAccess = GAuth.Access.None
	local parent = self:GetParent ()
	if self.InheritPermissions and parent then
		parentAccess = parent:GetAccess (authId, actionId, permissionBlock or self)
	end
	
	if parentAccess == GAuth.Access.Deny then return GAuth.Access.Deny end
	
	local thisAccess = GAuth.Access.None
	for groupId, groupEntry in pairs (self.GroupEntries) do
		if GAuth.IsUserInGroup (groupId, authId, permissionBlock) then
			if groupEntry [actionId] == GAuth.Access.Allow then
				thisAccess = GAuth.Access.Allow
			elseif groupEntry [actionId] == GAuth.Access.Deny then
				return GAuth.Access.Deny
			end
		end
	end
	
	if parentAccess == GAuth.Access.Allow or
		thisAccess == GAuth.Access.Allow then
		return GAuth.Access.Allow
	end
	
	return GAuth.Access.None
end

function self:GetGroupAccess (groupId, actionId, permissionBlock)
	local parentAccess = GAuth.Access.None
	local parent = self:GetParent ()
	if self.InheritPermissions and parent then
		parentAccess = parent:GetGroupAccess (groupId, actionId, permissionBlock or self)
	end
	
	if parentAccess == GAuth.Access.Deny then return GAuth.Access.Deny end
	
	local thisAccess = GAuth.Access.None
	local groupEntry = self.GroupEntries [groupId]
	if not groupEntry then return parentAccess end
	
	if groupEntry [actionId] == GAuth.Access.Allow then
		thisAccess = GAuth.Access.Allow
	elseif groupEntry [actionId] == GAuth.Access.Deny then
		return GAuth.Access.Deny
	end
	
	if parentAccess == GAuth.Access.Allow or
		thisAccess == GAuth.Access.Allow then
		return GAuth.Access.Allow
	end
	
	return GAuth.Access.None
end

function self:GetGroupEntryEnumerator ()
	local next, tbl, key = pairs (self.GroupEntries)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:GetGroupPermission (groupId, actionId, permissionBlock)
	if not self.GroupEntries [groupId] then return GAuth.Access.None end
	return self.GroupEntries [groupId] [actionId] or GAuth.Access.None
end

function self:GetDisplayName ()
	if self.DisplayNameFunction then return self.DisplayNameFunction (self) end
	return self.DisplayName or self:GetName ()
end

function self:GetName ()
	if self.NameFunction then return self.NameFunction (self) end
	return self.Name
end

function self:GetOwner ()
	if self.InheritOwner and self:GetParent () then
		return self:GetParent ():GetOwner ()
	end

	return self.OwnerId
end

function self:GetParent ()
	if self.ParentFunction then
		return self:ParentFunction ()
	end
	
	return self.Parent
end

function self:GetPermissionDictionary ()
	if self.PermissionDictionary then return self.PermissionDictionary end
	if self:GetParent () then return self:GetParent ():GetPermissionDictionary () end
	return nil
end

function self:InheritsOwner ()
	return self.InheritOwner
end

function self:InheritsPermissions ()
	return self.InheritPermissions
end

function self:IsAuthorized (authId, actionId, permissionBlock)
	return self:GetAccess (authId, actionId, permissionBlock or self) == GAuth.Access.Allow
end

function self:IsDefault ()
	if not self.InheritOwner then return false end
	if not self.InheritPermissions then return false end
	if next (self.GroupEntries) then return false end
	return true
end

function self:RemoveGroupEntry (authId, groupId, callback)
	callback = callback or GAuth.NullCallback

	if not self.GroupEntries [groupId] then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Modify Permissions") then callback (GAuth.ReturnCode.AccessDenied) return end

	if self:DispatchEvent ("RequestRemoveGroupEntry", authId, groupId, callback) then return end
	
	self.GroupEntries [groupId] = nil
	self:DispatchEvent ("GroupEntryRemoved", groupId)
	self:DispatchEvent ("PermissionsChanged")
	
	callback (GAuth.ReturnCode.Success)
end

function self:Serialize (outBuffer)
	outBuffer = outBuffer or GAuth.StringOutBuffer ()
	outBuffer:Boolean (self.InheritOwner)
	outBuffer:Boolean (self.InheritPermissions)
	outBuffer:String (self.OwnerId)
	for groupId, groupEntry in pairs (self.GroupEntries) do
		outBuffer:String (groupId)
		for actionId, access in pairs (groupEntry) do
			if access ~= GAuth.Access.None then
				outBuffer:String (actionId)
				outBuffer:UInt8 (access)
			end
		end
		outBuffer:String ("")
	end
	outBuffer:String ("")
	return outBuffer
end

function self:SetGroupPermission (authId, groupId, actionId, access, callback)
	callback = callback or GAuth.NullCallback

	if not self:IsAuthorized (authId, "Modify Permissions") then callback (GAuth.ReturnCode.AccessDenied) return end

	if self:DispatchEvent ("RequestSetGroupPermission", authId, groupId, actionId, access, callback) then return end
	
	if self.GroupEntries [groupId] then
		if (self.GroupEntries [groupId] [actionId] or GAuth.Access.None) ~= access then
			self.GroupEntries [groupId] [actionId] = access
			self:DispatchEvent ("GroupPermissionChanged", groupId, actionId, access)
			self:DispatchEvent ("PermissionsChanged")
		end
		
		callback (GAuth.ReturnCode.Success)
	else
		self:AddGroupEntry (authId, groupId,
			function (returnCode)
				if returnCode ~= GAuth.ReturnCode.Success then callback (returnCode) return end
				
				self.GroupEntries [groupId] [actionId] = access
				self:DispatchEvent ("GroupPermissionChanged", groupId, actionId, access)
				self:DispatchEvent ("PermissionsChanged")
				
				callback (GAuth.ReturnCode.Success)
			end
		)
	end
end

function self:SetInheritOwner (authId, inheritOwner, callback)
	callback = callback or GAuth.NullCallback

	if self.InheritOwner == inheritOwner then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Set Owner") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if self:DispatchEvent ("RequestSetInheritOwner", authId, inheritOwner, callback) then return end
	
	if not inheritOwner then self.OwnerId = self:GetOwner () end
	self.InheritOwner = inheritOwner
	self:DispatchEvent ("InheritOwnerChanged", inheritOwner)
	self:DispatchEvent ("PermissionsChanged")
	
	callback (GAuth.ReturnCode.Success)
end

function self:SetInheritPermissions (authId, inheritPermissions, callback)
	callback = callback or GAuth.NullCallback

	if self.InheritPermissions == inheritPermissions then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Modify Permissions") then callback (GAuth.ReturnCode.AccessDenied) return end

	if self:DispatchEvent ("RequestSetInheritPermissions", authId, inheritPermissions, callback) then return end
	
	self.InheritPermissions = inheritPermissions
	self:DispatchEvent ("InheritPermissionsChanged", inheritPermissions)
	self:DispatchEvent ("PermissionsChanged")
	
	callback (GAuth.ReturnCode.Success)
end

function self:SetDisplayName (displayName)
	return self.DisplayName
end

function self:SetDisplayNameFunction (displayNameFunction)
	self.DisplayNameFunction = displayNameFunction
end

function self:SetName (name)
	return self.Name
end

function self:SetNameFunction (nameFunction)
	self.NameFunction = nameFunction
end

function self:SetOwner (authId, ownerId, callback)
	callback = callback or GAuth.NullCallback

	if self:GetOwner () == ownerId then callback (GAuth.ReturnCode.Success) return end
	if not self:IsAuthorized (authId, "Set Owner") then callback (GAuth.ReturnCode.AccessDenied) return end

	if self:DispatchEvent ("RequestSetOwner", authId, ownerId, callback) then return end
	
	-- Turn off owner inheritance. This line shouldn't be in the notification
	-- reception code, since the InheritOwnerChanged notification should 
	-- get sent separately
	self.InheritOwner = false
	self:DispatchEvent ("InheritOwnerChanged", false)
	
	self.OwnerId = ownerId
	self:DispatchEvent ("OwnerChanged", ownerId)
	self:DispatchEvent ("PermissionsChanged")	
	
	callback (GAuth.ReturnCode.Success)
end

function self:SetParent (parent)
	self.Parent = parent
end

function self:SetParentFunction (parentFunction)
	self.ParentFunction = parentFunction
end

function self:SetPermissionDictionary (permissionDictionary)
	self.PermissionDictionary = permissionDictionary
end

-- Events
function self:NotifyGroupEntryAdded (groupId)
	if self.GroupEntries [groupId] then return end
	self.GroupEntries [groupId] = self.GroupEntries [groupId] or {}
	self:DispatchEvent ("GroupEntryAdded", groupId)
	self:DispatchEvent ("PermissionsChanged")
end

function self:NotifyGroupEntryRemoved (groupId)
	if not self.GroupEntries [groupId] then return end
	self.GroupEntries [groupId] = nil
	self:DispatchEvent ("GroupEntryRemoved", groupId)
	self:DispatchEvent ("PermissionsChanged")
end

function self:NotifyGroupPermissionChanged (groupId, actionId, access)
	if self.GroupEntries [groupId] and (self.GroupEntries [groupId] [actionId] or GAuth.Access.None) == access then return end
	self.GroupEntries [groupId] = self.GroupEntries [groupId] or {}
	self.GroupEntries [groupId] [actionId] = access
	self:DispatchEvent ("GroupPermissionChanged", groupId, actionId, access)
	self:DispatchEvent ("PermissionsChanged")
end

function self:NotifyInheritOwnerChanged (inheritOwner)
	if self.InheritOwner == inheritOwner then return end
	if not inheritOwner then self.OwnerId = self:GetOwner () end
	self.InheritOwner = inheritOwner
	self:DispatchEvent ("InheritOwnerChanged", inheritOwner)
	self:DispatchEvent ("PermissionsChanged")
end

function self:NotifyInheritPermissionsChanged (inheritPermissions)
	if self.InheritPermissions == inheritPermissions then return end
	self.InheritPermissions = inheritPermissions
	self:DispatchEvent ("InheritPermissionsChanged", inheritPermissions)
	self:DispatchEvent ("PermissionsChanged")
end

function self:NotifyOwnerChanged (ownerId)
	if self.OwnerId == ownerId then return end
	self.OwnerId = ownerId
	self:DispatchEvent ("OwnerChanged", ownerId)
	self:DispatchEvent ("PermissionsChanged")
end