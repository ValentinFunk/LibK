local self = {}
GLib.Lua.GarbageCollectedConstant = GLib.MakeConstructor (self)

function self:ctor ()
	self.Index = 1
	
	self.Type  = nil
	self.Value = nil
end

function self:GetIndex ()
	return self.Index
end

function self:GetType ()
	return self.Type
end

function self:GetLuaString ()
	return tostring (self:GetValue ())
end

function self:GetValue ()
	return self.Value
end

function self:Deserialize (type, inBuffer)
	GLib.Error ("GarbageCollectedConstant:Deserialize : Not implemented.")
end

function self:SetIndex (index)
	self.Index = index
end

function self:SetType (type)
	self.Type = type
end

function self:SetValue (value)
	self.Value = value
end

function self:ToString ()
	return "{ " .. (GLib.Lua.GarbageCollectedConstantType [self:GetType ()] or "InvalidConstant") .. " }"
end