local self = {}
GLib.Coroutine = GLib.MakeConstructor (self)

function self:ctor (f)
	self.Coroutine = coroutine.create (f)
end

function self:Call (f, ...)
	local ret = { coroutine.yield ("call", f, ...) }
	return unpack (ret)
end

function self:Resume (...)
	local inArguments = { ... }
	
	GLib.CoroutineStack:Push (self)
	while true do
		local successCommandArguments = { coroutine.resume (self.Coroutine, unpack (inArguments)) }
		local success = successCommandArguments [1]
		local command = successCommandArguments [2]
		if success then
			table.remove (successCommandArguments, 2)
			table.remove (successCommandArguments, 1)
			if command == "call" then
				local f = successCommandArguments [1]
				table.remove (successCommandArguments, 1)
				inArguments = { f (unpack (successCommandArguments)) }
			elseif command == "yield" or command == "" or command == nil then
				GLib.CoroutineStack:Pop (self)
				return success, unpack (successCommandArguments)
			else
				GLib.CoroutineStack:Pop (self)
				return success, unpack (successCommandArguments)
			end
		else
			GLib.CoroutineStack:Pop (self)
			return unpack (successCommandArguments)
		end
	end
end

function self:Status ()
	return coroutine.status (self.Coroutine)
end

function self:Yield (...)
	return coroutine.yield ("yield", ...)
end