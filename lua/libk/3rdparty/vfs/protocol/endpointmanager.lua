VFS.EndPointManager = GLib.Protocol.EndPointManager ("VFS", VFS.Protocol.EndPoint)
VFS.PermissionBlockNetworker = GAuth.PermissionBlockNetworker ("VFS")

VFS.PermissionBlockNetworker:SetResolver (
	function (permissionBlockId)
		local node = VFS.Root:GetChildSynchronous (permissionBlockId)
		if not node then return false end
		return node:GetPermissionBlock ()
	end
)

VFS.PermissionBlockNetworker:SetNotificationFilter (
	function (remoteId, permissionBlockId, permissionBlock)
		local node = VFS.Root:GetChildSynchronous (permissionBlockId)
		if not node then return false end
		local netNode = node:GetInner ()
		if not netNode then return false end
		local hostId = netNode.EndPoint and netNode.EndPoint:GetRemoteId () or GAuth.GetLocalId ()

		if hostId == GAuth.GetLocalId () then return false end
		if hostId == remoteId then return true end
		if remoteId == GAuth.GetServerId () then return true end

		return false
	end
)

VFS.PermissionBlockNetworker:SetNotificationRecipientListGenerator (
	function (permissionBlockId, permissionBlock, notification)
		local node = VFS.Root:GetChildSynchronous (permissionBlockId)
		if not node then return {} end
		if node:IsRoot () then return "Everyone" end
		local parentNode = node:GetParentFolder ()
		
		local recipientList = {}
		for _, endPoint in VFS.EndPointManager:GetEndPointEnumerator () do
			if endPoint:GetRemoteId () ~= GAuth.GetEveryoneId () then
				if endPoint:IsNodeHooked (node) and parentNode:GetPermissionBlock ():IsAuthorized (endPoint:GetRemoteId (), "View Folder") then
					VFS.Debug (node:GetPath () .. " is hooked by " .. endPoint:GetRemoteId ())
					recipientList [#recipientList + 1] = endPoint:GetRemoteId ()
				end
			end
		end
		return recipientList
	end
)

VFS.PermissionBlockNetworker:SetRequestFilter (
	function (permissionBlock)
		local path = permissionBlock:GetName ()
		local node = VFS.Root:GetChildSynchronous (path)
		if not node then VFS.Error ("Failed to resolve path " .. path) return false end
		node = node:GetInner ()
		
		if not node.EndPoint then VFS.Error ("Non networked node " .. path) return false end
		if node:IsPredicted () then VFS.Debug (path .. " is predicted.") return false end
		
		VFS.Debug ("Remote: " .. node.EndPoint:GetRemoteId () .. ": " .. path)
		return true, node.EndPoint:GetRemoteId ()
	end
)