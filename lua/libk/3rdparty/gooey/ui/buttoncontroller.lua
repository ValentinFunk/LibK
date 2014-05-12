local self = {}
Gooey.ButtonController = Gooey.MakeConstructor (self)

function self:ctor ()
	self.Actions = {}
	
	Gooey.EventProvider (self)
end

function self:AddAction (actionName, action)
	if not self.Actions [actionName] then
		self:RegisterAction (actionName)
	end
	self.Actions [actionName].Actions [action] = true
	
	action:SetEnabled (self:CanPerformAction (actionName))
end

function self:AddButton (actionName, button)
	if not self.Actions [actionName] then
		self:RegisterAction (actionName)
	end
	self.Actions [actionName].Buttons [button] = true
	
	button:SetEnabled (self:CanPerformAction (actionName))
end

function self:CanPerformAction (actionName)
	if not self.Actions [actionName] then return false end
	return self.Actions [actionName].Enabled or false
end

function self:RegisterAction (actionName, eventName)
	if self.Actions [actionName] then return end
	self.Actions [actionName] = {}
	self.Actions [actionName].Enabled = false
	self.Actions [actionName].Actions = {}
	self.Actions [actionName].Buttons = {}
	self.Actions [actionName].EventName = eventName or ("Can" .. actionName .. "Changed")
end

function self:UpdateActionState (actionName, canPerformAction)
	if not self.Actions [actionName] then
		self:RegisterAction (actionName)
	end
	
	if self.Actions [actionName].Enabled == canPerformAction then return end
	self.Actions [actionName].Enabled = canPerformAction
	
	for action, _ in pairs (self.Actions [actionName].Actions) do
		action:SetEnabled (canPerformAction)
	end
	for button, _ in pairs (self.Actions [actionName].Buttons) do
		if button:IsValid () then
			button:SetEnabled (canPerformAction)
		end
	end
	
	self:DispatchEvent (self.Actions [actionName].EventName, canPeformAction)
end