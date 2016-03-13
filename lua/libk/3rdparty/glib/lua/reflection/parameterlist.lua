local self = {}
GLib.Lua.ParameterList = GLib.MakeConstructor (self, GLib.Serialization.ISerializable)

function GLib.Lua.ParameterList.ctor (func)
	if func then
		return GLib.Lua.ParameterList.FromFunction (func)
	end
	
	return GLib.Lua.ParameterList.__ictor ()
end

function GLib.Lua.ParameterList.FromFunction (func)
	local infoTable = nil
	
	if type (func) == "table" then
		infoTable = func:GetInfoTable ()
		func = func:GetRawFunction ()
	end
	
	local parameterList = GLib.Lua.ParameterList.__ictor ()
	if not func then return parameterList end
	
	-- Compute info
	infoTable = infoTable or debug.getinfo (func)
	
	for i = 1, infoTable.nparams do
		parameterList:AddParameter (debug.getlocal (func, i) or ("__param" .. tostring (i)))
	end
	
	if infoTable.isvararg then
		parameterList:AddVariadicParameter ()
	end
	
	return parameterList
end

function self:ctor ()
	self.FixedParameterCount = 0
	self.Parameters = {}
	
	self.Variadic = false
end

-- ISerializable
function self:Serialize (outBuffer)
	outBuffer:UInt32 (#self.Parameters)
	
	for i = 1, #self.Parameters do
		self.Parameters [i]:Serialize (outBuffer)
	end
	
	return outBuffer
end

function self:Deserialize (inBuffer)
	local parameterCount = inBuffer:UInt32 ()
	
	for i = 1, parameterCount do
		local parameter = GLib.Lua.Parameter (self)
		parameter:Deserialize (inBuffer)
		
		if parameter:IsVariadic () then
			self.Variadic = true
		else
			self.FixedParameterCount = self.FixedParameterCount + 1
		end
		
		self.Parameters [#self.Parameters + 1] = parameter
	end
	
	return self
end

-- ParameterList
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
	return GLib.ArrayEnumerator (self.Parameters)
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

function self:ToUnbracketedString ()
	local parameterList = ""
	
	local first = true
	for parameter in self:GetEnumerator () do
		if first then first = false
		else parameterList = parameterList .. ", " end
		
		parameterList = parameterList .. parameter:ToString ()
	end
	
	return parameterList
end

function self:ToString ()
	return "(" .. self:ToUnbracketedString () .. ")"
end