local PANEL = {}

--[[
	Events:
		Click (ListViewItem item)
			Fired when an item has been clicked.
		DoubleClick (ListViewItem item)
			Fired when an item has been double clicked.
		ItemChecked (ListViewItem item, columnId, checked)
			Fired when an item's checkbox has been toggled.
		ItemHeightChanged (itemHeight)
			Fired when the item height has changed.
		RightClick (ListViewItem item)
			Fired when an item has been right clicked.
		SelectionChanged (ListViewItem item)
			Fired when the selected item has changed.
		SelectionCleared ()
			Fired when the selection has been cleared.
]]

function PANEL:Init ()
	self.LastClickTime = 0

	self.Menu = nil
	self.HeaderMenu = nil
	
	-- Columns
	self.Columns = Gooey.ListView.ColumnCollection (self)
	self.ColumnComparators = {}
	
	self.Header = vgui.Create ("GListViewHeader", self)
	self.Header:SetListView (self)
	self.Header:SetColumnCollection (self.Columns)
	self.Header:SetZPos (10)
	
	self.HeaderHeight = 22
	self.HeaderVisible = true
	
	self.Columns:AddEventListener ("ColumnAdded",
		function (_, column)
			self:InvalidateSubItemLayout ()
		end
	)
	
	self.Columns:AddEventListener ("ColumnAlignmentChanged",
		function (_, column, alignment)
			self:InvalidateSubItemLayout ()
		end
	)
	
	self.Columns:AddEventListener ("ColumnRemoved",
		function (_, column)
			self:InvalidateSubItemLayout ()
		end
	)
	
	self.Header:AddEventListener ("HeaderWidthChanged",
		function (_, headerWidth)
			self.ScrollableViewController:SetContentWidth (headerWidth)
			self.ItemCanvas:SetWide (math.max (headerWidth, self:GetWide () - 2))
			self:InvalidateSubItemLayout ()
		end
	)
	
	-- Items
	self.Items = Gooey.ListView.ItemCollection (self)
	self.ItemHeight = 0
	self.ShowIcons = true
	
	self.Items:AddEventListener ("ItemAdded",
		function (_, listViewItem)
			listViewItem:SetParent (self.ItemCanvas)
			self:UpdateContentHeight ()
			self:InvalidateVerticalItemLayout ()
		end
	)
	
	self.Items:AddEventListener ("ItemRemoved",
		function (_, listViewItem)
			self:UpdateContentHeight ()
			self:InvalidateVerticalItemLayout ()
			self.SelectionController:RemoveFromSelection (listViewItem)
		end
	)
	
	-- Keyboard
	self.FocusedItem = nil
	
	-- Selection
	self.SelectionController = Gooey.SelectionController (self)
	
	self.SelectionController:AddEventListener ("SelectionChanged",
		function (_, listViewItem)
			self:DispatchEvent ("SelectionChanged", listViewItem)
		end
	)
	
	self.SelectionController:AddEventListener ("SelectionCleared",
		function (_, listViewItem)
			self:DispatchEvent ("SelectionCleared", listViewItem)
		end
	)
	
	-- Layout
	self.SubItemLayoutRevision = 0
	self.VerticalItemLayoutValid = true
	
	-- Scrolling
	self.ItemView = vgui.Create ("GContainer", self)
	self.ItemCanvas = vgui.Create ("GContainer", self.ItemView)
	
	self.VScroll = vgui.Create ("GVScrollBar", self)
	self.VScroll:SetZPos (20)
	self.HScroll = vgui.Create ("GHScrollBar", self)
	self.HScroll:SetZPos (20)
	self.ScrollBarCorner = vgui.Create ("GScrollBarCorner", self)
	self.ScrollableViewController = Gooey.ScrollableViewController ()
	self.ScrollableViewController:SetHorizontalScrollBar (self.HScroll)
	self.ScrollableViewController:SetVerticalScrollBar (self.VScroll)
	self.ScrollableViewController:SetScrollBarCorner (self.ScrollBarCorner)
	self.ScrollableViewController:SetViewSize (self:GetSize ())
	
	self.Header:SetScrollableViewController (self.ScrollableViewController)
	
	self.ScrollableViewController:AddEventListener ("InterpolatedViewPositionChanged",
		function (_, viewX, viewY)
			self.ItemCanvas:SetPos (-viewX, -viewY)
		end
	)
	
	self.ScrollableViewController:AddEventListener ("InterpolatedViewXChanged",
		function (_, interpolatedViewX)
		end
	)
	
	self.ScrollableViewController:AddEventListener ("InterpolatedViewYChanged",
		function (_, interpolatedViewY)
			-- Force the visible sub items to layout their contents.
			-- InvalidateLayout does not cause PerformLayout to be called soon
			-- enough, so items with improper layouts will be visible for 
			-- a single frame.
			self:LayoutVisibleSubItems ()
		end
	)
	
	-- Sorting
	self.Comparator = nil
	
	self.LastSortedByColumn = false
	self.LastSortColumnId = nil
	self.SortOrder = Gooey.SortOrder.None
	
	self:AddEventListener ("EnabledChanged",
		function (_, enabled)
			for listViewItem in self:GetItemEnumerator () do
				listViewItem:SetEnabled (enabled)
			end
		end
	)
	
	self:AddEventListener ("ItemHeightChanged",
		function (_, itemHeight)
			self.HScroll:SetSmallIncrement (itemHeight)
			self.VScroll:SetSmallIncrement (itemHeight)
		end
	)
	
	self:AddEventListener ("SizeChanged",
		function (_, w, h)
			self.ScrollableViewController:SetViewSize (w - 2, h - self:GetHeaderHeight () - 1)
			self.ScrollableViewController:SetViewSizeWithScrollBars (w - 1 - self.VScroll:GetWide (), h - self:GetHeaderHeight () - self.HScroll:GetTall ())
		end
	)
	
	self:AddEventListener ("WidthChanged",
		function (_, w)
			self.ItemCanvas:SetWide (math.max (self:GetHeaderWidth (), self:GetWide () - 2))
			self:InvalidateSubItemLayout ()
		end
	)
	
	self:SetItemHeight (20)
	self:SetKeyboardMap (Gooey.ListView.KeyboardMap)
	self:SetCanFocus (true)
