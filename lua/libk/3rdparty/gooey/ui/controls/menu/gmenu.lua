local PANEL = {}

function PANEL:Init ()
	self.ClassName = "DMenu"
	self:SetVisible (false)
	
	self.TargetItem = nil
	
	self.Menu = nil
	self.ItemControls = {}
	
	-- Anchoring
	self.AnchorOrientation = Gooey.Orientation.Vertical
	self.AnchorX = 0
	self.AnchorY = 0
	self.AnchorW = 0
	self.AnchorH = 0
	
	self.AnchorVerticalAlignment = Gooey.VerticalAlignment.Top
	self.AnchorHorizontalAlignment = Gooey.HorizontalAlignment.Top
	
	-- Submenus
	self.HoverActionTime = 0
	self.HoveredItem = nil
	self.ActiveSubMenu = nil
	
	self:SetMouseInputEnabled (true)
	self:SetKeyboardInputEnabled (true)
	
	-- Remove ourselves from the derma menu list
	local _, menuList = debug.getupvalue (RegisterDermaMenuForClose, 1)
	menuList [#menuList] = nil
	
	self:SetDeleteSelf (false)
	
	Gooey:AddEventListener ("Unloaded", self:GetHashCode (),
		function ()
			self:Remove ()
		end
	)
	
	self:AddEventListener ("VisibleChanged",
		function (_, visible)
			if visible then
				Gooey.RegisterOpenMenu (self)
				
				self:PerformLayout ()
				
				-- Set the enabled state and icons of all menu items associated with an action
				local actionMap, control = self:GetActionMap ()
				if actionMap then
					for menuItem in self:GetEnumerator () do
						if menuItem:IsItem () then
							if menuItem:GetAction () then
								local action = actionMap:GetAction (menuItem:GetAction (), control)
								menuItem:SetEnabled (menuItem:GetItem ():IsEnabled () and action and action:CanRun (control) or false)
								if action then
									if action:GetIcon ()then
										menuItem:SetIcon (action:GetIcon ())
									end
									if action:IsToggleAction () then
										menuItem:SetChecked (action:IsToggled ())
									end
								end
							else
								menuItem:SetEnabled (menuItem:GetItem ():IsEnabled ())
							end
						end
					end
				end
				
				DMenu.Open (self, self:GetPos ())
				
				-- This fixes menu items somehow losing mouse focus as 
				-- soon as a mouse press occurs when another panel has keyboard focus.
				self:SetKeyboardInputEnabled (true)
				self:Focus ()
			else
				DMenu.Hide (self)
				
				self:CloseSubMenu ()
				self:SetHoveredItem (nil)
				self:GetMenu ():DispatchEvent ("MenuClosed")
			end
		end
	)
end

function PANEL:CloseMenus ()
	Gooey.CloseMenus ()
end

function PANEL:CloseSubMenu ()
	if not self.ActiveSubMenu then return end
	if not self.ActiveSubMenu:IsValid () then return end
	
	self.ActiveSubMenu:Hide ()
	self.ActiveSubMenu = nil
end

function PANEL:GetAnchorHorizontalAlignment ()
	return self.AnchorHorizontalAlignment
end

function PANEL:GetAnchorVerticalAlignment ()
	return self.AnchorVerticalAlignment
end

function PANEL:GetEnumerator ()
	local children = self:GetCanvas ():GetChildren ()
	local i = 0
	return function ()
		i = i + 1
		while children [i] and children [i]:IsMarkedForDeletion () do
			i = i + 1
		end
		return children [i]
	end
end

function PANEL:GetHoveredItem ()
	return self.HoveredItem
end

function PANEL:GetItemById (id)
	for control in self:GetEnumerator () do
		if control.Id == id then
			return control
		end
	end
	return nil
end

function PANEL:GetMenu ()
	return self.Menu
end

function PANEL:GetTargetItem ()
	return self.TargetItem
end

function PANEL:Hide ()
	self:SetVisible (false)
end

function PANEL:Open ()
	self:SetVisible (true)
end

function PANEL:OpenSubMenu (item, menu)
	if item and not item:IsEnabled () then return end
	
	local activeSubMenu = self:GetActiveSubMenu ()
	if activeSubMenu then
		if menu and activeSubMenu:GetMenu () == menu then return end
		
		self:CloseSubMenu ()
	end
	
	if not menu then return end

	local x, y = item:LocalToScreen (0, 0)
	local activeSubMenu = menu:Show (self, self:GetTargetItem (), x + 3, y, item:GetWide () - 6, item:GetTall (), Gooey.Orientation.Horizontal)
	
	self:SetActiveSubMenu (activeSubMenu)
end

function PANEL:PerformLayout ()
	DMenu.PerformLayout (self)
	
	local w, h = self:GetMinimumWidth (), 0
	
	for control in self:GetEnumerator () do
		control:PerformLayout()
		w = math.max (w, control:GetWide ())
    end
	
	-- Enforce fixed width
	w = self.Menu:GetWidth () or w
	self:SetWidth (w)
	for control in self:GetEnumerator () do
		control:SetWide (w)
		control:SetPos (0, h)
		control:InvalidateLayout (true)
		
		if control:IsVisible () then
			h = h + control:GetTall ()
		end
	end
	
	self:SetHeight (h)
	self:Reanchor ()
	
	DScrollPanel.PerformLayout (self)
end

function PANEL:SetAnchorOrientation (anchorOrientation)
	if self.AnchorOrientation == anchorOrientation then return end
	
	self.AnchorOrientation = anchorOrientation
	
	if self:IsVisible () then
		self:Reanchor ()
	end
end

function PANEL:SetAnchorRectangle (x, y, w, h)
	self.AnchorX = x
	self.AnchorY = y
	self.AnchorW = w
	self.AnchorH = h
	
	if self:IsVisible () then
		self:Reanchor ()
	end
end

function PANEL:SetHoveredItem (hoveredItem)
	self.HoveredItem = hoveredItem
	if self.HoveredItem then
		self.HoverActionTime = CurTime () + 0.2
	else
		self.HoverActionTime = math.huge
	end
end

function PANEL:SetMenu (menu)
	if self.Menu == menu then return self end
	
	for control in self:GetEnumerator () do
		self:UnhookMenuItem (control.Item)
	end
	self:Clear ()
	self.ItemControls = {}
	
	self:UnhookMenu (self.Menu)
	
	self.Menu = menu
	
	if self.Menu then
		for menuItem in self.Menu:GetEnumerator () do
			self:AddMenuItem (menuItem)
		end
	end
	self:HookMenu (self.Menu)
	
	return self
end

function PANEL:SetTargetItem (targetItem)
	self.TargetItem = targetItem
end

-- Event handlers
function PANEL:OnRemoved ()
	if self:IsVisible () then self:Hide () end
	
	self:SetMenu (nil)
	
	Gooey:RemoveEventListener ("Unloaded", self:GetHashCode ())
end

function PANEL:Think ()
	if CurTime () > self.HoverActionTime then
		local subMenu = nil
		local hoveredItem = self:GetHoveredItem () and self:GetHoveredItem ():GetItem ()
		if hoveredItem and
		   hoveredItem:IsEnabled () and
		   hoveredItem:IsItem () then
			subMenu = hoveredItem:GetSubMenu ()
		end
		
		local currentSubMenu = self:GetActiveSubMenu () and self:GetActiveSubMenu ():GetMenu ()
		
		if subMenu ~= currentSubMenu then
			self:CloseSubMenu ()
			if subMenu then
				self:OpenSubMenu (self:GetHoveredItem (), subMenu)
			end
		end
		
		self.HoverActionTime = math.huge
	end
end

-- Internal, do not call
function PANEL:GetActiveSubMenu ()
	return self.ActiveSubMenu
end

function PANEL:Reanchor ()
	local x = self.AnchorX + (self.AnchorOrientation == Gooey.Orientation.Horizontal and self.AnchorW or 0)
	local horizontalAlignment = Gooey.HorizontalAlignment.Left
	if x + self:GetWide () > ScrW () then
		local leftClearance = self.AnchorX - self:GetWide ()
		local rightClearance = ScrW () - x - self:GetWide ()
		if leftClearance > rightClearance then
			x = self.AnchorX - self:GetWide () + (self.AnchorOrientation == Gooey.Orientation.Vertical and self.AnchorW or 0)
			horizontalAlignment = Gooey.HorizontalAlignment.Right
		end
	end
	
	local y = self.AnchorY + (self.AnchorOrientation == Gooey.Orientation.Vertical and self.AnchorH or 0)
	local verticalAlignment = Gooey.VerticalAlignment.Top
	if y + self:GetTall () > ScrH () then
		local topClearance = self.AnchorY - self:GetTall ()
		local bottomClearance = ScrH () - y - self:GetTall ()
		if topClearance > bottomClearance then
			y = self.AnchorY - self:GetTall () + (self.AnchorOrientation == Gooey.Orientation.Horizontal and self.AnchorH or 0)
			verticalAlignment = Gooey.VerticalAlignment.Bottom
		end
	end
	
	self:SetAnchorVerticalAlignment (verticalAlignment)
	self:SetAnchorHorizontalAlignment (horizontalAlignment)
	self:SetPos (x, y)
end

function PANEL:SetActiveSubMenu (subMenu)
	self.ActiveSubMenu = subMenu
end

function PANEL:SetAnchorHorizontalAlignment (anchorHorizontalAlignment)
	if self.AnchorHorizontalAlignment == anchorHorizontalAlignment then return end
	
	self.AnchorHorizontalAlignment = anchorHorizontalAlignment
end

function PANEL:SetAnchorVerticalAlignment (anchorVerticalAlignment)
	if self.AnchorVerticalAlignment == anchorVerticalAlignment then return end
	
	self.AnchorVerticalAlignment = anchorVerticalAlignment
end

function PANEL:AddMenuItem (menuItem)
	if not menuItem then return end
	
	local control = nil
	
	if menuItem:IsSeparator () then
		control = self:AddSeparator (menuItem)
	elseif menuItem:IsItem () then
		control = self:AddButton (menuItem)
	end
	
	if not control then return end
	
	GLib.BindProperty (control, menuItem, "Enabled", self:GetHashCode ())
	GLib.BindProperty (control, menuItem, "Visible", self:GetHashCode ())
	
	self.ItemControls [menuItem] = control
	
	control:AddEventListener ("Click", self:GetHashCode (),
		function (_, targetItem)
			menuItem:DispatchEvent ("Click", targetItem)
		end
	)
end

function PANEL:AddButton (menuItem)
	local control = vgui.Create ("GMenuItem", self)
	control:SetId (menuItem:GetId ())
	control:SetContainingMenu (self)
	control:SetItem (menuItem)
	
	GLib.BindProperty (control, menuItem, "Action",  self:GetHashCode ())
	GLib.BindProperty (control, menuItem, "Checked", self:GetHashCode ())
	GLib.BindProperty (control, menuItem, "Icon",    self:GetHashCode ())
	GLib.BindProperty (control, menuItem, "Text",    self:GetHashCode ())
	
	self:AddPanel (control)
	
	return control
end

function PANEL:AddSeparator (menuItem)
    local control = vgui.Create ("GMenuSeparator", self)
	control:SetId (menuItem:GetId ())
	control:SetContainingMenu (self)
	control:SetItem (menuItem)
	
    control:SetTall (1)
	
    self:AddPanel (control)
	
	return control
end

PANEL.AddSpacer = PANEL.AddSeparator

function PANEL:RemoveMenuItem (menuItem)
	if not menuItem then return end
	
	self:UnhookMenuItem (menuItem)
	
	self.ItemControls [menuItem]:Remove ()
	self.ItemControls [menuItem] = nil
end

function PANEL:UnhookMenuItem (menuItem)
	local control = self.ItemControls [menuItem]
	
	menuItem:RemoveEventListener ("Click", self:GetHashCode ())
	
	GLib.UnbindProperty (control, menuItem, "Enabled", self:GetHashCode ())
	GLib.UnbindProperty (control, menuItem, "Visible", self:GetHashCode ())
	GLib.UnbindProperty (control, menuItem, "Action",  self:GetHashCode ())
	GLib.UnbindProperty (control, menuItem, "Checked", self:GetHashCode ())
	GLib.UnbindProperty (control, menuItem, "Icon",    self:GetHashCode ())
	GLib.UnbindProperty (control, menuItem, "Text",    self:GetHashCode ())
end

function PANEL:HookMenu (menu)
	if not menu then return end
	
	menu:AddEventListener ("Cleared", self:GetHashCode (),
		function (_)
			for control in self:GetEnumerator () do
				self:UnhookMenuItem (control.Item)
			end
			self:Clear ()
			self.ItemControls = {}
		end
	)
	
	menu:AddEventListener ("ItemAdded", self:GetHashCode (),
		function (_, menuItem)
			self:AddMenuItem (menuItem)
		end
	)
	
	menu:AddEventListener ("ItemRemoved", self:GetHashCode (),
		function (_, menuItem)
			self:RemoveMenuItem (menuItem)
		end
	)
	
	menu:AddEventListener ("WidthChanged", self:GetHashCode (),
		function (_, width)
			self:PerformLayout ()
		end
	)
end

function PANEL:UnhookMenu (menu)
	if not menu then return end
	
	menu:RemoveEventListener ("Cleared",      self:GetHashCode ())
	menu:RemoveEventListener ("ItemAdded",    self:GetHashCode ())
	menu:RemoveEventListener ("ItemRemoved",  self:GetHashCode ())
	menu:RemoveEventListener ("WidthChanged", self:GetHashCode ())
end

Gooey.Register ("GMenu", PANEL, "DMenu")