local self = {}
GLib.Lua.BytecodeReader = GLib.MakeConstructor (self)

function self:ctor (functionOrDump, authId)
	-- Input
	self.Function = nil
	self.Dump = nil
	
	-- Function dumps
	self.Functions = {}
	
	-- String
	self.String = nil

	if type (functionOrDump) == "string" then
		self.Dump = functionOrDump
	else
		self.Function = functionOrDump
		local success, result = pcall (string.dump, self.Function)
		
		if success then
			self.Dump = result
		end
	end
	
	if not self.Dump then return end
	
	-- Read
	local reader = GLib.StringInBuffer (self.Dump)
	
	-- Header
	self.Signature = reader:Bytes (4)
	self.Reserved1 = reader:UInt8 ()
	
	self.Source = reader:Bytes (reader:UInt8 ())
	
	-- Functions
	local functionDataLength = reader:ULEB128 ()
	while functionDataLength ~= 0 do
		local functionData = reader:Bytes (functionDataLength)
		self.Functions [#self.Functions + 1] = GLib.Lua.FunctionBytecodeReader (self, functionData)
		
		functionDataLength = reader:ULEB128 ()
	end
	
	self:LinkFunctions (#self.Functions - 1, self.Functions [#self.Functions])
end

function self:GetDump ()
	return self.Dump
end

function self:GetFunction (index)
	return self.Functions [index]
end

function self:GetFunctionCount ()
	return #self.Functions
end

function self:GetFunctionEnumerator ()
	return GLib.ArrayEnumerator (self.Functions)
end

function self:GetInputFunction ()
	return self.Function
end

function self:GetSource ()
	return self.Source
end

function self:HasDump ()
	return self.Dump ~= nil
end

function self:ToString ()
	if not self.String then
		local str = GLib.StringBuilder ()
		if self:GetSource () then
			str:Append ("-- " .. self:GetSource ())
			str:Append ("\n")
		end
		if #self.Functions > 0 then
			str:Append (self.Functions [#self.Functions]:ToString ())
		end
		
		self.String = str:ToString ()
	end
	
	return self.String
end

self.__tostring = self.ToString

-- Internal, do not call
function self:LinkFunctions (lastUnallocatedFunction, functionBytecodeReader)
	for i = 1, functionBytecodeReader:GetGarbageCollectedConstantCount () do
		local garbageCollectedConstant = functionBytecodeReader:GetGarbageCollectedConstant (i)
		if garbageCollectedConstant:GetType () == GLib.Lua.GarbageCollectedConstantType.Function then
			local childFunctionBytecodeReader = self:GetFunction (lastUnallocatedFunction)
			garbageCollectedConstant:SetFunction (childFunctionBytecodeReader)
			lastUnallocatedFunction = lastUnallocatedFunction - 1
			if childFunctionBytecodeReader then
				lastUnallocatedFunction = self:LinkFunctions (lastUnallocatedFunction, childFunctionBytecodeReader)
			end
		end
	end
	
	return lastUnallocatedFunction
end