local self = {}
VFS.NetNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (endPoint, name, parentFolder)
	self.Type = "Net" .. (self:IsFolder () and "Folder" or "File")
	self.EndPoint = endPoint
	
	self.Name = name
	self.DisplayName = self.Name
	self.ParentFolder = parentFolder
	
	self.ModificationTime = -1
	
	self.PermissionBlock = GAuth.PermissionBlock ()
	self.PermissionBlock:SetParentFunction (
		function ()
			if not self:GetParentFolder () then return end
			return self:GetParentFolder ():GetPermissionBlock ()
		end
	)
	self.PermissionBlock:SetDisplayNameFunction (function () return self:GetDisplayPath () end)
	self.PermissionBlock:SetNameFunction (function () return self:GetPath () end)
	self.PermissionBlock:AddEventListener ("PermissionsChanged", self:GetHashCode (), function () self:DispatchEvent ("PermissionsChanged") end)
	
	VFS.PermissionBlockNetworker:HookRemoteBlock (self.PermissionBlock)
	
	self:AddEventListener ("Deleted", self.UnhookPermissionBlock)
end

function self:GetDisplayName ()
	return self.DisplayName or self:GetName ()
end

function self:GetModificationTime ()
	return self.ModificationTime
end

function self:GetName ()
	return self.Name
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:GetPermissionBlock ()
	return self.PermissionBlock
end

function self:IsNetNode ()
	return true
end

function self:Rename (authId, newName, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Rename") then callback (VFS.ReturnCode.AccessDenied) return end
	
	self:GetParentFolder ():RenameChild (authId, self:GetName (), newName, callback)
end

function self:SetDisplayName (displayName)
	if self.DisplayName == displayName then return end
	self.DisplayName = displayName
	
	self:DispatchEvent ("Updated", VFS.UpdateFlags.DisplayName)
	if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self, VFS.UpdateFlags.DisplayName) end
end

-- Internal, do not call
function self:SetModificationTime (modificationTime)
	if self.ModificationTime == modificationTime then return end
	self.ModificationTime = modificationTime
	
	self:DispatchEvent ("Updated", VFS.UpdateFlags.ModificationTime)
	if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self, VFS.UpdateFlags.ModificationTime) end
end