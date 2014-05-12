local self = {}

--[[
	Events:
		FileOpened (IFile file)
			Fired when the user tries to open a file.
		SelectedFolderChanged (IFolder folder)
			Fired when the selected folder is changed.
		SelectedNodeChanged (INode node)
			Fired when the selected file or folder is changed.
]]

function self:Init ()
	self.ShowFiles = false
	self.SubscribedNodes = VFS.WeakKeyTable ()
	
	self.LastSelectPath = nil

	-- Populate root group trees
	self:SetPopulator (function (node)
		if node.IsFolder then
			self:Populate (node.Node, node)
		end
	end)
	
	self.FilesystemRootNode = self:AddFilesystemNode (self, VFS.Root)
	self.FilesystemRootNode:SetText ("[root]")
	self:Populate (VFS.Root, self.FilesystemRootNode)
	self.FilesystemRootNode:Select ()
	self.FilesystemRootNode:SetExpanded (true)
	self:AddEventListener ("DoubleClick",
		function ()
			local file = self:GetSelectedFile ()
			if not file then return end
			self:DispatchEvent ("FileOpened", file)
		end
	)
	self:AddEventListener ("ItemSelected",
		function (tree, treeViewNode)
			self:DispatchEvent ("SelectedFolderChanged", self:GetSelectedFolder ())
			self:DispatchEvent ("SelectedNodeChanged", treeViewNode and treeViewNode.Node or nil)
		end
	)
	
	-- Menu
	self.Menu = Gooey.Menu ()
	
	self.Menu:AddEventListener ("MenuOpening",
		function (_, targetItem)
			-- Override the menu target item with the filesystem node
			if targetItem then
				targetItem = targetItem.Node
				self.Menu:SetTargetItem (targetItem)
			else
				targetItem = VFS.Root
				self.Menu:SetTargetItem (targetItem)
			end
			
			if not targetItem then
				self.Menu:GetItemById ("Open")         :SetVisible (false)
				self.Menu:GetItemById ("Browse")       :SetVisible (false)
				self.Menu:GetItemById ("OpenSeparator"):SetVisible (false)
				self.Menu:GetItemById ("Copy")         :SetEnabled (false)
				self.Menu:GetItemById ("Paste")        :SetEnabled (false)
				self.Menu:GetItemById ("Create Folder"):SetEnabled (false)
				self.Menu:GetItemById ("Delete")       :SetEnabled (false)
				self.Menu:GetItemById ("Rename")       :SetEnabled (false)
				self.Menu:GetItemById ("Permissions")  :SetEnabled (false)
				return
			end
			
			self.Menu:GetItemById ("Open")         :SetVisible (targetItem:IsFile ())
			self.Menu:GetItemById ("Browse")       :SetVisible (targetItem:IsFolder () and not targetItem:IsRoot ())
			self.Menu:GetItemById ("Refresh")      :SetVisible (targetItem:IsFolder ())
			self.Menu:GetItemById ("OpenSeparator"):SetVisible (not targetItem:IsRoot ())
			
			local pasteFolder = targetItem
			if not pasteFolder:IsFolder () then pasteFolder = pasteFolder:GetParentFolder () end
			local permissionBlock = targetItem:GetPermissionBlock ()
			if not permissionBlock then
				self.Menu:GetItemById ("Open")         :SetEnabled (targetItem:IsFile ())
				self.Menu:GetItemById ("Browse")       :SetEnabled (targetItem:IsFolder ())
				self.Menu:GetItemById ("Refresh")      :SetEnabled (targetItem:IsFolder ())
				self.Menu:GetItemById ("Copy")         :SetEnabled (true)
				self.Menu:GetItemById ("Paste")        :SetEnabled (true)
				self.Menu:GetItemById ("Create Folder"):SetEnabled (targetItem:IsFolder ())
				self.Menu:GetItemById ("Delete")       :SetEnabled (targetItem:CanDelete ())
				self.Menu:GetItemById ("Rename")       :SetEnabled (true)
			else
				self.Menu:GetItemById ("Open")         :SetEnabled (targetItem:IsFile ()    and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Read"))
				self.Menu:GetItemById ("Browse")       :SetEnabled (targetItem:IsFolder ()  and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "View Folder"))
				self.Menu:GetItemById ("Refresh")      :SetEnabled (targetItem:IsFolder ()  and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "View Folder"))
				self.Menu:GetItemById ("Copy")         :SetEnabled (permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Read") or permissionBlock:IsAuthorized (GAuth.GetLocalId (), "View Folder"))
				self.Menu:GetItemById ("Paste")        :SetEnabled (VFS.Clipboard:CanPaste (pasteFolder))
				self.Menu:GetItemById ("Create Folder"):SetEnabled (targetItem:IsFolder ()  and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Create Folder"))
				self.Menu:GetItemById ("Delete")       :SetEnabled (targetItem:CanDelete () and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Delete"))
				self.Menu:GetItemById ("Rename")       :SetEnabled (permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Rename"))
			end
			self.Menu:GetItemById ("Permissions"):SetEnabled (permissionBlock and true or false)
		end
	)
	
	self.Menu:AddItem ("Open",
		function (node)
			if not node then return end
			if not node:IsFile () then return end
			self:DispatchEvent ("FileOpened", node)
		end
	):SetIcon ("icon16/page_go.png")
	self.Menu:AddItem ("Browse",
		function (node)
			if not node then return end
			if not node:IsFolder () then return end
			VFS.FileSystemBrowser ():GetFrame ():SetFolder (node)
			VFS.FileSystemBrowser ():GetFrame ():SetVisible (true)
			VFS.FileSystemBrowser ():GetFrame ():MoveToFront ()
			VFS.FileSystemBrowser ():GetFrame ():Focus ()
		end
	):SetIcon ("icon16/folder_go.png")
	self.Menu:AddItem ("Refresh",
		function (node)
			if not node then return end
			if not node:IsFolder () then return end
			node:EnumerateChildren (GAuth.GetLocalId ())
		end
	):SetIcon ("icon16/arrow_refresh.png")
	self.Menu:AddSeparator ("OpenSeparator")
	self.Menu:AddItem ("Copy",
		function (node)
			if not node then return end
			VFS.Clipboard:Clear ()
			VFS.Clipboard:Add (node)
		end
	):SetIcon ("icon16/page_white_copy.png")
	self.Menu:AddItem ("Paste",
		function (node)
			if not node then return end
			if not node:IsFolder () then node = node:GetParentFolder () end
			if not node then return end
			
			VFS.Clipboard:Paste (node)
		end
	):SetIcon ("icon16/paste_plain.png")
	self.Menu:AddSeparator ()
	self.Menu:AddItem ("Create Folder",
		function (node)
			if not node then return end
			if not node:IsFolder () then return end
			Derma_StringRequest ("Create Folder", "Enter the name of the new folder:", "",
				function (name)
					node:CreateFolder (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("icon16/folder_add.png")
	self.Menu:AddItem ("Delete",
		function (node)
			if not node then return end
			Derma_Query ("Are you sure you want to delete " .. node:GetDisplayPath () .. "?", "Confirm deletion",
				"Yes", function () node:Delete (GAuth.GetLocalId ()) end,
				"No", VFS.NullCallback
			)
		end
	):SetIcon ("icon16/cross.png")
	self.Menu:AddItem ("Rename",
		function (node)
			if not node then return end
			Derma_StringRequest ("Rename " .. node:GetName () .. "...", "Enter " .. node:GetName () .. "'s new name:", node:GetName (),
				function (name)
					name = VFS.SanitizeNodeName (name)
					if not name then return end
					node:Rename (GAuth.GetLocalId (), name)
				end
			)
		end
	):SetIcon ("icon16/pencil.png")
	self.Menu:AddSeparator ()
	self.Menu:AddItem ("Permissions",
		function (node)
			if not node then return end
			if not node:GetPermissionBlock () then return end
			GAuth.OpenPermissions (node:GetPermissionBlock ())
		end
	):SetIcon ("icon16/key.png")
end

function self:UnhookNode (node)
	self.SubscribedNodes [node] = nil
	
	node:RemoveEventListener ("NodeCreated",            self:GetHashCode ())
	node:RemoveEventListener ("NodeDeleted",            self:GetHashCode ())
	node:RemoveEventListener ("NodePermissionsChanged", self:GetHashCode ())
	node:RemoveEventListener ("NodeRenamed",            self:GetHashCode ())
	node:RemoveEventListener ("NodeUpdated",            self:GetHashCode ())
end

function self:UnhookNodeRecursive (treeViewNode)
	self:UnhookNode (treeViewNode.Node)
	if not treeViewNode.AddedNodes then return end
	for _, childNode in pairs (treeViewNode.AddedNodes) do
		self:UnhookNodeRecursive (childNode)
	end
end

function self.DefaultComparator (a, b)
	-- Put folders at the top
	if a == b then return false end
	if a.Node:IsFolder () and not b.Node:IsFolder () then return true  end
	if b.Node:IsFolder () and not a.Node:IsFolder () then return false end
	if     a.Node.PlayerFolder and not b.Node.PlayerFolder then return false end
	if not a.Node.PlayerFolder and     b.Node.PlayerFolder then return true  end
	return string.lower (a:GetText ()) < string.lower (b:GetText ())
end

function self:GetSelectedFile ()
	local item = self:GetSelectedItem ()
	if not item then return end
	if not item.Node then return end
	return item.Node:IsFile () and item.Node or nil
end

function self:GetSelectedFolder ()
	local item = self:GetSelectedItem ()
	if not item then return end
	if not item.Node then return end
	return item.Node:IsFolder () and item.Node or item.Node:GetParentFolder ()
end

function self:GetSelectedNode ()
	local item = self:GetSelectedItem ()
	if not item then return end
	return item.Node
end

function self:Populate (filesystemNode, treeViewNode)
	self.SubscribedNodes [filesystemNode] = true
	
	treeViewNode.AddedNodes = treeViewNode.AddedNodes or {}
	treeViewNode:SetIcon ("icon16/folder_explore.png")
	treeViewNode:SuppressLayout (true)
	local lastLayout = SysTime ()
	filesystemNode:EnumerateChildren (GAuth.GetLocalId (),
		function (returnCode, node)
			if not self:IsValid () then return end
			if not treeViewNode:IsValid () then return end
			
			if returnCode == VFS.ReturnCode.Success then
				self:AddFilesystemNode (treeViewNode, node)
				
				-- Relayout the node at intervals
				-- if we do this every time a node is added, it creates
				-- excessive framerate drops.
				if treeViewNode:GetChildCount () < 10 or SysTime () - lastLayout > 0.2 then
					treeViewNode:SuppressLayout (false)
					treeViewNode:SortChildren ()
					lastLayout = SysTime ()
				else
					treeViewNode:SuppressLayout (true)
				end
			elseif returnCode == VFS.ReturnCode.EndOfBurst then		
				self:LayoutNode (treeViewNode)
				treeViewNode:SortChildren ()
			elseif returnCode == VFS.ReturnCode.AccessDenied then
				treeViewNode.CanView = not treeViewNode.Node:GetPermissionBlock () or treeViewNode.Node:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder")
				treeViewNode:MarkUnpopulated ()
				treeViewNode:SetIcon ("icon16/folder_delete.png")
				self:LayoutNode (treeViewNode)
			elseif returnCode == VFS.ReturnCode.Finished then
				treeViewNode:SetIcon ("icon16/folder.png")
				self:LayoutNode (treeViewNode)
	
				filesystemNode:AddEventListener ("NodeCreated", self:GetHashCode (),
					function (_, newNode)
						self:AddFilesystemNode (treeViewNode, newNode)
						treeViewNode:SortChildren ()
						
						self:LayoutNode (treeViewNode)
					end
				)
				
				filesystemNode:AddEventListener ("NodeDeleted", self:GetHashCode (),
					function (_, deletedNode)
						local childNode = treeViewNode.AddedNodes [deletedNode:GetName ()]
						self:UnhookNodeRecursive (childNode)
						
						treeViewNode.AddedNodes [deletedNode:GetName ()] = nil
						if childNode then
							treeViewNode:RemoveNode (childNode)
							self:LayoutNode (treeViewNode)
						end
					end
				)
			end
		end
	)
	
	filesystemNode:AddEventListener ("NodePermissionsChanged", self:GetHashCode (),
		function (_, node)
			local childNode = treeViewNode.AddedNodes [node:GetName ()]
			if not childNode then return end
			
			local canViewChanged, canReadChanged = self:UpdateIcon (childNode)
			if not node:IsFolder () then return end
			
			if canViewChanged then
				if childNode.CanView then
					childNode:SetExpandable (true)
					childNode:MarkUnpopulated ()
				else
					self:UnhookNodeRecursive (childNode)
					
					-- Move item selection upwards if necessary
					local selectedItem = self:GetSelectedItem ()
					if selectedItem and selectedItem:IsValid () then
						while selectedItem and selectedItem:IsValid () do
							selectedItem = selectedItem:GetParentNode ()
							if childNode == selectedItem then
								self:SetSelectedItem (childNode)
								break
							end
						end
					end
					
					childNode.AddedNodes = {}
					childNode:Clear ()
					childNode:SetExpanded (false)
					childNode:SetExpandable (false)
					childNode:MarkUnpopulated ()
				end
			end
			if childNode.CanView and canReadChanged then
				self:UpdateFileIconsRecursive (childNode)
			end
		end
	)
	
	filesystemNode:AddEventListener ("NodeRenamed", self:GetHashCode (),
		function (_, node, oldName, newName)
			if not treeViewNode.AddedNodes [oldName] then return end
			treeViewNode.AddedNodes [newName] = treeViewNode.AddedNodes [oldName]
			treeViewNode.AddedNodes [newName]:SetText (node:GetDisplayName ())
			treeViewNode.AddedNodes [oldName] = nil
			
			self:SortChildren ()
		end
	)
	
	filesystemNode:AddEventListener ("NodeUpdated", self:GetHashCode (),
		function (_, updatedNode, updateFlags)
			if not treeViewNode:IsValid () then return end
			local childNode = treeViewNode.AddedNodes [updatedNode:GetName ()]
			if not childNode then return end
			if bit.band (updateFlags, VFS.UpdateFlags.DisplayName) == 0 then return end
			
			childNode:SetText (updatedNode:GetDisplayName ())
			self:SortChildren ()
		end
	)
end

function self:SelectPath (path)
	if self.LastSelectPath == path then return end
	self.LastSelectPath = path
	self:ResolvePath (self.FilesystemRootNode, path,
		function (returnCode, treeViewNode)
			if not treeViewNode then return end
			if path ~= self.LastSelectPath then return end
			treeViewNode:Select ()
			treeViewNode:ExpandTo (true)
		end
	)
end

self.SetPath = self.SelectPath

function self:SetShowFiles (showFiles)
	self.ShowFiles = showFiles
end

-- Internal, do not call
function self:AddFilesystemNode (treeViewNode, filesystemNode)	
	if filesystemNode:IsFile () and not self.ShowFiles then return end
	if treeViewNode.AddedNodes and treeViewNode.AddedNodes [filesystemNode:GetName ()] then
		return treeViewNode.AddedNodes [filesystemNode:GetName ()]
	end
	
	local childNode = treeViewNode:AddNode (filesystemNode:GetName ())
	childNode:SetExpandable (filesystemNode:IsFolder ())
	childNode:SetText (filesystemNode:GetDisplayName ())
	
	childNode.Node = filesystemNode
	childNode.IsFolder = filesystemNode:IsFolder ()
	childNode.IsFile = filesystemNode:IsFile ()
	
	self:UpdateIcon (childNode)
	if filesystemNode:IsFolder () and not childNode.CanView then
		childNode:SetExpandable (false)
	end
	
	treeViewNode.AddedNodes = treeViewNode.AddedNodes or {}
	treeViewNode.AddedNodes [filesystemNode:GetName ()] = childNode
	return childNode
end

function self:LayoutNode (treeViewNode)
	treeViewNode:SuppressLayout (false)
	treeViewNode:LayoutRecursive ()
	if treeViewNode:GetChildCount () == 0 then
		treeViewNode:SetExpandable (false)
	else
		treeViewNode:SortChildren ()
	end
end

function self:ResolvePath (treeViewNode, path, callback)
	callback = callback or VFS.NullCallback
	
	local path = VFS.Path (path)
	
	if path:IsEmpty () then callback (VFS.ReturnCode.Success, treeViewNode) return end
	
	local segment = path:GetSegment (0)
	path:RemoveFirstSegment ()
	if treeViewNode.AddedNodes and treeViewNode.AddedNodes [segment] then
		if path:IsEmpty () then
			callback (VFS.ReturnCode.Success, treeViewNode.AddedNodes [segment])
		else
			self:ResolvePath (treeViewNode.AddedNodes [segment], path, callback)
		end
	else
		if not treeViewNode.Node:IsFolder () then callback (VFS.ReturnCode.NotAFolder) return end
		treeViewNode.Node:GetDirectChild (GAuth.GetLocalId (), segment,
			function (returnCode, node)
				if returnCode == VFS.ReturnCode.Success then
					if node:IsFile () and not self.ShowFiles then
						callback (VFS.NotAFolder, node)
						return
					end
					local childNode = self:AddFilesystemNode (treeViewNode, node)
					if path:IsEmpty () then
						callback (returnCode, childNode)
					elseif node:IsFolder () then
						self:ResolvePath (childNode, path, callback)
					else
						callback (VFS.ReturnCode.NotAFolder)
					end
				else
					callback (returnCode)
				end
			end
		)
		if not treeViewNode.AddedNodes then self:Populate (treeViewNode.Node, treeViewNode) end
	end
end

-- Returns true if the icon was changed
function self:UpdateIcon (treeViewNode)
	local node = treeViewNode.Node
	local permissionBlock = node:GetPermissionBlock ()
	local canRead = not permissionBlock or permissionBlock:IsAuthorized (GAuth.GetLocalId (), "Read")
	local canView = not permissionBlock or (treeViewNode.IsFolder and permissionBlock:IsAuthorized (GAuth.GetLocalId (), "View Folder") or canRead)
	
	local canViewChanged = treeViewNode.CanView ~= canView
	local canReadChanged = treeViewNode.CanRead ~= canRead
	treeViewNode.CanView = canView
	treeViewNode.CanRead = canRead
	
	if treeViewNode.IsFolder and canViewChanged then
		treeViewNode:SetIcon (canView and "icon16/folder.png" or "icon16/folder_delete.png")
	elseif treeViewNode.IsFile and canReadChanged then
		treeViewNode:SetIcon (canView and "icon16/page.png" or "icon16/page_delete.png")
	end
	return canViewChanged, canReadChanged
end

function self:UpdateFileIconsRecursive (treeViewNode)
	if not treeViewNode.AddedNodes then return end
	
	for _, childNode in pairs (treeViewNode.AddedNodes) do
		local _, canReadChanged = self:UpdateIcon (childNode)
		if canReadChanged and childNode.IsFolder then
			self:UpdateFileIconsRecursive (childNode)
		end
	end
end

-- Event handlers
function self:OnRemoved ()
	for node, _ in pairs (self.SubscribedNodes) do
		node:RemoveEventListener ("NodeCreated",            self:GetHashCode ())
		node:RemoveEventListener ("NodeDeleted",            self:GetHashCode ())
		node:RemoveEventListener ("NodePermissionsChanged", self:GetHashCode ())
		node:RemoveEventListener ("NodeRenamed",            self:GetHashCode ())
		node:RemoveEventListener ("NodeUpdated",            self:GetHashCode ())
	end
end

vgui.Register ("VFSFolderTreeView", self, "GTreeView")