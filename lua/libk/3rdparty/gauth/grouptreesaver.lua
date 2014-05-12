local self = {}
GAuth.GroupTreeSaver = GAuth.MakeConstructor (self)

function self:ctor ()
	self.Version = 1

	self.NeedsSaving = false
	
	timer.Create ("GAuth.GroupTreeSaver", 10, 0,
		function ()
			if not self.NeedsSaving then return end
			self:Save ()
		end
	)

	-- Make a closure for the NodeAdded and Removed event handler
	self.NodeAdded = function (groupTreeNode, childNode)
		self:HookNode (childNode)
	
		if groupTreeNode:GetHost () ~= GAuth.GetLocalId () then return end
		if childNode:GetHost () ~= GAuth.GetLocalId () then return end
		self:FlagUnsaved ()
	end
	
	self.NodeRemoved = function (groupTreeNode, childNode)
		if childNode:GetHost () ~= GAuth.GetLocalId () then return end
		self:FlagUnsaved ()
	end

	self.UserAdded = function (groupTreeNode, userId)
		if groupTreeNode:GetHost () ~= GAuth.GetLocalId () then return end
		self:FlagUnsaved ()
	end
			
	self.UserRemoved = function (groupTreeNode, userId)
		if groupTreeNode:GetHost () ~= GAuth.GetLocalId () then return end
		self:FlagUnsaved ()
	end
	
	self.HostChanged = function (groupTreeNode, hostId)
		if groupTreeNode:GetHost () == GAuth.GetLocalId () then
			groupTreeNode:GetPermissionBlock ():AddEventListener ("PermissionsChanged", self:GetHashCode (), self.PermissionsChanged)
			self:FlagUnsaved ()
		else
			groupTreeNode:GetPermissionBlock ():RemoveEventListener ("PermissionsChanged", self:GetHashCode ())
		end
	end
	
	self.PermissionsChanged = function (permissionBlock)
		local groupTreeNode = GAuth.ResolveGroupTreeNode (permissionBlock:GetName ())
		if not groupTreeNode then return end
		if groupTreeNode:GetHost () ~= GAuth.GetLocalId () then return end
		self:FlagUnsaved ()
	end
	
	self.Removed = function (groupTreeNode)
		if groupTreeNode:GetHost () == GAuth.GetLocalId () then
			self:FlagUnsaved ()
		end
		self:UnhookNode (groupTreeNode)
	end
end

function self:dtor ()
	timer.Destroy ("GAuth.GroupTreeSaver")

	if not self.NeedsSaving then return end
	self:Save ()
end

function self:HookNode (groupTreeNode)
	if groupTreeNode:IsGroup () then
		groupTreeNode:AddEventListener ("UserAdded",   self:GetHashCode (), self.UserAdded)		
		groupTreeNode:AddEventListener ("UserRemoved", self:GetHashCode (), self.UserRemoved)
	elseif groupTreeNode:IsGroupTree () then
		groupTreeNode:AddEventListener ("NodeAdded",   self:GetHashCode (), self.NodeAdded)
		groupTreeNode:AddEventListener ("NodeRemoved", self:GetHashCode (), self.NodeRemoved)
	end
	
	groupTreeNode:AddEventListener ("HostChanged", self:GetHashCode (), self.HostChanged)
	groupTreeNode:AddEventListener ("Removed",     self:GetHashCode (), self.Removed)
	
	if groupTreeNode:GetHost () == GAuth.GetLocalId () then
		groupTreeNode:GetPermissionBlock ():AddEventListener ("PermissionsChanged", self:GetHashCode (), self.PermissionsChanged)
	end
end

function self:HookNodeRecursive (groupTreeNode)
	self:HookNode (groupTreeNode)
	if not groupTreeNode:IsGroupTree () then return end
	for _, childNode in groupTreeNode:GetChildEnumerator () do
		self:HookNodeRecursive (childNode)
	end
end

