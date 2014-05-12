local self = {}
Gooey.Menu = Gooey.MakeConstructor (self)

--[[
	Events:
		Cleared ()
			Fired when the menu has been cleared.
		ItemAdded (menuItem)
			Fired when a menu item has been added.
		ItemRemoved (menuItem)
			Fired when a menu item has been removed.
		MenuClosed ()
			Fired when this menu has been closed.
		MenuOpening (Object targetItem)
			Fired when this menu is opening.
		WidthChanged (width)
			Fired when this menu's fixed width has changed.
]]

function self:ctor ()
	self.Items = {}
	self.ItemsById = {}
	
	self.Control = nil
	
	self.Width = nil
	
	Gooey.EventProvider (self)
end

function self:dtor ()
	if self.Control and self.Control:IsValid () then
		self.Control:Remove ()
		self.Control = nil
	end
end

function self:AddBaseMenuItem (baseMenuItem)
	baseMenuItem:SetParent (self)
	
	self.Items [#self.Items + 1] = baseMenuItem
	if baseMenuItem:GetId () then
		self.ItemsById [baseMenuItem:GetId ()] = baseMenuItem
	end
	
	self:HookItem (baseMenuItem)
	self:DispatchEvent ("ItemAdded", baseMenuItem)
	
	return self
end

function self:AddItem (id, callback)
	local menuItem = Gooey.MenuItem ()
	menuItem:SetId (id)
	menuItem:SetText (id)
	
	if callback then
		menuItem:AddEventListener ("Click",
			function (_, targetItems)
				callback (targetItems)
			end
		)
	end
	
	self:AddBaseMenuItem (menuItem)
	
	return menuItem
end

function self:AddSeparator (id)
	local menuItem = Gooey.MenuSeparator ()
	menuItem:SetId (id)
	
	self:AddBaseMenuItem (menuItem)
	
	return menuItem
end

function self:Clear ()
	self.Items = {}
	self.ItemsById = {}
	
	self:DispatchEvent ("Cleared")
end

function self:Clone (menu)
	menu = menu or Gooey.Menu ()
	
	-- Items
	for menuItem in self:GetEnumerator () do
		menu:AddBaseMenuItem (menuItem:Clone ())
	end
	
	menu:SetWidth (self:GetWidth ())
	
	-- Events
	self:GetEventProvider ():Clone (menu)
	
	return menu
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Items [i]
	end
end

function self:GetItemById (id)
	return self.ItemsById [id]
end

function self:GetWidth ()
	return self.Width
end

function self:Hide ()
	if not self.Control then return end
	if not self.Control:IsValid () then return end
	
	self.Control:SetVisible (false)
end

function self:IsVisible ()
	if not self.Control then return false end
	if not self.Control:IsValid () then return false end
	
	return self.Control:IsVisible ()
end

function self:RemoveItem (item)
	item:Remove ()
end

function self:SetTargetItem (targetItem)
	if not self.Control then return end
	if not self.Control:IsValid () then return end
	
	self.Control:SetTargetItem (targetItem)
end

function self:SetWidth (width)
	if self.Width == width then return end
	
	self.Width = width
	
	self:DispatchEvent ("WidthChanged", width)
end

function self:Show (control, ...)
	local arguments = {...}
	
	local targetItem = nil
	local x = nil
	local y = nil
	local w = 0
	local h = 0
	local anchorOrientation = Gooey.Orientation.Vertical
	local parentMenu = nil
	
	local numberStartIndex = nil
	local numberCount = nil
	for i = 1, #arguments do
		if type (arguments [i]) == "Panel" and
		   arguments [i].ClassName == "DMenu" then
			parentMenu = arguments [i]
		elseif type (arguments [i]) == "number" then
			if numberStartIndex and numberStartIndex + numberCount == i then
				numberCount = numberCount + 1
			else
				numberStartIndex = i
				numberCount = 1
			end
		else
			targetItem = arguments [i]
		end
	end
	
	if numberStartIndex then
		if numberCount >= 2 then
			x = arguments [numberStartIndex]
			y = arguments [numberStartIndex + 1]
		end
		if numberCount >= 4 then
			w = arguments [numberStartIndex + 2]
			h = arguments [numberStartIndex + 3]
		end
		if numberCount >= 5 then
			anchorOrientation = arguments [numberStartIndex + 4]
		end
	end
	
	if x == nil and y == nil then
		x = gui.MouseX ()
		y = gui.MouseY ()
	end
	
	if not self.Control or not self.Control:IsValid () then
		self.Control = vgui.Create ("GMenu")
		self.Control:SetMenu (self)
	end
	
	self.Control:SetOwner (control)
	self.Control:SetTargetItem (targetItem)
	self.Control:SetAnchorRectangle (x, y, w, h)
	self.Control:SetAnchorOrientation (anchorOrientation)
	
	self:DispatchEvent ("MenuOpening", targetItem)
	
	self.Control:SetVisible (true)
	
	return self.Control
end

-- Internal, do not call
function self:HookItem (menuItem)
	if not menuItem then return end
	
	menuItem:AddEventListener ("Removed", self:GetHashCode (),
		function ()
			for i = 1, #self.Items do
				if self.Items [i] == menuItem then
					table.remove (self.Items, i)
					break
				end
			end
			
			if self.ItemsById [menuItem:GetId ()] == menuItem then
				self.ItemsById [menuItem:GetId ()] = nil
			end
			
			self:DispatchEvent ("ItemRemoved", menuItem)
		end
	)
end

function self:UnhookItem (menuItem)
	if not menuItem then return end
	
	menuItem:RemoveEventListener ("Removed", self:GetHashCode ())
end