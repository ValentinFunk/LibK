local PANEL = {}

--[[
	Events:
		ExternalTabDragEnded (Tab tab)
			Fired when a tab's header is no longer being dragged outside the header area.
		ExternalTabDragStarted (Tab tab)
			Fired when a tab's header has been dragged outside the header area.
		SelectedContentsChanged (Tab oldSelectedTab, Panel oldSelectedContents, Tab selectedTab, Panel selectedContents)
			Fired when the selected contents has changed.
		SelectedTabChanged (Tab oldSelectedTab, Tab selectedTab)
			Fired when the selected tab has changed.
		TabAdded (Tab tab)
			Fired when a tab has been added to this TabControl.
		TabCloseRequested (Tab tab)
			Fired when a tab's close button has been clicked.
		TabContentsChanged (Tab tab, Panel oldContents, Panel contents)
			Fired when a tab's contents has changed.
		TabRemoved (Tab tab)
			Fired when a tab has been removed from this TabControl.
		TabTextChanged (Tab tab, text)
			Fired when a tab's header text has changed.
		TabVisibilityChanged (Tab tab, visible)
			Fired when a tab's visibility has changed.
]]

function PANEL:Init ()
	self.TabHeaderHeight = 24
	
	self.Tabs = {}
	self.TabSet = {}
	self.SelectedTab = nil
	self.SelectedTabIndex = 0
	self.SelectedTabHeaderVisible = false
	
	self:SetKeyboardMap (Gooey.KeyboardMap ())
	self:GetKeyboardMap ():Register ({ KEY_TAB },
		function (self, key, ctrl, shift, alt)
			if not ctrl then return false end
			
			local selectedTabIndex
			if shift then
				selectedTabIndex = self:GetPreviousSelectableTabIndex (self:GetSelectedTabIndex ())
			else
				selectedTabIndex = self:GetNextSelectableTabIndex (self:GetSelectedTabIndex ())
			end
			
			GLib.CallDelayed (
				function ()
					self:SetSelectedTabIndex (selectedTabIndex)
				end
			)
		end
	)
	
	-- Tab scrolling
	self.LeftScrollButton = vgui.Create ("GButton", self)
	self.LeftScrollButton:SetSize (14, 14)
	self.LeftScrollButton:SetText ("<")
	self.LeftScrollButton:SetVisible (false)
	self.LeftScrollButton:AddEventListener ("MouseDown",
		function ()
			self.TargetTabScrollSpeed = -1024
			self.TabScrollSpeed = -256
		end
	)
	self.LeftScrollButton:AddEventListener ("MouseUp",
		function ()
			self.TargetTabScrollSpeed = 0
		end
	)
	self.RightScrollButton = vgui.Create ("GButton", self)
	self.RightScrollButton:SetSize (14, 14)
	self.RightScrollButton:SetText (">")
	self.RightScrollButton:SetVisible (false)
	self.RightScrollButton:AddEventListener ("MouseDown",
		function ()
			self.TargetTabScrollSpeed = 1024
			self.TabScrollSpeed = 256
		end
	)
	self.RightScrollButton:AddEventListener ("MouseUp",
		function ()
			self.TargetTabScrollSpeed = 0
		end
	)
	
	self.TabScrollerEnabled = false
	self.TabScrollOffset = 0
	self.TotalHeaderWidth = 0
	
	self.LastThinkTime = SysTime ()
	self.TargetTabScrollSpeed = 0
	self.TabScrollSpeed = 0
	
	-- Tab dragging
	self.ExternalTabDraggingInProgress = false
	
	self.CloseRequested = function (tab)
		self:DispatchEvent ("TabCloseRequested", tab)
	end
	self.ContentsChanged = function (tab, oldContents, contents)
		self:DispatchEvent ("TabContentsChanged", tab, oldContents, contents)
		
		if tab:IsSelected () then
			self:DispatchEvent ("SelectedContentsChanged", tab, oldContents, tab, contents)
		end
	end
	self.TextChanged = function (tab, text)
		self:DispatchEvent ("TabTextChanged", tab, text)
		self:InvalidateLayout ()
	end
	self.VisibleChanged = function (tab, visible)
		if self:GetSelectedTab () == tab and not visible then
			self:SelectNextBestTab ()
		end
		if not self:GetSelectedTab () and visible then
			self:SetSelectedTab (tab)
		end
		self:LayoutTabHeaders ()
		self:InvalidateLayout ()
		self:DispatchEvent ("TabVisibilityChanged", tab, visible)
	end
	
	self:AddEventListener ("SizeChanged",
		function (_, w, h)
			if not self.SelectedTabHeaderVisible then return end
			self:EnsureTabVisible (self:GetSelectedTab ())
		end
	)
