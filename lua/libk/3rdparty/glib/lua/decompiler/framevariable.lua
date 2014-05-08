local self = {}
GLib.Lua.FrameVariable = GLib.MakeConstructor (self)

function self:ctor (functionBytecodeReader, index)
	-- Identity
	self.FunctionBytecodeReader = functionBytecodeReader
	self.Index = index
	
	self.Name = nil
	self.StartInstruction = nil
	self.EndInstruction = nil
	
	self.Tags = {}
	
	self.LoadStoreCount = 0
	self.LoadStoreTypes = {}
	self.LoadStoreInstructions = {}
	
	-- Loads
	self.LoadStoreInstructionSubIds = {}
	self.LoadStoreLastStoreIds = {}
	
	-- Stores
	self.LoadStoreExpressions = {}
	self.LoadStoreExpressionPrecedences = {}
	self.LoadStoreExpressionRawValues = {}
	self.LoadStoreExpressionInlineables = {}
	self.LoadStoreLoadCounts = {}
end

-- Identity
function self:GetFunctionBytecodeReader ()
	return self.FunctionBytecodeReader
end

function self:GetIndex ()
	return self.Index
end

-- Loads and store analysis
function self:AddLoad (instructionId, instructionSubId)
	self.LoadStoreCount = self.LoadStoreCount + 1
	self.LoadStoreTypes [self.LoadStoreCount] = "Load"
	self.LoadStoreInstructions [self.LoadStoreCount] = instructionId
	self.LoadStoreExpressions [self.LoadStoreCount] = nil
	
	return self.LoadStoreCount
end

function self:AddStore (instructionId, expression, expressionPrecedence, expressionRawValue)
	self.LoadStoreCount = self.LoadStoreCount + 1
	self.LoadStoreTypes [self.LoadStoreCount] = "Store"
	self.LoadStoreInstructions [self.LoadStoreCount] = instructionId
	self.LoadStoreExpressions [self.LoadStoreCount] = expression
	self.LoadStoreExpressionPrecedences [self.LoadStoreCount] = expressionPrecedence or GLib.Lua.Precedence.Lowest
	self.LoadStoreExpressionRawValues [self.LoadStoreCount] = expressionRawValue
	
	return self.LoadStoreCount
end

function self:GetLoadStore (id, loadStore)
	if id <= 0 then return nil end
	if id > self.LoadStoreCount then return nil end
	
	loadStore = loadStore or GLib.Lua.LoadStore (self)
	loadStore:SetFrameVariable (self)
	loadStore:SetIndex (id)
	
	return loadStore
end

function self:GetLoadStoreEnumerator (loadStore)
	loadStore = loadStore or GLib.Lua.LoadStore (self)
	
	local i = 0
	return function ()
		i = i + 1
		return self:GetLoadStore (i, loadStore)
	end
end

function self:ClearExpression ()
	self:SetTag ("Expression", nil)
	self:SetTag ("ExpressionIndexable", nil)
	self:SetTag ("ExpressionRawValue", nil)
end

function self:GetExpressionOrFallback ()
	return self:GetTag ("Expression") or self:GetNameOrFallbackName ()
end

function self:GetExpressionRawValue ()
	return self:GetTag ("ExpressionRawValue")
end

function self:GetName ()
	return self.Name
end

function self:GetNameOrFallbackName ()
	local name = self.Name
	if not name then
		if self:IsParameter () then
			name = "_param" .. tostring (self.Index - 1)
		else
			name = "_" .. tostring (self.Index - 1)
		end
	end
	return name
end

function self:GetStartInstruction ()
	return self.StartInstruction
end

function self:GetEndInstruction ()
	return self.EndInstruction
end

function self:GetInstructionRange ()
	return self.StartInstruction, self.EndInstruction
end

function self:GetTag (tagId)
	return self.Tags [tagId]
end

function self:IsParameter ()
	if self.Index == "..." then return false end
	
	return self.Index <= self.FunctionBytecodeReader:GetParameterCount ()
end

--- Returns true if this is the first assignment
function self:SetAssigned (instructionId)
	local isFirstAssignment = self:GetTag ("FirstAssignment") == nil
	self:SetTag ("FirstAssignment", instructionId)
	
	if isFirstAssignment and self:IsParameter () then
		isFirstAssignment = false
	end
	return isFirstAssignment
end

function self:SetExpression (expression, indexable, rawValue)
	self:SetTag ("Expression", expression)
	self:SetTag ("ExpressionIndexable", indexable)
	self:SetTag ("ExpressionRawValue", rawValue)
end

function self:SetIndex (index)
	self.Index = index
end

function self:SetName (name)
	if name == "" then name = nil end
	if name and not GLib.Lua.IsValidVariableName (name) and name ~= "..." then name = nil end
	
	self.Name = name
end

function self:SetStartInstruction (instructionId)
	self.StartInstruction = instructionId
end

function self:SetEndInstruction (instructionId)
	self.EndInstruction = instructionId
end

function self:SetTag (tagId, data)
	self.Tags [tagId] = data
end

function self:ToString ()
	return self:GetNameOrFallbackName ()
end