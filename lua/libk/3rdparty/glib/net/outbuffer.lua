local self = {}
GLib.Net.OutBuffer = GLib.MakeConstructor (self, GLib.OutBuffer)

function self:ctor ()
	self.Data = {}
	self.Types = {}
	
	self.NextDataId = 1
	self.Size = 0
end

for typeName, enumValue in pairs (GLib.Net.DataType) do
	self [typeName] = function (self, n)
		if n == nil then GLib.Error ("OutBuffer:" .. typeName .. " : Called with nil value") end
		
		self.Data [self.NextDataId] = n
		self.Types [self.NextDataId] = enumValue
		self.NextDataId = self.NextDataId + 1
		
		local typeSize = GLib.Net.DataTypeSizes [typeName]
		if type (typeSize) == "number" then
			self.Size = self.Size + typeSize
		else
			self.Size = self.Size + typeSize (n)
		end
		
		return self
	end
	
	self ["Prepend" .. typeName] = function (self, n)
		if n == nil then GLib.Error ("OutBuffer:Prepend" .. typeName .. " : Called with nil value") end
		
		table.insert (self.Data, 1, n)
		table.insert (self.Types, 1, enumValue)
		self.NextDataId = self.NextDataId + 1
		
		local typeSize = GLib.Net.DataTypeSizes [typeName]
		if type (typeSize) == "number" then
			self.Size = self.Size + typeSize
		else
			self.Size = self.Size + typeSize (n)
		end
		
		return self
	end
end

function self:GetSize ()
	return self.Size
end

function self:Bytes (data, length)
	length = length or #data
	length = math.min (length, #data)
	
	data = string.sub (data, 1, length)
	self.Data [self.NextDataId] = data
	self.Types [self.NextDataId] = GLib.Net.DataType.Bytes
	self.NextDataId = self.NextDataId + 1
	
	self.Size = self.Size + length
end

--[[
	OutBuffer:OutBuffer (OutBuffer outBuffer)
	
		Appends the contents of outBuffer to this OutBuffer
]]
function self:OutBuffer (outBuffer)
	for i = 1, #outBuffer.Data do
		self.Data [self.NextDataId] = outBuffer.Data [i]
		self.Types [self.NextDataId] = outBuffer.Types [i]
		self.NextDataId = self.NextDataId + 1
	end
	
	self.Size = self.Size + outBuffer:GetSize ()
end

function self:GetString ()
	local outBuffer = GLib.StringOutBuffer ()
	for i = 1, #self.Data do
		outBuffer [GLib.Net.DataType [self.Types [i]]] (outBuffer, self.Data [i])
	end
	return outBuffer:GetString ()
end