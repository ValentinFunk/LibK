local self = {}
GLib.Event = GLib.MakeConstructor (self)

function self:ctor ()
	self.Listeners = {}
	self.ShouldSuppressEvents = false
end

function self:dtor ()
	self:ClearListeners ()
end

function self:AddListener (nameOrCallback, callback)
	callback = callback or nameOrCallback
	self.Listeners [nameOrCallback] = callback
end

function self:ClearListeners ()
	self.Listeners = {}
end

function self:Clone (event)
	event = event or GLib.Event ()
	
	for callbackName, callback in pairs (self.Listeners) do
		event.Listeners [callbackName] = callback
	end
	
	return event
end

function self:Dispatch (...)
	if self.ShouldSuppressEvents then return end
	
	local a, b, c = nil, nil, nil
	
	for callbackName, callback in pairs (self.Listeners) do
		local success, r0, r1, r2 = xpcall (callback, GLib.Error, ...)
		if not success then
			ErrorNoHalt ("Error in hook " .. eventName .. ": " .. tostring (callbackName) .. "!\n")
		else
			a = a or r0
			b = b or r1
			c = c or r2
		end
	end
	
	return a, b, c
end

function self:RemoveListener (nameOrCallback)
	self.Listeners [nameOrCallback] = nil
end

function self:SuppressEvents (suppress)
	self.ShouldSuppressEvents = suppress
end

function self:__call (...)
	return self:Dispatch (...)
end