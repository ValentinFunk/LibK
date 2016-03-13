local self = {}
GLib.Lua.BytecodeReader = GLib.MakeConstructor (self)

function self:ctor (functionOrDump, authId)
	-- Input
	self.Function = nil
	self.Dump = nil
	
	-- Header
	self.Signature = nil
	self.Version   = nil
	self.Flags     = nil
	
	self.Source    = nil
	
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
	self.Signature = reader:Bytes (3)
	self.Version   = reader:UInt8 ()
	self.Flags     = reader:UInt8 ()
	
	if bit.band (self.Flags, GLib.Lua.BytecodeFlags.DebugInformationStripped) == 0 then
		self.Source = reader:Bytes (reader:ULEB128 ())
	end
	
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

function self:HasDump ()
	return self.Dump ~= nil
end

-- Header
function self:GetSignature ()
	return self.Signature
end

function self:GetVersion ()
	return self.Version
end

function self:GetFlags ()
	return self.Flags
end

function self:IsDebugInformationStripped ()
	return bit.band (self.Flags, GLib.Lua.BytecodeFlags.DebugInformationStripped) ~= 0
end

function self:GetSource ()
	return self.Source
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

function self:ToString ()
	if not self.String then
		local str = GLib.StringBuilder ()
		local source = self:GetSource ()
		if source then
			str:Append ("-- " .. GLib.String.EscapeNonprintable (source))
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