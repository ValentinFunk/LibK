local self = {}
Gooey.KeyboardMap = Gooey.MakeConstructor (self)

function self:ctor ()
	self.Keys = {}
end

function self:Clone ()
	local keyboardMap = Gooey.KeyboardMap ()
	for key, handlers in pairs (self.Keys) do
		for _, handler in ipairs (handlers) do
			keyboardMap:Register (key, handler)
		end
	end
	return keyboardMap
end

function self:Execute (control, key, ctrl, shift, alt)
	if not self.Keys [key] then return false end
	
	local handled
	for _, handler in ipairs (self.Keys [key]) do
		if type (handler) == "string" then
			handled = control:DispatchAction (handler)
		else
			handled = handler (control, key, ctrl, shift, alt)
		end
		
		if handled == nil then handled = true end
		if handled then break end
	end
	
	if handled and key == KEY_ESCAPE then
		if gui.IsGameUIVisible () then
			gui.HideGameUI ()
		else
			gui.ActivateGameUI ()
		end
	end
	
	return handled or false
end

function self:Register (key, handler)
	if type (key) == "table" then
		for _, v in ipairs (key) do
			self:Register (v, handler)
		end
		return
	end
	
	self.Keys [key] = self.Keys [key] or {}
	self.Keys [key] [#self.Keys [key] + 1] = handler
end