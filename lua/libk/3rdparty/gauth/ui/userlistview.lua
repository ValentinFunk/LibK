local self = {}

--[[
	Events:
		UserSelected (userId)
			Fired when a user is selected from the list.
]]

function self:Init ()
	for userId in GAuth.PlayerMonitor:GetUserEnumerator () do
		local item = self:AddItem (GAuth.PlayerMonitor:GetUserName (userId), userId)
		item:SetIcon (GAuth.GetUserIcon (userId))
		item.UserId = userId
	end
	local item = self:AddItem ("System", "System")
	item:SetIcon (GAuth.GetUserIcon ("System"))
	item.UserId = "System"
	local item = self:AddItem ("Server", "Server")
	item:SetIcon (GAuth.GetUserIcon ("Server"))
	item.UserId = "Server"
	self:Sort ()
end

function self.DefaultComparator (a, b)
	if a == b then return false end
	if a.UserId == "System" then return true end
	if b.UserId == "System" then return false end
	if a.UserId == "Server" then return true end
	if b.UserId == "Server" then return false end
	return a:GetText ():lower () < b:GetText ():lower ()
end

function self:GetSelectedUser ()
	local item = self.SelectionController:GetSelectedItem ()
	return item and item.UserId or nil
end

function self:GetSelectedUsers ()
	local selectedUsers = {}
	for userId in self:GetSelectionEnumerator () do
		selectedUsers [#selectedUsers + 1] = userId
	end
	return selectedUsers
end

function self:GetSelectionEnumerator ()
	local next, tbl, key = ipairs (self.SelectionController:GetSelectedItems ())
	return function ()
		key = next (tbl, key)
		return tbl [key] and tbl [key].UserId or nil
	end
end

vgui.Register ("GAuthUserListView", self, "GListBox")