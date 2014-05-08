local self = {}
GLib.Lua.StringConstant = GLib.MakeConstructor (self, GLib.Lua.GarbageCollectedConstant)

function self:ctor (str)
	self.Type = GLib.Lua.GarbageCollectedConstantType.String
	self.Length = 0
	self.Value = str or ""
end

function self:Deserialize (type, inBuffer)
	self.Length = type - GLib.Lua.GarbageCollectedConstantType.String
	self.Value = inBuffer:Bytes (self.Length)
end

function self:GetLuaString ()
	return "\"" .. GLib.String.EscapeNonprintable (self.Value) .. "\""
end

function self:ToString ()
	return "{ String: " .. self:GetLuaString () .. " }"
end