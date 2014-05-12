local PANEL = {}

--[[
	GComboBox
	
	Events:
		SelectedItemChanged (ComboBoxItem lastSelectedItem, ComboBoxItem selectedItem)
			Fired when the selected item has changed.
]]

function PANEL:Init ()
	self.DropButton = vgui.Create ("GPanel", self)
	self.DropButton.Paint = function (panel, w, h)
		derma.SkinHook ("Paint", "ComboDownArrow", panel, w, h)
	end
	self.DropButton:SetMouseInputEnabled (false)
	self.DropButton.ComboBox = self
		
	self:SetHeight (22)
	
	self:SetContentAlignment (4)
	self:SetTextInset (8, 0)
	
	self.Items = {}
	self.ItemsById = {}
	self.SelectedItem = nil
	
	self.Menu = Gooey.Menu ()
	self.MenuDownwards = true
	self.MenuOpen = false
	self.MenuCloseTime = 0
	self.Menu:AddEventListener ("MenuOpening",
		function ()
			self:DispatchEvent ("MenuOpening", self.Menu)
		end
	)
	self.Menu:AddEventListener ("MenuClosed",
		function ()
			self.MenuOpen = false
			self.MenuCloseTime = CurTime ()
		end
	)
	
	self:AddEventListener ("MouseDown",
		function (_, mouseCode)
			if mouseCode == MOUSE_LEFT then
				if self.MenuCloseTime ~= CurTime () then
					if not self.Menu then return end
					self.MenuOpen = true
					
					local x, y = self:LocalToScreen (0, 1)
					local menu = self.Menu:Show (self, x, y, self:GetWide (), self:GetTall () - 2, Gooey.Orientation.Vertical)
					self.MenuDownwards = menu:GetAnchorVerticalAlignment () == Gooey.VerticalAlignment.Top
				end
			end
		end
	)
end

function PANEL:AddItem (text, id)
	-- Auto-assign an id if possible
	id = id or text
	if self:GetItemById (id) then
		-- Id already taken
		id = nil
	end
	
	local comboBoxItem = Gooey.ComboBoxItem (self, id)
	comboBoxItem:SetText (text)
	
	self.Items [#self.Items + 1] = comboBoxItem
	self.ItemsById [comboBoxItem:GetId ()] = comboBoxItem
	
	local menuItem = self.Menu:AddItem (comboBoxItem:GetText ())
	comboBoxItem:SetMenuItem (menuItem)
	
	self:HookComboBoxItem (comboBoxItem)
	
	if not self:GetSelectedItem () then
		self:SetSelectedItem (comboBoxItem)
	end
	
	return comboBoxItem
end

function PANEL:Clear ()
	self.Items = {}
	self.ItemsById = {}
	
	self.Menu:Clear ()
	
	self:SetSelectedItem (nil)
end

function PANEL:GetItemById (id)
	return self.ItemsById [id]
end

function PANEL:GetItemCount ()
	return #self.Items
end

function PANEL:GetSelectedItem ()
	return self.SelectedItem
end

function PANEL:IsMenuOpen ()
	return self.MenuOpen
end

function PANEL:SetSelectedItem (comboBoxItem)
	if type (comboBoxItem) == "string" then
		comboBoxItem = self:GetItemById (comboBoxItem)
	end
	
	if self.SelectedItem == comboBoxItem then return self end
	
	local lastSelectedItem = self.SelectedItem
	
	if self.SelectedItem then
		self.SelectedItem:DispatchEvent ("Deselected")
	end
	
	self.SelectedItem = comboBoxItem
	self:SetText (comboBoxItem and comboBoxItem:GetText () or "")
	
	if self.SelectedItem then
		self.SelectedItem:DispatchEvent ("Selected")
	end
	
	self:DispatchEvent ("SelectedItemChanged", lastSelectedItem, self.SelectedItem)
	
	return self
end

function PANEL:DoClick ()
end

function PANEL:OnRemoved ()
	self.Menu:dtor ()
end

function PANEL:OnSelect (index, text, comboBoxItem)
	self:SetSelectedItem (comboBoxItem)
end

function PANEL:Paint (w, h)
	derma.SkinHook ("Paint", "ComboBox", self, w, h)
end

function PANEL:PerformLayout ()
	self.DropButton:SetSize (15, 15)
	self.DropButton:AlignRight (4)
	self.DropButton:CenterVertical ()
	
	self.Menu:SetWidth (self:GetWidth ())
end

-- Hooks
function PANEL:HookComboBoxItem (comboBoxItem)
	if not comboBoxItem then return end
	
	comboBoxItem:AddEventListener ("TextChanged", self:GetHashCode (),
		function ()
			
		end
	)
end

function PANEL:UnhookComboBoxItem (comboBoxItem)
	if not comboBoxItem then return end
	
	comboBoxItem:RemoveEventListener ("TextChanged", self:GetHashCode ())
end

Gooey.Register ("GComboBox", PANEL, "GButton")