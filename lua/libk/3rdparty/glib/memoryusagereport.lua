local self = {}
GLib.MemoryUsageReport = GLib.MakeConstructor (self)

local pointerSize = 8
local hashSize = 4
local typeSize = 4
local functionSize = 64
local stringLengthSize = 4
local tableSizeSize = 4

function self:ctor ()
	self.Pools = {}
	self.CountedTables = GLib.WeakKeyTable ()
	self.CountedStrings = {}
	self.CountedFunctions = {}
end

function self:Credit (poolName, object, size)
	poolName = poolName or "Unknown"
	self.Pools [poolName] = self.Pools [poolName] or 0
	self.Pools [poolName] = self.Pools [poolName] + size
end

function self:CreditFunction (poolName, object)
	if self:IsCounted (object) then return end
	self:MarkCounted (object)
	
	self:CreditTable (poolName or "Function Metadata", debug.getinfo (object))	
	self:Credit (poolName or "Functions", object, functionSize)
end

function self:CreditObject (poolName, object)
	if type (object) == "table" then
		if type (object.ComputeMemoryUsage) == "function" and poolName ~= "Metatables" then
			object:ComputeMemoryUsage (self, poolName)
		else
			self:CreditTable (poolName, object)
		end
	elseif type (object) == "string" then
		self:CreditString (poolName or "Strings", object)
	elseif type (object) == "number" then
		self:Credit (poolName, nil, 8)
	elseif type (object) == "function" then
		self:CreditFunction (poolName or "Functions", object, functionSize)
	end
end

function self:CreditString (poolName, object)
	if object == nil then return end
	
	if self:IsCounted (object) then return end
	self:MarkCounted (object)
	
	self:Credit (poolName, object, stringLengthSize + string.len (object) + 1) -- Length, string data, null terminator
end

function self:CreditTable (poolName, object)
	if self:IsCounted (object) then return end
	self:CreditTableStructure (poolName, object)

	for k, v in pairs (object) do
		self:CreditObject (poolName, k)
		self:CreditObject (poolName, v)
	end
end

function self:CreditTableStructure (poolName, object)
	if self:IsCounted (object) then return end
	self:MarkCounted (object)
	
	local count = 0
	for k, v in pairs (object) do
		count = count + 1
	end
	self:CreditObject ("Metatables", object.__index)
	self:CreditObject ("Metatables", getmetatable (object))
	
	local size = tableSizeSize * 2 -- Hash table size + array size
	size = size + count * 2 * pointerSize -- Hash table array
	size = size + count * hashSize -- Hashes
	size = size + count * typeSize -- Metadata
	
	poolName = poolName or "Unknown"
	self.Pools [poolName] = self.Pools [poolName] or 0
	self.Pools [poolName] = self.Pools [poolName] + size
end

function self:GetTotalBytes ()
	local totalBytes = 0
	for _, poolBytes in pairs (self.Pools) do
		totalBytes = totalBytes + poolBytes
	end
	return totalBytes
end

function self:IsCounted (object)
	return self.CountedTables [object] or self.CountedStrings [object] or self.CountedFunctions [object] or false
end

function self:MarkCounted (object)
	if type (object) == "table" then
		self.CountedTables [object] = true
	elseif type (object) == "string" then
		self.CountedStrings [object] = true
	elseif type (object) == "function" then
		self.CountedFunctions [object] = true
	end
end

function self:ToString ()
	local memoryUsageReport = ""
	memoryUsageReport = memoryUsageReport .. "=============================\n"
	memoryUsageReport = memoryUsageReport .. "Memory Usage Report\n"
	memoryUsageReport = memoryUsageReport .. "=============================\n"
	
	local sortedPools = {}
	for poolName, size in pairs (self.Pools) do
		sortedPools [#sortedPools + 1] = { Name = poolName, Size = size }
	end
	table.sort (sortedPools, function (a, b) return a.Size > b.Size end)
	
	local totalSize = 0
	for _, poolEntry in ipairs (sortedPools) do
		memoryUsageReport = memoryUsageReport .. string.format ("%9d", poolEntry.Size) .. " B - " .. poolEntry.Name .. "\n"
		totalSize = totalSize + poolEntry.Size
	end
	memoryUsageReport = memoryUsageReport .. "=============================\n"
	memoryUsageReport = memoryUsageReport .. string.format ("%9d", totalSize) .. " B - Total\n"
	memoryUsageReport = memoryUsageReport .. "=============================\n"
	return memoryUsageReport
end