function self:UnhookNode (groupTreeNode)
	if groupTreeNode:IsGroup () then
		groupTreeNode:RemoveEventListener ("UserAdded",   self:GetHashCode ())
		groupTreeNode:RemoveEventListener ("UserRemoved", self:GetHashCode ())
	elseif groupTreeNode:IsGroupTree () then
		groupTreeNode:RemoveEventListener ("NodeAdded",   self:GetHashCode ())
		groupTreeNode:RemoveEventListener ("NodeRemoved", self:GetHashCode ())
	end
	
	groupTreeNode:RemoveEventListener ("HostChanged", self:GetHashCode ())
	groupTreeNode:RemoveEventListener ("Removed",     self:GetHashCode ())
	
	groupTreeNode:GetPermissionBlock ():RemoveEventListener ("PermissionsChanged", self:GetHashCode ())
end

function self:FlagUnsaved ()
	self.NeedsSaving = true
end

function self:Load (callback)
	callback = callback or GAuth.NullCallback

	local data = file.Read ("data/gauth_" .. (SERVER and "sv" or "cl") .. ".txt", "GAME") or ""
	if data == "" then callback (GAuth.ReturnCode.Success) return end
	local inBuffer = GAuth.StringInBuffer (data)
	inBuffer:String () -- discard warning
	local version = inBuffer:UInt32 ()
	if version ~= self.Version then
		GAuth.Error ("GAuth.GroupTreeSaver:Load : Cannot load version " .. version .. " files. Current version is " .. self.Version .. ".")
		callback (GAuth.ReturnCode.Success)
		return
	end
	self:LoadNextGroup (inBuffer,
		function (returnCode)
			self.NeedsSaving = false
			callback (returnCode)
		end
	)
end

function self:LoadNextGroup (inBuffer, callback)
	local groupId = inBuffer:String ()
	if groupId == "" then callback (GAuth.ReturnCode.Success) return end
	
	local isGroupTree = inBuffer:Boolean ()
	GAuth.Groups:AddGroupTreeNodeRecursive (GAuth.GetSystemId (), groupId, isGroupTree,
		function (returnCode, groupTreeNode)
			if returnCode == GAuth.ReturnCode.Success then
				groupTreeNode:GetPermissionBlock ():Deserialize (inBuffer:String ())
				if not isGroupTree then
					local userId = inBuffer:String ()
					while userId ~= "" do
						groupTreeNode:AddUser (GAuth.GetSystemId (), userId)
						userId = inBuffer:String ()
					end
				end
			end
			inBuffer:Char () -- discard the newline
			self:LoadNextGroupDelayed (inBuffer, callback) 
		end
	)
end

function self:LoadNextGroupDelayed (inBuffer, callback)
	GLib.CallDelayed (
		function ()
			self:LoadNextGroup (inBuffer, callback)
		end
	)
end

function self:Save ()
	self.NeedsSaving = false
	
	local outBuffer = GAuth.StringOutBuffer ()
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
	self:SaveNode (GAuth.Groups, outBuffer)
	outBuffer:String ("")
	
	local data = outBuffer:GetString ()
	file.Write ("gauth_" .. (SERVER and "sv" or "cl") .. ".txt", data)
end

function self:SaveNode (groupTreeNode, outBuffer)
	local save = true
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () then save = false end
	if GAuth.Groups == groupTreeNode then save = false end
	if not groupTreeNode:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Modify Permissions") then save = false end
	
	if save then
		outBuffer:String (groupTreeNode:GetFullName ())
		outBuffer:Boolean (groupTreeNode:IsGroupTree ())
		outBuffer:String (groupTreeNode:GetPermissionBlock ():Serialize ():GetString ())
	end
	if groupTreeNode:IsGroup () then
		if save then
			if not groupTreeNode:GetMembershipFunction () then
				for userId in groupTreeNode:GetUserEnumerator () do
					outBuffer:String (userId)
				end
			end
			outBuffer:String ("")
			outBuffer:Char ("\n")
		end
	elseif groupTreeNode:IsGroupTree () then
		if save then outBuffer:Char ("\n") end
		for _, childNode in groupTreeNode:GetChildEnumerator () do
			self:SaveNode (childNode, outBuffer)
		end
	end
end

-- Events
self.NodeAdded          = GAuth.NullCallback
self.NodeRemoved        = GAuth.NullCallback
self.UserAdded          = GAuth.NullCallback
self.UserRemoved        = GAuth.NullCallback
self.HostChanged        = GAuth.NullCallback
self.PermissionsChanged = GAuth.NullCallback
self.Removed            = GAuth.NullCallback

GAuth.GroupTreeSaver = GAuth.GroupTreeSaver ()