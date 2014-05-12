local self = {}
Gooey.MenuSeparator = Gooey.MakeConstructor (self, Gooey.BaseMenuItem)

function self:ctor ()
end

function self:dtor ()
end

function self:Clone (menuItem)
	menuItem = menuItem or Gooey.MenuSeparator ()
	
	-- BaseMenuItem
	menuItem:SetId (self:GetId ())
	menuItem:SetEnabled (self:IsEnabled ())
	menuItem:SetVisible (self:IsVisible ())
	
	-- Events
	self:GetEventProvider ():Clone (menuItem)
	
	return menuItem
end

function self:GetText ()
	return "-"
end

function self:IsSeparator ()
	return true
end