end

function PANEL:AddTab (...)
	local tab = nil
	local text = nil
	local contents = nil
	
	for _, v in ipairs ({...}) do
		if type (v) == "Panel" then
			contents = v
		elseif type (v) == "table" then
			tab = v
		elseif type (v) == "string" then
			text = v
		end
	end
	
	tab = tab or Gooey.Tab ()
	if self.TabSet [tab] then return end
	
	self.Tabs [#self.Tabs + 1] = tab
	self.TabSet [tab] = true
	
	tab:SetTabControl (self)
	if text     then tab:SetText (text)         end
	if contents then tab:SetContents (contents) end
	
	tab:AddEventListener ("CloseRequested",  self:GetHashCode (), self.CloseRequested)
	tab:AddEventListener ("ContentsChanged", self:GetHashCode (), self.ContentsChanged)
	tab:AddEventListener ("TextChanged",     self:GetHashCode (), self.TextChanged)
	tab:AddEventListener ("VisibleChanged",  self:GetHashCode (), self.VisibleChanged)
	
	if not self:GetSelectedTab () then
		self:SetSelectedTab (tab)
	end
	
	self:InvalidateLayout ()
	
	self:DispatchEvent ("TabAdded", tab)
	
	return tab
end

function PANEL:Clear ()
	local tabs = {}
	for tab in self:GetEnumerator () do
		tabs [#tabs + 1] = tab
	end
	for _, tab in ipairs (tabs) do
		tab:Remove ()
	end
end

function PANEL:ContainsTab (tab)
	return self.TabSet [tab] or false
end

function PANEL:EnsureTabVisible (tab)
	if not self.TabScrollerEnabled then return end
	
	local left = tab:GetHeader ():GetOffset ()
	local right = tab:GetHeader ():GetOffset () + tab:GetHeader ():GetWide ()
	if tab:GetHeader ():GetWide () > self:GetAvailableHeaderWidth () then
		self:SetScrollOffset (left)
	elseif self.TabScrollOffset > left then
		self:SetScrollOffset (left)
	elseif self.TabScrollOffset + self:GetAvailableHeaderWidth () < right then
		self:SetScrollOffset (right - self:GetAvailableHeaderWidth ())
	end
end

function PANEL:GetAvailableHeaderWidth ()
	local availableHeaderWidth = self:GetWide ()
	if self.TabScrollerEnabled then
		availableHeaderWidth = availableHeaderWidth - self.LeftScrollButton:GetWide ()
		availableHeaderWidth = availableHeaderWidth - self.RightScrollButton:GetWide ()
	end
	return availableHeaderWidth
end

function PANEL:GetContentRectangle ()
	local x, y, w, h = self:GetPaddedContentRectangle ()
	x = x + 4
	y = y + 4
	w = w - 8
	h = h - 8
	return x, y, w, h
end

function PANEL:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Tabs [i]
	end
end

function PANEL:GetHeaderHeight ()
	return self.TabHeaderHeight
end

function PANEL:GetHeaderRectangle ()
	return 0, 0, self:GetWide (), self.TabHeaderHeight
end

function PANEL:GetPaddedContentRectangle ()
	return 0, self.TabHeaderHeight, self:GetWide (), self:GetTall () - self.TabHeaderHeight
end

function PANEL:GetScrollOffset ()
	return self.TabScrollOffset
end

function PANEL:GetSelectedContents ()
	if not self.SelectedTab then return nil end
	if not self.SelectedTab:GetContents () then return nil end
	if not self.SelectedTab:GetContents ():IsValid () then return nil end
	return self.SelectedTab:GetContents ()
end

function PANEL:GetSelectedTab ()
	return self.SelectedTab
end

function PANEL:GetSelectedTabIndex ()
	return self:GetTabIndex (self.SelectedTab)
end

function PANEL:GetTab (index)
	return self.Tabs [index]
end

function PANEL:GetTabCount ()
	return #self.Tabs
end

function PANEL:GetTabHeader (index)
	return self.Tabs [index] and self.Tabs [index]:GetHeader ()
end

function PANEL:GetTabIndex (tab)
	if not self.TabSet [tab] then return 0 end
	
	for k, t in ipairs (self.Tabs) do
		if t == tab then return k end
	end
	return 0
end

function PANEL:GetVisibleTabCount ()
	local visibleTabCount = 0
	for tab in self:GetEnumerator () do
		if tab:IsVisible () then
			visibleTabCount = visibleTabCount + 1
		end
	end
	return visibleTabCount
end

function PANEL:IsPointInHeaderArea (x, y)
	if x < 0 then return false end
	if x > self:GetWide () then return false end
	if y < 0 then return false end
	if y > self.TabHeaderHeight then return false end
	return true
end

function PANEL:IsTabHeaderVisible (tab)
	if not tab then return false end
	if not self.TabScrollerEnabled then return true end
	
	local left = tab:GetHeader ():GetOffset ()
	local right = tab:GetHeader ():GetOffset () + tab:GetHeader ():GetWide ()
	return right > self.TabScrollOffset and left < self.TabScrollOffset + self:GetWide ()
end

function PANEL:LayoutTabHeaders ()
	local x = 0
	for _, tab in ipairs (self.Tabs) do
		tab:GetHeader ():SetOffset (x, 0)
		tab:GetHeader ():PerformLayout ()
		if tab:IsVisible () then
			x = x + tab:GetHeader ():GetWide ()
		end
	end
	self.TotalHeaderWidth = x
	
	if self.TotalHeaderWidth > self:GetWide () then
		self:EnableTabScroller ()
		
		if self.TabScrollOffset + self:GetAvailableHeaderWidth () > self.TotalHeaderWidth then
			self:SetScrollOffset (self.TotalHeaderWidth - self:GetAvailableHeaderWidth ())
		end
	else
		self:DisableTabScroller ()
	end
end

function PANEL:Paint (w, h)
	draw.RoundedBoxEx (4, 0, self.TabHeaderHeight, w, h - self.TabHeaderHeight, GLib.Colors.Silver,
		self.TotalHeaderWidth == 0,
		self.TotalHeaderWidth - self.TabScrollOffset < self:GetWide () - 4,
		true,
		true
	)
end

function PANEL:PerformLayout ()
	self:LayoutTabHeaders ()
	
	for _, tab in ipairs (self.Tabs) do
		tab:LayoutContents ()
		tab:GetHeader ():SetPos (tab:GetHeader ():GetOffset () - self.TabScrollOffset)
	end
	
	local x = self:GetWide ()
	x = x - self.RightScrollButton:GetWide ()
	self.RightScrollButton:SetPos (x, 0.5 * (self:GetHeaderHeight () - self.RightScrollButton:GetTall ()))
	self.RightScrollButton:MoveToFront ()
	x = x - self.LeftScrollButton:GetWide ()
	self.LeftScrollButton:SetPos (x, 0.5 * (self:GetHeaderHeight () - self.LeftScrollButton:GetTall ()))
	self.LeftScrollButton:MoveToFront ()
	
	-- x is now self:GetWide () - total scroll button width
	self.LeftScrollButton:SetEnabled (self.TabScrollOffset > 0)
	self.RightScrollButton:SetEnabled (self.TabScrollOffset + x < self.TotalHeaderWidth)
	
	self.SelectedTabHeaderVisible = self:IsTabHeaderVisible (self:GetSelectedTab ())
end

function PANEL:RemoveTab (tab, delete)
	if delete == nil then delete = true end
	if not self.TabSet [tab] then return end
	
	-- Determine tab index
	local index = 1
	for k, v in ipairs (self.Tabs) do
		if v == tab then
			index = k
			table.remove (self.Tabs, k)
			break
		end
	end
	
	-- Update selected tab index
	if self.SelectedTabIndex and index < self.SelectedTabIndex then
		self.SelectedTabIndex = self.SelectedTabIndex - 1
	end
	
	self.TabSet [tab] = nil
	
	-- Unhook tab
	tab:RemoveEventListener ("CloseRequested",  self:GetHashCode ())
	tab:RemoveEventListener ("ContentsChanged", self:GetHashCode ())
	tab:RemoveEventListener ("TextChanged",     self:GetHashCode ())
	tab:RemoveEventListener ("VisibleChanged",  self:GetHashCode ())
	
	-- Update selected tab
	if self:GetSelectedTab () == tab then
		self:SetSelectedTab (self.Tabs [index] or self.Tabs [index - 1])
	end
	
	tab:SetTabControl (nil)
	
	self:DispatchEvent ("TabRemoved", tab)
	
	if delete then
		tab:Remove ()
	end
	
	self:InvalidateLayout ()
end

function PANEL:SetScrollOffset (scrollOffset)
	if scrollOffset + self:GetAvailableHeaderWidth () > self.TotalHeaderWidth then
		scrollOffset = self.TotalHeaderWidth - self:GetAvailableHeaderWidth ()
	end
	if scrollOffset < 0 then scrollOffset = 0 end
	if self.TabScrollOffset == scrollOffset then return end
	
	self.TabScrollOffset = scrollOffset
	
	self:InvalidateLayout ()
end

function PANEL:SetSelectedTab (tab)
	if tab and tab:GetTabControl () ~= self then return end
	if self.SelectedTab == tab then return end
	
	self:SetSelectedTabIndex (self:GetTabIndex (tab))
end

function PANEL:SetSelectedTabIndex (tabIndex)
	if tabIndex < 0 then return end
	if tabIndex > self:GetTabCount () then return end
	
	local selectedTab = self:GetTab (tabIndex)
	if self.SelectedTab == selectedTab and
	   self.SelectedTabIndex == tabIndex then
		return
	end
	
	local oldSelectedTab = self.SelectedTab
	local oldSelectedContents = nil
	if self.SelectedTab then
		oldSelectedContents = self.SelectedTab:GetContents ()
		if oldSelectedContents then
			oldSelectedContents:SetVisible (false)
		end
	end
	
	self.SelectedTab = selectedTab
	self.SelectedTabIndex = tabIndex
	
	local selectedContents = nil
	if self.SelectedTab then
		selectedContents = self.SelectedTab:GetContents ()
		self.SelectedTab:LayoutContents ()
		
		self:LayoutTabHeaders ()
		self:EnsureTabVisible (self.SelectedTab)
		
		if self.SelectedTab:GetContents () then
			self.SelectedTab:GetContents ():Focus ()
		end
	end
	
	self:DispatchEvent ("SelectedTabChanged", oldSelectedTab, self.SelectedTab)
	if oldSelectedContents ~= selectedContents then
		self:DispatchEvent ("SelectedContentsChanged", oldSelectedTab, oldSelectedContents, tab, selectedContents)
	end
end

function PANEL:SetTabIndex (tab, index)
	if not self.TabSet [tab] then return end
	
	-- Clamp index
	if index < 1 then index = 1 end
	if index > #self.Tabs then index = #self.Tabs end
	
	local currentIndex = tab:GetIndex ()
	if index == currentIndex then return end
	
	local displacedTab = self.Tabs [index]
	self.Tabs [index] = tab
	self.Tabs [currentIndex] = displacedTab
	
	-- Update selected tab index
	self.SelectedTabIndex = self:GetTabIndex (self.SelectedTab)
	
	self:LayoutTabHeaders ()
	self:InvalidateLayout ()
end

-- Internal, do not call
function PANEL:BeginExternalTabDragging (tab)
	if self.ExternalTabDraggingInProgress then return end
	self.ExternalTabDraggingInProgress = true
	
	self:DispatchEvent ("ExternalTabDragStarted", tab)
end

function PANEL:EnableTabScroller ()
	if self.TabScrollerEnabled then return end
	self.TabScrollerEnabled = true
	
	self.LeftScrollButton:SetVisible (true)
	self.RightScrollButton:SetVisible (true)
end

function PANEL:EndExternalTabDragging (tab)
	if not self.ExternalTabDraggingInProgress then return end
	self.ExternalTabDraggingInProgress = false
	
	self:DispatchEvent ("ExternalTabDragEnded", tab)
end

function PANEL:DisableTabScroller ()
	if not self.TabScrollerEnabled then return end
	self.TabScrollerEnabled = false
	
	self:SetScrollOffset (0)
	self.LeftScrollButton:SetVisible (false)
	self.RightScrollButton:SetVisible (false)
end

-- Internal, do not call
function PANEL:GetNextSelectableTabIndex (tabIndex)
	local initialTabIndex = tabIndex
	tabIndex = tabIndex + 1
	
	while self.Tabs [tabIndex] and
	      not self.Tabs [tabIndex]:IsVisible () do
		tabIndex = tabIndex + 1
	end
	
	if self.Tabs [tabIndex] then return tabIndex end
	
	-- Search from the beginning
	tabIndex = 1
	while self.Tabs [tabIndex] and
	      tabIndex <= initialTabIndex and
	      not self.Tabs [tabIndex]:IsVisible () do
		tabIndex = tabIndex + 1
	end
	
	if not self.Tabs [tabIndex] or
	   not self.Tabs [tabIndex]:IsVisible () then
		tabIndex = 0
	end
	
	return tabIndex
end

function PANEL:GetPreviousSelectableTabIndex (tabIndex)
	local initialTabIndex = tabIndex
	tabIndex = tabIndex - 1
	
	while self.Tabs [tabIndex] and
	      not self.Tabs [tabIndex]:IsVisible () do
		tabIndex = tabIndex - 1
	end
	
	if self.Tabs [tabIndex] then return tabIndex end
	
	-- Search from the beginning
	tabIndex = self:GetTabCount ()
	while self.Tabs [tabIndex] and
	      tabIndex >= initialTabIndex and
	      not self.Tabs [tabIndex]:IsVisible () do
		tabIndex = tabIndex - 1
	end
	
	if not self.Tabs [tabIndex] or
	   not self.Tabs [tabIndex]:IsVisible () then
		tabIndex = 0
	end
	
	return tabIndex
end

function PANEL:SelectNextBestTab ()
	local tabIndex = self.SelectedTabIndex
	
	-- Go forwards until we find an appropriate tab
	while self.Tabs [tabIndex] and
	      not self.Tabs [tabIndex]:IsVisible () do
		tabIndex = tabIndex + 1
	end
	
	if not self.Tabs [tabIndex] then
		-- Overshot, look backwards instead
		tabIndex = self.SelectedTabIndex
		while self.Tabs [tabIndex] and 
		      not self.Tabs [tabIndex]:IsVisible () do
			tabIndex = tabIndex - 1
		end
	end
	
	self:SetSelectedTabIndex (tabIndex)
end

-- Event handlers
function PANEL:OnMouseWheel (delta, x, y)
	local headerX, headerY, headerWidth, headerHeight = self:GetHeaderRectangle ()
	if x < headerX or x > headerX + headerWidth or
	   y < headerY or y > headerY + headerHeight then
		return
	end
	self:SetScrollOffset (self:GetScrollOffset () + delta * -20)
	return true
end

function PANEL:OnRemoved ()
	for _, tab in ipairs (self.Tabs) do
		tab:Remove ()
	end
end

function PANEL:Think ()
	local deltaTime = SysTime () - self.LastThinkTime
	self.LastThinkTime = SysTime ()
	
	local acceleration = 512
	
	if self.TargetTabScrollSpeed > self.TabScrollSpeed then
		self.TabScrollSpeed = math.min (self.TabScrollSpeed + acceleration * deltaTime, self.TargetTabScrollSpeed)
	elseif self.TargetTabScrollSpeed < self.TabScrollSpeed then
		self.TabScrollSpeed = math.max (self.TabScrollSpeed - acceleration * deltaTime, self.TargetTabScrollSpeed)
	end
	
	self:SetScrollOffset (self:GetScrollOffset () + self.TabScrollSpeed * deltaTime)
end

PANEL.CloseRequested  = Gooey.NullCallback
PANEL.ContentsChanged = Gooey.NullCallback
PANEL.TextChanged     = Gooey.NullCallback
PANEL.VisibleChanged  = Gooey.NullCallback

Gooey.Register ("GTabControl", PANEL, "GPanel")