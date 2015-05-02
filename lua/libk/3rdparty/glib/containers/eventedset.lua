local self = {}
GLib.Containers.EventedSet = GLib.MakeConstructor (self, GLib.Containers.Set)

--[[
	Events:
		Cleared ()
			Fired when this set has been cleared.
		ItemAdded (item)
			Fired when an item has been added to this set.
		ItemRemoved (item)
			Fired when an item has been removed from this set.
]]

function self:ctor ()
	GLib.EventProvider (self)
end

function self:Add (item)
	if self:Contains (item) then return self end
	
	self.Count = self.Count + 1
	self.ItemSet [item] = true
	
	self:DispatchEvent ("ItemAdded", item)
	
	return self
end

function self:Clear ()
	if self.Count == 0 then return end
	
	for item, _ in pairs (self.ItemSet) do
		self.ItemSet [item] = nil
		self:DispatchEvent ("ItemRemoved", item)
	end
	
	self.Count = 0
	
	self:DispatchEvent ("Cleared")
end

function self:Remove (item)
	if not self:Contains (item) then return end
	
	self.Count = self.Count - 1
	self.ItemSet [item] = nil
	
	self:DispatchEvent ("ItemRemoved", item)
end