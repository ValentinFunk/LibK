local self = {}
GLib.Lua.FunctionConstant = GLib.MakeConstructor (self, GLib.Lua.GarbageCollectedConstant)

function self:ctor ()
	self.Function = nil
	self.Type = GLib.Lua.GarbageCollectedConstantType.Function
end

function self:GetFunction ()
	return self.Function
end

function self:Deserialize (type, inBuffer)
end

function self:GetLuaString ()
	if self.Function then
		return self.Function:ToString ()
	end
	return "function () --[[ Closure ]] end"
end

function self:SetFunction (functionBytecodeReader)
	self.Function = functionBytecodeReader
end

function self:ToString ()
	return "{ Function: " .. self:GetLuaString () .. " }"
end