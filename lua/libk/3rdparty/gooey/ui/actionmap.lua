local self = {}
Gooey.ActionMap = Gooey.MakeConstructor (self)

function self:ctor ()
	self.ChainedActionMap = nil
	self.ChainedActionMapControl = nil
	
	self.Actions = {}
end

function self:dtor ()
	for _, action in pairs (self.Actions) do
		action:dtor ()
	end
end

function self:CanRunAction (actionName, control, ...)
	local action, control = self:GetAction (actionName, control)
	if not action then return false end
	
	return action:CanRun (control, ...)
end

function self:Execute (actionName, control, ...)
	local action, control = self:GetAction (actionName, control)
	if not action then return false end
	if not action:CanRun (control, ...) then return false end
	
	action:Execute (control, ...)
	return true
end

function self:GetAction (actionName, control)
	if self.ChainedActionMap then
		local action, control = self.ChainedActionMap:GetAction (actionName, self.ChainedActionMapControl)
		if action then return action, control end
	end
	
	return self.Actions [actionName], control
end

function self:GetChainedActionMap ()
	return self.ChainedActionMap, self.ChainedActionMapControl
end

function self:GetTarget ()
	return self.Target
end

function self:Register (actionName, handler, canRunFunction)
	local action = Gooey.Action (actionName)
	self.Actions [actionName] = action
	
	action:SetHandler (handler)
	action:SetCanRunFunction (canRunFunction)
	return action
end

function self:RegisterToggle (actionName, booleanController, canRunFunction)
	local action = Gooey.ToggleAction (actionName, booleanController)
	self.Actions [actionName] = action
	
	action:SetCanRunFunction (canRunFunction)
	return action
end

function self:SetChainedActionMap (actionMap, control)
	-- Prevent cycles
	if actionMap == self then
		actionMap = nil
		control = nil
	end
	
	self.ChainedActionMap = actionMap
	self.ChainedActionMapControl = control
end