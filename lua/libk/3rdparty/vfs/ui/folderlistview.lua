local self = {}

--[[
	Events:
		FolderChanged (IFolder folder)
			Fired when the selected folder has changed.
		NodeOpened (INode node)
			Fired when a file or folder is double clicked.
		SelectedFileChanged (IFile file)
			Fired when a file is selected from the list.
		SelectedFolderChanged (IFolder folder)
			Fired when a folder is selected from the list.
		SelectedNodeChanged (INode node)
			Fired when a file or folder is selected from the list.
]]

function self:Init ()
	self.Folder = nil
	self.ChildNodes = {}
	self.HookedNodes = {} -- IFolders whose PermissionsChanged event have been hooked
	self.LastAccess = false
	self.LastReadAccess = false
	
	self.ShowParentFolder = false
	self.ParentFolderItem = nil
	
	self:AddColumn ("Name")
		:SetComparator (
			function (a, b)
				return self.DefaultComparator (a, b)
			end
		)
	self:AddColumn ("Size")
		:SetAlignment (6)
		:SetWidth (80)
		:SetComparator (
			function (a, b)
				-- Put folders at the top
				if a == b then return false end
				if a.Node:IsFolder () and not b.Node:IsFolder () then return true end
				if b.Node:IsFolder () and not a.Node:IsFolder () then return false end
				return a.Size < b.Size
			end
		)
	self:AddColumn ("Last Modified")
		:SetWidth (192)
		:SetComparator (
			function (a, b)
				-- Put folders at the top
				if a == b then return false end
				if a.Node:IsFolder () and not b.Node:IsFolder () then return true end
				if b.Node:IsFolder () and not a.Node:IsFolder () then return false end
				return a.LastModified < b.LastModified
			end
		)

	self.Menu = Gooey.Menu ()
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			local targetItem = self:GetSelectedNodes ()
			self.Menu:SetTargetItem (targetItem)
			self.Menu:GetItemById ("Permissions"):SetEnabled (#targetItem ~= 0)
			
			if self.Folder and self.Folder:IsFolder () then
				local permissionBlock = self.Folder:GetPermissionBlock ()
				if not permissionBlock then
					self.Menu:GetItemById ("Copy")         :SetEnabled (#targetItem ~= 0)
					self.Menu:GetItemById ("Paste")        :SetEnabled (true)
					self.Menu:GetItemById ("Create Folder"):SetEnabled (true)
					self.Menu:GetItemById ("Delete")       :SetEnabled (#targetItem ~= 0 and targetItem [1]:CanDelete ())
					self.Menu:GetItemById ("Rename")       :SetEnabled (#targetItem ~= 0)
				else
					self.Menu:GetItemById ("Copy")         :SetEnabled (#targetItem ~= 0 and (permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Read") or permissionBlock:IsAuthorized (GAuth.GetLocalId (), "View Folder")))
					self.Menu:GetItemById ("Paste")        :SetEnabled (VFS.Clipboard:CanPaste (self.Folder))
					self.Menu:GetItemById ("Create Folder"):SetEnabled (not permissionBlock or permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Folder"))
					self.Menu:GetItemById ("Delete")       :SetEnabled (#targetItem ~= 0 and targetItem [1]:CanDelete () and (not targetItem [1]:GetPermissionBlock () or targetItem [1]:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Delete")))
					self.Menu:GetItemById ("Rename")       :SetEnabled (#targetItem ~= 0 and (not targetItem [1]:GetPermissionBlock () or targetItem [1]:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Rename")))
				end
			else
				self.Menu:GetItemById ("Copy")         :SetEnabled (false)
				self.Menu:GetItemById ("Paste")        :SetEnabled (false)
				self.Menu:GetItemById ("Create Folder"):SetEnabled (false)
				self.Menu:GetItemById ("Delete")       :SetEnabled (false)
				self.Menu:GetItemById ("Rename")       :SetEnabled (false)
			end
		end
	)
	self.Menu:AddItem ("Copy",
		function (targetNodes)
			if #targetNodes == 0 then return end
			VFS.Clipboard:Clear ()
			for _, node in ipairs (targetNodes) do
				VFS.Clipboard:Add (node)
			end
		end
	):SetIcon ("icon16/page_white_copy.png")
	self.Menu:AddItem ("Paste",
		function ()
			VFS.Clipboard:Paste (self.Folder)
		end
	):SetIcon ("icon16/paste_plain.png")
	self.Menu:AddSeparator ()
	self.Menu:AddItem ("Create Folder",
		function ()
			if not self.Folder then return end
			local folder = self.Folder
			Derma_StringRequest ("Create folder...", "Enter the name of the new folder:", "", function (name)
				folder:CreateFolder (GAuth.GetLocalId (), name)
			end)
		end
	):SetIcon ("icon16/folder_add.png")
	self.Menu:AddItem ("Delete",
		function (targetNodes)
			if not self.Folder then return end
			if not targetNodes then return end
			if #targetNodes == 0 then return end
			local names = ""
			for i = 1, 3 do
				if i > 1 then
					if i == #targetNodes then names = names .. " and "
					else names = names .. ", " end
				end
				names = names .. targetNodes [i]:GetDisplayName ()
				if i == #targetNodes then break end
			end
			if #targetNodes > 3 then names = names .. " and " .. (#targetNodes - 3) .. " more item" .. ((#targetNodes - 3) > 1 and "s" or "") end
			Derma_Query ("Are you sure you want to delete " .. names .. "?", "Confirm deletion",
				"Yes",
					function ()					
						for _, node in ipairs (targetNodes) do
							node:Delete (GAuth.GetLocalId ())
						end
					end,
				"No", VFS.NullCallback
			)
		end
	):SetIcon ("icon16/cross.png")
	self.Menu:AddItem ("Rename",
		function (targetNodes)
			if not targetNodes then return end
			if #targetNodes == 0 then return end
			Derma_StringRequest ("Rename " .. targetNodes [1]:GetName () .. "...", "Enter " .. targetNodes [1]:GetName () .. "'s new name:", targetNodes [1]:GetName (),
				function (name)
					name = VFS.SanitizeNodeName (name)
					if not name then return end
					targetNodes [1]:Rename (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("icon16/pencil.png")
	self.Menu:AddSeparator ()
	self.Menu:AddItem ("Permissions",
		function (targetNodes)
			if not self.Folder then return end
			if not targetNodes then return end
			if #targetNodes == 0 then return end
			GAuth.OpenPermissions (targetNodes [1]:GetPermissionBlock ())
		end
	):SetIcon ("icon16/key.png")
	
	self:AddEventListener ("DoubleClick",
		function (_, item)
			if not item then return end
			if not item.Node then return end
			self:DispatchEvent ("NodeOpened", item.Node)
		end
	)
	
	self:AddEventListener ("SelectionChanged",
		function (_, item)
			local node = item and item.Node or nil
			self:DispatchEvent ("SelectedNodeChanged", node)
			self:DispatchEvent ("SelectedFileChanged", node and node:IsFile () and node or nil)
			self:DispatchEvent ("SelectedFolderChanged", node and node:IsFolder () and node or nil)
		end
	)
	
	self.PermissionsChanged = function (_)
		local access = self.Folder:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder")
		local readAccess = self.Folder:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Read")
		if self.LastAccess ~= access then
			self.LastAccess = access
			if self.LastAccess then
				self:MergeRefresh ()
			else
				self:Clear ()
				self.ChildNodes = {}
			end
		end
		if self.LastReadAccess ~= readAccess then
			self.LastReadAccess = readAccess
			for _, listViewItem in pairs (self.ChildNodes) do
				if listViewItem.IsFile then
					self:UpdateIcon (listViewItem)
				end
			end
		end
	end
end

function self.DefaultComparator (a, b)
	-- Put folders at the top
	if a == b then return false end
	if a.ParentFolder then return true  end
	if b.ParentFolder then return false end
	if a.Node:IsFolder () and not b.Node:IsFolder () then return true  end
	if b.Node:IsFolder () and not a.Node:IsFolder () then return false end
	if     a.Node.PlayerFolder and not b.Node.PlayerFolder then return false end
	if not a.Node.PlayerFolder and     b.Node.PlayerFolder then return true  end
	return string.lower (a:GetText ()) < string.lower (b:GetText ())
end

function self:GetFolder ()
	return self.Folder
end

function self:GetPath ()
	if not self.Folder then return nil end
	return self.Folder:GetPath ()
end

function self:GetSelectedFile ()
	local node = self:GetSelectedNode ()
	return node:IsFile () and node or nil
end

function self:GetSelectedFolder ()
	local node = self:GetSelectedNode ()
	return node:IsFolder () and node or nil
end

function self:GetSelectedNode ()
	local item = self.SelectionController:GetSelectedItem ()
	return item and item.Node or nil
end

function self:GetSelectedNodes ()
	local selectedNodes = {}
	for _, item in ipairs (self.SelectionController:GetSelectedItems ()) do
		selectedNodes [#selectedNodes + 1] = item.Node
	end
	return selectedNodes
end

function self:MergeRefresh ()
	if not self.Folder then return end

	local folder = self.Folder
	local lastLayout = SysTime ()
	self.Folder:EnumerateChildren (GAuth.GetLocalId (),
		function (returnCode, node)
			if self.Folder ~= folder then return end
			
			if returnCode == VFS.ReturnCode.Success then
				self:AddNode (node)
				if self:GetItemCount () < 10 or SysTime () - lastLayout > 0.2 then
					self:Sort ()
					lastLayout = SysTime ()
				end
			elseif returnCode == VFS.ReturnCode.EndOfBurst then
				self:Sort ()
			elseif returnCode == VFS.ReturnCode.AccessDenied then
			elseif returnCode == VFS.ReturnCode.Finished then				
				self.Folder:AddEventListener ("NodeCreated", self:GetHashCode (),
					function (_, newNode)
						self:AddNode (newNode)
						self:Sort ()
					end
				)
				
				self.Folder:AddEventListener ("NodeDeleted", self:GetHashCode (),
					function (_, deletedNode)
						self:RemoveItem (self.ChildNodes [deletedNode:GetName ()])
						self.ChildNodes [deletedNode:GetName ()] = nil
					end
				)
				
				self:Sort ()
			end
		end
	)
end

function self:SetFolder (folder)
	if type (folder) == "string" then
		VFS.Error ("FolderListView:SetFolder was called with a string. Did you mean SetPath?")
		self:SetPath (folder)
	end
	if self.Folder == folder then return end

	self:Clear ()
	self.ChildNodes = {}
	if self.Folder then
		self.Folder:RemoveEventListener ("NodeCreated",            self:GetHashCode ())
		self.Folder:RemoveEventListener ("NodeDeleted",            self:GetHashCode ())
		self.Folder:RemoveEventListener ("NodePermissionsChanged", self:GetHashCode ())
		self.Folder:RemoveEventListener ("NodeRenamed",            self:GetHashCode ())
		self.Folder:RemoveEventListener ("NodeUpdated",            self:GetHashCode ())
		
		for i = #self.HookedNodes, 1, -1 do
			self.HookedNodes [i]:RemoveEventListener ("PermissionsChanged", self:GetHashCode ())
			self.HookedNodes [i] = nil
		end
		self.Folder = nil
	end
	if not folder then return end
	if not folder:IsFolder () then return end
	
	local oldFolder = self.Folder
	self.Folder = folder
	self:DispatchEvent ("FolderChanged", oldFolder, self.Folder)
	
	if self.ShowParentFolder and self.Folder:GetParentFolder () then
		self:AddNode (self.Folder:GetParentFolder (), true)
	end
	self:MergeRefresh ()
	
	self.Folder:AddEventListener ("NodePermissionsChanged", self:GetHashCode (),
		function (_, node)
			if not self.ChildNodes [node:GetName ()] then return end
			self:UpdateIcon (self.ChildNodes [node:GetName ()])
		end
	)
				
	self.Folder:AddEventListener ("NodeRenamed", self:GetHashCode (),
		function (_, node, oldName, newName)
			self.ChildNodes [newName] = self.ChildNodes [oldName]
			self.ChildNodes [newName]:SetText (node:GetDisplayName ())
			self.ChildNodes [oldName] = nil
			
			self:Sort ()
		end
	)
	
	self.Folder:AddEventListener ("NodeUpdated", self:GetHashCode (),
		function (_, updatedNode, updateFlags)
			local listViewItem = self.ChildNodes [updatedNode:GetName ()]
			if not listViewItem then return end
			if bit.band (updateFlags, VFS.UpdateFlags.DisplayName) ~= 0 then
				listViewItem:SetText (updatedNode:GetDisplayName ())
				self:Sort ()
			end
			if bit.band (updateFlags, VFS.UpdateFlags.Size) ~= 0 then
				listViewItem.Size = updatedNode:IsFile () and updatedNode:GetSize () or -1
				listViewItem:SetColumnText ("Size", listViewItem.Size ~= -1 and VFS.FormatFileSize (listViewItem.Size) or "")
			end
			if bit.band (updateFlags, VFS.UpdateFlags.ModificationTime) ~= 0 then
				listViewItem.LastModified = updatedNode:GetModificationTime ()
				listViewItem:SetColumnText ("Last Modified", listViewItem.LastModified ~= -1 and VFS.FormatDate (listViewItem.LastModified) or "")
			end
		end
	)

	local parentFolder = self.Folder
	while parentFolder do
		self.HookedNodes [#self.HookedNodes + 1] = parentFolder
		parentFolder:AddEventListener ("PermissionsChanged", self:GetHashCode (), self.PermissionsChanged)
		parentFolder = parentFolder:GetParentFolder ()
	end
	
	self.LastAccess = self.Folder:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder")
end

function self:SetPath (path)
	VFS.Root:GetChild (GAuth.GetLocalId (), path,
		function (returnCode, node)
			if not node then return end
			if node:IsFolder () then
				self:SetFolder (node)
			else
				self:SetFolder (node:GetParentFolder ())
				self:AddNode (node):Select ()
			end
		end
	)
end

function self:SetShowParentFolder (showParentFolder)
	if self.ShowParentFolder == showParentFolder then return end
	
	self.ShowParentFolder = showParentFolder
	
	local folder = self:GetFolder () and self:GetFolder ():GetParentFolder ()
	if not folder then return end
	
	if self.ShowParentFolder then
		self:AddNode (folder, true)
		self:Sort ()
	else
		self.ParentFolderItem:Remove ()
		self.ParentFolderItem = nil
	end
end

-- Internal, do not call
function self:AddNode (node, parentFolder)
	if not parentFolder and self.ChildNodes [node:GetName ()] then return end
	
	local listViewItem = self:AddItem (node:GetName ())
	listViewItem:SetText (parentFolder and ".." or node:GetDisplayName ())
	listViewItem.ParentFolder = parentFolder or false
	listViewItem.Node = node
	
	listViewItem.IsFolder = node:IsFolder ()
	listViewItem.IsFile = node:IsFile ()
	listViewItem.Size = node:IsFile () and node:GetSize () or -1
	listViewItem.LastModified = node:GetModificationTime ()
	
	self:UpdateIcon (listViewItem)
	
	listViewItem:SetColumnText ("Size", listViewItem.Size ~= -1 and VFS.FormatFileSize (listViewItem.Size) or "")
	listViewItem:SetColumnText ("Last Modified", listViewItem.LastModified ~= -1 and VFS.FormatDate (listViewItem.LastModified) or "")
	
	if parentFolder then
		self.ParentFolderItem = listViewItem
	else
		self.ChildNodes [node:GetName ()] = listViewItem
	end
	return listViewItem
end

function self:UpdateIcon (listViewItem)
	local node = listViewItem.Node
	local permissionBlock = node:GetPermissionBlock ()
	local canView = not permissionBlock or permissionBlock:IsAuthorized (GAuth.GetLocalId (), listViewItem.IsFolder and "View Folder" or "Read")
	if listViewItem.IsFolder then
		listViewItem:SetIcon (canView and "icon16/folder.png" or "icon16/folder_delete.png")
	else
		listViewItem:SetIcon (canView and "icon16/page.png" or "icon16/page_delete.png")
	end
end

-- Event handlers
function self:OnRemoved ()
	self:SetFolder (nil)
end

-- Event handlers
self.PermissionsChanged = VFS.NullCallback

vgui.Register ("VFSFolderListView", self, "GListView")