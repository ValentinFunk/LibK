local self = {}
GLib.Lua.StackTraceCache = GLib.MakeConstructor (self)

function self:ctor ()
	self.Cache = {}
end

function self:AddStackTrace (stackTrace)
	if self.Cache [stackTrace:GetHash ()] then
		return self.Cache [stackTrace:GetHash ()]
	end
	
	self.Cache [stackTrace:GetHash ()] = stackTrace
	
	return stackTrace
end

function self:CreateStackTrace (offset)
	offset = offset or 0
	local stackTrace = GLib.Lua.StackTrace (nil, offset + 1)
	stackTrace = self:AddStackTrace (stackTrace)
	return stackTrace
end

function self:Clear ()
	self.Cache = {}
end

function self:GetStackTrace (hash)
	return self.Cache [hash]
end