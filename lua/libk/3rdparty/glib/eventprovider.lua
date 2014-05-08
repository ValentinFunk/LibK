local self = {}
GLib.EventProvider = GLib.MakeConstructor (self)

local pairs    = pairs
local pcall    = pcall
local tostring = tostring
local xpcall   = xpcall

function self:ctor (host, getParentEventProvider)
	if host then
		host.AddEventListener = function (host, ...)
			self:AddEventListener (...)
			return host
		end
		host.DispatchEvent = function (host, eventName, ...)
			return self:DispatchEvent (eventName, host, ...)
		end
		host.RemoveEventListener = function (host, ...)
			return self:RemoveEventListener (...)
		end
		host.SuppressEvents = function (host, ...)
			return self:SuppressEvents (...)
		end
	end

	self.EventListeners = {}
	self.ShouldSuppressEvents = false
	self.GetParentEventProvider = getParentEventProvider
end

function self:AddEventListener (eventName, nameOrCallback, callback)
	callback = callback or nameOrCallback
	if not self.EventListeners [eventName] then
		self.EventListeners [eventName] = {}
	end
	self.EventListeners [eventName] [nameOrCallback] = callback
end

function self:DispatchEvent (eventName, ...)
	if self.ShouldSuppressEvents then return end
	local a, b, c = nil, nil, nil
	if self.EventListeners [eventName] then
		for callbackName, callback in pairs (self.EventListeners [eventName]) do
			local success, r0, r1, r2 = xpcall (callback, GLib.Error, ...)
			if not success then
				ErrorNoHalt ("Error in hook " .. eventName .. ": " .. tostring (callbackName) .. "!\n")
			else
				a = a or r0
				b = b or r1
				c = c or r2
			end
		end
	elseif type (eventName) ~= "string" then
		GLib.Error ("EventProvider:DispatchEvent called incorrectly.")
	end
	
	if self.GetParentEventProvider then
		local parent = self:GetParentEventProvider ()
		if parent then
			local success, r0, r1, r2 = pcall (parent.DispatchEvent, parent, eventName, ...)
			if not success then
				ErrorNoHalt ("Error in hook " .. eventName .. ": Parent: " .. tostring (r0) .. "\n")
			else
				a = a or r0
				b = b or r1
				c = c or r2
			end
		end
	end
	return a, b, c
end

function self:RemoveEventListener (eventName, nameOrCallback)
	if not self.EventListeners [eventName] then return end
	self.EventListeners [eventName] [nameOrCallback] = nil
	if next (self.EventListeners [eventName]) == nil then
		self.EventListeners [eventName] = nil
	end
end

function self:RemoveEventListeners (nameOrCallback)
	for	eventName, eventListeners in pairs (self.EventListeners) do
		eventListeners [nameOrCallback] = nil
		if next (eventListeners) == nil then
			self.EventListeners [eventName] = nil
		end
	end
end

function self:SuppressEvents (suppress)
	self.ShouldSuppressEvents = suppress
end