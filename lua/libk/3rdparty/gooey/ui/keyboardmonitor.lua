local self = {}
Gooey.KeyboardMonitor = Gooey.MakeConstructor (self)

--[[
	Events:
		KeyPressed (key)
			Fired when a key has been pressed.
		KeyReleased (key)
			Fired when a key has been released.
]]

function self:ctor ()
	self.KeysWatched = {}
	self.KeysPressed = {}
	
	Gooey.EventProvider (self)
	
	hook.Add ("Think", "Gooey.KeyboardMonitor." .. self:GetHashCode (),
		function ()
			self:Tick ()
		end
	)
	
	Gooey:AddEventListener ("Unloaded", "Gooey.KeyboardMonitor." .. self:GetHashCode (),
		function ()
			self:dtor ()
		end
	)
end

function self:dtor ()
	hook.Remove ("Think", "Gooey.KeyboardMonitor." .. self:GetHashCode ())
	Gooey:RemoveEventListener ("Unloaded", "Gooey.KeyboardMonitor." .. self:GetHashCode ())
end

function self:IsKeyDown (key)
	return self.KeysPressed [key] or false
end

function self:RegisterKey (key)
	if self.KeysWatched [key] then return end
	
	self.KeysWatched [key] = true
	self.KeysPressed [key] = false
end

function self:Tick ()
	local keyPressed = false
	for key, _ in pairs (self.KeysWatched) do
		keyPressed = input.IsKeyDown (key)
		if keyPressed ~= self.KeysPressed [key] then
			self.KeysPressed [key] = keyPressed
			if keyPressed then
				self:DispatchEvent ("KeyPressed", key)
			else
				self:DispatchEvent ("KeyReleased", key)
			end
		end
	end
end

function self:UnregisterKey (key)
	self.KeysWatched [key] = false
	self.KeysPressed [key] = nil
end