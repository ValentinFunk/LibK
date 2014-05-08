local self = {}
GLib.Containers.NetworkableList = GLib.MakeConstructor (self, GLib.Networking.NetworkableContainer)
GLib.RegisterSerializable ("GLib.Containers.NetworkableList", GLib.Containers.NetworkableList)

--[[
	Events:
		Cleared ()
			Fired when this NetworkableList has been cleared.
		Sorted ()
			Fired when this NetworkableList has been sorted.
]]

function self:ctor ()
	self.ItemRefCounts = {}
	self.Items = {}
	self.Count = 0
end

-- Networkable
function self:HandleMessage (sourceId, inBuffer)
	if self:IsAuthoritative () then return end
	
	local messageType = inBuffer:String ()
	if messageType == "Add" then
		self:InternalAdd (GLib.Deserialize (inBuffer))
	elseif messageType == "Clear" then
		self:InternalClear ()
	elseif messageType == "Insert" then
		local index = inBuffer:UInt16 ()
		self:InternalInsert (index, GLib.Deserialize (inBuffer))
	elseif messageType == "RemoveAt" then
		self:InternalRemoveAt (inBuffer:UInt16 ())
	elseif messageType == "Sort" then
		local newItems = {}
		local newItemCount = inBuffer:UInt16 ()
		for i = 1, newItemCount do
			newItems [i] = self.Items [inBuffer:UInt16 ()]
		end
		self.Items = newItems
		
		self:DispatchEvent ("Sorted")
	end
end

-- NetworkableContainer
function self:GetChildNetworkable (address)
	return self.Items [tonumber (address)]
end

function self:GetChildNetworkableAddress (childNetworkable)
	return self:IndexOf (childNetworkable)
end

-- NetworkableList
function self:Add (item)
	if not self:IsAuthoritative () then
		GLib.Error ("NetworkableList:Add : This NetworkableList is not authoritative.")
	end
	
	self:InternalAdd (item)
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:String ("Add")
	GLib.Serialize (item, outBuffer)
	self:NetworkMessage (outBuffer)
	
	return self
end

function self:Clear ()
	if not self:IsAuthoritative () then
		GLib.Error ("NetworkableList:Clear : This NetworkableList is not authoritative.")
	end
	
	self:InternalClear ()
	
	self:NetworkMessage ("Clear")
end

function self:Contains (item)
	return self.ItemRefCounts [item] ~= nil
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
	if not self:Contains (item) then return nil end
	
	for i = 1, self.Count do
		if self.Items [i] == item then return i end
	end
	
	return nil
end

function self:Insert (index, item)
	if not self:IsAuthoritative () then
		GLib.Error ("NetworkableList:Insert : This NetworkableList is not authoritative.")
	end
	
	self:InternalInsert (index, item)
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:String ("Insert")
	outBuffer:UInt16 (index)
	GLib.Serialize (item, outBuffer)
	self:NetworkMessage (outBuffer)
	
	return self
end

function self:Remove (item)
	self:RemoveAt (self:IndexOf (item))
end

function self:RemoveAt (index)
	if not self:IsAuthoritative () then
		GLib.Error ("NetworkableList:RemoveAt : This NetworkableList is not authoritative.")
	end
	
	self:InternalRemoveAt (index)
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:String ("RemoveAt")
	outBuffer:UInt16 (index)
	self:NetworkMessage (outBuffer)
end

function self:Sort (comparator)
	if not self:IsAuthoritative () then
		GLib.Error ("NetworkableList:Sort : This NetworkableList is not authoritative.")
	end
	
	local originalIndices = {}
	for i = 1, self.Count do
		originalIndices [self.Items [i]] = i
	end
	
	table.sort (self.Items, comparator)
	
	local newIndices = {}
	for i = 1, self.Count do
		newIndices [i] = originalIndices [self.Items [i]]
	end
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:String ("Sort")
	outBuffer:UInt16 (#newIndices)
	for i = 1, #newIndices do
		outBuffer:UInt16 (newIndices [i])
	end
	self:NetworkMessage (outBuffer)
	
	self:DispatchEvent ("Sorted")
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

self.__tostring = self.ToString

-- Internal, do not call
function self:HookItem (item)
	if not item then return end
	if type (item) ~= "table" then return end
	
	self:HookNetworkable (item)
end

function self:UnhookItem (item)
	if not item then return end
	if type (item) ~= "table" then return end
	
	self:UnhookNetworkable (item)
end

function self:InternalAdd (item)
	self.Count = self.Count + 1
	self.Items [self.Count] = item
	
	if not self.ItemRefCounts [item] then
		self:HookItem (item)
		self.ItemRefCounts [item] = 0
	end
	self.ItemRefCounts [item] = self.ItemRefCounts [item] + 1
	
	self:DispatchEvent ("ItemAdded", item)
end

function self:InternalClear ()
	for item, _ in pairs (self.ItemRefCounts) do
		self:UnhookItem (item)
	end
	
	self.ItemRefCounts = {}
	self.Items = {}
	self.Count = 0
	
	self:DispatchEvent ("Cleared")
end

function self:InternalInsert (index, item)
	self.Count = self.Count + 1
	table.insert (self.Items, index, item)
	
	if not self.ItemRefCounts [item] then
		self:HookItem (item)
		self.ItemRefCounts [item] = 0
	end
	self.ItemRefCounts [item] = self.ItemRefCounts [item] + 1
	
	self:DispatchEvent ("ItemInserted", item, index)
end

function self:InternalRemoveAt (index)
	if not index then return end
	if index <= 0 then return end
	if index > self.Count then return end
	
	local item = self.Items [i]
	table.remove (self.Items, i)
	self.Count = self.Count - 1
	self.ItemRefCounts [item] = self.ItemRefCounts [item] - 1
	
	if self.ItemRefCounts [item] == 0 then
		self.ItemRefCounts [item] = nil
		self:UnhookItem (item)
	end
	
	self:DispatchEvent ("ItemRemoved", item)
end