local PANEL = {}

--[[
	Events:
		MenuClosed ()
			Fired when this menu has been closed.
		MenuOpening (Object targetItem)
			Fired when this menu is opening.
]]

Derma_Hook (PANEL, "Paint", "Paint", "MenuBar")

function PANEL:Init ()
	self:SetTall (24)
	
	self.TargetItem = nil
	
	self:SetMouseInputEnabled (true)
	self:SetKeyboardInputEnabled (true)
	
	self.Menus = {}
	self.Items = {}
	
	self.OpenMenus = {}
end

function PANEL:AddMenu (id)
	if self.Menus [id] then return self.Menus [id] end
	
	local menu = Gooey.Menu ()
	self.Menus [id] = menu
	
	menu:AddEventListener ("MenuClosed",
		function (_)
			self.OpenMenus [menu] = nil
		end
	)
	
	menu:AddEventListener ("MenuOpening",
		function (_)
			self.OpenMenus [menu] = true
		end
	)
	
	local item = vgui.Create ("GMenuStripItem", self)
	item:SetMenuStrip (self)
	item:SetMenu (menu)
	item:SetText (id)
	item.Id = id
	self.Items [#self.Items + 1] = item
	
	item:AddEventListener ("TextChanged",
		function (_, text)
			self:InvalidateLayout ()
		end
	)
	
	return menu
end

function PANEL:AddSeparator (id)
    local item = vgui.Create ("GMenuSeparator", self)
    item:SetWide (1)
    item.Id = id
	
	self.Items [#self.Items + 1] = item
	self:InvalidateLayout ()
	
	return item
end

function PANEL:CloseMenus ()
	for menu, _ in pairs (self.OpenMenus) do
		menu:Hide ()
	end
end

function PANEL:GetItemById (id)
	for _, item in pairs (self.Items) do
		if item.Id == id then
			return item.Menu or item
		end
	end
	return nil
end

function PANEL:GetTargetItem ()
	return self.TargetItem
end

function PANEL:IsMenuOpen ()
	return next (self.OpenMenus) ~= nil
end

function PANEL:PerformLayout ()
	local x = 1
	for _, item in ipairs (self.Items) do
		item:SetPos (x, 1)
		item:SetTall (self:GetTall () - 3)
		item:PerformLayout ()
		
		if item:IsVisible () then
			x = x + item:GetWide () + 3
		end
	end
end

function PANEL:SetTargetItem (targetItem)
	self.TargetItem = targetItem
end

-- Event handlers
function PANEL:OnRemoved ()
	for _, menu in pairs (self.Menus) do
		menu:dtor ()
	end
end

Gooey.Register ("GMenuStrip", PANEL, "GPanel")