end

-- Control
function PANEL:GetHeaderMenu ()
	return self.HeaderMenu
end

function PANEL:GetMenu ()
	return self.Menu
end

function PANEL:Paint (w, h)
	return derma.SkinHook ("Paint", "ListView", self, w, h)
end

function PANEL:PaintOver ()
	self.SelectionController:PaintOver (self)
end

function PANEL:PerformLayout ()
	self.Header:SetPos (1, 0)
	self.Header:SetSize (self:GetWide () - 1 - (self.VScroll:IsVisible () and self.VScroll:GetWide () or 1), self:GetHeaderHeight ())
	
	self.ItemView:SetPos (1, self.Header:GetTall ())
	self.ItemView:SetSize (self:GetWide () - 1 - (self.VScroll:IsVisible () and self.VScroll:GetWide () or 1), self:GetTall () - self:GetHeaderHeight () - (self.HScroll:IsVisible () and self.HScroll:GetTall () or 1))
	
	self.VScroll:SetPos (self:GetWide () - self.VScroll:GetWide (), 0)
	self.VScroll:SetTall (self:GetTall () - (self.HScroll:IsVisible () and self.HScroll:GetTall () or 0))
	self.HScroll:SetPos (0, self:GetTall () - self.HScroll:GetTall (), 0)
	self.HScroll:SetWide (self:GetWide () - (self.VScroll:IsVisible () and self.VScroll:GetWide () or 0))
	self.ScrollBarCorner:SetPos (self:GetWide () - self.ScrollBarCorner:GetWide (), self:GetTall () - self.ScrollBarCorner:GetTall ())
	self.ScrollBarCorner:SetVisible (self.VScroll:IsVisible () and self.HScroll:IsVisible ())
	
	if not self.VerticalItemLayoutValid then
		self.VerticalItemLayoutValid = true
		
		local y = 0
		for listViewItem in self:GetItemEnumerator () do
			listViewItem:SetPos (0, y)
			listViewItem:SetTall (self:GetItemHeight ())
			
			if listViewItem:IsVisible () then
				y = y + listViewItem:GetTall ()
			end
		end
	end
	
	self:LayoutVisibleSubItems ()
end

function PANEL:SetHeaderMenu (headerMenu)
	if self.HeaderMenu == headerMenu then return self end
	
	self.HeaderMenu = headerMenu
	return self
end

function PANEL:SetMenu (menu)
	if self.Menu == menu then return self end
	
	self.Menu = menu
	return self
