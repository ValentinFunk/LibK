local self = {}
GAuth.Group = GAuth.MakeConstructor (self, GAuth.GroupTreeNode)

--[[
	Events:
		NotifyUserAdded (userId)
			Fire this when a user is added to the host Group
		NotifyUserRemoved (userId)
			Fire this when a user is removed from the host Group
			
		UserAdded (userId)
			Fired when a user has been added
		UserRemoved (userId)
			Fired when a user has been removed
]]

function self:ctor (name)
	self.Users = {}
	
	self.MembershipFunction = nil
	
	self.Icon = "icon16/group.png"
	
	self:AddEventListener ("NotifyUserAdded",  self.NotifyUserAdded)	
	self:AddEventListener ("NotifyUserRemoved", self.NotifyUserRemoved)
end

function self:AddUser (authId, userId, callback)
	callback = callback or GAuth.NullCallback

	if self.Users [userId] then callback (GAuth.ReturnCode.Success) return end
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Add User") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if not self:IsPredicted () and not self:IsHostedLocally () then
		local userAdditionRequest = GAuth.Protocol.UserAdditionRequest (self, userId, callback)
		GAuth.EndPointManager:GetEndPoint (self:GetHost ()):StartSession (userAdditionRequest)
		return
	end
	
	self.Users [userId] = true
	self:DispatchEvent ("UserAdded", userId)
	
	callback (GAuth.ReturnCode.Success)
end

function self:ContainsUser (userId, permissionBlock)
	if self.MembershipFunction then return self.MembershipFunction (userId, permissionBlock) end
	return self.Users [userId] and true or false
end

function self:GetMembershipFunction ()
	return self.MembershipFunction
end

function self:GetUserEnumerator ()
	local userList = self.Users
	if self.MembershipFunction then
		for userId, _ in GAuth.PlayerMonitor:GetPlayerEnumerator () do
			if self.MembershipFunction (userId, nil) then
				userList [userId] = true
			end
		end
	end
	
	local next, tbl, key = pairs (userList)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function self:IsGroup ()
	return true
end

function self:RemoveUser (authId, userId, callback)
	callback = callback or GAuth.NullCallback

	if not self.Users [userId] then callback (GAuth.ReturnCode.Success) return end
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Remove User") then callback (GAuth.ReturnCode.AccessDenied) return end
	
	if not self:IsPredicted () and not self:IsHostedLocally () then
		local userRemovalRequest = GAuth.Protocol.UserRemovalRequest (self, userId, callback)
		GAuth.EndPointManager:GetEndPoint (self:GetHost ()):StartSession (userRemovalRequest)
		return
	end
	
	self.Users [userId] = nil
	
	self:DispatchEvent ("UserRemoved", userId)
end

function self:SetMembershipFunction (membershipFunction)
	self.MembershipFunction = membershipFunction
end

-- Events
function self:NotifyUserAdded (userId)
	if self.Users [userId] then return end
	self.Users [userId] = true
	self:DispatchEvent ("UserAdded", userId)
end
	
function self:NotifyUserRemoved (userId)
	if not self.Users [userId] then return end
	self.Users [userId] = nil
	self:DispatchEvent ("UserRemoved", userId)
end