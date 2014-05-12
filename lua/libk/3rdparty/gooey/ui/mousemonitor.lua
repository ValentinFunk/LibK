local self = {}
Gooey.MouseMonitor = Gooey.MakeConstructor (self)

--[[
	Events:
		MousePressed (button)
			Fired when a button has been pressed.
		MouseReleased (button)
			Fired when a button has been released.
]]

function self:ctor ()
	self.ButtonsWatched = {}
	self.ButtonsPressed = {}
	
	Gooey.EventProvider (self)
	
	hook.Add ("Think", "Gooey.MouseMonitor." .. self:GetHashCode (),
		function ()
			self:Tick ()
		end
	)
	
	Gooey:AddEventListener ("Unloaded", "Gooey.MouseMonitor." .. self:GetHashCode (),
		function ()
			self:dtor ()
		end
	)
end

function self:dtor ()
	hook.Remove ("Think", "Gooey.MouseMonitor." .. self:GetHashCode ())
	Gooey:RemoveEventListener ("Unloaded", "Gooey.MouseMonitor." .. self:GetHashCode ())
end

function self:IsButtonDown (button)
	return self.ButtonsPressed [button] or false
end

function self:RegisterButton (button)
	if self.ButtonsWatched [button] then return end
	
	self.ButtonsWatched [button] = true
	self.ButtonsPressed [button] = false
end

function self:Tick ()
	local buttonPressed = false
	for button, _ in pairs (self.ButtonsWatched) do
		buttonPressed = input.IsMouseDown (button)
		if buttonPressed ~= self.ButtonsPressed [button] then
			self.ButtonsPressed [button] = buttonPressed
			if buttonPressed then
				self:DispatchEvent ("MousePressed", button)
			else
				self:DispatchEvent ("MouseReleased", button)
			end
		end
	end
end

function self:UnregisterButton (button)
	self.ButtonsWatched [button] = false
	self.ButtonsPressed [button] = nil
end