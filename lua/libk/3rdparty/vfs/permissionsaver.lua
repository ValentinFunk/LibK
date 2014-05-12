local self = {}
VFS.PermissionSaver = VFS.MakeConstructor (self)

function self:ctor ()
	self.Version = 1

	self.NeedsSaving = false
	self.IgnorePermissionsChanged = false
	
	self.HookedNodes = VFS.WeakKeyTable ()
	self.SavableNodes = VFS.WeakKeyTable ()
	self.SavedBlocks = {}
	
	timer.Create ("VFS.PermissionSaver", 10, 0,
		function ()
			if not self.NeedsSaving then return end
			self:Save ()
		end
	)
	
	self.NodeCreated = function (node, childNode)
		if childNode:IsFolder () then
			self:HookNode (childNode)
			-- PermissionSaver:HookNode () will automatically load up permissions on the node
			-- it's given
		else
			if childNode:IsLocalNode () then
				self.SavableNodes [childNode] = true
			end
			if childNode:IsLocalNode () and self.SavedBlocks [childNode:GetPath ()] then
				self.IgnorePermissionsChanged = true
				childNode:GetPermissionBlock ():Deserialize (self.SavedBlocks [childNode:GetPath ()])
				self.IgnorePermissionsChanged = false
			end
		end
	end
	
	self.NodeDeleted = function (node, childNode)
		if self:IsNodeHooked (childNode) then self:UnhookNode (childNode) end
		self.SavableNodes [childNode] = nil
	end
	
	self.NodePermissionsChanged = function (node, childNode)
		if self.IgnorePermissionsChanged then return end
		if self.SavableNodes [childNode] then
			self:FlagUnsaved ()
		end
	end
	
	self.NodeRenamed = function (node, childNode, oldName, newName)
		if not self.SavableNodes [childNode] then return end
	
		local newPath = childNode:GetPath ()
		local parts = newPath:Split ("/")
		parts [#parts] = oldName
		local oldPath = table.concat (parts, "/")
		
		local changedCount = self.SavedBlocks [oldPath] and 1 or 0
		self.SavedBlocks [newPath] = self.SavedBlocks [oldPath]
		self.SavedBlocks [oldPath] = nil
		
		if childNode:IsFolder () then
			-- Fixup child node paths
		
			local changedPaths = {}
			for originalPath, _ in pairs (self.SavedBlocks) do
				if originalPath:sub (1, oldPath:len () + 1) == oldPath .. "/" then
					changedPaths [#changedPaths + 1] = originalPath
				end
			end
			
			for _, originalPath in ipairs (changedPaths) do
				self.SavedBlocks [newPath .. originalPath:sub (oldPath:len () + 1)] = self.SavedBlocks [originalPath]
				self.SavedBlocks [originalPath] = nil
				ErrorNoHalt ("Changing " .. originalPath .. " to " .. newPath .. originalPath:sub (oldPath:len () + 1) .. "\n")
			end
			
			changedCount = changedCount + #changedPaths
		end
		
		if changedCount > 0 then
			self:FlagUnsaved ()
		end
	end
end

function self:dtor ()
	timer.Destroy ("VFS.PermissionSaver")

	if not self.NeedsSaving then return end
	self:Save ()
end

function self:HookNode (node)
	self.HookedNodes [node] = true
	if not node:IsRoot () and node:IsLocalNode () then
		self.SavableNodes [node] = true
	end
	
	if node:IsLocalNode () and self.SavedBlocks [node:GetPath ()] then
		self.IgnorePermissionsChanged = true
		node:GetPermissionBlock ():Deserialize (self.SavedBlocks [node:GetPath ()])
		self.IgnorePermissionsChanged = false
	end
	
	node:AddEventListener ("NodeCreated",            self:GetHashCode (), self.NodeCreated)
	node:AddEventListener ("NodeDeleted",            self:GetHashCode (), self.NodeDeleted)
	node:AddEventListener ("NodePermissionsChanged", self:GetHashCode (), self.NodePermissionsChanged)
	node:AddEventListener ("NodeRenamed",            self:GetHashCode (), self.NodeRenamed)
end

function self:HookNodeRecursive (node)
	self:HookNode (node)
	
	if node:IsFolder () then
		for _, childNode in pairs (node:EnumerateChildrenSynchronous ()) do
			if childNode:IsFolder () then
				self:HookNodeRecursive (childNode)
			end
		end
	end
end

function self:IsNodeHooked (node)
	return self.HookedNodes [node] or false
end

function self:UnhookNode (node)
	self.HookedNodes [node] = nil
	self.SavableNodes [node] = nil
	
	node:RemoveEventListener ("NodeCreated",            self:GetHashCode ())
	node:RemoveEventListener ("NodeDeleted",            self:GetHashCode ())
	node:RemoveEventListener ("NodePermissionsChanged", self:GetHashCode ())
	node:RemoveEventListener ("NodeRenamed",            self:GetHashCode ())
end

function self:FlagUnsaved ()
	self.NeedsSaving = true
end

function self:Load (callback)
	callback = callback or VFS.NullCallback

	local data = file.Read ("data/vfs_" .. (SERVER and "sv" or "cl") .. ".txt", "GAME") or ""
	if data == "" then callback (VFS.ReturnCode.Success) return end
	local inBuffer = VFS.StringInBuffer (data)
	inBuffer:String () -- discard warning
	local version = inBuffer:UInt32 ()
	if version ~= self.Version then
		VFS.Error ("VFS.PermissionSaver:Load : Cannot load version " .. version .. " files. Current version is " .. self.Version .. ".")
		callback (VFS.ReturnCode.Success)
		return
	end
	
	local path = inBuffer:String ()
	while path ~= "" do
		local permissionBlockData = inBuffer:String ()
		self.SavedBlocks [path] = permissionBlockData
		
		local node = VFS.Root:GetChildSynchronous (path)
		if node then
			node:GetPermissionBlock ():Deserialize (permissionBlockData)
		end
		
		inBuffer:Char () -- discard newline
		path = inBuffer:String ()
	end
end

function self:Save ()
	self.NeedsSaving = false
	
	local outBuffer = VFS.StringOutBuffer ()
	outBuffer:String ([[

============================================================
Warning: Do not try editing this file without a hex editor.
         You'll probably end up corrupting it.
         
         In fact, you shouldn't even be editing this
         by hand unless you're sure you know what you're
         doing.
============================================================
]])
	outBuffer:UInt32 (self.Version)
	for node, _ in pairs (self.SavableNodes) do
		if node:GetPermissionBlock ():IsDefault () then
			self.SavedBlocks [node:GetPath ()] = nil
		elseif node:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Modify Permissions") then
			self.SavedBlocks [node:GetPath ()] = node:GetPermissionBlock ():Serialize ():GetString ()
		end
	end
	for path, permissionBlockData in pairs (self.SavedBlocks) do
		outBuffer:String (path)
		outBuffer:String (permissionBlockData)
		outBuffer:Char ("\n")
	end
	outBuffer:String ("")
	
	file.Write ("vfs_" .. (SERVER and "sv" or "cl") .. ".txt", outBuffer:GetString ())
end

function self:SaveNode (node, outBuffer)
	outBuffer:String (node:GetPath ())
	outBuffer:String (node:GetPermissionBlock ():Serialize ())
end

self.NodeCreated            = VFS.NullCallback
self.NodeDeleted            = VFS.NullCallback
self.NodePermissionsChanged = VFS.NullCallback
self.NodeRenamed            = VFS.NullCallback

VFS.PermissionSaver = VFS.PermissionSaver ()