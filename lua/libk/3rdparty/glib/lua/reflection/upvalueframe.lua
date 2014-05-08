local self = {}
GLib.Lua.UpvalueFrame = GLib.MakeConstructor (self, GLib.Lua.VariableFrame)

function self:ctor (func)
	if type (func) == "table" then
		func = func:GetRawFunction ()
	end
	
	local i = 1
	while true do
		local name, value = debug.getupvalue (func, i)
		if name == nil then break end
		
		self:AddVariableAtIndex (i, name, value)
		
		i = i + 1
	end
end