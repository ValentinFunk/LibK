local self = {}
GLib.Lua.VariableFrame = GLib.MakeConstructor (self)

function self:ctor ()
	self.VariableCount = 0
	
	self.VariableIndexSet = {}
	self.VariableIndexList = {}
	self.VariableIndexListSorted = true
	
	self.VariableNamesByIndex = {}
	self.VariableValuesByIndex = {}
	self.VariableIndicesByName = {}
end

function self:AddVariable (name, value)
	local index = #self.VariableIndexList > 0 and (self.VariableIndexList [#self.VariableIndexList] + 1) or 1
	return self:AddVariableAtIndex (index, name, value)
end

function self:AddVariableAtIndex (index, name, value)
	if not self.VariableIndexSet [index] then
		self.VariableCount = self.VariableCount + 1
		self.VariableIndexList [#self.VariableIndexList + 1] = index
		self.VariableIndexListSorted = false
	end
	
	self.VariableNamesByIndex [index] = name
	self.VariableValuesByIndex [index] = value
	
	if name then
		self.VariableIndicesByName [name] = index
	end
end

function self:GetEnumerator ()
	if not self.VariableIndexListSorted then
		self.VariableIndexListSorted = true
		table.sort (self.VariableIndexList)
	end
	
	local i = 0
	return function ()
		i = i + 1
		return self.VariableIndexList [i], self.VariableNamesByIndex [self.VariableIndexList [i]], self.VariableValuesByIndex [self.VariableIndexList [i]]
	end
end

function self:GetVariableCount ()
	return self.VariableCount
end

function self:GetVariableIndex (name)
	return self.VariableIndicesByName [name]
end

function self:GetVariableName (index)
	return self.VariableNamesByIndex [index]
end

function self:GetVariableNameOrFallback (index)
	return self.VariableNamesByIndex [index] or ("__var" .. tostring (index))
end

function self:GetVariableValue (index)
	return self.VariableValuesByIndex [index]
end

function self:SetVariableName (index, name)
	if self.VariableIndicesByName [self.VariableNamesByIndex [index]] == index then
		self.VariableIndicesByName [self.VariableNamesByIndex [index]] = nil
	end
	
	self.VariableNamesByIndex [index] = name
	if name then
		self.VariableIndicesByName [name] = index
	end
end

function self:SetVariableValue (index, name)
	if type (index) == "string" then
		index = self:GetVariableIndex (index)
	end
	
	self.VariableValuesByIndex [index] = name
end

function self:ToString ()
	local variableFrame = GLib.StringBuilder ()
	
	variableFrame:Append ("{\n")
	
	local longestName = 0
	for index, name, value in self:GetEnumerator () do
		if #name > longestName then
			longestName = #name
		end
	end
	
	for index, name, value in self:GetEnumerator () do
		name = name or self:GetVariableNameOrFallback (index)
		
		local indexString = tostring (math.abs (index))
		if #indexString < 2 then
			indexString = " " .. indexString
		end
		indexString = (index < 0 and "-" or " ") .. indexString
		
		variableFrame:Append ("\t")
		variableFrame:Append (indexString)
		variableFrame:Append (": ")
		variableFrame:Append (name)
		variableFrame:Append (string.rep (" ", longestName - #name))
		variableFrame:Append (" = ")
		variableFrame:Append (GLib.Lua.ToLuaString (value))
		variableFrame:Append ("\n")
	end
	variableFrame:Append ("}")
	
	return variableFrame:ToString ()
end