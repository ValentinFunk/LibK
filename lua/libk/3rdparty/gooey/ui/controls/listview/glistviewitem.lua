local PANEL = {}

function PANEL:Init ()
	-- ListViewItem
	self.ListView = nil
	self.Id = 0
	
	-- Layout
	self.LayoutRevision = 0
	
	-- SubItems
	self.Icon = nil
	self.Columns = {}
	
	-- Selection
	self.Selectable = true
	
	self:AddEventListener ("EnabledChanged",
		function (_, enabled)
			for _, columnItem in pairs (self.Columns) do
				if columnItem.SetEnabled == Gooey.BasePanel.SetEnabled then columnItem:SetEnabled (enabled)
				elseif columnItem.SetDisabled then columnItem:SetDisabled (not enabled) end
			end
		end
	)
	
	self:AddEventListener ("TextChanged",
		function (_, text)
			self:SetColumnText (1, text)
		end
	)
end

-- Control
function PANEL:Paint (w, h)
	if self.BackgroundColor then
		surface.SetDrawColor (self.BackgroundColor)
		self:DrawFilledRect ()
	end
	
	if self:IsSelected () then
		local col = self:GetSkin ().listview_selected
		if not self:GetListView ():IsFocused () then
			col = GLib.Colors.Silver
		end
		surface.SetDrawColor (col.r, col.g, col.b, col.a)
		self:DrawFilledRect ()
	elseif self:IsHovered () then
		local col = self:GetSkin ().listview_selected
		surface.SetDrawColor (col.r, col.g, col.b, col.a * 0.25)
		self:DrawFilledRect ()
	end
	
	if self.Icon then
		local image = Gooey.ImageCache:GetImage (self.Icon)
		local spacing = (self:GetTall () - image:GetHeight ()) * 0.5
		image:Draw (Gooey.RenderContext, spacing + 1, spacing)
	end
end

function PANEL:PerformLayout ()
	for _, control in pairs (self.Columns) do
		control:SetTall (self:GetTall ())
	end
end

-- ListViewItem
function PANEL:GetId ()
	return self.Id
end

function PANEL:GetListView ()
	return self.ListView
end

function PANEL:SetId (id)
	self.Id = id
end

function PANEL:SetListView (listView)
	self.ListView = listView
end

-- SubItems
function PANEL:GetIcon ()
	return self.Icon
end

function PANEL:GetText (columnIdOrIndex)
	local column = self:GetListView ():GetColumns ():GetColumnByIdOrIndex (columnIdOrIndex or 1)
	if not column then return "" end
	
	local columnId = column:GetId ()
	return self.Columns [columnId] and tostring (self.Columns [columnId]:GetValue ()) or ""
end

function PANEL:SetCheckState (columnIdOrIndex, checked)
	local column = self:GetListView ():GetColumns ():GetColumnByIdOrIndex (columnIdOrIndex)
	if not column then return end
	
	local columnId = column:GetId ()
	
	if not self.Columns [columnId] then
		self.Columns [columnId] = vgui.Create ("GCheckbox", self)
		self.Columns [columnId]:SetEnabled (self:IsEnabled ())
		self.Columns [columnId]:SetValue (checked)
		self.Columns [columnId]:AddEventListener ("CheckStateChanged",
			function (_, checked)
				self.ListView:ItemChecked (self, columnId, checked)
			end
		)
	end
	self.Columns [columnId]:SetValue (checked)
end

function PANEL:SetIcon (icon)
	self.Icon = icon
end

function PANEL:SetColumnText (columnIdOrIndex, text)
	local column = self:GetListView ():GetColumns ():GetColumnByIdOrIndex (columnIdOrIndex)
	if not column then return end
	
	local columnId = column:GetId ()
	
	if not self.Columns [columnId] then
		self.Columns [columnId] = vgui.Create ("GLabel", self)
		self.Columns [columnId]:SetTextInset (5, 0)
		self.Columns [columnId]:SetTextColor (GLib.Colors.Black)
	end
	self.Columns [columnId]:SetText (text)
end

-- Selection
function PANEL:CanSelect ()
	return self.Selectable
end

function PANEL:IsHovered ()
	if not self.Hovered then return false end
	
	local mouseX, mouseY = self:CursorPos ()
	return mouseX >= 0 and mouseX < self:GetWide () and
	       mouseY >= 0 and mouseY < self:GetTall ()
end

function PANEL:IsSelected ()
	return self.ListView.SelectionController:IsSelected (self)
end

function PANEL:Select ()
	self.ListView.SelectionController:ClearSelection ()
	self.ListView.SelectionController:AddToSelection (self)
end

function PANEL:SetCanSelect (canSelect)
	self.Selectable = canSelect
end

-- Event handlers
function PANEL:DoClick ()
	self.ListView:DoClick (self)
end

function PANEL:DoRightClick ()
	self.ListView:DoRightClick (self)
end

function PANEL:OnMousePressed (mouseCode)
	self.ListView:OnMousePressed (mouseCode)
end

function PANEL:OnMouseReleased (mouseCode)
	self.ListView:OnMouseReleased (mouseCode)
end

function PANEL:OnRemoved ()
	local listView = self:GetListView ()
	if listView then
		self:SetListView (nil)
		listView:GetItems ():RemoveItem (self)
	end
end

-- Internal, do not call
function PANEL:LayoutSubItems (layoutRevision)
	if self.LayoutRevision >= layoutRevision then return end
	self.LayoutRevision = layoutRevision
	
	self:SetWide (math.max (self:GetListView ():GetWide () - 2, self:GetListView ():GetHeaderWidth ()))
	
	local x = 0
	local iconWidth = 0
	if self.Icon then
		local image = Gooey.ImageCache:GetImage (self.Icon)
		local spacing = (self:GetTall () - image:GetHeight ()) * 0.5
		iconWidth = image:GetWidth () + spacing
	end
	
	for column in self:GetListView ():GetColumnEnumerator () do
		local columnId = column:GetId ()
		local width = column:GetWidth ()
		if self.Columns [columnId] then
			self.Columns [columnId]:SetVisible (column:IsVisible ())
			
			if column:GetType () == Gooey.ListView.ColumnType.Text then
				self.Columns [columnId]:SetPos (x + iconWidth, 0)
				self.Columns [columnId]:SetWide (width - iconWidth)
				
				local horizontalAlignment = column:GetAlignment ()
				if horizontalAlignment == Gooey.HorizontalAlignment.Left then
					horizontalAlignment = 4
				elseif horizontalAlignment == Gooey.HorizontalAlignment.Center then
					horizontalAlignment = 5
				elseif horizontalAlignment == Gooey.HorizontalAlignment.Right then
					horizontalAlignment = 6
				end
				self.Columns [columnId]:SetContentAlignment (horizontalAlignment)
			elseif column:GetType () == Gooey.ListView.ColumnType.Checkbox then
				self.Columns [columnId]:SetPos (x + (width - 15) * 0.5, (self:GetTall () - 15) * 0.5)
				self.Columns [columnId]:SetSize (15, 15)
			end
		end
		
		if column:IsVisible () then
			x = x + width - 1
			iconWidth = 0
		end
	end
end

Gooey.Register ("GListViewItem", PANEL, "GPanel")