local self = {}
Gooey.ComboBoxItem = Gooey.MakeConstructor (self)

--[[
	Events:
		Deselected ()
			Fired when this item has been deselected.
		Selected ()
			Fired when this item has been selected.
		TextChanged (string text)
			Fired when this item's text has changed.
]]

function self:ctor (comboBox, id, text)
	self.ComboBox = comboBox
	self.Id = id
	self.Text = text
	
	self.MenuItem = nil
	
	Gooey.EventProvider (self)
	
	self:AddEventListener ("Deselected",
		function ()
			if not self.MenuItem then return end
			
			self.MenuItem:SetChecked (false)
		end
	)
	
	self:AddEventListener ("Selected",
		function ()
			if not self.MenuItem then return end
			
			self.MenuItem:SetChecked (true)
		end
	)
end

function self:GetComboBox ()
	return self.ComboBox
end

function self:GetId ()
	return self.Id or self:GetHashCode ()
end

function self:GetMenuItem ()
	return self.MenuItem
end

function self:GetText ()
	return self.Text
end

function self:IsSelected ()
	return self == self.ComboBox:GetSelectedItem ()
end

function self:Select ()
	self.ComboBox:SetSelectedItem (self)
end

function self:SetId (id)
	self.Id = id
end

function self:SetMenuItem (menuItem)
	if self.MenuItem == menuItem then return self end
	
	self:UnhookMenuItem (self.MenuItem)
	self.MenuItem = menuItem
	self:HookMenuItem (self.MenuItem)
	
	if self.MenuItem then
		self.MenuItem:SetText (self:GetText ())
		self.MenuItem:SetChecked (self:IsSelected ())
	end
	
	return self
end

function self:SetText (text)
	if self.Text == text then return self end
	
	self.Text = text
	if self.MenuItem then
		self.MenuItem:SetText (self.Text)
	end
	
	self:DispatchEvent ("TextChanged", text)
	
	return self
end

-- Internal, do not call
function self:HookMenuItem (menuItem)
	if not menuItem then return end
	
	menuItem:AddEventListener ("Click", self:GetHashCode (),
		function ()
			self:Select ()
		end
	)
end

function self:UnhookMenuItem (menuItem)
	if not menuItem then return end
	
	menuItem:RemoveEventListener ("Click", self:GetHashCode ())
end