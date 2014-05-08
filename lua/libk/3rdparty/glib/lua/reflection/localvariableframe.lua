local self = {}
GLib.Lua.LocalVariableFrame = GLib.MakeConstructor (self, GLib.Lua.VariableFrame)

function GLib.Lua.LocalVariableFrame.ctor (frameOffset)
	return GLib.Lua.LocalVariableFrame.__ictor (frameOffset, nil, GLib.Lua.StackCaptureOptions.None)
end

function GLib.Lua.LocalVariableFrame.CreateForStackFrame (frameOffset, stackFrame, stackCaptureOptions)
	return GLib.Lua.LocalVariableFrame.__ictor (frameOffset, stackFrame, stackCaptureOptions)
end

function self:ctor (frameOffset, stackFrame, stackCaptureOptions)
	frameOffset = frameOffset or 0
	frameOffset = 4 + frameOffset
	stackCaptureOptions = stackCaptureOptions or GLib.Lua.StackCaptureOptions.None
	
	local i = 1
	local localCount = math.huge
	
	if bit.band (stackCaptureOptions, GLib.Lua.StackCaptureOptions.Arguments) ~= 0 then
		localCount = stackFrame:GetFunction ():GetParameterList ():GetFixedParameterCount ()
		
		if stackFrame:GetFunction ():IsNative () then
			localCount = math.huge
		end
	end
	
	for i = 1, localCount do
		local name, value = debug.getlocal (frameOffset, i)
		if name == nil and value == nil then break end
		
		self:AddVariableAtIndex (i, name, value)
		
		i = i + 1
	end
	
	-- Variadic arguments
	i = -1
	while true do
		local name, value = debug.getlocal (frameOffset, i)
		if name == nil and value == nil then break end
		
		self:AddVariableAtIndex (i, name, value)
		
		i = i - 1
	end
end