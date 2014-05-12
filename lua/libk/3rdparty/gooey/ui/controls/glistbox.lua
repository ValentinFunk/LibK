local PANEL = {}

--[[
	Events:
		Scroll (scrollOffset)
			Fired when the ListBox has been scrolled.
		SelectionChanged (item)
			Fired when the selected item has changed.
		SelectionCleared ()
			Fired when the selection has been cleared.
]]

function PANEL:Init ()
	self.SelectionController = Gooey.SelectionController (self)
	
	self.LastClickTime = 0

	self.pnlCanvas.LocalToParent = self.LocalToParent
	self.pnlCanvas.LocalToScreen = self.LocalToScreen
	self.pnlCanvas.OnMouseReleased = function (self, mouseCode)
		self:GetParent ():OnMouseReleased (mouseCode)
	end
	
	self.ItemsByID = {}
	self.Sorted = {}
	self.SortedIdsValid = true
	
	self.Comparator = nil
	
	self.ExpectingScrollLayout = false
	self.LastRebuildTime = 0

	self.Menu = nil
	
	self.SelectionController:AddEventListener ("SelectionChanged",
		function (_, item)
			self:DispatchEvent ("SelectionChanged", item)
		end
	)
	
	self.SelectionController:AddEventListener ("SelectionCleared",
		function (_, item)
			self:DispatchEvent ("SelectionCleared", item)
		end
	)
end

