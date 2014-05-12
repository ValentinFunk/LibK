local self = {}
Gooey.ListView.ItemCollection = Gooey.MakeConstructor (self)

--[[
	Events:
		Cleared ()
			Fired when this ItemCollection has been cleared.
		ItemAdded (GListViewItem listViewItem)
			Fired when a ListViewItem has been added.
		ItemRemoved (GListViewItem listViewItem)
			Fired when a ListViewItem has been removed.
]]

function self:ctor (listView)
	self.ListView = listView
	
	self.Items = {}
	self.OrderedItems = {}
	
	Gooey.EventProvider (self)
end

function self:AddItem (...)
	local listViewItem = vgui.Create ("GListViewItem", self:GetListView ())
	local id = #self.Items + 1
	listViewItem:SetListView (self:GetListView ())
	listViewItem:SetId (id)
	listViewItem:SetEnabled (self:GetListView ():IsEnabled ())
	
	local values = {...}
	for i = 1, self:GetListView ():GetColumns ():GetColumnCount () do
		local column = self:GetListView ():GetColumns ():GetColumn (i)
		if column:GetType () == Gooey.ListView.ColumnType.Text then
			listViewItem:SetColumnText (column:GetId (), tostring (values [i] or ""))
		elseif column:GetType () == Gooey.ListView.ColumnType.Checkbox then
			listViewItem:SetCheckState (column:GetId (), values [i] and true or false)
		end
	end
	
	self.Items [id] = listViewItem
	self.OrderedItems [#self.OrderedItems + 1] = listViewItem
	
	self:DispatchEvent ("ItemAdded", listViewItem)
	
	return listViewItem
end

function self:Clear ()
	for id, listViewItem in pairs (self.Items) do
		self.Items [id] = nil
		listViewItem:Remove ()
		self:DispatchEvent ("ItemRemoved", listViewItem)
	end
	
	self.OrderedItems = {}
	
	self:DispatchEvent ("Cleared")
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.OrderedItems [i]
	end
end

function self:GetItem (index)
	return self.OrderedItems [index]
end

function self:GetItemById (id)
	return self.Items [id]
end

function self:GetItemCount ()
	return #self.OrderedItems
end

function self:GetListView ()
	return self.ListView
end

function self:RemoveItem (listViewItem)
	if not listViewItem then return end
	if not listViewItem:IsValid () then return end
	if self.Items [listViewItem:GetId ()] ~= listViewItem then return end
	
	for i = 1, #self.OrderedItems do
		if self.OrderedItems [i] == listViewItem then
			table.remove (self.OrderedItems, i)
			break
		end
	end
	
	self.Items [listViewItem:GetId ()] = nil
	
	listViewItem:Remove ()
	
	self:DispatchEvent ("ItemRemoved", listViewItem)
end

function self:Sort (comparator, sortOrder)
	if not comparator then return end
	sortOrder = sortOrder or Gooey.SortOrder.Ascending
	
	if sortOrder == Gooey.SortOrder.Ascending then
		table.sort (self.OrderedItems, comparator)
	elseif sortOrder == Gooey.SortOrder.Descending then
		table.sort (self.OrderedItems,
			function (a, b)
				return comparator (b, a)
			end
		)
	end
end