end

-- Columns
function PANEL:AddColumn (id)
	return self.Columns:AddColumn (id)
end

function PANEL:GetColumnById (columnId)
	return self.Columns:GetColumnById (columnId)
end

function PANEL:GetColumnCount ()
	return self.Columns:GetCount ()
end

function PANEL:GetColumnEnumerator ()
	return self.Columns:GetEnumerator ()
end

function PANEL:GetColumns ()
	return self.Columns
end

function PANEL:GetHeader ()
	return self.Header
end

function PANEL:GetHeaderHeight ()
	return self.HeaderHeight
end

function PANEL:GetHeaderWidth ()
	return self.Header:GetHeaderWidth ()
end

function PANEL:RemoveColumn (column)
	self.Columns:RemoveColumn (column)
end

function PANEL:SetHeaderHeight (headerHeight)
	if self.HeaderHeight == headerHeight then return end
	
	self.HeaderHeight = headerHeight
	self:UpdateContentHeight ()
end

-- Items
function PANEL:AddItem (...)
	return self.Items:AddItem (...)
end

function PANEL:Clear ()
	self.Items:Clear ()
end

function PANEL:FindItem (text)
	for item in self:GetItemEnumerator () do
		if item:GetColumnText (1) == text then
			return item
		end
	end
	return nil
end

function PANEL:GetItemCount ()
	return self.Items:GetItemCount ()
end

function PANEL:GetItemEnumerator ()
	return self.Items:GetEnumerator ()
end

function PANEL:GetItemHeight ()
	return self.ItemHeight
end

function PANEL:GetItems ()
	return self.Items
end

function PANEL:ItemFromPoint (x, y)
	local left, top, right, bottom = self:GetContentBounds ()
	if x < left    then return nil end
	if x >= right  then return nil end
	if y < top     then return nil end
	if y >= bottom then return nil end
	
	x, y = self:LocalToScreen (x, y)
	for item in self:GetItemEnumerator () do
		local px, py = item:LocalToScreen (0, 0)
		local w, h = item:GetSize ()
		if px <= x and x < px + w and
		   py <= y and y < py + h then
			return item
		end
	end
	return nil
end

function PANEL:RemoveItem (listViewItem)
	return self.Items:RemoveItem (listViewItem)
end

function PANEL:SetItemHeight (itemHeight)
	if self.ItemHeight == itemHeight then return self end
	
	self.ItemHeight = itemHeight
	self:UpdateContentHeight ()
	self:InvalidateSubItemLayout ()
	self:InvalidateVerticalItemLayout ()
	self:DispatchEvent ("ItemHeightChanged", self.ItemHeight)
	
	return self
end

-- Keyboard
function PANEL:GetFocusedItem ()
	return self.FocusedItem
end

function PANEL:SetFocusedItem (listViewItem)
	self.FocusedItem = listViewItem
end

-- Selection
function PANEL:ClearSelection ()
	self.SelectionController:ClearSelection ()
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

function PANEL:SetSelectionMode (selectionMode)
	self.SelectionController:SetSelectionMode (selectionMode)
end

-- Layout
function PANEL:GetContentBounds ()
	local scrollBarWidth  = 1
	local scrollBarHeight = 1
	if self.VScroll and self.VScroll:IsVisible () then
		scrollBarWidth = self.VScroll:GetWide ()
	end
	if self.HScroll and self.HScroll:IsVisible () then
		scrollBarHeight = self.HScroll:GetTall ()
	end
	return 1, self:GetHeaderHeight (), self:GetWide () - scrollBarWidth, self:GetTall () - scrollBarHeight
end

-- Sorting
function PANEL.DefaultComparator (a, b)
	return a:GetText () < b:GetText ()
end

function PANEL:GetComparator ()
	return self.Comparator or self.DefaultComparator
end

function PANEL:GetSortColumnId ()
	if not self.LastSortedByColumn then return nil end
	return self.LastSortColumnId
end

function PANEL:GetSortOrder ()
	return self.SortOrder
end

function PANEL:SetComparator (comparator)
	self.Comparator = comparator
end

function PANEL:Sort (comparator)
	if not comparator and self.LastSortedByColumn then
		self:SortByColumn (self.LastSortColumnId, self.SortOrder)
		return
	end
	
	self.Items:Sort (comparator or self:GetComparator ())
	self.SortOrder = Gooey.SortOrder.Ascending
	
	self.LastSortedByColumn = false
	
	self:InvalidateVerticalItemLayout ()
