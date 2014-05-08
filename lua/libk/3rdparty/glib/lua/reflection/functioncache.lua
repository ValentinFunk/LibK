local self = {}
GLib.Lua.FunctionCache = GLib.MakeConstructor (self)

function self:ctor ()
	-- Avoid having the cache directly accessible from _G
	local cache = GLib.WeakTable ()
	self.GetCache = function ()
		return cache
	end
end

function self:ContainsFunction (func)
	return self:GetCache () [func] ~= nil
end

function self:GetFunction (func)
	local cache = self:GetCache ()
	
	if cache [func] then
		return cache [func]
	end
	
	local functionInfo = GLib.Lua.Function.FromFunction (func)
	cache [func] = functionInfo
	
	return functionInfo
end

GLib.Lua.FunctionCache = GLib.Lua.FunctionCache ()