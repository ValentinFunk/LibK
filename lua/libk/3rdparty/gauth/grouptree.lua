local self = {}
GAuth.GroupTree = GAuth.MakeConstructor (self, GAuth.GroupTreeNode)

--[[
	Events:
		NotifyGroupAdded (name)
			Fire this when a child Group has been added to the host GroupTree
		NotifyGroupTreeAdded (name)
			Fire this when a child GroupTree has been added to the host GroupTree
		NotifyNodeRemoved (name)
			Fire this when a child node is removed from the host GroupTree
	
		GroupAdded (Group group)
			Fired when a child group has been added
		GroupTreeAdded (GroupTree groupTree)
			Fired when a child group tree has been added
		NodeAdded (GroupTreeNode groupTreeNode)
			Fired when a child node has been added
		NodeDisplayNameChanged (GroupTreeNode groupTreeNode, displayName)
			Fired when a child node's display name has been changed
		NodeRemoved (GroupTreeNode groupTreeNode)
			Fired when a child node has been removed
]]

function self:ctor (name)
	self.Children = {}
	
	self.Icon = "icon16/folder_user.png"
	
	self:AddEventListener ("NotifyGroupAdded",     self.NotifyGroupAdded)
	self:AddEventListener ("NotifyGroupTreeAdded", self.NotifyGroupTreeAdded)
	self:AddEventListener ("NotifyNodeRemoved",    self.NotifyNodeRemoved)
end

function self:AddGroup (authId, name, callback)
	self:AddGroupTreeNode (authId, name, false, callback)
end

function self:AddGroupTree (authId, name, callback)
	self:AddGroupTreeNode (authId, name, true, callback)
end

function self:AddGroupTreeNode (authId, name, isGroupTree, callback)
	callback = callback or GAuth.NullCallback
	name = name:gsub ("/", "")

	if self.Children [name] then
		if self.Children [name]:IsGroupTree () == isGroupTree then
			callback (GAuth.ReturnCode.Success, self.Children [name])
		else
			callback (GAuth.ReturnCode.NodeAlreadyExists)
		end
		return
	end
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Create Group" .. (isGroupTree and " Tree" or "")) then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if not self:IsPredicted () and not self:IsHostedLocally () then
		local nodeAdditionRequest = GAuth.Protocol.NodeAdditionRequest (self, name, isGroupTree,
			function (returnCode)
				callback (returnCode, self.Children [name])
			end
		)
		GAuth.EndPointManager:GetEndPoint (self:GetHost ()):StartSession (nodeAdditionRequest)
		return
	end
	
	self.Children [name] = (isGroupTree and GAuth.GroupTree or GAuth.Group) (name)
	self.Children [name]:SetParentNode (self)
	self.Children [name]:SetHost (self:GetHost ())
	
	self:DispatchEvent (isGroupTree and "GroupTreeAdded" or "GroupAdded", self.Children [name])
	self:DispatchEvent ("NodeAdded", self.Children [name])
	
	callback (GAuth.ReturnCode.Success, self.Children [name])
end

function self:AddGroupTreeNodeRecursive (authId, name, isGroupTree, callback)
	callback = callback or GAuth.NullCallback
	
	if parts == "" then
		if self:IsGroupTree () == isGroupTree then
			callback (GAuth.ReturnCode.Success, self)
		else
			callback (GAuth.ReturnCode.NodeAlreadyExists)
		end
		return
	end
	
	local parts = name:Split ("/")
	local segment = table.remove (parts, 1)
	name = table.concat (parts, "/")
	self:AddGroupTreeNode (authId, segment, #parts > 0 or isGroupTree,
		function (returnCode, groupTreeNode)
			if returnCode ~= GAuth.ReturnCode.Success then callback (returnCode) return end
			if name == "" then callback (GAuth.ReturnCode.Success, groupTreeNode) return end
			groupTreeNode:AddGroupTreeNodeRecursive (authId, name, isGroupTree, callback)
		end
	)
end

function self:ContainsUser (userId, permissionBlock)
	for _, groupTreeNode in pairs (self.Children) do
		if groupTreeNode:ContainsUser (userId, permissionBlock) then return true end
	end
	return false
end

function self:GetChild (name)
	return self.Children [name]
end

--[[
	GroupTree:GetChildEnumerator ()
		Returns: ()->(name, GroupTreeNode childNode)
]]
function self:GetChildEnumerator ()
	return pairs (self.Children)
end

function self:IsGroupTree ()
	return true
end

function self:RemoveNode (authId, name, callback)
	callback = callback or GAuth.NullCallback
	
	local node = self.Children [name]
	if not node then callback (GAuth.ReturnCode.Success) return end
	if not node:GetPermissionBlock ():IsAuthorized (authId, "Delete") then callback (GAuth.ReturnCode.AccessDenied) return end
	if not node:CanRemove () then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if not self:IsPredicted () and not self:IsHostedLocally () then
		local nodeRemovalRequest = GAuth.Protocol.NodeRemovalRequest (self, node, callback)
		GAuth.EndPointManager:GetEndPoint (self:GetHost ()):StartSession (nodeRemovalRequest)
	end
	
	self.Children [name] = nil
	node:DispatchEvent ("Removed")
	self:DispatchEvent ("NodeRemoved", node)
	
	callback (GAuth.ReturnCode.Success)
end

-- Events
function self:NotifyGroupAdded (name)
	if self.Children [name] then return end
	self.Children [name] = GAuth.Group (name)
	self.Children [name]:SetParentNode (self)
	self.Children [name]:SetHost (self:GetHost ())
	
	self:DispatchEvent ("GroupAdded", self.Children [name])
	self:DispatchEvent ("NodeAdded", self.Children [name])
end

function self:NotifyGroupTreeAdded (name)
	if self.Children [name] then return end
	self.Children [name] = GAuth.GroupTree (name)
	self.Children [name]:SetParentNode (self)
	self.Children [name]:SetHost (self:GetHost ())
	
	self:DispatchEvent ("GroupTreeAdded", self.Children [name])
	self:DispatchEvent ("NodeAdded", self.Children [name])
end

function self:NotifyNodeRemoved (name)
	local node = self.Children [name]
	if not node then return end
	self.Children [name] = nil
	node:DispatchEvent ("Removed")
	self:DispatchEvent ("NodeRemoved", node)
end