function PANEL:AddItem (text, id)
    local listBoxItem = vgui.Create ("GListBoxItem", self)
	
	-- inline expansion of SetMother and SetID
    listBoxItem.ListBox = self
	listBoxItem.m_pMother = self
	listBoxItem.ID = id
    listBoxItem:SetText (text)
	if id then
		self.ItemsByID [id] = listBoxItem
	end

    -- inline expansion of DPanelList.AddItem (self, listBoxItem)
	listBoxItem:SetVisible (true)
	listBoxItem:SetParent (self.pnlCanvas)
	self.Items [#self.Items + 1] = listBoxItem
	
	self.Sorted [#self.Sorted + 1] = listBoxItem
	listBoxItem:SetSortedId (#self.Sorted)
	
	self.LastRebuildTime = 0
	
	self:InvalidateLayout ()
	
    return listBoxItem
end

function PANEL:Clear ()
	self.Sorted = {}

	DListBox.Clear (self)
	
	self:ClearSelection ()
end

function PANEL:ClearSelection ()
	self.SelectionController:ClearSelection ()
end

function PANEL.DefaultComparator (a, b)
	return a:GetText () < b:GetText ()
end

function PANEL:EnsureVisible (listBoxItem)
	if not listBoxItem then return end
	if self:IsItemVisible (listBoxItem) then return end
	
	local left, top, right, bottom = self:GetContentBounds ()
	local _, y = listBoxItem:GetPos ()
	local h = listBoxItem:GetTall ()
	if y < self:GetScrollOffset () then
		self:SetScrollOffset (-top + y)
	elseif y + h > self:GetScrollOffset () + self:GetTall () then
		self:SetScrollOffset (y + h - bottom)
	end
end

function PANEL:GetContentBounds ()
	return 1, 1, self:GetWide () - 1, self:GetTall () - 1
end

function PANEL:GetFirstItem ()
	return self:GetItems () [next (self:GetItems ())]
end

function PANEL:GetItemByID (id)
	local item = self.ItemsByID [id]
	if item and not item:IsValid () then
		self.ItemsByID [id] = nil
		item = nil
	end
	return nil
end

function PANEL:GetItemBySortedId (sortedId)
	return self.Sorted [sortedId]
end

function PANEL:GetItemCount ()
	return #self.Items
end

function PANEL:GetItemEnumerator ()
	local next, tbl, key = pairs (self:GetItems ())
	return function ()
		key = next (tbl, key)
		return tbl [key]
	end
end

function PANEL:GetMenu ()
	return self.Menu
end

function PANEL:GetScrollOffset ()
	if not self.VBar then return 0 end
	return self.VBar:GetScroll ()
end

function PANEL:GetSelectedItems ()
	return self.SelectionController:GetSelectedItems ()
end

function PANEL:GetSelectedItem ()
	return self.SelectionController:GetSelectedItem ()
end

function PANEL:GetSelectionEnumerator ()
	return self.SelectionController:GetSelectionEnumerator ()
end

function PANEL:GetSelectionMode ()
	return self.SelectionController:GetSelectionMode ()
end

function PANEL:HasFocus ()
	if debug.getregistry ().Panel.HasFocus (self) then
		return true
	end
	return self.VBar:HasFocus () or self.VBar.btnUp:HasFocus () or self.VBar.btnDown:HasFocus () or self.VBar.btnGrip:HasFocus ()
end

function PANEL:IsEmpty ()
	return next (self.Items) == nil
end

function PANEL:IsHovered ()
	if self.Hovered then
		return true
	end
	if not self:IsVisible () then
		return false
	end
	local mx, my = gui.MouseX (), gui.MouseY ()
	mx, my = self:ScreenToLocal (mx, my)
	if mx >= 0 and my >= 0 and mx <= self:GetWide () and my <= self:GetTall () then
		return true
	end
	return false
end

--- Returns whether the specified ListBoxItem lies fully within the visible part of the ListBox
-- @return A boolean indicating whether the specified ListBoxItem lies fully within the visible part of the ListBox
function PANEL:IsItemVisible (listBoxItem)
	if not listBoxItem then return false end
	local _, y = listBoxItem:GetPos ()
	local h = listBoxItem:GetTall ()
	local viewY = self:GetScrollOffset ()
	return y >= viewY and y + h < viewY + self:GetTall ()
end

function PANEL:ItemFromPoint (x, y)
	x, y = self:LocalToScreen (x, y)
	for _, item in pairs (self:GetItems ()) do
		local px, py = item:GetPos ()
		px, py = item:GetParent ():LocalToScreen (px, py)
		local w, h = item:GetSize ()
		if px <= x and x < px + w and
			py <= y and y < py + h then
			return item
		end
	end
	return nil
end

function PANEL:PaintOver ()
	self.SelectionController:PaintOver (self)
end

function PANEL:PerformLayout ()
	DListBox.PerformLayout (self)
	
	if self.ExpectingScrollLayout then
		self.ExpectingScrollLayout = false
		self:DispatchEvent ("Scroll", self:GetScrollOffset ())
	end
end

function PANEL:Rebuild ()
	if CurTime () == self.LastRebuildTime then return end
	
	local offset = 0
	
	local padding = self.Padding
	local spacing = self.Spacing
	
	local canvasWidth = self.pnlCanvas:GetWide ()
	canvasWidth = canvasWidth - padding
	if not self.VBar or not self.VBar:IsVisible () then
		canvasWidth = canvasWidth - padding
	end
	
	local y = padding
	local h = 0
	for _, panel in ipairs (self.Sorted) do
		h = panel:GetTall ()
		if panel:IsVisible () then
			panel:SetPos (padding, y)
			panel:SetWide (canvasWidth)
			
			y = y + h + spacing
		end
	end
	if h ~= 0 then
		offset = y + h + spacing
	end
	
	self.pnlCanvas:SetTall (offset + padding * 2 - spacing)
	
	self.LastRebuildTime = CurTime ()
end

function PANEL:RemoveID (id)
	local item = self:GetItemByID (id)
	item:SetID (nil)
	self:RemoveItem (item)
end

function PANEL:RemoveItem (item)
	for k, v in pairs (self.Sorted) do
		if v == item then
			table.remove (self.Sorted, k)
			self:InvalidateSortedIds ()
			break
		end
	end
	
	if self.SelectionController:IsSelected (item) then
		self.SelectionController:RemoveFromSelection (item)
	end

	DPanelList.RemoveItem (self, item)
end

function PANEL:SetComparator (comparator)
	self.Comparator = comparator
end

function PANEL:SetItemID (item, id)
	if self.ItemsByID [item:GetID ()] and self.ItemsByID [item:GetID ()] == item then
		self.ItemsByID [item:GetID ()] = nil
	end
	if self.ItemsByID [id] == item then
		return
	end
	if id ~= nil then
		self.ItemsByID [id] = item
	end
	item:SetID (id)
end

function PANEL:SetMenu (menu)
	self.Menu = menu
end

function PANEL:SetScrollOffset (scrollOffset)
	if scrollOffset + self:GetTall () > self.pnlCanvas:GetTall () then
		scrollOffset = self.pnlCanvas:GetTall () - self:GetTall ()
	end
	if scrollOffset < 0 then scrollOffset = 0 end
	
	self.VBar:SetScroll (scrollOffset)
end

function PANEL:SetSelectedItem (listBoxItem)
	self.SelectionController:ClearSelection ()
	self.SelectionController:AddToSelection (listBoxItem)
end

function PANEL:SetSelectionMode (selectionMode)
	self.SelectionController:SetSelectionMode (selectionMode)
end

function PANEL:Sort (comparator)
	comparator = comparator or self.Comparator or self.DefaultComparator
	table.sort (self.Sorted,
		function (a, b)
			if a == nil then return false end
			if b == nil then return true end
			return comparator (a, b)
		end
	)
	
	self:InvalidateSortedIds ()
	self:InvalidateLayout ()
end

-- Internal, do not call
function PANEL:InvalidateSortedIds ()
	self.SortedIdsValid = false
end

function PANEL:ValidateSortedIds ()
	if self.SortedIdsValid then return end
	self.SortedIdsValid = true
	
	for sortedId, listBoxItem in ipairs (self.Sorted) do
		listBoxItem:SetSortedId (sortedId)
	end
end

-- Event handlers
function PANEL:DoClick (item)
	if SysTime () - self.LastClickTime < 0.3 then
		self:DoDoubleClick ()
		self.LastClickTime = 0
	else
		self:DispatchEvent ("Click", self:ItemFromPoint (self:CursorPos ()))
		self.LastClickTime = SysTime ()
	end
end

function PANEL:DoDoubleClick ()
	self:DispatchEvent ("DoubleClick", self:ItemFromPoint (self:CursorPos ()))
end

function PANEL:DoRightClick ()
	self:DispatchEvent ("RightClick", self:ItemFromPoint (self:CursorPos ()))
end

function PANEL:OnCursorMoved (x, y)
	self:DispatchEvent ("MouseMove", 0, x, y)
end

function PANEL:OnMousePressed (mouseCode)
	self:DispatchEvent ("MouseDown", mouseCode, self:CursorPos ())
end

function PANEL:OnMouseReleased (mouseCode)
	self:DispatchEvent ("MouseUp", mouseCode, self:CursorPos ())
	if mouseCode == MOUSE_LEFT then
		self:DoClick (self:ItemFromPoint (self:CursorPos ()))
	elseif mouseCode == MOUSE_RIGHT then
		self:DoRightClick (self:ItemFromPoint (self:CursorPos ()))
		if self:GetSelectionMode () == Gooey.SelectionMode.Multiple then
			if self.Menu then
				self.Menu:Show (self, self:GetSelectedItems ())
			end
		else
			if self.Menu then
				self.Menu:Show (self, self:GetSelectedItem ())
			end
		end
	end
end

function PANEL:OnRemoved ()
	if self.Menu then self.Menu:dtor () end
end

function PANEL:OnVScroll (scrollOffset)
	DListBox.OnVScroll (self, scrollOffset)
	self.ExpectingScrollLayout = true
end

Gooey.Register ("GListBox", PANEL, "DListBox")