local self = {}
Gooey.MenuItem = Gooey.MakeConstructor (self, Gooey.BaseMenuItem)

--[[
	Events:
		ActionChanged (actionName)
			Fired when this menu item's action has changed.
		Checked (checked)
			Fired when this menu item's check state has changed.
		Click ()
			Fired when this item has been clicked.
		IconChanged (icon)
			Fired when this menu item's icon has changed.
		SubMenuChanged (oldSubMenu, newSubMenu)
			Fired when this menu item's submenu has changed.
		TextChanged (text)
			Fired when this menu item's text has changed.
]]

function self:ctor ()
	self.Text = ""
	self.Checked = false
	self.Icon = nil
	
	self.SubMenu = nil
	
	-- Actions
	self.Action = nil
end

function self:dtor ()
	if self.SubMenu then
		self.SubMenu:dtor ()
	end
end

function self:Clone (menuItem)
	menuItem = menuItem or Gooey.MenuItem ()
	
	-- BaseMenuItem
	menuItem:SetId (self:GetId ())
	menuItem:SetEnabled (self:IsEnabled ())
	menuItem:SetVisible (self:IsVisible ())
	
	-- MenuItem
	menuItem:SetText (self:GetText ())
	menuItem:SetChecked (self:IsChecked ())
	menuItem:SetIcon (self:GetIcon ())
	
	menuItem:SetSubMenu (self:GetSubMenu () and self:GetSubMenu ():Clone () or nil)
	
	-- Events
	self:GetEventProvider ():Clone (menuItem)
	self:GetEventProvider ():Clone (menuItem:GetEventProvider ())
	
	menuItem:SetAction (self:GetAction ())
	
	return menuItem
end

function self:CreateSubMenu ()
	if not self.SubMenu then
		self:SetSubMenu (Gooey.Menu ())
	end
	return self.SubMenu
end

function self:GetAction ()
	return self.Action
end

function self:GetIcon ()
	return self.Icon
end

function self:GetSubMenu ()
	return self.SubMenu
end

function self:GetText ()
	return self.Text
end

function self:IsChecked ()
	return self.Checked
end

function self:IsParent ()
	return self.ChildMenu ~= nil
end

function self:IsItem ()
	return true
end

function self:IsValid ()
	return true
end

function self:SetAction (action)
	if self.Action == action then return self end
	
	self.Action = action
	self:DispatchEvent ("ActionChanged", self.Action)
	
	return self
end

function self:SetChecked (checked)
	if self.Checked == checked then return self end
	
	self.Checked = checked
	self:DispatchEvent ("CheckedChanged", self.Checked)
	
	return self
end

function self:SetIcon (icon)
	if self.Icon == icon then return self end
	
	self.Icon = icon
	self:DispatchEvent ("IconChanged", self.Icon)
	
	return self
end

function self:SetSubMenu (subMenu)
	if self.SubMenu == subMenu then return self end
	
	local oldSubMenu = self.SubMenu
	self.SubMenu = subMenu
	self:DispatchEvent ("SubMenuChanged", oldSubMenu, self.SubMenu)
	
	return self
end

function self:SetText (text)
	if self.Text == text then return self end
	
	self.Text = text
	self:DispatchEvent ("TextChanged", self.Text)
	
	return self
end