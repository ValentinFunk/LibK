local self = {}
GLib.Lua.StackFrame = GLib.MakeConstructor (self)

function self:ctor (frameInfo, captureIndex, index)
	-- Index of this stack frame relative to the StackTrace constructor
	self.CaptureIndex = captureIndex
	self.Index = index
	
	self.Function = nil
	self.FrameInfo = frameInfo
	
	self.Locals   = nil
	self.Upvalues = nil
end

function self:CaptureArguments (frameOffset)
	if self.Locals then return end
	
	self.Locals = GLib.Lua.LocalVariableFrame.CreateForStackFrame (frameOffset, self, GLib.Lua.StackCaptureOptions.Arguments)
end

function self:CaptureLocals (frameOffset)
	if self.Locals then return end
	
	self.Locals = GLib.Lua.LocalVariableFrame.CreateForStackFrame (frameOffset, self, GLib.Lua.StackCaptureOptions.Locals)
end

function self:CaptureUpvalues ()
	if self.Upvalues then return end
	
	self.Upvalues = GLib.Lua.UpvalueFrame (self:GetFunction ())
end

-- Returns the index of this stack frame relative to the StackTrace constructor
function self:GetCaptureIndex ()
	return self.CaptureIndex
end

function self:GetCurrentLine ()
	return self.FrameInfo.currentline
end

function self:GetData ()
	return self.FrameInfo
end

function self:GetFunction ()
	if not self.Function then
		self.Function = GLib.Lua.FunctionCache:GetFunction (self.FrameInfo.func)
	end
	
	return self.Function
end

function self:GetIndex ()
	return self.Index
end

function self:GetLocals ()
	return self.Locals
end

function self:GetRawFunction ()
	return self.FrameInfo.func
end

function self:GetUpvalues ()
	return self.Upvalues
end

function self:IsNative ()
	return self.FrameInfo.what == "C"
end

function self:IsTrusted (...)
	if self:IsNative () then return true end
	
	return false
end

function self:IsUntrusted ()
	if self:IsNative () then return false end
	
	if file.Exists (self.FrameInfo.short_src, "GAME") or
	   GLib.Loader.File.Exists (self.FrameInfo.short_src, "LUA") then
		return false
	end
	
	return true
end

function self:ToString ()
	local name = self.FrameInfo.name
	local src  = self.FrameInfo.short_src
	src = src or "<unknown>"
	
	-- Argument list
	local argumentList = ""
	if self.Locals then
		argumentList = argumentList .. " ("
		
		local argumentCount = 0
		local parameterList = self:GetFunction ():GetParameterList ()
		local fixedParameterCount = parameterList:GetFixedParameterCount ()
		
		-- Native functions
		if self:GetFunction ():IsNative () then
			fixedParameterCount = self.Locals:GetVariableCount ()
		end
		
		for i = 1, fixedParameterCount do
			if argumentCount > 0 then
				argumentList = argumentList .. ", "
			end
			
			local parameterName = parameterList:GetParameterName (i)
			if parameterName then
				argumentList = argumentList .. parameterName .. " = " .. GLib.Lua.ToCompactLuaString (self.Locals:GetVariableValue (i))
			else
				argumentList = argumentList .. GLib.Lua.ToCompactLuaString (self.Locals:GetVariableValue (i))
			end
			
			argumentCount = argumentCount + 1
		end
		
		for i = 1, math.huge do
			if not self.Locals:GetVariableName (-i) then break end
			
			if argumentCount > 0 then
				argumentList = argumentList .. ", "
			end
			
			argumentList = argumentList .. GLib.Lua.ToCompactLuaString (self.Locals:GetVariableValue (-i))
			
			argumentCount = argumentCount + 1
		end
		
		argumentList = argumentList .. ")"
	end
	
	if name then
		return string.format ("%2d", self.Index) .. ": " .. name .. argumentList .. " [" .. src .. ": " .. tostring (self.FrameInfo.currentline) .. "]"
	elseif src and self.FrameInfo.currentline then
		return string.format ("%2d", self.Index) .. ":" .. argumentList .. " [" .. src .. ": " .. tostring (self.FrameInfo.currentline) .. "]"
	else
		return string.format ("%2d", self.Index) .. ":" .. argumentList .. " <unknown>"
	end
end

self.__tostring = self.ToString