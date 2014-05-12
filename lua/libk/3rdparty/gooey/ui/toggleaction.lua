local self = {}
Gooey.ToggleAction = Gooey.MakeConstructor (self, Gooey.Action)

--[[
	Events:
		ToggledChanged (toggled)
			Fired when this action's toggle state has changed.
]]

function self:ctor (name, booleanController)
	self.CanRunFunction = nil
	self.Handler = Gooey.NullCallback
	
	self.Toggled = false
	self.BooleanController = nil
	
	self:SetBooleanController (booleanController)
end

function self:dtor ()
	self:SetBooleanController (nil)
end

function self:Execute (control, ...)
	if not self:CanRun (control, ...) then return end
	
	self:SetToggled (not self:IsToggled ())
	self.Handler (control, self:IsToggled ())
end

function self:GetBooleanController ()
	return self.BooleanController
end

function self:IsToggleAction ()
	return true
end

function self:IsToggled ()
	if self.BooleanController then
		return self.BooleanController:GetValue ()
	end
	
	return self.Toggled
end

function self:SetBooleanController (booleanController)
	if self.BooleanController == booleanController then return end
	
	local toggled = self:IsToggled ()
	self:UnhookBooleanController (self.BooleanController)
	self.BooleanController = booleanController
	self:HookBooleanController (self.BooleanController)
	
	if self:IsToggled () ~= toggled then
		self:DispatchEvent ("ToggleChanged", self:IsToggled ())
	end
end

function self:SetToggled (toggled)
	if self:IsToggled () == toggled then return self end
	
	self.Toggled = toggled
	if self.BooleanController then
		self.BooleanController:SetValue (self.Toggled)
	end
	self:DispatchEvent ("ToggleChanged", self:IsToggled ())
	
	return self
end

-- Internal, do not call
function self:HookBooleanController (booleanController)
	if not booleanController then return end
	
	booleanController:AddEventListener ("ValueChanged",
		function (_, value)
			self:DispatchEvent ("ToggleChanged", self:GetHashCode (), self:IsToggled ())
		end
	)
end
function self:UnhookBooleanController (booleanController)
	if not booleanController then return end
	
	booleanController:RemoveEventListener ("ValueChanged", self:GetHashCode ())
end