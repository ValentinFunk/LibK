local self = {}
GLib.Containers.Set = GLib.MakeConstructor (self, GLib.Containers.ICollection)

function self:ctor ()
	self.Count = 0
	
	self.ItemSet = {}
end

-- ICollection
function self:Add (item)
	if self:Contains (item) then return self end
	
	self.Count = self.Count + 1
	self.ItemSet [item] = true
	
	return self
end

function self:Clear ()
	if self.Count == 0 then return end
	
	self.Count = 0
	
	self.ItemSet = {}
end

function self:Contains (item)
	return self.ItemSet [item] ~= nil
end

function self:GetCount ()
	return self.Count
end

function self:GetEnumerator ()
	return GLib.KeyEnumerator (self.ItemSet)
end

function self:IsEmpty ()
	return self.Count == 0
end

function self:Remove (item)
	if not self:Contains (item) then return end
	
	self.Count = self.Count - 1
	self.ItemSet [item] = nil
end

-- Set
function self:Intersect (enumerable, out)
	out = out or self.__ictor ()
	
	for item in enumerable:GetEnumerator () do
		if self:Contains (item) then
			out:Add (item)
		end
	end
	
	return out
end

function self:Subtract (set, out)
	out = out or self.__ictor ()
	
	for item in self:GetEnumerator () do
		if not set:Contains (item) then
			out:Add (item)
		end
	end
	
	return out
end

function self:Union (enumerable, out)
	out = out or self.__ictor ()
	
	for item in self:GetEnumerator () do
		out:Add (item)
	end
	for item in enumerable:GetEnumerator () do
		out:Add (item)
	end
	
	return out
end

function self:ToArray ()
	local array = {}
	for item, _ in pairs (self.ItemSet) do
		array [#array + 1] = item
	end
	return array
end

function self:ToString ()
	local content = ""
	for item in self:GetEnumerator () do
		if content ~= "" then
			content = content .. ", "
		end
		
		if #content > 2048 then
			content = content .. "..."
			break
		end
		
		item = item or "[nil]"
		
		if type (item) == "table" and item.ToString then item = item:ToString ()
		elseif type (item) == "string" then item = "\"" .. GLib.String.Escape (item) .. "\"" end
		item = tostring (item)
		
		content = content .. item
	end
	return "[" .. tostring (self.Count) .. "] : {" .. content .. "}"
end