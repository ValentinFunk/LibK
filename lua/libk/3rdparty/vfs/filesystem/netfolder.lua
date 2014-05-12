local self = {}
VFS.NetFolder = VFS.MakeConstructor (self, VFS.IFolder, VFS.NetNode)

function self:ctor (endPoint, path, name, parentFolder)
	self.FolderPath = self:GetPath () == "" and "" or self:GetPath () .. "/"
	
	self.ReceivedChildren = false
	self.FolderListingRequest = nil
	self.Children = {}
	self.LowercaseChildren = {}
	
	self.LastAccess = false
	
	self:AddEventListener ("PermissionsChanged", self.PermissionsChanged)
	self:AddEventListener ("Renamed", self.Renamed)
end

function self:CreateDirectNode (authId, name, isFolder, callback)
	callback = callback or VFS.NullCallback
	
	local lowercaseName = name:lower ()
	if self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName]) then
		if self.Children [name]:IsFolder () == isFolder then callback (VFS.ReturnCode.Success, self.Children [name])
		elseif self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName] then callback (VFS.ReturnCode.Success, self.LowercaseChildren [lowercaseName])
		elseif isFolder then callback (VFS.ReturnCode.NotAFolder)
		else callback (VFS.ReturnCode.NotAFile) end
		return
	end
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, (isFolder and "Create Folder" or "Write")) then callback (VFS.ReturnCode.AccessDenied) return end
	
	local nodeCreationRequest = VFS.Protocol.NodeCreationRequest (self, name, isFolder,
		function (returnCode, inBuffer)
			if returnCode == VFS.ReturnCode.Success then
				callback (returnCode, self:DeserializeNode (inBuffer))
			else
				callback (returnCode)
			end
		end
	)
	self.EndPoint:StartSession (nodeCreationRequest)
end

function self:CreatePredictedFolder (name)
	self.Children [name] = VFS.NetFolder (self.EndPoint, name, self)
	self.Children [name].Predicted = true
	self.LowercaseChildren [name:lower ()] = self.Children [name]
	
	self:DispatchEvent ("NodeCreated", self.Children [name])
	
	return self.Children [name]
end

function self:DeleteDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	local lowercaseName = name:lower ()
	local childNode = self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName] or nil)
	if childNode and not childNode:GetPermissionBlock ():IsAuthorized (authId, "Delete") then callback (VFS.ReturnCode.AccessDenied) return end
	if not childNode:CanDelete () then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.EndPoint:StartSession (VFS.Protocol.NodeDeletionRequest (self, name, callback))
end

function self:EnumerateChildren (authId, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "View Folder") then callback (VFS.ReturnCode.AccessDenied) return end
	
	-- Enumerate received children
	for _, node in pairs (self.Children) do
		callback (VFS.ReturnCode.Success, node)
	end
	
	-- TODO: Run callback on unreceived children
	if self.ReceivedChildren then
		callback (VFS.ReturnCode.Finished)
	else
		callback (VFS.ReturnCode.EndOfBurst)
		
		if not self.FolderListingRequest then
			self.FolderListingRequest = VFS.Protocol.FolderListingRequest (self)
			self.EndPoint:StartSession (self.FolderListingRequest)
			
			self.FolderListingRequest:AddEventListener ("ReceivedNodeInfo", function (request, inBuffer)
				local receivedNode = self:DeserializeNode (inBuffer)
				request:DispatchEvent ("RunCallback", VFS.ReturnCode.Success, receivedNode)
				return receivedNode
			end)
			
			self.FolderListingRequest:AddEventListener ("TimedOut", function (request)
				request:DispatchEvent ("RunCallback", VFS.ReturnCode.TimedOut)
				request:DispatchEvent ("RunCallback", VFS.ReturnCode.Finished)
				self.FolderListingRequest = nil
			end)
			
			local failed = false
			self.FolderListingRequest:AddEventListener ("RunCallback", function (request, returnCode)
				if returnCode == VFS.ReturnCode.Success then
				elseif returnCode == VFS.ReturnCode.Finished then
					self.ReceivedChildren = not failed
					self.FolderListingRequest = nil
				elseif returnCode == VFS.ReturnCode.EndOfBurst then
				else
					failed = true
				end
			end)
		end
		
		self.FolderListingRequest:AddEventListener ("RunCallback", function (request, returnCode, node)
			callback (returnCode, node)
		end)
	end
end

