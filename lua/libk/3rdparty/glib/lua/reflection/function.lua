local self = {}
GLib.Lua.Function = GLib.MakeConstructor (self)

function GLib.Lua.Function.ctor (func)
	return GLib.Lua.FunctionCache:GetFunction (func)
end

function GLib.Lua.Function.FromFunction (func)
	if type (func) == "table" then
		func = func:GetRawFunction ()
	end
	
	return GLib.Lua.Function.__ictor (func)
end

function self:ctor (func)
	self.Function = func
	self.InfoTable = debug.getinfo (func)
	
	self.ParameterList = nil
end

-- Definition
function self:GetStartLine ()
	return self.InfoTable.linedefined
end

function self:GetEndLine ()
	return self.InfoTable.lastlinedefined
end

function self:GetLineRange ()
	return self:GetStartLine (), self:GetEndLine ()
end

function self:GetFilePath ()
	return self.InfoTable.short_src
end

function self:GetFunction ()
	return self.Function
end

function self:GetPrototype ()
	return "function " .. self:GetParameterList ():ToString ()
end

function self:GetInfoTable ()
	return self.InfoTable
end

function self:GetParameterList ()
	if self.ParameterList == nil then
		self.ParameterList = GLib.Lua.ParameterList (self)
	end
	
	return self.ParameterList
end

function self:GetRawFunction ()
	return self.Function
end

function self:IsNative ()
	return self.InfoTable.what == "C"
end

function self:ToString ()
	return "function " .. self:GetParameterList ():ToString ()
end