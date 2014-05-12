local self = {}
GAuth.GroupTreeNode = GAuth.MakeConstructor (self)

--[[
	Events:
		DisplayNameChanged
			Fired when this node's display name has been changed.
		HostChanged
			Fired when this node's host is updated.
		IconChanged
			Fired when this node's icon has been changed.
		Removed
			Fired when this node has been removed.
]]

function self:ctor (name)
	self.Name = name or ""
	self.DisplayName = nil
	self.ParentNode = nil
	self.Host = GAuth.GetSystemId ()
	
	self.Icon = nil
	self.Removable = true
	self.Predicted = false
	
	self.PermissionBlock = GAuth.PermissionBlock ()
	self.PermissionBlock:SetDisplayNameFunction (function () return self:GetFullDisplayName () end)
	self.PermissionBlock:SetNameFunction (function () return self:GetFullName () end)
	self.PermissionBlock:SetParentFunction (
		function (permissionBlock)
			local parentNode = self:GetParentNode ()
			return parentNode and parentNode:GetPermissionBlock () or nil
		end
	)
	
	GAuth.EventProvider (self)
end

function self:CanRemove ()
	return self.Removable
end

function self:ClearPredictedFlag ()
	self.Predicted = false
end

function self:ContainsUser (userId, permissionBlock)
	return false
end

function self:GetDisplayName ()
	return self.DisplayName or self:GetName ()
end

function self:GetFullDisplayName ()
	local fullDisplayName = self:GetDisplayName ()
	local parent = self:GetParentNode ()
	
	while parent do
		if fullDisplayName:len () > 1000 then
			GAuth.Error ("GroupTreeNode:GetFullDisplayName : Full display name is too long!")
			break
		end
	
		if parent:GetDisplayName () ~= "" then
			fullDisplayName = parent:GetDisplayName () .. "/" .. fullDisplayName
		end
		parent = parent:GetParentNode ()
	end
	
	return fullDisplayName
end

function self:GetFullName ()
	local fullName = self:GetName ()
	local parent = self:GetParentNode ()
	
	while parent do
		if fullName:len () > 1000 then
			GAuth.Error ("GroupTreeNode:GetFullName : Full name is too long!")
			break
		end
	
		if parent:GetName () ~= "" then
			fullName = parent:GetName () .. "/".. fullName
		end
		parent = parent:GetParentNode ()
	end
	
	return fullName
end

function self:GetHost ()
	return self.Host
end

function self:GetIcon ()
	return self.Icon or "icon16/user.png"
end

function self:GetName ()
	return self.Name
end

function self:GetParentNode ()
	return self.ParentNode
end

function self:GetPermissionBlock ()
	return self.PermissionBlock
end

function self:IsGroup ()
	return false
end

function self:IsGroupTree ()
	return false
end

function self:IsHostedLocally ()
	return self:GetHost () == GAuth.GetSystemId () or self:GetHost () == GAuth.GetLocalId ()
end

function self:IsHostedRemotely ()
	return self:GetHost () ~= GAuth.GetLocalId ()
end

function self:IsPredicted ()
	return self.Predicted
end

function self:MarkPredicted ()
	self.Predicted = true
end

function self:Remove (authId, callback)
	callback = callback or GAuth.NullCallback
	
	if not self:CanRemove () then callback (VFS.ReturnCode.AccessDenied) return end
	
	self:GetParentNode ():RemoveNode (authId, self:GetName (), callback)
end

function self:SetDisplayName (displayName)
	self.DisplayName = displayName
	
	self:DispatchEvent ("DisplayNameChanged", displayName)
	if self:GetParentNode () then
		self:GetParentNode ():DispatchEvent ("NodeDisplayNameChanged", self, displayName)
	end
end

function self:SetHost (hostId)
	if self.Host == hostId then return end

	GAuth.Debug (self:GetFullName () .. ": Host is now " .. hostId)
	self.Host = hostId
	
	self:DispatchEvent ("HostChanged", self.Host)
end

function self:SetIcon (icon)
	self.Icon = icon
	
	self:DispatchEvent ("IconChanged", self:GetIcon ())
end

function self:SetName (name)
	self.Name = name
end

--[[
	GroupTreeNode:SetParentNode (GroupTree parentNode)
		
		Internal function, do not call.
]]
function self:SetParentNode (parentNode)
	if self.ParentNode == parentNode then return end
	self.ParentNode = parentNode
end

function self:SetRemovable (removable)
	self.Removable = removable
end