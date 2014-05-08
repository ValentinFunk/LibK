local self = {}
GLib.Lua.OpcodeInfo = GLib.MakeConstructor (self)

function self:ctor (opcode, name)
	self.Opcode = opcode
	self.Name = name
	
	self.OperandAType = GLib.Lua.OperandType.None
	self.OperandBType = GLib.Lua.OperandType.None
	self.OperandCType = GLib.Lua.OperandType.None
	self.OperandDType = GLib.Lua.OperandType.None
	
	self.FunctionName = nil
end

function self:GetFunctionName ()
	return self.FunctionName
end

function self:GetName ()
	return self.Name
end

function self:GetOpcode ()
	return self.Opcode
end

function self:GetOperandAType ()
	return self.OperandAType
end

function self:GetOperandBType ()
	return self.OperandBType
end

function self:GetOperandCType ()
	return self.OperandCType
end

function self:GetOperandDType ()
	return self.OperandDType
end

function self:SetFunctionName (functionName)
	self.FunctionName = functionName
end

function self:SetName (name)
	self.Name = name
end

function self:SetOperandAType (operandAType)
	self.OperandAType = operandAType
end

function self:SetOperandBType (operandBType)
	self.OperandBType = operandBType
end

function self:SetOperandCType (operandCType)
	self.OperandCType = operandCType
end

function self:SetOperandDType (operandDType)
	self.OperandDType = operandDType
end