end

function PANEL:SortByColumn (columnIdOrIndex, sortOrder)
	local column = self.Columns:GetColumnByIdOrIndex (columnIdOrIndex)
	if not column then return end
	
	sortOrder = sortOrder or Gooey.SortOrder.Ascending
	if sortOrder == Gooey.SortOrder.None then
		Gooey.Error ("GListView:SortByColumn : None is not a valid sort order!")
	end
	self.Items:Sort (column:GetComparator (), sortOrder)
	
	self.LastSortedByColumn = true
	self.LastSortColumnId = column:GetId ()
	self.SortOrder = sortOrder
	
	self:InvalidateVerticalItemLayout ()
end

-- Event handlers
function PANEL:DoClick ()
	if SysTime () - self.LastClickTime < 0.3 then
		self:DoDoubleClick ()
		self.LastClickTime = 0
	else
		local listViewItem = self:ItemFromPoint (self:CursorPos ())
		self:DispatchEvent ("Click", listViewItem)
		
		if listViewItem then
			listViewItem:DispatchEvent ("Click")
		end
		
		self.LastClickTime = SysTime ()
	end
end

function PANEL:DoDoubleClick ()
	local listViewItem = self:ItemFromPoint (self:CursorPos ())
	self:DispatchEvent ("DoubleClick", listViewItem)
	
	if listViewItem then
		listViewItem:DispatchEvent ("DoubleClick")
	end
end

function PANEL:DoRightClick ()
	self:DispatchEvent ("RightClick", self:ItemFromPoint (self:CursorPos ()))
end

function PANEL:ItemChecked (item, columnId, checked)
	self:DispatchEvent ("ItemChecked", item, columnId, checked)
end

function PANEL:OnCursorMoved (x, y)
	self:DispatchEvent ("MouseMove", 0, x, y)
end

function PANEL:OnMousePressed (mouseCode)
	self:DispatchEvent ("MouseDown", mouseCode, self:CursorPos ())
	if self.OnMouseDown then self:OnMouseDown (mouseCode, self:CursorPos ()) end
	
	if self:CanFocus () and
	   not self:IsFocused () and
	   not vgui.FocusedHasParent (self) then
		self:Focus ()
	end
end

function PANEL:OnMouseReleased (mouseCode)
	self:DispatchEvent ("MouseUp", mouseCode, self:CursorPos ())
	if mouseCode == MOUSE_LEFT then
		self:DoClick ()
	elseif mouseCode == MOUSE_RIGHT then
		self:DoRightClick ()
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

function PANEL:OnMouseWheel (delta)
	if self.VScroll:IsVisible () then
		self.VScroll:OnMouseWheeled (delta)
	else
		self.HScroll:OnMouseWheeled (delta)
	end
	return true
end

function PANEL:OnRemoved ()
	if self.Menu then self.Menu:dtor () end
	if self.HeaderMenu then self.HeaderMenu:dtor () end
end

-- Internal, do not call
function PANEL:GetSubItemLayoutRevision ()
	return self.SubItemLayoutRevision
end

function PANEL:InvalidateSubItemLayout ()
	self.SubItemLayoutRevision = self.SubItemLayoutRevision + 1
	self:InvalidateLayout ()
end

function PANEL:InvalidateVerticalItemLayout ()
	self.VerticalItemLayoutValid = false
	self:InvalidateLayout ()
end

function PANEL:LayoutVisibleSubItems ()
	local visibleStartY = self.ScrollableViewController:GetInterpolatedViewY ()
	local visibleEndY = visibleStartY + self.ScrollableViewController:GetViewHeight ()
	local x, y
	for listViewItem in self:GetItemEnumerator () do
		x, y = listViewItem:GetPos ()
		if y + listViewItem:GetTall () >= visibleStartY then
			if y > visibleEndY then
				break
			end
			listViewItem:LayoutSubItems (self:GetSubItemLayoutRevision ())
		end
	end
end

function PANEL:UpdateContentHeight ()
	self.ScrollableViewController:SetContentHeight (self.Items:GetItemCount () * self:GetItemHeight ())
	self.ItemCanvas:SetTall (self.Items:GetItemCount () * self:GetItemHeight ())
end

Gooey.Register ("GListView", PANEL, "GPanel")