function self:GetDirectChild (authId, name, callback)
	callback = callback or VFS.NullCallback
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "View Folder") then callback (VFS.ReturnCode.AccessDenied) return end
	
	if self.Children [name] then
		callback (VFS.ReturnCode.Success, self.Children [name])
	elseif self:IsCaseInsensitive () and self.LowercaseChildren [name:lower ()] then
		callback (VFS.ReturnCode.Success, self.LowercaseChildren [name:lower ()])
	elseif self.ReceivedChildren then
		callback (VFS.ReturnCode.NotFound)
	else
		local folderChildRequest = VFS.Protocol.FolderChildRequest (self, name,
			function (returnCode, inBuffer)
				if returnCode == VFS.ReturnCode.Success then
					callback (returnCode, self:DeserializeNode (inBuffer))
				else
					callback (returnCode)
				end
			end
		)
		self.EndPoint:StartSession (folderChildRequest)
	end
end

function self:GetDirectChildSynchronous (name)
	return self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [name:lower ()] or nil)
end

function self:IsCaseSensitive ()
	return false
end

function self:MountLocal (name, node)
	if not node then return end

	self.Children [name] = (node:IsFolder () and VFS.MountedFolder or VFS.MountedFile) (name, node, self)
	self.LowercaseChildren [name:lower ()] = self.Children [name]
	
	self:DispatchEvent ("NodeCreated", self.Children [name])
	
	return self.Children [name]
end

function self:RenameChild (authId, name, newName, callback)
	callback = callback or VFS.NullCallback
	
	local child = self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [name:lower ()] or nil)
	if child and not child:GetPermissionBlock ():IsAuthorized (authId, "Rename") then callback (VFS.ReturnCode.AccessDenied) return end
	
	self.EndPoint:StartSession (VFS.Protocol.NodeRenameRequest (self, name, newName, callback))
end

function self:UnhookPermissionBlock ()
	VFS.PermissionBlockNetworker:UnhookBlock (self:GetPermissionBlock ())
	for _, node in pairs (self.Children) do
		node:UnhookPermissionBlock ()
	end
end

-- Internal, do not call
-- The corresponding SerializeNode function is in
-- vfs/protocol/session.lua : Session:SerializeNode
function self:DeserializeNode (inBuffer)
	local nodeType = inBuffer:UInt8 ()
	local name = inBuffer:String ()
	local displayName = inBuffer:String ()
	local size = inBuffer:UInt32 ()
	local lastModified = inBuffer:UInt32 ()
	
	local lowercaseName = name:lower ()
	if displayName == "" then displayName = nil end
	if size == 0xFFFFFFFF then size = -1 end
	if lastModified == 0xFFFFFFFF then lastModified = -1 end

	local child = self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName] or nil)
	local newNode = false
	if child then
		child:ClearPredictedFlag ()
	else
		newNode = true
		if bit.band (nodeType, VFS.NodeType.Folder) ~= 0 then
			child = VFS.NetFolder (self.EndPoint, name, self)
		elseif bit.band (nodeType, VFS.NodeType.File) ~= 0 then
			child = VFS.NetFile (self.EndPoint, name, self)
		end
		self.Children [name] = child
		self.LowercaseChildren [lowercaseName] = child
	end
	child:SetDisplayName (displayName)
	if child:IsNetNode () then
		if child:IsFile () then child:SetSize (size) end
		child:SetModificationTime (lastModified)
	end
	
	VFS.PermissionBlockNetworker:HandleNotificationForBlock (child:GetPermissionBlock (), inBuffer)
	if newNode then self:DispatchEvent ("NodeCreated", self.Children [name]) end
	return self.Children [name] or (self:IsCaseInsensitive () and self.LowercaseChildren [lowercaseName] or nil)
end

-- Events
function self:PermissionsChanged ()
	local access = self:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "View Folder")
	if self.LastAccess == access then return end
	self.LastAccess = access
	if not self.LastAccess then
		for _, childNode in pairs (self.Children) do
			childNode:DispatchEvent ("Deleted")
			self:DispatchEvent ("NodeDeleted", childNode)
		end
	
		self.Children = {}
		self.LowercaseChildren = {}
		self.ReceivedChildren = false
	end
	
	if self:GetParentFolder () then
		self:GetParentFolder ():DispatchEvent ("NodePermissionsChanged", self)
	end
end

function self:Renamed ()
	self.FolderPath = self:GetPath () == "" and "" or self:GetPath () .. "/"
end