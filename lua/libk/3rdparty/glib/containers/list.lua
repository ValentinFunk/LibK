local self = {}
GLib.Containers.List = GLib.MakeConstructor (self, GLib.Containers.ICollection)

function GLib.Containers.List.FromArray (array, list)
	list = list or GLib.Containers.List ()
	
	for i = 1, #array do
		list:Add (array [i])
	end
	
	return list
end

function GLib.Containers.List.FromEnumerable (enumerable, list)
	list = list or GLib.Containers.List ()
	
	list:AddRange (enumerable)
	
	return list
end

function self:ctor (array)
	self.Count = 0
	
	self.Items = {}
	
	if array then
		GLib.Containers.List.FromArray (array, self)
	end
end

-- ICollection
function self:Add (item)
	self.Count = self.Count + 1
	self.Items [self.Count] = item
	
	return self
end

function self:Clear ()
	self.Count = 0
	
	self.Items = {}
end

function self:Contains (item)
	return self:IndexOf (item) ~= nil
end

function self:GetCount ()
	return self.Count
end

function self:GetEnumerator ()
	return GLib.ArrayEnumerator (self.Items)
end

function self:IsEmpty ()
	return self.Count == 0
end

function self:Remove (item)
	self:RemoveAt (self:IndexOf (item))
end

-- List
function self:Filter (filter)
	local filteredList = GLib.Containers.List ()
	
	for i = 1, self.Count do
		if filter (self.Items [i]) then
			filteredList:Add (self.Items [i])
		end
	end
	
	return filteredList
end

function self:Get (index)
	return self.Items [index]
end

function self:IndexOf (item)
	for i = 1, self.Count do
		if self.Items [i] == item then return i end
	end
	return nil
end

function self:Insert (index, item)
	table.insert (self.Items, index, item)
	self.Count = self.Count + 1
	return self
end

function self:RemoveAt (index)
	if not index then return end
	if index <= 0 then return end
	if index > self.Count then return end
	
	table.remove (self.Items, i)
	self.Count = self.Count - 1
end

function self:Sort (comparator)
	table.sort (self.Items, comparator)
end

function self:ToArray ()
	local array = {}
	for i = 1, self.Count do
		array [i] = self.Items [i]
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