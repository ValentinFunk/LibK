local self = {}
GLib.Lua.FunctionBytecodeReader = GLib.MakeConstructor (self)

function self:ctor (bytecodeReader, functionDump)
	self.BytecodeReader = bytecodeReader
	
	-- Input
	self.Dump = functionDump
	
	-- ToString
	self.String = nil
	
	self.PrototypeFlags = 0
	
	-- Variables
	-- Frame
	self.FrameSize      = 0
	self.FrameVariables = {}
	self.VariadicFrameVariable = GLib.Lua.FrameVariable (self, "...")
	self.VariadicFrameVariable:SetName ("...")
	
	-- Parameters
	self.ParameterCount = 0
	self.Variadic       = false
	
	-- Upvalues
	self.UpvalueCount = 0
	self.UpvalueData  = {}
	self.UpvalueNames = {}
	
	-- Constants
	-- Garbage Collected Constants
	self.GarbageCollectedConstantCount = 0
	self.GarbageCollectedConstants     = {}
	
	-- Numeric Constants
	self.NumericConstantCount = 0
	self.NumericConstants     = {}
	
	-- Instructions
	self.InstructionCount     = 0
	self.InstructionOpcodes   = {}
	self.InstructionOperandAs = {}
	self.InstructionOperandBs = {}
	self.InstructionOperandCs = {}
	self.InstructionLines     = {}
	self.InstructionTags      = {}
	
	-- Debugging
	self.StartLine = 0
	self.LineCount = 0
	self.EndLine   = 0
	
	self.DebugDataLength   = 0
	self.DebugData         = nil
	self.ResidualDebugData = nil
	
	-- Read
	local reader = GLib.StringInBuffer (functionDump)
	
	-- Parameters
	self.PrototypeFlags = reader:UInt8 ()
	self.Variadic = bit.band (self.PrototypeFlags, 2) ~= 0
	
	self.ParameterCount = reader:UInt8 ()
	
	-- Variables
	self.FrameSize    = reader:UInt8 ()
	self.UpvalueCount = reader:UInt8 ()
	
	for i = 1, self.FrameSize do
		local frameVariable = GLib.Lua.FrameVariable (self, i)
		self.FrameVariables [i] = frameVariable
	end
	
	-- Constant Counts
	self.GarbageCollectedConstantCount = reader:ULEB128 ()
	self.NumericConstantCount          = reader:ULEB128 ()
	self.InstructionCount              = reader:ULEB128 ()
	
	if not self.BytecodeReader:IsDebugInformationStripped () then
		self.DebugDataLength = reader:ULEB128 ()
		
		self.StartLine = reader:ULEB128 ()
		self.LineCount = reader:ULEB128 ()
		self.EndLine = self.StartLine + self.LineCount
	end
	
	-- Instructions
	for i = 1, self.InstructionCount do
		self.InstructionOpcodes   [#self.InstructionOpcodes + 1] = reader:UInt8 ()
		self.InstructionOperandAs [#self.InstructionOperandAs + 1] = reader:UInt8 ()
		self.InstructionOperandCs [#self.InstructionOperandCs + 1] = reader:UInt8 ()
		self.InstructionOperandBs [#self.InstructionOperandBs + 1] = reader:UInt8 ()
	end
	
	-- Upvalues
	for i = 1, self.UpvalueCount do
		self.UpvalueData [i] = reader:UInt16 ()
	end
	
	-- Garbage collected constants
	for i = 1, self.GarbageCollectedConstantCount do
		local constant = nil
		local constantType = reader:ULEB128 ()
		if constantType == GLib.Lua.GarbageCollectedConstantType.Function then
			-- Function
			constant = GLib.Lua.FunctionConstant ()
		elseif constantType == GLib.Lua.GarbageCollectedConstantType.Table then
			-- Table
			constant = GLib.Lua.TableConstant ()
		elseif constantType == GLib.Lua.GarbageCollectedConstantType.Int64 then
			-- Int64
			constant = GLib.Lua.GarbageCollectedConstant ()
			constant:SetType (constantType)
			GLib.Error ("Unhandled garbage collected constant type (int64)")
		elseif constantType == GLib.Lua.GarbageCollectedConstantType.UInt64 then
			-- UInt64
			constant = GLib.Lua.GarbageCollectedConstant ()
			constant:SetType (constantType)
			GLib.Error ("Unhandled garbage collected constant type (uint64)")
		elseif constantType == GLib.Lua.GarbageCollectedConstantType.Complex then
			-- Complex
			constant = GLib.Lua.GarbageCollectedConstant ()
			constant:SetType (constantType)
			GLib.Error ("Unhandled garbage collected constant type (complex)")
		elseif constantType >= GLib.Lua.GarbageCollectedConstantType.String then
			constant = GLib.Lua.StringConstant ()
		end
		constant:SetIndex (i)
		constant:Deserialize (constantType, reader)
		self.GarbageCollectedConstants [i] = constant
	end
	
	-- Numeric constants
	for i = 1, self.NumericConstantCount do
		local constant = {}
		self.NumericConstants [i] = constant
		
		local low32 = reader:ULEB128 ()
		local high32 = 0
		
		if (low32 % 2) == 1 then
			high32 = reader:ULEB128 ()
			low32 = math.floor (low32 / 2)
			constant.Value = GLib.BitConverter.UInt32sToDouble (low32, high32)
		else
			low32 = math.floor (low32 / 2)
			constant.Value = low32
		end
		
		constant.High = string.format ("0x%08x", high32)
		constant.Low = string.format ("0x%08x", low32)
	end
	
	-- Debugging data
	if not self.BytecodeReader:IsDebugInformationStripped () then
		self.DebugData = reader:Bytes (self.DebugDataLength)
		
		local debugReader = GLib.StringInBuffer (self.DebugData)
		if self.LineCount < 256 then
			for i = 1, self.InstructionCount do
				self.InstructionLines [i] = debugReader:UInt8 ()
			end
		elseif self.LineCount < 65536 then
			for i = 1, self.InstructionCount do
				self.InstructionLines [i] = debugReader:UInt16 ()
			end
		else
			for i = 1, self.InstructionCount do
				self.InstructionLines [i] = debugReader:UInt32 ()
			end
		end
		
		-- Upvalues
		for i = 1, self.UpvalueCount do
			self.UpvalueNames [i] = debugReader:StringZ ()
			if self.UpvalueNames [i] == "" or not GLib.Lua.IsValidVariableName (self.UpvalueNames [i]) then
				self.UpvalueNames [i] = nil
			end
		end
		
		-- Frame Variables
		for i = 1, self.FrameSize do
			local frameVariable = self.FrameVariables [i]
			frameVariable:SetName (debugReader:StringZ ())
			frameVariable:SetStartInstruction (debugReader:ULEB128 ())
			frameVariable:SetEndInstruction   (debugReader:ULEB128 ())
		end
		
		self.DebugResidualData = debugReader:Bytes (1024)
	end
	self.Rest = reader:Bytes (1024)
end

function self:GetBytecodeReader ()
	return self.BytecodeReader
end

-- Constants
-- Garbage Collected Constants
function self:GetGarbageCollectedConstant (i)
	return self.GarbageCollectedConstants [i]
end

function self:GetGarbageCollectedConstantCount ()
	return self.GarbageCollectedConstantCount
end

function self:GetGarbageCollectedConstantEnumerator ()
	return GLib.ArrayEnumerator (self.GarbageCollectedConstants)
end

function self:GetGarbageCollectedConstantValue (constantId)
	local constant = self.GarbageCollectedConstants [constantId]
	if not constant then return nil end
	return constant:GetValue ()
end

-- Numeric Constants
function self:GetNumericConstantCount ()
	return self.NumericConstantCount
end

function self:GetNumericConstantValue (constantId)
	local constant = self.NumericConstants [constantId]
	if not constant then return nil end
	return constant.Value
end

-- Instructions
function self:GetInstruction (instructionId, instruction)
	instruction = instruction or GLib.Lua.Instruction (self)
	
	instruction:SetIndex (instructionId)
	instruction:SetOpcode (self.InstructionOpcodes [instructionId])
	instruction:SetOperandA (self.InstructionOperandAs [instructionId])
	instruction:SetOperandB (self.InstructionOperandBs [instructionId])
	instruction:SetOperandC (self.InstructionOperandCs [instructionId])
	instruction:SetLine (self.InstructionLines [instructionId])
	
	return instruction
end

function self:GetInstructionCount ()
	return self.InstructionCount
end

function self:GetInstructionCount ()
	return #self.Instructions
end

function self:GetInstructionEnumerator ()
	local i = 0
	local instruction = GLib.Lua.Instruction (self)
	return function ()
		i = i + 1
		
		if i > self.InstructionCount then return nil end
		
		instruction = self:GetInstruction (i, instruction)
		
		return instruction
	end
end

function self:GetInstructionTag (instructionId, tagId)
	if not self.InstructionTags [tagId] then return nil end
	return self.InstructionTags [tagId] [instructionId]
end

function self:SetInstructionTag (instructionId, tagId, data)
	self.InstructionTags [tagId] = self.InstructionTags [tagId] or {}
	self.InstructionTags [tagId] [instructionId] = data
end

-- Variables
-- Frame
function self:GetFrameSize ()
	return self.FrameSize
end

function self:GetFrameVariable (id)
	if id == "..." then
		return self.VariadicFrameVariable
	end
	return self.FrameVariables [id]
end

function self:GetFrameVariableEnumerator ()
	return GLib.ArrayEnumerator (self.FrameVariables)
end

function self:GetFrameVariableName (id)
	local frameVariable = self:GetFrameVariable (id)
	if not frameVariable then return nil end
	return frameVariable:GetName ()
end

-- Parameters
function self:GetParameter (id, frameVariable)
	return self:GetFrameVariable (id, frameVariable)
end

function self:GetParameterCount ()
	return self.ParameterCount
end

function self:GetParameterName (id)
	return self:GetFrameVariableName (id)
end

function self:IsVariadic ()
	return self.Variadic
end

-- Upvalues
function self:GetUpvalueCount ()
	return self.UpvalueCount
end

function self:GetUpvalueName (upvalueId)
	return self.UpvalueNames [upvalueId]
end

-- String
function self:InvalidateString ()
	self.String = nil
end

function self:ToString ()
	if self.String then return self.String end
	
	if not self.Decompiled then
		self:Decompile ()
	end
	
	local str = GLib.StringBuilder ()
	
	str:Append ("function (")
	local parameterVariable = GLib.Lua.FrameVariable (self)
	for i = 1, self:GetParameterCount () do
		if i > 1 then
			str:Append (", ")
		end
		
		parameterVariable = self:GetParameter (i, parameterVariable)
		str:Append (parameterVariable:GetNameOrFallbackName ())
	end
	
	if self:IsVariadic () then
		if self:GetParameterCount () > 0 then
			str:Append (", ")
		end
		str:Append ("...")
	end
	
	str:Append (")\n")
	
	
	local instruction = GLib.Lua.Instruction (self)
	
	local lastLine = 0
	local lastIndentationLevel = 0
	local indentation = "\t"
	local newlineAndIndentation = "\n\t"
	for i = 1, self.InstructionCount do
		instruction = self:GetInstruction (i, instruction)
		
		local instructionVisible = true
		if instruction:GetTag ("Lua") and instruction:GetTag ("Lua") == "" then
			instructionVisible = false
		end
		
		-- End of blocks
		local indentationLevel = instruction:GetTag ("Indentation")
		if indentationLevel < lastIndentationLevel then
			for i = lastIndentationLevel - 1, indentationLevel, -1 do
				str:Append (string.rep ("\t", 1 + i))
				str:Append ("end\n")
			end
		end
		if lastIndentationLevel ~= indentationLevel then
			lastIndentationLevel = indentationLevel
			indentation = string.rep ("\t", 1 + lastIndentationLevel)
			newlineAndIndentation = "\n" .. indentation
		end
		
		-- Newlines
		if lastLine and instruction:GetLine () and instruction:GetLine () - lastLine >= 2 then
			str:Append (indentation)
			str:Append ("\n")
		end
		lastLine = instruction:GetLine ()
		
		-- Instruction
		if instruction:GetTag ("Lua") then
			if instruction:GetTag ("Lua") ~= "" then
				str:Append (indentation)
				str:Append (instruction:GetTag ("Lua"):gsub ("\n", newlineAndIndentation))
				if instruction:GetTag ("Comment") then
					str:Append ("\t// ")
					str:Append (instruction:GetTag ("Comment"))
				end
				str:Append ("\n")
			else
				-- Debugging
				-- str:Append ("\t\t\t")
				-- str:Append (instruction:ToString ())
				-- if instruction:GetTag ("Comment") then
				-- 	str:Append ("\t// ")
				-- 	str:Append (instruction:GetTag ("Comment"))
				-- end
				-- str:Append ("\n")
			end
		else
			str:Append (indentation)
			str:Append (instruction:ToString ())
			if instruction:GetTag ("Comment") then
				str:Append ("\t// ")
				str:Append (instruction:GetTag ("Comment"))
			end
			str:Append ("\n")
		end
	end
	
	str:Append ("end")
	
	self.String = str:ToString ()
	
	return self.String
end

self.__tostring = self.ToString

-- Internal, do not call
function self:Decompile ()
	if self.Decompiled then return end
	self.Decompile = true
	
	self:AnalyseJumps ()
	self:GenerateIndentation ()
	
	self:DecompilePass1 ()
	self:DecompilePass2 ()
	self:DecompilePass3 ()
end

function self:AnalyseJumps ()
	local targetInstruction = GLib.Lua.Instruction (self)
	
	self.JumpSources = {}
	self.DestinationForwardJumpCount = {}
	self.DestinationBackwardJumpCount = {}
	
	for instruction in self:GetInstructionEnumerator () do
		local opcode = instruction:GetOpcode ()
		local opcodeName = instruction:GetOpcodeName ()
		
		if opcode == GLib.Lua.Opcode.JMP then
			local jump = instruction:GetOperandDValue ()
			local destinationInstructionId = instruction:GetIndex () + 1 + jump
			local destinationInstruction = self:GetInstruction (destinationInstructionId)
			self.JumpSources [instruction:GetIndex ()] = destinationInstructionId
			if jump > 0 then
				self.DestinationForwardJumpCount [destinationInstructionId] = self.DestinationForwardJumpCount [destinationInstructionId] or 0
				self.DestinationForwardJumpCount [destinationInstructionId] = self.DestinationForwardJumpCount [destinationInstructionId] + 1
			else
				self.DestinationBackwardJumpCount [destinationInstructionId] = self.DestinationBackwardJumpCount [destinationInstructionId] or 0
				self.DestinationBackwardJumpCount [destinationInstructionId] = self.DestinationBackwardJumpCount [destinationInstructionId] + 1
			end
		end
	end
end

function self:GenerateIndentation ()
	local indentation = 0
	for instruction in self:GetInstructionEnumerator () do
		local instructionId = instruction:GetIndex ()
		
		if self.DestinationForwardJumpCount [instructionId] then
			indentation = indentation - self.DestinationForwardJumpCount [instructionId]
		elseif self.DestinationBackwardJumpCount [instruction:GetIndex ()] then
			indentation = indentation + self.DestinationBackwardJumpCount [instructionId]
		end
		
		instruction:SetTag ("Indentation", indentation)
		
		if self.JumpSources [instructionId] then
			local destinationInstructionId = self.JumpSources [instructionId]
			if destinationInstructionId > instructionId then
				indentation = indentation + 1
			else
				indentation = indentation - 1
			end
		end
	end
end

function self:DecompilePass1 ()
	local variable
	local destinationVariable
	local assignmentExpression
	local assignmentExpressionPrecedence
	local assignmentExpressionRawValue
	
	for instruction in self:GetInstructionEnumerator () do
		local opcode = instruction:GetOpcode ()
		local opcodeName = instruction:GetOpcodeName ()
		assignmentExpression = nil
		assignmentExpressionPrecedence = GLib.Lua.Precedence.Lowest
		assignmentExpressionRawValue = nil
		destinationVariable = nil
		
		if instruction:GetOperandAType () == GLib.Lua.OperandType.DestinationVariable then
			destinationVariable = self:GetFrameVariable (instruction:GetOperandA () + 1)
		end
		
		-- Constant loads
		if opcodeName == "KSTR" then
			local constant = self:GetGarbageCollectedConstant (self:GetGarbageCollectedConstantCount () - instruction:GetOperandD ())
			assignmentExpressionRawValue = constant:GetValue ()
			assignmentExpression = constant:GetLuaString ()
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "KSHORT" then
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "KNUM" then
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "KPRI" then
			assignmentExpressionRawValue = instruction:GetOperandDValue ()
			assignmentExpression = tostring (assignmentExpressionRawValue)
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "KNIL" then
			for i = instruction:GetOperandA (), instruction:GetOperandD () do
				destinationVariable = self:GetFrameVariable (i + 1)
				destinationVariable:AddStore (instruction:GetIndex (), "nil", GLib.Lua.Precedence.Atom, nil)
			end
			
			destinationVariable = nil -- Don't add another store at the end of the loop
		end
		
		-- Upvalue and function operations
		if opcodeName == "UGET" then
			assignmentExpression = self:GetUpvalueName (instruction:GetOperandD () + 1) or ("_up" .. tostring (instruction:GetOperandD ()))
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "FNEW" then
			local constant = self:GetGarbageCollectedConstant (self:GetGarbageCollectedConstantCount () - instruction:GetOperandD ())
			assignmentExpression = constant:GetLuaString ()
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		end
		
		-- Tables
		if opcodeName == "TNEW" then
			assignmentExpression = "{}"
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "TDUP" then
			local constant = self:GetGarbageCollectedConstant (self:GetGarbageCollectedConstantCount () - instruction:GetOperandD ())
			assignmentExpression = constant:GetLuaString ()
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		elseif opcodeName == "GGET" then
			assignmentExpression = instruction:GetOperandDValue ()
			assignmentExpressionPrecedence = GLib.Lua.Precedence.Atom
		end
		
		-- Calls
		if opcodeName == "CALLM" then
			-- Function
			variable = self:GetFrameVariable (instruction:GetOperandA () + 1)
			variable:AddLoad (instruction:GetIndex ())
			
			-- Parameters
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () do
				variable = self:GetFrameVariable (i + 1)
				variable:AddLoad (instruction:GetIndex ())
			end
			self.VariadicFrameVariable:AddLoad (instruction:GetIndex ())
			
			-- Return values
			local returnCount = instruction:GetOperandB () - 1
			if returnCount > 0 then
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					destinationVariable = self:GetFrameVariable (i + 1)
					destinationVariable:AddStore (instruction:GetIndex ())
				end
				destinationVariable = nil
			elseif returnCount == -1 then
				self.VariadicFrameVariable:AddStore (instruction:GetIndex ())
			end
		elseif opcodeName == "CALL" then
			-- Function
			variable = self:GetFrameVariable (instruction:GetOperandA () + 1)
			variable:AddLoad (instruction:GetIndex ())
			
			-- Parameters
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () - 1 do
				variable = self:GetFrameVariable (i + 1)
				variable:AddLoad (instruction:GetIndex ())
			end
			
			-- Return values
			local returnCount = instruction:GetOperandB () - 1
			if returnCount > 0 then
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					destinationVariable = self:GetFrameVariable (i + 1)
					destinationVariable:AddStore (instruction:GetIndex ())
				end
				destinationVariable = nil
			elseif returnCount == -1 then
				self.VariadicFrameVariable:AddStore (instruction:GetIndex ())
			end
		end
		
		-- Binary operators
		if opcodeName == "CAT" then
			for i = instruction:GetOperandB (), instruction:GetOperandC () do
				variable = self:GetFrameVariable (i + 1)
				variable:AddLoad (instruction:GetIndex ())
			end
		end
		
		-- Returns
		if opcodeName == "RET" then
			for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandD () - 2 do
				variable = self:GetFrameVariable (i + 1)
				variable:AddLoad (instruction:GetIndex ())
			end
		elseif opcodeName == "RET1" then
			variable = self:GetFrameVariable (instruction:GetOperandA () + 1)
			variable:AddLoad (instruction:GetIndex ())
		end
		
		-- Generic loads
		if instruction:GetOperandAType () == GLib.Lua.OperandType.Variable then
			variable = self:GetFrameVariable (instruction:GetOperandA () + 1)
			variable:AddLoad (instruction:GetIndex ())
		end
		if instruction:GetOperandBType () == GLib.Lua.OperandType.Variable then
			variable = self:GetFrameVariable (instruction:GetOperandB () + 1)
			variable:AddLoad (instruction:GetIndex ())
		end
		if instruction:GetOperandCType () == GLib.Lua.OperandType.Variable then
			variable = self:GetFrameVariable (instruction:GetOperandC () + 1)
			variable:AddLoad (instruction:GetIndex ())
		end
		if instruction:GetOperandDType () == GLib.Lua.OperandType.Variable then
			variable = self:GetFrameVariable (instruction:GetOperandD () + 1)
			variable:AddLoad (instruction:GetIndex ())
		end
		
		if destinationVariable then
			local storeId = destinationVariable:AddStore (instruction:GetIndex (), assignmentExpression, assignmentExpressionPrecedence, assignmentExpressionRawValue)
			instruction:SetStoreVariable (destinationVariable)
			instruction:SetStoreId (storeId)
		end
	end
end

function self:DecompilePass2 ()
	for frameVariable in self:GetFrameVariableEnumerator () do
		self:AnalyseFrameVariableUsage (frameVariable)
	end
	self:AnalyseFrameVariableUsage (self.VariadicFrameVariable)
end

function self:AnalyseFrameVariableUsage (frameVariable)
	local loadStore = GLib.Lua.LoadStore (frameVariable)
	local store = nil
	
	loadStore = loadStore:GetNext ()
	
	local loadCount = 0
	while loadStore do
		if loadStore:IsStore () then
			-- Commit last store data
			if store then
				store:SetLoadCount (loadCount)
				if loadCount == 1 then
					store:SetExpressionInlineable (true)
				end
			end
			
			-- Reset data for new store
			store = loadStore:Clone (store or GLib.Lua.LoadStore (frameVariable))
			loadCount = 0
		else
			loadCount = loadCount + 1
			if store then
				loadStore:SetLastStore (store:GetIndex ())
			end
		end
		
		loadStore = loadStore:GetNext ()
	end
	
	-- Commit last store data
	if store then
		store:SetLoadCount (loadCount)
		if loadCount == 1 then
			store:SetExpressionInlineable (true)
		end
	end
end

local function GetNextLoad (loadCache, frameVariable, instructionId)
	local frameVariableId = frameVariable:GetIndex ()
	local loadStore = loadCache [frameVariableId]
	loadStore = loadStore or GLib.Lua.LoadStore (frameVariable)
	loadCache [loadStore] = loadStore
	
	loadStore = loadStore:GetNextLoad ()
	while loadStore do
		loadCache [frameVariableId] = loadStore
		if loadStore:GetInstructionId () == instructionId then
			return loadStore
		end
		
		loadStore = loadStore:GetNextLoad ()
	end
	
	return nil
end

local function GetNextStore (storeCache, frameVariable, instructionId)
	local frameVariableId = frameVariable:GetIndex ()
	local loadStore = storeCache [frameVariableId]
	loadStore = loadStore or GLib.Lua.LoadStore (frameVariable)
	storeCache [loadStore] = loadStore
	
	loadStore = loadStore:GetNextStore ()
	while loadStore do
		storeCache [frameVariableId] = loadStore
		if loadStore:GetInstructionId () == instructionId then
			return loadStore
		end
		
		loadStore = loadStore:GetNextStore ()
	end
	
	return nil
end

local conditionalOpcodes =
{
	[GLib.Lua.Opcode.ISLT]  = ">=",
	[GLib.Lua.Opcode.ISGE]  = "<",
	[GLib.Lua.Opcode.ISLE]  = ">",
	[GLib.Lua.Opcode.ISGT]  = "<=",
	[GLib.Lua.Opcode.ISEQV] = "~=",
	[GLib.Lua.Opcode.ISNEV] = "==",
	[GLib.Lua.Opcode.ISEQS] = "~=",
	[GLib.Lua.Opcode.ISNES] = "==",
	[GLib.Lua.Opcode.ISEQN] = "~=",
	[GLib.Lua.Opcode.ISNEN] = "==",
	[GLib.Lua.Opcode.ISEQP] = "~=",
	[GLib.Lua.Opcode.ISNEP] = "==",
}

local binaryOpcodes =
{
	[GLib.Lua.Opcode.ADDVN] = "+",
	[GLib.Lua.Opcode.SUBVN] = "-",
	[GLib.Lua.Opcode.MULVN] = "*",
	[GLib.Lua.Opcode.DIVVN] = "/",
	[GLib.Lua.Opcode.MODVN] = "%",
	[GLib.Lua.Opcode.ADDNV] = "+",
	[GLib.Lua.Opcode.SUBNV] = "-",
	[GLib.Lua.Opcode.MULNV] = "*",
	[GLib.Lua.Opcode.DIVNV] = "/",
	[GLib.Lua.Opcode.MODNV] = "%",
	[GLib.Lua.Opcode.ADDVV] = "+",
	[GLib.Lua.Opcode.SUBVV] = "-",
	[GLib.Lua.Opcode.MULVV] = "*",
	[GLib.Lua.Opcode.DIVVV] = "/",
	[GLib.Lua.Opcode.MODVV] = "%"
}

local binaryOpcodePrecedences =
{
	[GLib.Lua.Opcode.ADDVN] = GLib.Lua.Precedence.Addition,
	[GLib.Lua.Opcode.SUBVN] = GLib.Lua.Precedence.Subtraction,
	[GLib.Lua.Opcode.MULVN] = GLib.Lua.Precedence.Multiplication,
	[GLib.Lua.Opcode.DIVVN] = GLib.Lua.Precedence.Division,
	[GLib.Lua.Opcode.MODVN] = GLib.Lua.Precedence.Modulo,
	[GLib.Lua.Opcode.ADDNV] = GLib.Lua.Precedence.Addition,
	[GLib.Lua.Opcode.SUBNV] = GLib.Lua.Precedence.Subtraction,
	[GLib.Lua.Opcode.MULNV] = GLib.Lua.Precedence.Multiplication,
	[GLib.Lua.Opcode.DIVNV] = GLib.Lua.Precedence.Division,
	[GLib.Lua.Opcode.MODNV] = GLib.Lua.Precedence.Modulo,
	[GLib.Lua.Opcode.ADDVV] = GLib.Lua.Precedence.Addition,
	[GLib.Lua.Opcode.SUBVV] = GLib.Lua.Precedence.Subtraction,
	[GLib.Lua.Opcode.MULVV] = GLib.Lua.Precedence.Multiplication,
	[GLib.Lua.Opcode.DIVVV] = GLib.Lua.Precedence.Division,
	[GLib.Lua.Opcode.MODVV] = GLib.Lua.Precedence.Modulo
}

function self:DecompilePass3 ()
	local loadCache = {}
	local storeCache = {}
	
	local variable
	local aVariable
	local bVariable
	local cVariable
	local dVariable
	
	local loadStore = GLib.Lua.LoadStore ()
	
	local lastInstructionOpcode
	local lastInstructionOpcodeName
	
	for instruction in self:GetInstructionEnumerator () do
		local opcode = instruction:GetOpcode ()
		local opcodeName = instruction:GetOpcodeName ()
		
		local destinationVariable
		local destinationVariableName
		local isAssignment = false
		local firstAssignment = false
		local assignmentExpression
		local assignmentExpressionPrecedence
		local assignmentExpressionIndexable = false
		local assignmentInlineable = false
		local load = nil
		local store = nil
		
		aVariable = self:GetFrameVariable (instruction:GetOperandA () + 1)
		bVariable = self:GetFrameVariable (instruction:GetOperandB () + 1)
		cVariable = self:GetFrameVariable (instruction:GetOperandC () + 1)
		dVariable = self:GetFrameVariable (instruction:GetOperandD () + 1)
		
		if instruction:GetOperandAType () == GLib.Lua.OperandType.DestinationVariable then
			destinationVariable = aVariable
			
			-- Set store LoadStore
			store = GetNextStore (storeCache, destinationVariable, instruction:GetIndex ())
			assignmentExpressionRawValue = store:GetExpressionRawValue ()
			assignmentExpression = store:GetExpression ()
		end
		
		-- Loads
		if opcodeName == "KSTR" or
		   opcodeName == "KSHORT" or
		   opcodeName == "KNUM" or
		   opcodeName == "KPRI" then
			isAssignment = true
		elseif opcodeName == "KNIL" then
			assignmentExpression = "nil"
			local lua = ""
			local first = true
			for i = instruction:GetOperandA (), instruction:GetOperandD () do
				if first then
					first = false
				else
					lua = lua .. "\n"
				end
				
				variable = self:GetFrameVariable (i + 1)
				firstAssignment = firstAssignment or variable:SetAssigned (instruction:GetIndex ())
				lua = lua .. (firstAssignment and "local " or "") .. variable:GetNameOrFallbackName () .. " = " .. assignmentExpression
				variable:SetExpression ("nil", false, nil)
			end
			instruction:SetTag ("Lua", lua)
		end
		
		-- Upvalue and function operations
		if opcodeName == "UGET" then
			isAssignment = true
		elseif opcodeName == "FNEW" then
			isAssignment = true
		end
		
		-- Tables
		if opcodeName == "TNEW" or
		   opcodeName == "TDUP" or
		   opcodeName == "GGET" then
			isAssignment = true
		elseif opcodeName == "GSET" then
			isAssignment = true
			destinationVariableName = instruction:GetOperandDValue ()
			
			load = GetNextLoad (loadCache, aVariable, instruction:GetIndex ())
			assignmentExpression = load:GetExpression ()
		elseif opcodeName == "TGETV" or
		       opcodeName == "TGETS" or
			   opcodeName == "TGETB" then
			isAssignment = true
			
			-- varA = varB [varC]
			local bExpression = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			bExpression = bExpression:GetExpression ()
			
			local squareBrackets = true
			if instruction:GetOperandCType () == GLib.Lua.OperandType.Variable then
				load = GetNextLoad (loadCache, cVariable, instruction:GetIndex ())
				cValue = load:GetExpressionRawValue ()
				if not cValue then
					cExpression = load:GetExpression ()
				end
			else
				cValue = instruction:GetOperandCValue ()
			end
			
			if cValue then
				if type (cValue) == "string" then
					if GLib.Lua.IsValidVariableName (cValue) then
						cExpression = cValue
						squareBrackets = false
					else
						cExpression = "\"" .. GLib.String.EscapeNonprintable (cValue) .. "\""
					end
				else
					cExpression = tostring (cValue)
				end
			end
			
			if squareBrackets then
				assignmentExpression = bExpression .. " [" .. cExpression .. "]"
			else
				assignmentExpression = bExpression .. "." .. cExpression
			end
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
		elseif opcodeName == "TSETV" or
		       opcodeName == "TSETS" or
			   opcodeName == "TSETB" then
			load = GetNextLoad (loadCache, aVariable, instruction:GetIndex ())
			local aExpression = load:GetExpression ()
			
			-- varB [varC] = varA
			local bExpression = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
			bExpression = bExpression:GetExpression ()
			
			local squareBrackets = true
			if instruction:GetOperandCType () == GLib.Lua.OperandType.Variable then
				load = GetNextLoad (loadCache, cVariable, instruction:GetIndex ())
				cValue = load:GetExpressionRawValue ()
				if not cValue then
					cExpression = load:GetExpression ()
				end
			else
				cValue = instruction:GetOperandCValue ()
			end
			
			if cValue then
				if type (cValue) == "string" then
					if GLib.Lua.IsValidVariableName (cValue) then
						cExpression = cValue
						squareBrackets = false
					else
						cExpression = "\"" .. GLib.String.EscapeNonprintable (cValue) .. "\""
					end
				else
					cExpression = tostring (cValue)
				end
			end
			
			local lua
			if squareBrackets then
				lua = bExpression .. " [" .. cExpression .. "]"
			else
				lua = bExpression .. "." .. cExpression
			end
			lua = lua .. " = " .. aExpression
			instruction:SetTag ("Lua", lua)
		end
		
		-- Calls
		if opcodeName == "CALLM" then
			local returnCount = instruction:GetOperandB () - 1
			
			load = GetNextLoad (loadCache, aVariable, instruction:GetIndex ())
			assignmentExpression = load:GetExpression () .. " ("
			
			-- Parameters
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () do
				variable = self:GetFrameVariable (i + 1)
				load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
				
				assignmentExpression = assignmentExpression .. load:GetExpression () .. ", "
			end
			variable = self.VariadicFrameVariable
			load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
			assignmentExpression = assignmentExpression .. load:GetExpression ()
			assignmentExpression = assignmentExpression .. ")"
			
			-- Return values
			if returnCount == 0 then
				instruction:SetTag ("Lua", assignmentExpression)
			elseif returnCount == -1 then
				isAssignment = true
				
				-- Set store LoadStore
				destinationVariable = self.VariadicFrameVariable
				store = GetNextStore (storeCache, destinationVariable, instruction:GetIndex ())
				store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
				
				instruction:SetTag ("Lua", "... = " .. assignmentExpression)
			else
				local destinationVariableNames = ""
				local first = true
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					if not first then
						destinationVariableNames = destinationVariableNames ..  ", "
					end
					first = false
					
					variable = self:GetFrameVariable (i + 1)
					if returnCount ~= 1 then
						firstAssignment = firstAssignment or variable:SetAssigned (instruction:GetIndex ())
					end
					destinationVariableNames = destinationVariableNames .. variable:GetNameOrFallbackName ()
				end
				
				if returnCount == 1 then
					isAssignment = true
					
					-- Set store LoadStore
					destinationVariable = self:GetFrameVariable (instruction:GetOperandA () + 1)
					store = GetNextStore (storeCache, variable, instruction:GetIndex ())
					store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
					
					if not store:IsExpressionInlineable () then
						firstAssignment = firstAssignment or destinationVariable:SetAssigned (instruction:GetIndex ())
					end
				else
					instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableNames .. " = " .. assignmentExpression)
				end
			end
		elseif opcodeName == "CALL" then
			local returnCount = instruction:GetOperandB () - 1
			
			load = GetNextLoad (loadCache, aVariable, instruction:GetIndex ())
			assignmentExpression = load:GetExpression () .. " ("
			
			-- Parameters
			local first = true
			for i = instruction:GetOperandA () + 1, instruction:GetOperandA () + instruction:GetOperandC () - 1 do
				if not first then
					assignmentExpression = assignmentExpression .. ", "
				end
				first = false
				
				variable = self:GetFrameVariable (i + 1)
				load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
				
				assignmentExpression = assignmentExpression .. load:GetExpression ()
			end
			assignmentExpression = assignmentExpression .. ")"
			
			-- Return values
			if returnCount == 0 then
				instruction:SetTag ("Lua", assignmentExpression)
			elseif returnCount == -1 then
				isAssignment = true
				
				-- Set store LoadStore
				destinationVariable = self.VariadicFrameVariable
				store = GetNextStore (storeCache, destinationVariable, instruction:GetIndex ())
				store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
			else
				local destinationVariableNames = ""
				local first = true
				for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandB () - 2 do
					if not first then
						destinationVariableNames = destinationVariableNames ..  ", "
					end
					first = false
					
					variable = self:GetFrameVariable (i + 1)
					if returnCount ~= 1 then
						firstAssignment = firstAssignment or variable:SetAssigned (instruction:GetIndex ())
					end
					destinationVariableNames = destinationVariableNames .. variable:GetNameOrFallbackName ()
				end
				
				if returnCount == 1 then
					isAssignment = true
					
					-- Set store LoadStore
					destinationVariable = self:GetFrameVariable (instruction:GetOperandA () + 1)
					store = GetNextStore (storeCache, variable, instruction:GetIndex ())
					store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Atom)
					
					if not store:IsExpressionInlineable () then
						firstAssignment = firstAssignment or destinationVariable:SetAssigned (instruction:GetIndex ())
					end
				else
					instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableNames .. " = " .. assignmentExpression)
				end
			end
		end
		
		-- Comparison operators
		if conditionalOpcodes [opcode] then
			local operator = conditionalOpcodes [opcode]
			
			local aExpression
			local dExpression
			
			if instruction:GetOperandAType () == GLib.Lua.OperandType.Variable then
				load = GetNextLoad (loadCache, aVariable, instruction:GetIndex ())
				aExpression = load:GetBracketedExpression (GLib.Lua.Precedence.Lowest)
			elseif instruction:GetOperandAType () == GLib.Lua.OperandType.StringConstantId then
				aExpression = "\"" .. GLib.String.EscapeNonprintable (instruction:GetOperandAValue ()) .. "\""
			else
				aExpression = tostring (instruction:GetOperandAValue ())
			end
			
			if instruction:GetOperandDType () == GLib.Lua.OperandType.Variable then
				load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
				dExpression = load:GetBracketedExpression (GLib.Lua.Precedence.Lowest)
			elseif instruction:GetOperandDType () == GLib.Lua.OperandType.StringConstantId then
				dExpression = "\"" .. GLib.String.EscapeNonprintable (instruction:GetOperandDValue ()) .. "\""
			else
				dExpression = tostring (instruction:GetOperandDValue ())
			end
			
			instruction:SetTag ("Lua", "if " .. aExpression .. " " .. operator .. " " .. dExpression .. " then")
		end
		
		-- Unary testing operators
		if opcodeName == "IST" then
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			instruction:SetTag ("Lua", "if not " .. load:GetBracketedExpression (GLib.Lua.Precedence.LeftUnaryOperator) .. " then")
		elseif opcodeName == "ISF" then
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			instruction:SetTag ("Lua", "if " .. load:GetExpression () .. " then")
		end
		
		-- Unary operations
		if opcodeName == "MOV" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			assignmentExpression, assignmentExpressionPrecedence = load:GetExpression ()
			store:SetExpression (assignmentExpression, assignmentExpressionPrecedence)
		elseif opcodeName == "NOT" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			assignmentExpression = "not " .. load:GetBracketedExpression (GLib.Lua.Precedence.LeftUnaryOperator)
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.LeftUnaryOperator)
		elseif opcodeName == "UNM" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			assignmentExpression = "-" .. load:GetBracketedExpression (GLib.Lua.Precedence.LeftUnaryOperator)
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.LeftUnaryOperator)
		elseif opcodeName == "LEN" then
			isAssignment = true
			
			load = GetNextLoad (loadCache, dVariable, instruction:GetIndex ())
			assignmentExpression = "#" .. load:GetBracketedExpression (GLib.Lua.Precedence.LeftUnaryOperator)
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.LeftUnaryOperator)
		end
		
		-- Binary operators
		if binaryOpcodes [opcode] then
			local operator = binaryOpcodes [opcode]
			assignmentExpressionPrecedence = binaryOpcodePrecedences [opcode]
			
			local bExpression
			local cExpression
			
			if instruction:GetOperandBType () == GLib.Lua.OperandType.Variable then
				load = GetNextLoad (loadCache, bVariable, instruction:GetIndex ())
				bExpression = load:GetBracketedExpression (assignmentExpressionPrecedence)
			elseif instruction:GetOperandBType () == GLib.Lua.OperandType.StringConstantId then
				bExpression = "\"" .. GLib.String.EscapeNonprintable (instruction:GetOperandBValue ()) .. "\""
			else
				bExpression = tostring (instruction:GetOperandBValue ())
			end
			
			if instruction:GetOperandCType () == GLib.Lua.OperandType.Variable then
				load = GetNextLoad (loadCache, cVariable, instruction:GetIndex ())
				cExpression = load:GetBracketedExpression (assignmentExpressionPrecedence)
			elseif instruction:GetOperandCType () == GLib.Lua.OperandType.StringConstantId then
				cExpression = "\"" .. GLib.String.EscapeNonprintable (instruction:GetOperandCValue ()) .. "\""
			else
				cExpression = tostring (instruction:GetOperandCValue ())
			end
			
			isAssignment = true
			assignmentExpression = bExpression .. " " .. operator .. " " .. cExpression
			store:SetExpression (assignmentExpression, assignmentExpressionPrecedence)
		elseif opcodeName == "CAT" then
			isAssignment = true
			
			local first = true
			assignmentExpression = ""
			for i = instruction:GetOperandB (), instruction:GetOperandC () do
				if not first then
					assignmentExpression = assignmentExpression .. " .. "
				end
				first = false
				
				variable = self:GetFrameVariable (i + 1)
				
				load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
				
				assignmentExpression = assignmentExpression .. load:GetBracketedExpression (GLib.Lua.Precedence.Lowest)
			end
			store:SetExpression (assignmentExpression, GLib.Lua.Precedence.Lowest)
		end
		
		-- Returns
		if opcodeName == "RET" then
			local first = true
			assignmentExpression = ""
			for i = instruction:GetOperandA (), instruction:GetOperandA () + instruction:GetOperandD () - 2 do
				if not first then
					assignmentExpression = assignmentExpression .. ", "
				end
				first = false
				
				variable = self:GetFrameVariable (i + 1)
				load = GetNextLoad (loadCache, variable, instruction:GetIndex ())
				assignmentExpression = assignmentExpression .. load:GetExpression ()
			end
			instruction:SetTag ("Lua", "return " .. assignmentExpression)
		elseif opcodeName == "RET0" then
			instruction:SetTag ("Lua", "return")
		elseif opcodeName == "RET1" then
			load = GetNextLoad (loadCache, aVariable, instruction:GetIndex ())
			assignmentExpression = load:GetExpression ()
			instruction:SetTag ("Lua", "return " .. assignmentExpression)
		end
		
		-- Jumps
		if opcodeName == "JMP" then
			if conditionalOpcodes [lastInstructionOpcode] or
			   lastInstructionOpcodeName == "IST" or
			   lastInstructionOpcodeName == "ISF" then
				instruction:SetTag ("Lua", "")
			end
		end
		
		if isAssignment then
			store = store or instruction:GetStore (store)
			if store and store:IsExpressionInlineable () then
				instruction:SetTag ("Lua", "")
			else
				if destinationVariable then
					firstAssignment = firstAssignment or destinationVariable:SetAssigned (instruction:GetIndex ())
					
					-- Give unnamed variables a suitable name on their first assignment
					if firstAssignment and not destinationVariable:GetName () then
						destinationVariable:SetName ("_" .. assignmentExpression:gsub ("[^a-zA-Z0-9_]+", "_"):sub (-16))
					end
					destinationVariableName = destinationVariable:GetNameOrFallbackName ()
				end
				instruction:SetTag ("Lua", (firstAssignment and "local " or "") .. destinationVariableName .. " = " .. assignmentExpression)
			end
		end
		
		lastInstructionOpcode = opcode
		lastInstructionOpcodeName = opcodeName
	end
end