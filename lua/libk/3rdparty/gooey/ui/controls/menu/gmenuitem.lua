local PANEL = {}

function PANEL:Init ()
	self.Id = nil
	self.ContainingMenu = nil
	
	self.Item = nil
	
	self.Checked = false
	self.Icon = nil
	
	self:SetContentAlignment (4)
	self:SetTextInset (20, 0)
	
	self:AddEventListener ("Click",
		function (_)
			self:RunAction ()
		end
	)
end

function PANEL:ContainsPoint (x, y)
	return x >= 0 and x < self:GetWide () and
	       y >= 0 and y < self:GetTall ()
end

function PANEL:DoClick ()
	self:DispatchEvent ("Click", self.ContainingMenu and self.ContainingMenu:GetTargetItem () or nil)
end

function PANEL:GetIcon ()
	return self.Icon and self.Icon.ImageName or nil
end

function PANEL:GetContainingMenu ()
	return self.ContainingMenu
end

function PANEL:GetId ()
	return self.Id
end

function PANEL:GetItem ()
	return self.Item
end

function PANEL:IsChecked ()
	return self.Checked
end

function PANEL:IsItem ()
	return true
end

function PANEL:IsSeparator ()
	return false
end

function PANEL:Paint (w, h)
	if self:IsChecked () then
		surface.SetDrawColor (GLib.Colors.LightBlue)
		surface.DrawRect (2, 2, w - 4, h - 4)
		surface.SetDrawColor (GLib.Colors.CornflowerBlue)
		surface.DrawOutlinedRect (2, 2, w - 4, h - 4)
	end
	
	local subMenu = self:GetItem ():GetSubMenu ()
	local activeMenu = self:GetContainingMenu ():GetActiveSubMenu ()
	if not self.Hovered and
	   self:GetContainingMenu ():GetHoveredItem () == nil and
	   activeMenu and activeMenu:GetMenu () == subMenu then
		self:GetSkin ().tex.MenuBG_Hover (0, 0, w, h)
	end
	derma.SkinHook ("Paint", "MenuOption", self, w, h)
	
	if self:GetItem ():GetSubMenu () then
		self:GetSkin ().tex.Menu.RightArrow (w - 15 - 4, 0.5 * (h - 15), 15, 15)
	end
	
	surface.SetFont ("DermaDefault")
	if self:IsEnabled () then
		surface.SetTextColor (GLib.Colors.Black)
		surface.SetTextPos (22, 4)
	else
		surface.SetTextColor (GLib.Colors.White)
		surface.SetTextPos (23, 5)
		surface.DrawText (self:GetText ())
		surface.SetTextColor (GLib.Colors.Gray)
		surface.SetTextPos (22, 4)
	end
	surface.DrawText (self:GetText ())
	return true
end

function PANEL:SetChecked (checked)
	if self.Checked == checked then return self end
	
	self.Checked = checked
	self:DispatchEvent ("CheckedChanged", self.Checked)
	
	return self
end

function PANEL:SetContainingMenu (menu)
	self.ContainingMenu = menu
end

function PANEL:SetIcon (icon)
	if not icon then
		if self.Icon and self.Icon:IsValid () then
			self.Icon:Remove ()
		end
		self.Icon = nil
		return
	end
	if not self.Icon then
		self.Icon = vgui.Create ("GImage", self)
		self.Icon:SetPos (3, 3)
		self.Icon:SetSize (16, 16)
	end
	
	self.Icon:SetImage (icon)
	
	return self
end

function PANEL:SetId (id)
	self.Id = id
	return self
end

function PANEL:SetItem (menuItem)
	self.Item = menuItem
end

-- Event handlers
function PANEL:OnActionChanged (action)
	if not self:GetAction () then
		self:SetEnabled (self:GetItem ():IsEnabled ())
		return
	end
	
	local actionMap, control = self:GetActionMap ()
	if actionMap then
		local action = actionMap:GetAction (self:GetAction (), control)
		self:SetEnabled (self:GetItem ():IsEnabled () and action and action:CanRun (control) or false)
		if action then
			if action:GetIcon () then
				item:SetIcon (action:GetIcon ())
			end
			if action:IsToggleAction () then
				item:SetChecked (action:IsToggled ())
			end
		end
	end
end

function PANEL:OnCursorEntered ()
	self:GetContainingMenu ():SetHoveredItem (self)
end

function PANEL:OnCursorExited ()
	if self:GetContainingMenu ():GetHoveredItem () == self then
		self:GetContainingMenu ():SetHoveredItem (nil)
	end
end

function PANEL:OnMousePressed (mouseCode)
	if not self:IsEnabled () then
		return false
	end
	
	self.m_MenuClicking = true
	
	DButton.OnMousePressed (self, mouseCode)
end

function PANEL:OnMouseReleased (mouseCode)
	if not self:IsEnabled () then
		return false
	end
	
	DButton.OnMouseReleased (self, mouseCode)

	if self.m_MenuClicking then
		self.m_MenuClicking = false
		self.ContainingMenu:CloseMenus ()
	end
end

Gooey.Register ("GMenuItem", PANEL, "DMenuOption")