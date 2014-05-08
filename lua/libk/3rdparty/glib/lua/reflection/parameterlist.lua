local self = {}
GLib.Lua.ParameterList = GLib.MakeConstructor (self)

function self:ctor (func)
	if type (func) == "table" then
		self.InfoTable = func:GetInfoTable ()
		func = func:GetRawFunction ()
	end
	
	self.Function = func
	self.InfoTable = self.InfoTable or debug.getinfo (self.Function)
	
	self.FixedParameterCount = 0
	self.Parameters = {}
	
	self.VariadicValid = true
	self.Variadic = false
	
	-- Compute info
	for i = 1, self.InfoTable.nparams do
		self:AddParameter (debug.getlocal (self.Function, i))
	end
	
	if self.InfoTable.isvararg then
		self:AddVariadicParameter ()
	end
end

function self:AddParameter (name)
	local parameter = GLib.Lua.Parameter (self, name)
	parameter:SetFrameIndex (#self.Parameters)
	
	self.Parameters [#self.Parameters + 1] = parameter
	self.FixedParameterCount = self.FixedParameterCount + 1
	
	return parameter
end

function self:AddVariadicParameter ()
	local parameter = self:AddParameter ()
	parameter:SetVariadic (true)
	
	self.Variadic = true
	
	-- Correct our FixedParameterCount, since AddParameter increments it
	self.FixedParameterCount = self.FixedParameterCount - 1
	
	return parameter
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Parameters [i]
	end
end

function self:GetFixedParameterCount ()
	return self.FixedParameterCount
end

function self:GetParameterName (index)
	if not self.Parameters [index] then return nil end
	return self.Parameters [index]:GetName ()
end

function self:IsVariadic ()
	return self.Variadic
end

function self:ToString ()
	local parameterList = "("
	
	local first = true
	for parameter in self:GetEnumerator () do
		if first then first = false
		else parameterList = parameterList .. ", " end
		
		parameterList = parameterList .. parameter:ToString ()
	end
	
	parameterList = parameterList .. ")"
	
	return parameterList
end