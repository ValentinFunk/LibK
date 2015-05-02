local self = {}
GLib.Lua.Function = GLib.MakeConstructor (self)
GLib.RegisterSerializable ("GLib.Lua.Function", GLib.Lua.Function)

function GLib.Lua.Function.ctor (func)
	if func then
		return GLib.Lua.FunctionCache:GetFunction (func)
	end
	
	return GLib.Lua.Function.__ictor ()
end

function GLib.Lua.Function.FromFunction (func)
	if type (func) == "table" then
		func = func:GetRawFunction ()
	end
	
	return GLib.Lua.Function.__ictor (func)
end

function self:ctor (func)
	self.Function = func
	self.InfoTable = func and debug.getinfo (func) or nil
	
	self.ParameterList = nil
	
	-- Definition
	self.FilePath = self.InfoTable and self.InfoTable.short_src
	
	self.StartLine = self.InfoTable and self.InfoTable.linedefined
	self.EndLine = self.InfoTable and self.InfoTable.lastlinedefined
	
	self.Native = self.InfoTable and self.InfoTable.what == "C"
end

-- ISerializable
function self:Deserialize (inBuffer)
	self:GetParameterList ():Deserialize (inBuffer)
	
	self.FilePath = inBuffer:String ()
	self.StartLine = inBuffer:UInt32 ()
	self.EndLine = inBuffer:UInt32 ()
	self.Native = inBuffer:Boolean ()
end

function self:Serialize (outBuffer)
	self:GetParameterList ():Serialize (outBuffer)
	
	outBuffer:String (self.FilePath)
	outBuffer:UInt32 (self.StartLine)
	outBuffer:UInt32 (self.EndLine)
	outBuffer:Boolean (self.Native)
end

-- Definition
function self:GetStartLine ()
	return self.StartLine
end

function self:GetEndLine ()
	return self.EndLine
end

function self:GetLineRange ()
	return self.StartLine, self.EndLine
end

function self:GetFilePath ()
	return self.FilePath
end

function self:GetFunction ()
	return self.Function
end

function self:GetInfoTable ()
	return self.InfoTable
end

function self:GetName ()
	return GLib.Lua.GetFunctionName (self.Function)
end

function self:GetPrototype ()
	return "function " .. self:GetParameterList ():ToString ()
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
	return self.Native
end

function self:ToString ()
	return "function " .. self:GetParameterList ():ToString ()
end