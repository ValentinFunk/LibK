local self = {}
GLib.Lua.LoadStore = GLib.MakeConstructor (self)

function self:ctor (frameVariable)
	self.FrameVariable = frameVariable
	
	self.Index = 0
end

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	self:SetFrameVariable (source:GetFrameVariable ())
	self:SetIndex         (source:GetIndex         ())
	
	return self
end

function self:GetBracketedExpression (outerPrecedence)
	local expression, precedence = self:GetExpression ()
	
	if outerPrecedence > precedence or
	   (outerPrecedence == precedence and not GLib.Lua.IsPrecedenceAssociative (precedence)) then
		expression = "(" .. expression .. ")"
	end
	
	return expression
end

function self:GetExpression ()
	if self:IsLoad () then
		local expression = nil
		local expressionPrecedence = nil
		if self:IsExpressionInlineable () then
			local lastStoreId = self:GetLastStoreId ()
			expression = self.FrameVariable.LoadStoreExpressions [lastStoreId]
			expressionPrecedence = self.FrameVariable.LoadStoreExpressionPrecedences [lastStoreId]
		end
		if not expression then
			expression = self.FrameVariable:GetNameOrFallbackName ()
			expressionPrecedence = GLib.Lua.Precedence.Atom
		end
		expressionPrecedence = expressionPrecedence or GLib.Lua.Precedence.Lowest
		return expression, expressionPrecedence
	end
	return self.FrameVariable.LoadStoreExpressions [self.Index], self.FrameVariable.LoadStoreExpressionPrecedences [self.Index]
end

function self:GetExpressionPrecedence ()
	local _, expressionPrecedence = self:GetExpression ()
	return expressionPrecedence
end

function self:GetExpressionRawValue ()
	if self:IsLoad () then
		if self:IsExpressionInlineable () then
			local lastStoreId = self:GetLastStoreId ()
			return self.FrameVariable.LoadStoreExpressionRawValues [lastStoreId]
		end
		return nil
	end
	return self.FrameVariable.LoadStoreExpressionRawValues [self.Index]
end

function self:GetFrameVariable ()
	return self.FrameVariable
end

function self:GetIndex ()
	return self.Index
end

function self:GetInstruction (instruction)
	return self.FrameVariable:GetFunctionBytecodeReader ():GetInstruction (self:GetInstructionId ())
end

function self:GetInstructionId ()
	return self.FrameVariable.LoadStoreInstructions [self.Index]
end

function self:GetLastStore (loadStore)
	return self.FrameVariable:GetLoadStore (self:GetLastStoreId (), loadStore)
end

function self:GetLastStoreId ()
	return self.FrameVariable.LoadStoreLastStoreIds [self.Index]
end

function self:GetLoadCount ()
	return self.FrameVariable.LoadStoreLoadCounts [self.Index] or 0
end

function self:GetNext (loadStore)
	return self.FrameVariable:GetLoadStore (self.Index + 1, loadStore or self)
end

function self:GetNextLoad (loadStore)
	local index = self.Index + 1
	while self.FrameVariable.LoadStoreTypes [index] and self.FrameVariable.LoadStoreTypes [index] ~= "Load" do
		index = index + 1
	end
	return self.FrameVariable:GetLoadStore (index, loadStore or self)
end

function self:GetNextStore (loadStore)
	local index = self.Index + 1
	while self.FrameVariable.LoadStoreTypes [index] and self.FrameVariable.LoadStoreTypes [index] ~= "Store" do
		index = index + 1
	end
	return self.FrameVariable:GetLoadStore (index, loadStore or self)
end

function self:GetPrevious (loadStore)
	return self.FrameVariable:GetLoadStore (self.Index - 1, loadStore or self)
end

function self:IsExpressionInlineable ()
	if self:IsLoad () then
		local lastStoreId = self:GetLastStoreId ()
		return self.FrameVariable.LoadStoreExpressionInlineables [lastStoreId] or false
	end
	return self.FrameVariable.LoadStoreExpressionInlineables [self.Index] or false
end

function self:IsLoad ()
	return self.FrameVariable.LoadStoreTypes [self.Index] == "Load"
end

function self:IsStore ()
	return self.FrameVariable.LoadStoreTypes [self.Index] == "Store"
end

function self:SetExpression (expression, expressionPrecedence)
	expressionPrecedence = expressionPrecedence or GLib.Lua.Precedence.Lowest
	
	self.FrameVariable.LoadStoreExpressions [self.Index] = expression
	self.FrameVariable.LoadStoreExpressionPrecedences [self.Index] = expressionPrecedence
end

function self:SetExpressionPrecedence (expressionPrecedence)
	self.FrameVariable.LoadStoreExpressionPrecedences [self.Index] = expressionPrecedence
end

function self:SetExpressionRawValue (expressionRawValue)
	self.FrameVariable.LoadStoreExpressionRawValues [self.Index] = expressionRawValue
end

function self:SetExpressionInlineable (expressionInlineable)
	self.FrameVariable.LoadStoreExpressionInlineables [self.Index] = expressionInlineable
end

function self:SetFrameVariable (frameVariable)
	self.FrameVariable = frameVariable
end

function self:SetIndex (index)
	self.Index = index
end

function self:SetInstructionId (instructionId)
	self.FrameVariable.LoadStoreInstructions [self.Index] = instructionId
end

function self:SetLastStore (loadStoreOrIndex)
	if type (loadStoreOrIndex) == "table" then
		loadStoreOrIndex = loadStoreOrIndex:GetIndex ()
	end
	self.FrameVariable.LoadStoreLastStoreIds [self.Index] = loadStoreOrIndex
end

function self:SetLoadCount (loadCount)
	self.FrameVariable.LoadStoreLoadCounts [self.Index] = loadCount
end

function self:ToString ()
	local loadStore = self:IsLoad () and "Load" or "Store"
	loadStore = loadStore .. self:GetIndex ()
	loadStore = loadStore .. " "
	loadStore = loadStore .. self.FrameVariable:GetNameOrFallbackName ()
	
	local instruction = self:GetInstruction ()
	if instruction then
		loadStore = loadStore .. "\t" .. instruction:ToString ()
	end
	return loadStore
end

self.__tostring = self.ToString