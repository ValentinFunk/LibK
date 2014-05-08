local self = {}
GLib.Lua.Instruction = GLib.MakeConstructor (self)

function self:ctor (bytecodeReader)
	self.BytecodeReader = bytecodeReader
	self.Index = 1
	
	self.Line = nil
	
	self.Opcode = nil
	self.OpcodeName = nil
	self.OpcodeInfo = nil
	
	self.OperandA = 0
	self.OperandB = 0
	self.OperandC = 0
	self.OperandD = 0
end

function self:GetIndex ()
	return self.Index
end

function self:GetLine ()
	return self.Line
end

function self:GetOperandA ()
	return self.OperandA
end

function self:GetOperandAType ()
	return self.OpcodeInfo:GetOperandAType ()
end

function self:GetOperandAValue ()
	return self:GetOperandValue (self.OperandA, self:GetOperandAType ())
end

function self:GetOperandB ()
	return self.OperandB
end

function self:GetOperandBType ()
	return self.OpcodeInfo:GetOperandBType ()
end

function self:GetOperandBValue ()
	return self:GetOperandValue (self.OperandB, self:GetOperandBType ())
end

function self:GetOperandC ()
	return self.OperandC
end

function self:GetOperandCType ()
	return self.OpcodeInfo:GetOperandCType ()
end

function self:GetOperandCValue ()
	return self:GetOperandValue (self.OperandC, self:GetOperandCType ())
end

function self:GetOperandD ()
	return self.OperandD
end

function self:GetOperandDType ()
	return self.OpcodeInfo:GetOperandDType ()
end

function self:GetOperandDValue ()
	return self:GetOperandValue (self.OperandD, self:GetOperandDType ())
end

function self:GetOpcode ()
	return self.Opcode
end

function self:GetOpcodeInfo ()
	return self.OpcodeInfo
end

function self:GetOpcodeName ()
	return self.OpcodeName
end

function self:GetStore (loadStore)
	local storeVariable = self:GetStoreVariable ()
	if not storeVariable then return nil end
	return storeVariable:GetLoadStore (self:GetStoreId (), loadStore)
end

function self:GetStoreId ()
	return self:GetTag ("StoreId")
end

function self:GetStoreVariable ()
	return self:GetTag ("StoreVariable")
end

function self:GetTag (tagId)
	return self.BytecodeReader:GetInstructionTag (self.Index, tagId)
end

function self:SetIndex (index)
	self.Index = index
end

function self:SetLine (line)
	self.Line = line
end

function self:SetOperandA (operandA)
	self.OperandA = operandA or 0
end

function self:SetOperandB (operandB)
	self.OperandB = operandB or 0
	
	self.OperandD = self.OperandB * 256 + self.OperandC
end

function self:SetOperandC (operandC)
	self.OperandC = operandC or 0
	
	self.OperandD = self.OperandB * 256 + self.OperandC
end

function self:SetOperandD (operandD)
	self.OperandD = operandD or 0
	
	self.OperandB = math.floor (self.OperandD / 256)
	self.OperandC = self.OperandD % 256
end

function self:SetOpcode (opcode)
	self.Opcode = opcode
	self.OpcodeName = GLib.Lua.Opcode [self.Opcode]
	self.OpcodeInfo = GLib.Lua.Opcodes:GetOpcode (self.Opcode)
end

function self:SetStoreId (storeId)
	self:SetTag ("StoreId", storeId)
end

function self:SetStoreVariable (storeVariable)
	self:SetTag ("StoreVariable", storeVariable)
end

function self:SetTag (tagId, data)
	self.BytecodeReader:SetInstructionTag (self.Index, tagId, data)
end

function self:ToString ()
	local instruction = self.OpcodeName .. " "
	
	local operandA = self:FormatOperand (self.OperandA, self:GetOperandAType ())
	
	if self:GetOperandDType () == GLib.Lua.OperandType.None then
		-- A, B, C
		local operandB = self:FormatOperand (self.OperandB, self:GetOperandBType ())
		local operandC = self:FormatOperand (self.OperandC, self:GetOperandCType ())
		
		instruction = instruction .. operandA .. ", " .. operandB .. ", " .. operandC
	else
		-- A, D
		local operandD = self:FormatOperand (self.OperandD, self:GetOperandDType ())
		
		instruction = instruction .. operandA .. ", " .. operandD
	end
	
	return instruction
end

self.__tostring = self.ToString

-- Internal, do not call
function self:GetOperandValue (operand, operandType)
	if operandType == GLib.Lua.OperandType.Literal then
		return operand
	elseif operandType == GLib.Lua.OperandType.SignedLiteral then
		return operand < 32768 and operand or (operand - 65536)
	elseif operandType == GLib.Lua.OperandType.Primitive then
		if operand == 0 then return nil
		elseif operand == 1 then return false
		elseif operand == 2 then return true end
		return "pri" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.NumericConstantId then
		local constantValue = self.BytecodeReader:GetNumericConstantValue (operand + 1)
		if constantValue then return constantValue end
		return "num" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.StringConstantId then
		local constantValue = self.BytecodeReader:GetGarbageCollectedConstantValue (self.BytecodeReader:GetGarbageCollectedConstantCount () - operand)
		if constantValue then
			return constantValue
		end
		return "str-" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.RelativeJump then
		return operand - 0x8000
	end
	
	return nil
end

function self:FormatOperand (operand, operandType)
	if operandType == GLib.Lua.OperandType.Variable then
		local variableName = self.BytecodeReader:GetFrameVariableName (operand + 1)
		if variableName then return variableName end
		return "_" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.DestinationVariable then
		local variableName = self.BytecodeReader:GetFrameVariableName (operand + 1)
		if variableName then return variableName end
		return "_" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.UpvalueId then
		local upvalueName = self.BytecodeReader:GetUpvalueName (operand + 1)
		return upvalueName or ("_up" .. tostring (operand))
	elseif operandType == GLib.Lua.OperandType.Literal then
		return tostring (operand)
	elseif operandType == GLib.Lua.OperandType.SignedLiteral then
		return operand < 32768 and tostring (operand) or tostring (operand - 65536)
	elseif operandType == GLib.Lua.OperandType.Primitive then
		if operand == 0 then return "nil"
		elseif operand == 1 then return "false"
		elseif operand == 2 then return "true" end
		return "pri" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.NumericConstantId then
		local constantValue = self.BytecodeReader:GetNumericConstantValue (operand + 1)
		if constantValue then return tostring (constantValue) end
		return "num" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.StringConstantId then
		local constantValue = self.BytecodeReader:GetGarbageCollectedConstantValue (self.BytecodeReader:GetGarbageCollectedConstantCount () - operand)
		if constantValue then
			return "\"" .. GLib.String.EscapeNonprintable (constantValue) .. "\""
		end
		return "str-" .. tostring (operand)
	elseif operandType == GLib.Lua.OperandType.RelativeJump then
		return tostring (operand - 0x8000)
	else
		return GLib.Lua.OperandType [operandType] .. " " .. tostring (operand)
	end
	
	return tostring (operand)
end