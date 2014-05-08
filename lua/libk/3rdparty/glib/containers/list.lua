local self = {}
GLib.Containers.List = GLib.MakeConstructor (self)

function self:ctor ()
	self.Items = {}
	self.Count = 0
end

function self:Add (item)
	self.Count = self.Count + 1
	self.Items [self.Count] = item
	return self
end

function self:Clear ()
	self.Items = {}
	self.Count = 0
end

function self:Contains (item)
	return self:IndexOf (item) ~= nil
end

function self:Get (index)
	return self.Items [index]
end

function self:GetCount ()
	return self.Count
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Items [i]
	end
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

function self:Remove (item)
	self:RemoveAt (self:IndexOf (item))
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