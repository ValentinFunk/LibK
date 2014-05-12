local self = {}

function self:Init ()
	self:SetTitle ("Permissions - ")

	self:SetSize (ScrW () * 0.3, ScrH () * 0.6)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:MakePopup ()
	
	self.PermissionBlock = nil
	self.TestPermissionBlock = nil
	self.SelectedGroup = nil
	self.SelectedGroupId = nil
	self.SelectedPermissionBlock = nil
	
	self.HookedOwnerBlocks = {}
	self.HookedPermissionBlocks = {}
	self.PermissionBlockHeaders = {}
	self.AddGroupEntryButton = nil
	
	self.Owner = vgui.Create ("DLabel", self)
	self.Owner:SetText ("Owner: ")
	self.OwnerIcon = vgui.Create ("GImage", self)
	self.OwnerName = vgui.Create ("DLabel", self)
	self.OwnerName:SetText ("Unknown")
	
	self.ChangeOwner = vgui.Create ("GButton", self)
	self.ChangeOwner:SetText ("Change")
	self.ChangeOwner:AddEventListener ("Click",
		function (_)
			local permissionBlock = self.PermissionBlock
			local testPermissionBlock = self.TestPermissionBlock
			local dialog = GAuth.OpenUserSelectionDialog (
				function (userId)
					if not userId then return end
					
					local ownerName = userId
					local ownerEntity = GAuth.PlayerMonitor:GetUserEntity (ownerName)
					if ownerEntity then ownerName = ownerEntity:Name () .. " (" .. userId .. ")" end
					
					self:Confirm ("Are you sure you want to change the owner to " .. ownerName .. "?", "Confirm owner change",
						function (permissionBlock) permissionBlock:SetOwner (GAuth.GetLocalId (), userId) end,
						GAuth.NullCallback,
						permissionBlock,
						testPermissionBlock
					)
				end
			)
			dialog:SetTitle ("Change owner...")
			dialog:SetSelectionMode (Gooey.SelectionMode.One)
		end
	)
	
	self.InheritOwner = vgui.Create ("GCheckbox", self)
	self.InheritOwner:SetText ("Inherit owner from parent")
	self.InheritPermissions = vgui.Create ("GCheckbox", self)
	self.InheritPermissions:SetText ("Inherit permissions from parent")
	
	self.InheritOwner:AddEventListener ("CheckStateChanged",
		function (_, checked)
			self:Confirm ("Are you sure you want to " .. (checked and "enable" or "disable") .. " owner inheritance?", "Confirm owner inheritance change",
				function (permissionBlock) permissionBlock:SetInheritOwner (GAuth.GetLocalId (), checked) end,
				function () self.InheritOwner:SetChecked (not checked) end
			)
		end
	)
	
	self.InheritPermissions:AddEventListener ("CheckStateChanged",
		function (_, checked)
			self:Confirm ("Are you sure you want to " .. (checked and "enable" or "disable") .. " permission inheritance?", "Confirm permission inheritance change",
				function (permissionBlock) permissionBlock:SetInheritPermissions (GAuth.GetLocalId (), checked) end,
				function () self.InheritPermissions:SetChecked (not checked) end
			)
		end
	)
	
	self.Groups = vgui.Create ("GListBox", self)
	self.Groups:SetSelectionMode (Gooey.SelectionMode.One)
	self.Groups:SetComparator (
		function (a, b)
			-- Sorted by permission block hierarchy,
			-- permission block headers go first
			if a == b then return false end
			if a.PermissionBlockIndex > b.PermissionBlockIndex then return true end
			if a.PermissionBlockIndex < b.PermissionBlockIndex then return false end
			if a.IsPermissionBlock then return true end
			if b.IsPermissionBlock then return false end
			if a.IsGroupAdder then return false end
			if b.IsGroupAdder then return true end
			return a:GetText ():lower () < b:GetText ():lower ()
		end
	)
	
	self.Groups.Menu = Gooey.Menu ()
	self.Groups.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			self.Groups.Menu:GetItemById ("Add"):SetEnabled (self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions"))
			if not targetItem or not targetItem.GroupId then
				self.Groups.Menu:GetItemById ("Remove"):SetEnabled (false)
				return
			end
			self.Groups.Menu:SetTargetItem (targetItem.GroupId)
			local targetGroupId = targetItem.GroupId
			if targetItem.PermissionBlock ~= self.PermissionBlock then
				self.Groups.Menu:GetItemById ("Remove"):SetEnabled (false)
			else
				self.Groups.Menu:GetItemById ("Remove"):SetEnabled (self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions"))
			end
		end
	)
	self.Groups.Menu:AddItem ("Add",
		function ()
			local permissionBlock = self.PermissionBlock
			GAuth.OpenGroupSelectionDialog (
				function (group)
					if not group then return end
					permissionBlock:AddGroupEntry (GAuth.GetLocalId (), group:GetFullName ())
				end
			):SetTitle ("Add group...")
		end
	):SetIcon ("icon16/group_add.png")
	self.Groups.Menu:AddItem ("Remove",
		function (targetGroupId)
			if not targetGroupId then return end
			local groupTreeNode = GAuth.ResolveGroupTreeNode (targetGroupId)
			local groupDisplayName = groupTreeNode and groupTreeNode:GetFullDisplayName () or targetGroupId
			self:Confirm ("Are you sure you want to remove " .. groupDisplayName .. "'s permissions?", "Confirm group entry removal",
				function (permissionBlock) permissionBlock:RemoveGroupEntry (GAuth.GetLocalId (), targetGroupId) end
			)
		end
	):SetIcon ("icon16/group_delete.png")
	
	self.Groups:AddEventListener ("Click", self:GetHashCode (),
		function (_, item)
			if not item then return end
			if item.IsGroupAdder then
				local permissionBlock = self.PermissionBlock
				GAuth.OpenGroupSelectionDialog (
					function (group)
						if not group then return end
						permissionBlock:AddGroupEntry (GAuth.GetLocalId (), group:GetFullName ())
					end
				):SetTitle ("Add group...")
			end
		end
	)
	
	self.Groups:AddEventListener ("SelectionChanged",
		function (_, item)
			self.SelectedGroup = item and item.Group or nil
			self.SelectedGroupId = item and item.GroupId
			self.SelectedPermissionBlock = item and item.PermissionBlock
			self:CheckPermissions ()
			self:PopulatePermissions ()
		end
	)
	
	self.PermissionList = vgui.Create ("GListView", self)
	self.PermissionList:AddColumn ("Name")
	self.PermissionList:AddColumn ("Allow")
		:SetWidth (64)
		:SetType (Gooey.ListView.ColumnType.Checkbox)
	self.PermissionList:AddColumn ("Deny")
		:SetWidth (64)
		:SetType (Gooey.ListView.ColumnType.Checkbox)
	
	self.PermissionList:AddEventListener ("ItemChecked", function (_, item, columnId, checked)
		if not self.SelectedGroupId then return end
		if self.SelectedPermissionBlock ~= self.PermissionBlock then return end
		self.PermissionList:SuppressEvents (true)
		
		local newAccess = nil
		if checked then
			if columnId == "Allow" then
				item:SetCheckState ("Deny", false)
				newAccess = GAuth.Access.Allow
			elseif columnId == "Deny" then
				item:SetCheckState ("Allow", false)
				newAccess = GAuth.Access.Deny
			end
		else
			newAccess = GAuth.Access.None
		end
		
		local selectedGroupId = self.SelectedGroupId
		if newAccess then
			self:Confirm ("Are you sure?", "Confirm group permission change",
				function (permissionBlock) permissionBlock:SetGroupPermission (GAuth.GetLocalId (), selectedGroupId, item.ActionId, newAccess) end,
				function ()
					if not item:IsValid () then return end
					self.PermissionList:SuppressEvents (true)
					if columnId == "Allow" then
						item:SetCheckState ("Allow", not checked)
						item:SetCheckState ("Deny", checked)
					elseif columnId == "Deny" then
						item:SetCheckState ("Allow", checked)
						item:SetCheckState ("Deny", not checked)
					end
					self.PermissionList:SuppressEvents (false)
				end
			)
		end
		self.PermissionList:SuppressEvents (false)
	end)
	
	self.SplitContainer = vgui.Create ("GSplitContainer", self)
	self.SplitContainer:SetPanel1 (self.Groups)
	self.SplitContainer:SetPanel2 (self.PermissionList)
	self.SplitContainer:SetSplitterFraction (0.5)
	self.SplitContainer:SetSplitterThickness (7)
	self.SplitContainer:SetOrientation (Gooey.Orientation.Horizontal)
	
	self:PerformLayout ()
	
	GAuth:AddEventListener ("Unloaded", self:GetHashCode (), function ()
		self:Remove ()
	end)
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.PermissionList then
		local y = 30
		
		self.InheritOwner:SetPos (8, y)
		self.InheritOwner:SetSize (self:GetWide () - 16, 15)
		y = y + self.InheritOwner:GetTall () + 8
		
		self.InheritPermissions:SetPos (8, y)
		self.InheritPermissions:SetSize (self:GetWide () - 16, 15)
		y = y + self.InheritPermissions:GetTall () + 8
		
		self.ChangeOwner:SetSize (80, 24)
		self.ChangeOwner:SetPos (self:GetWide () - 8 - self.ChangeOwner:GetWide (), y)
		
		self.Owner:SizeToContents ()
		self.Owner:SetPos (8, y + (self.ChangeOwner:GetTall () - self.Owner:GetTall ()) * 0.5)
		self.OwnerIcon:SetSize (16, 16)
		self.OwnerIcon:SetPos (8 + self.Owner:GetWide (), y + (self.ChangeOwner:GetTall () - self.OwnerIcon:GetTall ()) * 0.5)
		self.OwnerName:SizeToContents ()
		self.OwnerName:SetPos (8 + self.Owner:GetWide () + self.OwnerIcon:GetWide () + 2, y + (self.ChangeOwner:GetTall () - self.OwnerName:GetTall ()) * 0.5)
		y = y + self.ChangeOwner:GetTall () + 8
		
		self.SplitContainer:SetPos (8, y)
		self.SplitContainer:SetSize (self:GetWide () - 16, self:GetTall () - y - 8)
	end
end

function self:Confirm (query, title, yesCallback, noCallback, permissionBlock, testPermissionBlock)
	noCallback = noCallback or GAuth.NullCallback

	permissionBlock = permissionBlock or self.PermissionBlock
	testPermissionBlock = testPermissionBlock or self.TestPermissionBlock
	local testAccess = testPermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions")
	yesCallback (testPermissionBlock)
	local newAccess = testPermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions")
	if newAccess or testAccess == newAccess then
		yesCallback (permissionBlock)
	else
		Derma_Query ("This will lock you out of this permission block.\n\n" .. query, title,
			"Yes", function () yesCallback (permissionBlock) end,
			"No", function () testPermissionBlock:CopyFrom (permissionBlock) noCallback () end
		)
	end
end

function self:SetPermissionBlock (permissionBlock)
	if self.PermissionBlock then return end

	self.PermissionBlock = permissionBlock
	self.TestPermissionBlock = GAuth.PermissionBlock ()
	self.TestPermissionBlock:CopyFrom (self.PermissionBlock)
	self.TestAccess = self.TestPermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions")
	self:SetTitle ("Permissions - " .. permissionBlock:GetDisplayName ())
	
	self:UpdateInheritOwner ()
	self:UpdateInheritPermissions ()
	
	self:UpdateOwner ()
	
	-- Populate group entries
	self.Groups:Clear ()
	self.PermissionBlockHeaders = {}
	self:PopulateGroupEntries (self.PermissionBlock, 1)
	self:AddPermissionBlockHeader (self.PermissionBlock, 1)
	self:AddGroupEntryAdder (self.PermissionBlock, 1)
	self.Groups:Sort ()
	
	self:CheckPermissions ()
	
	-- Populate permissions
	self.PermissionList:Clear ()
	if self.PermissionBlock:GetPermissionDictionary () then
		for actionId in self.PermissionBlock:GetPermissionDictionary ():GetPermissionEnumerator () do
			local listViewItem = self.PermissionList:AddItem (actionId)
			listViewItem.ActionId = actionId
		end
		self.PermissionList:Sort ()
	end
	
	-- Events
	self:HookBlock (self.PermissionBlock, 1)
end

-- Internal, do not call
function self:AddGroup (groupId, permissionBlock, permissionBlockIndex)
	if not self.PermissionBlockHeaders [permissionBlockIndex] then
		self:AddPermissionBlockHeader (permissionBlock, permissionBlockIndex)
	end

	local group = GAuth.ResolveGroup (groupId)
	local item = self.Groups:AddItem (group and group:GetFullDisplayName () or groupId)
	item:SetIcon (group and group:GetIcon () or "icon16/group.png")
	item:SetIndent (16)
	item.Group = group
	item.GroupId = groupId
	item.PermissionBlock = permissionBlock
	item.PermissionBlockIndex = permissionBlockIndex
	item.IsPermissionBlock = false
	item.IsGroup = true
	item.IsGroupAdder = false
end

function self:AddPermissionBlockHeader (permissionBlock, permissionBlockIndex)
	if self.PermissionBlockHeaders [permissionBlockIndex] then return end

	local item = self.Groups:AddItem (permissionBlock:GetDisplayName ())
	if item:GetText () == "" then item:SetText ("[root]") end
	item:SetIcon ("icon16/key.png")
	item:SetCanSelect (false)
	item.PermissionBlock = permissionBlock
	item.PermissionBlockIndex = permissionBlockIndex
	item.IsPermissionBlock = true
	item.IsGroup = false
	item.IsGroupAdder = false
	
	self.PermissionBlockHeaders [permissionBlockIndex] = item
end

function self:AddGroupEntryAdder (permissionBlock, permissionBlockIndex)
	if self.AddGroupEntryButton then return end

	local item = self.Groups:AddItem ("Click here to add a group entry...")
	item:SetIcon ("icon16/group_add.png")
	item:SetIndent (16)
	item:SetCanSelect (false)
	item.PermissionBlock = permissionBlock
	item.PermissionBlockIndex = permissionBlockIndex
	item.IsPermissionBlock = false
	item.IsGroup = false
	item.IsGroupAdder = true
	
	self.AddGroupEntryButton = item
end

function self:CheckPermissions ()
	self.InheritOwner      :SetEnabled (self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Set Owner"))
	self.InheritPermissions:SetEnabled (self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions"))
	self.ChangeOwner       :SetEnabled (self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Set Owner"))
	
	if not self.SelectedGroupId or self.SelectedPermissionBlock ~= self.PermissionBlock then
		self.PermissionList:SetEnabled (false)
	else
		self.PermissionList:SetEnabled (self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions"))
	end
	
	if self.PermissionBlock:IsAuthorized (GAuth.GetLocalId (), "Modify Permissions") then
		self:AddGroupEntryAdder (self.PermissionBlock, 1)
	else
		if self.AddGroupEntryButton then
			self.Groups:RemoveItem (self.AddGroupEntryButton)
			self.AddGroupEntryButton = nil
		end
	end
end

function self:HookBlock (permissionBlock, permissionBlockIndex)
	if not permissionBlock then return end
	
	self:HookBlockOwner (permissionBlock, permissionBlockIndex)
	self:HookBlockPermissions (permissionBlock, permissionBlockIndex)
end

function self:HookBlockOwner (permissionBlock, permissionBlockIndex)
	if not permissionBlock then return end
	
	self.HookedOwnerBlocks [permissionBlockIndex] = permissionBlock
	if permissionBlock:InheritsOwner () then
		self:HookBlockOwner (permissionBlock:GetParent (), permissionBlockIndex + 1)
	end
	
	permissionBlock:AddEventListener ("InheritOwnerChanged", self:GetHashCode (),
		function (permissionBlock, inheritOwner)
			if permissionBlock == self.PermissionBlock then
				self.TestPermissionBlock:SetInheritOwner (GAuth.GetSystemId (), inheritOwner)
				self:UpdateInheritOwner ()
			end
			
			if inheritOwner then
				self:HookBlockOwner (permissionBlock:GetParent (), permissionBlockIndex + 1)
			else
				for i = #self.HookedOwnerBlocks, permissionBlockIndex + 1, -1 do
					self:UnhookBlockOwner (self.HookedOwnerBlocks [i])
					self.HookedOwnerBlocks [i] = nil
				end
			end
			
			self:CheckPermissions ()
			self:UpdateOwner ()
		end
	)
	
	permissionBlock:AddEventListener ("OwnerChanged", self:GetHashCode (),
		function (permissionBlock, ownerId)
			if permissionBlock == self.PermissionBlock then
				self.TestPermissionBlock:SetOwner (GAuth.GetSystemId (), ownerId)
				self:UpdateOwner ()
			end
		
			self:CheckPermissions ()
		end
	)
end

function self:HookBlockPermissions (permissionBlock, permissionBlockIndex)
	if not permissionBlock then return end
	
	self.HookedPermissionBlocks [permissionBlockIndex] = permissionBlock
	if permissionBlock:InheritsPermissions () then
		self:HookBlockPermissions (permissionBlock:GetParent (), permissionBlockIndex + 1)
	end
	
	permissionBlock:AddEventListener ("GroupEntryAdded", self:GetHashCode (),
		function (permissionBlock, groupId)
			if permissionBlock == self.PermissionBlock then
				self.TestPermissionBlock:AddGroupEntry (GAuth.GetSystemId (), groupId)
			end
			
			self:AddGroup (groupId, permissionBlock, permissionBlockIndex)
			self.Groups:Sort ()
		end
	)
	
	permissionBlock:AddEventListener ("GroupEntryRemoved", self:GetHashCode (),
		function (permissionBlock, groupId)
			if permissionBlock == self.PermissionBlock then
				self.TestPermissionBlock:RemoveGroupEntry (GAuth.GetSystemId (), groupId)
			end
			
			local groupEntryCount = 0
			for _, item in pairs (self.Groups:GetItems ()) do
				if item.PermissionBlockIndex == permissionBlockIndex then
					if item.GroupId == groupId then
						self.Groups:RemoveItem (item)
					elseif item.IsGroup then
						groupEntryCount = groupEntryCount + 1
					end
				end
			end
			if groupEntryCount == 0 and permissionBlockIndex > 1 then
				-- Remove permission block header
				self.Groups:RemoveItem (self.PermissionBlockHeaders [permissionBlockIndex])
				self.PermissionBlockHeaders [permissionBlockIndex] = nil
			end
			
			self:CheckPermissions ()
			self:PopulatePermissions ()
		end
	)
	
	permissionBlock:AddEventListener ("GroupPermissionChanged", self:GetHashCode (),
		function (permissionBlock, groupId, actionId, access)
			if permissionBlock == self.PermissionBlock then
				self.TestPermissionBlock:SetGroupPermission (GAuth.GetSystemId (), groupId, actionId, access)
			end
			
			self:CheckPermissions ()
			if self.SelectedGroupId == groupId then
				self:PopulatePermissions ()
			end
		end
	)
	
	permissionBlock:AddEventListener ("InheritPermissionsChanged", self:GetHashCode (),
		function (permissionBlock, inheritPermissions)
			if permissionBlock == self.PermissionBlock then
				self.TestPermissionBlock:SetInheritPermissions (GAuth.GetSystemId (), inheritPermissions)
				self:UpdateInheritPermissions ()
			end
			
			if inheritPermissions then
				-- Hook parent permission blocks
				-- Add parent group entries
				self:HookBlockPermissions (permissionBlock:GetParent (), permissionBlockIndex + 1)
				self:PopulateGroupEntries (permissionBlock:GetParent (), permissionBlockIndex + 1)
				self.Groups:Sort ()
			else
				-- Unhook parent permission blocks
				for i = #self.HookedPermissionBlocks, permissionBlockIndex + 1, -1 do
					self:UnhookBlockPermissions (self.HookedPermissionBlocks [i])
					self.HookedPermissionBlocks [i] = nil
				end
				
				-- Remove parent group entries
				for _, item in pairs (self.Groups:GetItems ()) do
					if item.PermissionBlockIndex > permissionBlockIndex then
						-- Unregister permission block header
						if item.IsPermissionBlock then
							self.PermissionBlockHeaders [item.PermissionBlockIndex] = nil
						end
						self.Groups:RemoveItem (item)
					end
				end
			end
			
			self:CheckPermissions ()
			self:PopulatePermissions ()
		end
	)
end

function self:UnhookBlock (permissionBlock)
	if not permissionBlock then return end
	
	self:UnhookBlockOwner (permissionBlock)
	self:UnhookBlockPermissions (permissionBlock)
end

function self:UnhookBlockOwner (permissionBlock)
	if not permissionBlock then return end

	permissionBlock:RemoveEventListener ("InheritOwnerChanged",       self:GetHashCode ())
	permissionBlock:RemoveEventListener ("OwnerChanged",              self:GetHashCode ())
end

function self:UnhookBlockPermissions (permissionBlock)
	if not permissionBlock then return end

	permissionBlock:RemoveEventListener ("GroupEntryAdded",           self:GetHashCode ())
	permissionBlock:RemoveEventListener ("GroupEntryRemoved",         self:GetHashCode ())
	permissionBlock:RemoveEventListener ("GroupPermissionChanged",    self:GetHashCode ())
	permissionBlock:RemoveEventListener ("InheritPermissionsChanged", self:GetHashCode ())
end

function self:PopulateGroupEntries (permissionBlock, permissionBlockIndex)
	if not permissionBlock then return end
	
	for groupId in permissionBlock:GetGroupEntryEnumerator () do
		self:AddGroup (groupId, permissionBlock, permissionBlockIndex)
	end
	if permissionBlock:InheritsPermissions () then
		self:PopulateGroupEntries (permissionBlock:GetParent (), permissionBlockIndex + 1)
	end
end

function self:PopulatePermissions ()
	self.PermissionList:SuppressEvents (true)
	for permissionItem in self.PermissionList:GetItemEnumerator () do
		if self.SelectedGroupId then
			local access = self.SelectedPermissionBlock:GetGroupPermission (self.SelectedGroupId, permissionItem.ActionId)
			if access == GAuth.Access.Allow then
				permissionItem:SetCheckState ("Allow", true)
				permissionItem:SetCheckState ("Deny", false)
			elseif access == GAuth.Access.Deny then
				permissionItem:SetCheckState ("Allow", false)
				permissionItem:SetCheckState ("Deny", true)
			else
				permissionItem:SetCheckState ("Allow", false)
				permissionItem:SetCheckState ("Deny", false)
			end
		else
			-- group deselected
			permissionItem:SetCheckState ("Allow", false)
			permissionItem:SetCheckState ("Deny", false)
		end
	end
	self.PermissionList:SuppressEvents (false)
end

function self:UpdateInheritOwner ()
	self.InheritOwner:SuppressEvents (true)
	self.InheritOwner:SetValue (self.PermissionBlock:InheritsOwner ())
	self.InheritOwner:SuppressEvents (false)
end

function self:UpdateInheritPermissions ()
	self.InheritPermissions:SuppressEvents (true)
	self.InheritPermissions:SetValue (self.PermissionBlock:InheritsPermissions ())
	self.InheritPermissions:SuppressEvents (false)
end

function self:UpdateOwner ()
	local ownerId = self.PermissionBlock:GetOwner ()
	local ownerName = GAuth.PlayerMonitor:GetUserName (ownerId)
	self.OwnerIcon:SetImage (GAuth.GetUserIcon (ownerId))
	if ownerName ~= ownerId then
		self.OwnerName:SetText (ownerName .. " (" .. ownerId .. ")")
	else
		self.OwnerName:SetText (ownerName)
	end
	self.OwnerName:SizeToContents ()
end

-- Event handlers
function self:OnRemoved ()
	for i = 1, #self.HookedOwnerBlocks do
		self:UnhookBlockOwner (self.HookedOwnerBlocks [i])
	end
	for i = 1, #self.HookedPermissionBlocks do
		self:UnhookBlockPermissions (self.HookedPermissionBlocks [i])
	end

	GAuth:RemoveEventListener ("Unloaded", self:GetHashCode ())
end

vgui.Register ("GAuthPermissions", self, "GFrame")

function GAuth.OpenPermissions (permissionBlock)
	local dialog = vgui.Create ("GAuthPermissions")
	dialog:SetPermissionBlock (permissionBlock)
	dialog:SetVisible (true)
	
	return dialog
end