local PANEL = {}

--[[
	Events:
		HeaderWidthChanged (headerWidth)
			Fired when the header width has changed.
]]

function PANEL:Init ()
	self.ListView = nil
	self.Canvas = vgui.Create ("GContainer", self)
	
	self.FirstHeader = nil
	self.LastHeader = nil
	self.HeaderWidth = 0
	self.HeaderLayoutValid = true
	self.ScrollableViewController = nil
	
	self.ColumnCollection = nil
	self.SizeGrips = {}
	
	self:AddEventListener ("RightClick",
		function (_)
			if not self.ListView:GetHeaderMenu () then return end
			self.ListView:GetHeaderMenu ():Show (self.ListView)
		end
	)
end

function PANEL:GetListView ()
	return self.ListView
end

function PANEL:GetHeaderWidth ()
	return self.HeaderWidth
end

function PANEL:Paint (w, h)
	local headerWidth = self:GetHeaderWidth ()
	local left  = self.Canvas:GetPos () + headerWidth
	local right = w
	local rectWidth = math.max (right - left + 1, 32)
	
	if headerWidth == 0 then
		left = left - 1
		rectWidth = rectWidth + 1
	end
	
	self:GetSkin ().tex.Button (left, 0, rectWidth, h)
end

function PANEL:PerformLayout ()
	if not self.HeaderLayoutValid then
		self:LayoutHeaders ()
	end
	self.Canvas:SetPos (-self.ScrollableViewController:GetInterpolatedViewX (), 0)
end

function PANEL:SetColumnCollection (columnCollection)
	if self.ColumnCollection then
		self:UnhookColumnCollection (self.ColumnCollection)
		
		for column in self.ColumnCollection:GetEnumerator () do
			self:OnColumnRemoved (column)
		end
	end
	
	self.ColumnCollection = columnCollection
	
	if self.ColumnCollection then
		self:HookColumnCollection (self.ColumnCollection)
		
		for column in self.ColumnCollection:GetEnumerator () do
			self:OnColumnAdded (column)
		end
	end
end

function PANEL:SetListView (listView)
	self.ListView = listView
end

function PANEL:SetScrollableViewController (scrollableViewController)
	self:UnhookScrollableViewController (self.ScrollableViewController)
	self.ScrollableViewController = scrollableViewController
	self:HookScrollableViewController (self.ScrollableViewController)
end

function PANEL:OnRemoved ()
	self:SetColumnCollection (nil)
end

-- Internal, do not call
function PANEL:CreateColumnSizeGrip (column)
	if not self.SizeGrips [column] then
		self.SizeGrips [column] = vgui.Create ("GListViewColumnSizeGrip", self.Canvas)
		self.SizeGrips [column]:SetColumn (column)
	end
	return self.SizeGrips [column]
end

function PANEL:GetColumnSizeGrip (column, create)
	if not self.SizeGrips [column] and create then
		return self:CreateColumnSizeGrip (column)
	end
	return self.SizeGrips [column]
end

function PANEL:GetFirstHeader ()
	return self.FirstHeader
end

function PANEL:GetLastHeader ()
	return self.LastHeader
end

function PANEL:InvalidateHeaderLayout ()
	self.HeaderLayoutValid = false
end

function PANEL:LayoutHeaders ()
	local x = 0
	local firstHeader = nil
	local lastHeader = nil
	for column in self.ColumnCollection:GetEnumerator () do
		column:GetHeader ():SetPos (x, 0)
		column:GetHeader ():SetTall (self:GetTall ())
		
		local sizeGrip = self:GetColumnSizeGrip (column, column:IsVisible ())
		if sizeGrip then
			sizeGrip:SetVisible (column:IsVisible ())
		end
		if column:IsVisible () then
			x = x + column:GetHeader ():GetWide ()
			firstHeader = firstHeader or column:GetHeader ()
			lastHeader = column:GetHeader ()
			sizeGrip:SetPos (x - sizeGrip:GetWide () / 2, 0)
			sizeGrip:SetTall (self:GetTall ())
			x = x - 1
		end
	end
	x = x + 1
	
	self:SetFirstHeader (firstHeader)
	self:SetLastHeader (lastHeader)
	
	self.Canvas:SetPos (-self.ScrollableViewController:GetViewX (), 0)
	self.Canvas:SetSize (math.max (self:GetWide (), x), self:GetTall ())
	
	if self.HeaderWidth ~= x then
		self.HeaderWidth = x
		self:DispatchEvent ("HeaderWidthChanged", self.HeaderWidth)
	end
end

function PANEL:SetFirstHeader (firstHeader)
	self.FirstHeader = firstHeader
end

function PANEL:SetLastHeader (lastHeader)
	self.LastHeader = lastHeader
end

function PANEL:OnColumnAdded (column)
	if not column then return end
	
	column:GetHeader ():SetHeader (self)
	column:GetHeader ():SetParent (self.Canvas)
	self:InvalidateHeaderLayout ()
	
	self:HookColumn (column)
end

function PANEL:OnColumnRemoved (column)
	if not column then return end
	
	if self.SizeGrips [column] then
		self.SizeGrips [column]:Remove ()
	end
	self:InvalidateHeaderLayout ()
	
	self:UnhookColumn (column)
end

function PANEL:HookColumnCollection (columnCollection)
	if not columnCollection then return end
	
	columnCollection:AddEventListener ("ColumnAdded", self:GetHashCode (),
		function (_, column)
			self:OnColumnAdded (column)
		end
	)
	
	columnCollection:AddEventListener ("ColumnRemoved", self:GetHashCode (),
		function (_, column)
			self:OnColumnRemoved (column)
		end
	)
end

function PANEL:UnhookColumnCollection (columnCollection)
	if not columnCollection then return end
	
	columnCollection:AddEventListener ("ColumnAdded",   self:GetHashCode ())
	columnCollection:AddEventListener ("ColumnRemoved", self:GetHashCode ())
end

function PANEL:HookColumn (column)
	if not column then return end
	
	column:GetHeader ():AddEventListener ("Click", self:GetHashCode (),
		function (_)
			local sortOrder = Gooey.SortOrder.Ascending
			if self:GetListView ():GetSortColumnId () == column:GetId () and
			   self:GetListView ():GetSortOrder () == Gooey.SortOrder.Ascending then
				sortOrder = Gooey.SortOrder.Descending
			end
			self:GetListView ():SortByColumn (column:GetId (), sortOrder)
		end
	)
	
	column:GetHeader ():AddEventListener ("SizeChanged", self:GetHashCode (),
		function (_)
			self:LayoutHeaders ()
		end
	)
	
	column:GetHeader ():AddEventListener ("VisibleChanged", self:GetHashCode (),
		function (_)
			self:LayoutHeaders ()
		end
	)
end

function PANEL:UnhookColumn (column)
	if not column then return end
	
	column:GetHeader ():RemoveEventListener ("Click",          self:GetHashCode ())
	column:GetHeader ():RemoveEventListener ("SizeChanged",    self:GetHashCode ())
	column:GetHeader ():RemoveEventListener ("VisibleChanged", self:GetHashCode ())
end

function PANEL:HookScrollableViewController (scrollableViewController)
	if not scrollableViewController then return end
	
	scrollableViewController:AddEventListener ("ViewXChanged", self:GetHashCode (),
		function (_, viewX)
			self:PerformLayout ()
		end
	)
end

function PANEL:UnhookScrollableViewController (scrollableViewController)
	if not scrollableViewController then return end
	
	scrollableViewController:RemoveEventListener ("ViewXChanged", self:GetHashCode ())
end

Gooey.Register ("GListViewHeader", PANEL, "GPanel")