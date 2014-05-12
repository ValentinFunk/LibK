local self = {}
VFS.INode = VFS.MakeConstructor (self)

--[[
	Events:
		Deleted ()
			Fired when this node has been deleted.
		Renamed (oldName, newName)
			Fired when this node has been renamed.
		PermissionsChanged ()
			Fired when this node's permissions have changed.
		Updated (INode node, UpdateFlags updateFlags)
			Fired when this node's display name, size or other
			attribute has been changed.
]]

function self:ctor ()
	VFS.EventProvider (self)
	
	self.Deletable = true
	self.Predicted = false
	
	self:AddEventListener ("PermissionsChanged", self.PermissionsChanged)
end

function self:CanDelete ()
	return self.Deletable
end

function self:ClearPredictedFlag ()
	self.Predicted = false
end

--[[
	INode:Delete (authId, function (returnCode))
		
		Do not implement this, implement IFolder:DeleteDirectChild instead
		Delete this filesystem node
]]
function self:Delete (authId, callback)
	if not self:GetParentFolder () then
		VFS.Error ("IFolder:Delete : " .. self:GetPath () .. " has no parent folder from which to delete.")
		return
	end
	self:GetParentFolder ():DeleteDirectChild (authId, self:GetName (), callback)
end

function self:GetDisplayName ()
	return self:GetName ()
end

function self:GetDisplayPath ()
	local path = self:GetDisplayName ()
	local parent = self:GetParentFolder ()
	
	while parent do
		if path:len () > 1000 then
			error ("INode:GetDisplayPath : Path is too long!")
		end
		if parent:GetDisplayName () ~= "" then
			path = parent:GetDisplayName () .. "/" .. path
		end
		parent = parent:GetParentFolder ()
	end
	
	return path
end

function self:GetInner ()
	return self
end

--[[
	INode:GetModificationTime ()
		Returns: int secondsPastUnixEpoch
		
		Returns the last modification time of this node
		in seconds past 00:00:00 UTC January 1, 1970
		or -1 if unavailable
]]
function self:GetModificationTime ()
	return -1
end

function self:GetName ()
	VFS.Error ("INode:GetName : Not implemented")
    return "[Node]"
end

function self:GetNodeType ()
	VFS.Error ("INode:GetNodeType : Not implemented")
	return VFS.NodeType.Unknown
end

function self:GetOwner ()
	return self:GetPermissionBlock ():GetOwner ()
end

function self:GetParentFolder ()
	VFS.Error ("INode:GetParentFolder : Not implemented")
	return nil
end

function self:GetPermissionBlock ()
	VFS.Error ("INode:GetPermissionBlock : Not implemented")
end

function self:GetPath ()
	local path = self:GetName ()
	local parent = self:GetParentFolder ()
	
	while parent do
		if path:len () > 1000 then
			error ("INode:GetPath : Path is too long!")
		end
		if parent:GetName () ~= "" then
			path = parent:GetName () .. "/" .. path
		end
		parent = parent:GetParentFolder ()
	end
	
	return path
end

function self:IsFile ()
	return bit.band (self:GetNodeType (), VFS.NodeType.File) ~= 0
end

function self:IsFolder ()
	return bit.band (self:GetNodeType (), VFS.NodeType.Folder) ~= 0
end

function self:IsLocalNode ()
	return not self:IsNetNode ()
end

function self:IsMountedNode ()
	return false
end

function self:IsNetNode ()
	return false
end

function self:IsPredicted ()
	return self.Predicted
end

function self:IsRoot ()
	return VFS.Root == self
end

function self:MarkPredicted ()
	self.Predicted = true
end

function self:Rename (authId, name)
	VFS.Error ("INode:Rename : Not implemented")
end

function self:SetDeletable (deletable)
	self.Deletable = deletable
end

function self:SetDisplayName (displayName)
end

function self:SetOwner (authId, ownerId, callback)
	self:GetPermissionBlock ():SetOwner (authId, ownerId, callback)
end

function self:UnhookPermissionBlock ()
	VFS.PermissionBlockNetworker:UnhookBlock (self:GetPermissionBlock ())
end

-- Events
function self:PermissionsChanged ()
	if not self:GetParentFolder () then return end
	self:GetParentFolder ():DispatchEvent ("NodePermissionsChanged", self)
end