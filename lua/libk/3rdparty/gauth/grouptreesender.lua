local self = {}
GAuth.GroupTreeSender = GAuth.MakeConstructor (self)

function self:ctor ()
	self.PermissionBlockNetworker = GAuth.PermissionBlockNetworker ("GAuth")
	self.PermissionBlockNetworker:SetResolver (
		function (permissionBlockId)
			local groupTreeNode = GAuth.ResolveGroupTreeNode (permissionBlockId)
			return groupTreeNode and groupTreeNode:GetPermissionBlock ()
		end
	)
	self.PermissionBlockNetworker:SetNotificationFilter (
		function (remoteId, permissionBlockId, permissionBlock)
			local groupTreeNode = GAuth.ResolveGroupTreeNode (permissionBlockId)
			if not groupTreeNode then return end
			
			local hostId = groupTreeNode:GetHost ()
	
			if hostId == GAuth.GetLocalId () then return false end
			if hostId == remoteId then return true end
			if remoteId == GAuth.GetServerId () then return true end

			return false
		end
	)
	self.PermissionBlockNetworker:SetRequestFilter (
		function (permissionBlock)
			local groupId = permissionBlock:GetName ()
			local groupTreeNode = GAuth.ResolveGroupTreeNode (groupId)
			if not groupTreeNode then return false end
			if groupTreeNode:IsPredicted () then return false end
			
			return true, groupTreeNode:GetHost ()
		end
	)

	-- Make a closure for the NodeAdded and Removed event handler
	self.NodeAdded = function (groupTreeNode, childNode)
		self:HookNode (childNode)
	
		if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
		GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.NodeAdditionNotification (groupTreeNode, childNode))
	end
	
	self.HostChanged = function (groupTreeNode, hostId)
		self.PermissionBlockNetworker:UnhookBlock (groupTreeNode:GetPermissionBlock ())
		if groupTreeNode:IsHostedLocally () then
			self.PermissionBlockNetworker:HookBlock (groupTreeNode:GetPermissionBlock ())
		else
			self.PermissionBlockNetworker:HookRemoteBlock (groupTreeNode:GetPermissionBlock ())
		end
	end
	
	self.Removed = function (groupTreeNode)
		self:UnhookNode (groupTreeNode)
	end
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
	
	if groupTreeNode:IsHostedLocally () then
		self.PermissionBlockNetworker:HookBlock (groupTreeNode:GetPermissionBlock ())
	else
		self.PermissionBlockNetworker:HookRemoteBlock (groupTreeNode:GetPermissionBlock ())
	end
end

function self:SendNode (destUserId, groupTreeNode)
	local send = true
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then send = false end
	if groupTreeNode:GetHost () == destUserId then send = false end
	
	if send then
		self.PermissionBlockNetworker:SynchronizeBlock (destUserId, groupTreeNode:GetPermissionBlock ())
	end
	
	if groupTreeNode:IsGroup () then
		if send then
			for userId in groupTreeNode:GetUserEnumerator () do
				GAuth.EndPointManager:GetEndPoint (destUserId):SendNotification (GAuth.Protocol.UserAdditionNotification (groupTreeNode, userId))
			end
		end
	elseif groupTreeNode:IsGroupTree () then
		for _, childNode in groupTreeNode:GetChildEnumerator () do
			if send then
				GAuth.EndPointManager:GetEndPoint (destUserId):SendNotification (GAuth.Protocol.NodeAdditionNotification (groupTreeNode, childNode))
			end
			self:SendNode (destUserId, childNode)
		end
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
	
	self.PermissionBlockNetworker:UnhookBlock (groupTreeNode:GetPermissionBlock ())
end

-- Events
self.NodeAdded = GAuth.NullCallback -- Needs to be a closure to access self:Hook ()

function self.NodeRemoved (groupTreeNode, childNode)
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
	GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.NodeRemovalNotification (groupTreeNode, childNode))
end

function self.UserAdded (groupTreeNode, userId)
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
	GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.UserAdditionNotification (groupTreeNode, userId))
end
		
function self.UserRemoved (groupTreeNode, userId)
	if groupTreeNode:GetHost () ~= GAuth.GetLocalId () and not SERVER then return end
	GAuth.EndPointManager:GetEndPoint (GAuth.GetEveryoneId ()):SendNotification (GAuth.Protocol.UserRemovalNotification (groupTreeNode, userId))
end

-- These needs to be closures in order to access self.PermissionBlockNetworker
-- and self:UnhookNode ()
self.HostChanged = GAuth.NullCallback
self.Removed     = GAuth.NullCallback

GAuth.GroupTreeSender = GAuth.GroupTreeSender ()