local self = {}
Gooey.BooleanController = Gooey.MakeConstructor (self)

--[[
	Events:
		ValueChanged (value)
			Fired when this BooleanController's value has changed.
]]

function self:ctor ()
	self.Value = false
	
	Gooey.EventProvider (self)
end

function self:GetValue ()
	local value = self:DispatchEvent ("GetValue")
	if value ~= nil then return value end
	return self.Value
end

function self:SetValue (value)
	if self:GetValue () == value then return self end
	
	self.Value = value
	self:DispatchEvent ("ValueChanged", self.Value)
	return self
end