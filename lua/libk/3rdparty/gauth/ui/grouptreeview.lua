local self = {}

--[[
	Events:
		SelectedGroupChanged (Group group)
			Fired when the selected group is changed.
		SelectedGroupTreeNodeChanged (GroupTreeNode groupTreeNode)
			Fired when the selected group or group tree is changed.
]]

function self:Init ()
	self.SubscribedNodes = {}

	-- Populate root group trees
	self:SetPopulator (
		function (node)
			if node.IsGroupTree then
				self:Populate (node.Item, node)
			end
		end
	)
	self:Populate (GAuth.Groups, self)
	self:AddEventListener ("ItemSelected", self.ItemSelected)
	
	-- Menu
	self.Menu = Gooey.Menu ()
	
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			-- Override the menu target item with the group tree node
			if targetItem then
				targetItem = targetItem.Item
				self.Menu:SetTargetItem (targetItem)
			else
				targetItem = GAuth.Groups
				self.Menu:SetTargetItem (targetItem)
			end
			
			if not targetItem then
				self.Menu:GetItemById ("Browse")           :SetEnabled (false)
				self.Menu:GetItemById ("Create Group")     :SetEnabled (false)
				self.Menu:GetItemById ("Create Group Tree"):SetEnabled (false)
				self.Menu:GetItemById ("Delete")           :SetEnabled (false)
				self.Menu:GetItemById ("Permissions")      :SetEnabled (false)
				return
			end
			
			local permissionBlock = targetItem:GetPermissionBlock ()
			self.Menu:GetItemById ("Browse")           :SetEnabled (true)
			self.Menu:GetItemById ("Create Group")     :SetEnabled (targetItem:IsGroupTree () and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Group"))
			self.Menu:GetItemById ("Create Group Tree"):SetEnabled (targetItem:IsGroupTree () and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Group"))
			self.Menu:GetItemById ("Delete")           :SetEnabled (targetItem:CanRemove ()   and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Delete"))
			self.Menu:GetItemById ("Permissions")      :SetEnabled (true)
		end
	)
	
	self.Menu:AddItem ("Browse",
		function (groupTreeNode)
			if not groupTreeNode then return end
			GAuth.GroupBrowser ():GetFrame ():SetGroupTree (groupTreeNode)
			GAuth.GroupBrowser ():GetFrame ():SetVisible (true)
			GAuth.GroupBrowser ():GetFrame ():MoveToFront ()
			GAuth.GroupBrowser ():GetFrame ():Focus ()
		end
	):SetIcon ("icon16/group_go.png")
	self.Menu:AddSeparator ()
	self.Menu:AddItem ("Create Group",
		function (groupTreeNode)
			if not groupTreeNode then return end
			if not groupTreeNode:IsGroupTree () then return end
			Derma_StringRequest ("Create Group", "Enter the name of the new group:", "",
				function (name)
					groupTreeNode:AddGroup (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("icon16/group_add.png")
	self.Menu:AddItem ("Create Group Tree",
		function (groupTreeNode)
			if not groupTreeNode then return end
			if not groupTreeNode:IsGroupTree () then return end
			Derma_StringRequest ("Create Group Tree", "Enter the name of the new group tree:", "",
				function (name)
					groupTreeNode:AddGroupTree (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("icon16/folder_add.png")
	self.Menu:AddItem ("Delete",
		function (groupTreeNode)
			if not groupTreeNode then return end
			groupTreeNode:Remove (GAuth.GetLocalId ())
		end
	):SetIcon ("icon16/cross.png")
	self.Menu:AddSeparator ()
	self.Menu:AddItem ("Permissions",
		function (groupTreeNode)
			if not groupTreeNode then return end
			GAuth.OpenPermissions (groupTreeNode:GetPermissionBlock ())
		end
	):SetIcon ("icon16/key.png")
end

function self:GetSelectedGroup ()
	local item = self:GetSelectedItem ()
	if not item then return end
	if item.IsGroupTree then return end
	return item.Item
end

function self:GetSelectedGroupTreeNode ()
	local item = self:GetSelectedItem ()
	if not item then return end
	return item.Item
end

function self:IsPopulated ()
	return true
end

function self.ItemComparator (a, b)
	-- Put group trees at the top
	if a == b then return false end
	if a.Item:IsGroupTree () and not b.Item:IsGroupTree () then return true end
	if b.Item:IsGroupTree () and not a.Item:IsGroupTree () then return false end
	return a:GetText ():lower () < b:GetText ():lower ()
end

function self:Populate (groupTreeNode, treeViewNode)
	for name, groupNode in groupTreeNode:GetChildEnumerator () do
		local childNode = treeViewNode:AddNode (name)
		childNode:SetExpandable (groupNode:IsGroupTree ())
		childNode:SetText (groupNode:GetDisplayName ())
		childNode:SetIcon (groupNode:GetIcon ())
		childNode.Item = groupNode
		childNode.IsGroupTree = groupNode:IsGroupTree ()
	end
	if treeViewNode:GetChildCount () == 0 then
		treeViewNode:SetExpandable (false)
	else
		treeViewNode:SortChildren (self.ItemComparator)
	end
	
	self.SubscribedNodes [#self.SubscribedNodes + 1] = groupTreeNode
	groupTreeNode:AddEventListener ("NodeAdded", self:GetHashCode (),
		function (_, newNode)
			local childNode = treeViewNode:AddNode (newNode:GetName ())
			childNode:SetExpandable (newNode:IsGroupTree ())
			childNode:SetText (newNode:GetDisplayName ())
			childNode:SetIcon (newNode:GetIcon ())
			childNode.Item = newNode
			childNode.IsGroupTree = newNode:IsGroupTree ()
			treeViewNode:SortChildren (self.ItemComparator)
		end
	)
	
	groupTreeNode:AddEventListener ("NodeDisplayNameChanged", self:GetHashCode (),
		function (_, childNode, displayName)
			local node = treeViewNode:FindChild (childNode:GetName ())
			if not node then return end
			node:SetText (displayName)
			treeViewNode:SortChildren (self.ItemComparator)
		end
	)
	
	groupTreeNode:AddEventListener ("NodeRemoved", self:GetHashCode (),
		function (_, deletedNode)
			local childNode = treeViewNode:FindChild (deletedNode:GetName ())
			deletedNode:RemoveEventListener ("NodeAdded",   self:GetHashCode ())
			deletedNode:RemoveEventListener ("NodeRemoved", self:GetHashCode ())
			treeViewNode:RemoveNode (childNode)
		end
	)
end

--[[
	GroupTreeView:Select ()
	
		Don't call this, it's used to simulate a GTreeViewNode
]]
function self:Select ()
end

function self:SelectGroup (group)
	local groupId = group:GetFullName ()
	local parts = groupId:Split ("/")
	local currentNode = self
	for _, part in ipairs (parts) do
		if not currentNode:IsPopulated () then
			currentNode:Populate ()
		end
		local childNode = currentNode:FindChild (part)
		if not childNode then break end
		currentNode = childNode
	end
	currentNode:Select ()
	currentNode:ExpandTo (true)
end

-- Event handlers
function self:OnRemoved ()
	for _, groupTreeNode in ipairs (self.SubscribedNodes) do
		groupTreeNode:RemoveEventListener ("NodeAdded",              self:GetHashCode ())
		groupTreeNode:RemoveEventListener ("NodeDisplayNameChanged", self:GetHashCode ())
		groupTreeNode:RemoveEventListener ("NodeRemoved",            self:GetHashCode ())
	end
end

-- Events
function self:ItemSelected (item)
	self:DispatchEvent ("SelectedGroupChanged", self:GetSelectedGroup ())
	self:DispatchEvent ("SelectedGroupTreeNodeChanged", item and item.Item or nil)
end

vgui.Register ("GAuthGroupTreeView", self, "GTreeView")