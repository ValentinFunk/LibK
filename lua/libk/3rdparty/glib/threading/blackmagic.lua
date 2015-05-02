local function GetArgumentList (n, fixedParameterCount)
	-- Get arguments
	local arguments = {}
	local argumentCount = 0
	
	for i = 1, fixedParameterCount do
		local _, argument = debug.getlocal (n, i)
		arguments [i] = argument
	end
	argumentCount = fixedParameterCount
	
	-- Variadic arguments
	for i = 1, math.huge do
		local argumentName, argument = debug.getlocal (n, -i)
		if not argumentName then break end
		
		argumentCount = argumentCount + 1
		arguments [argumentCount] = argument
	end
	
	return arguments, argumentCount
end

-- Useful for preventing tail calls to CallSelfAsAsync
function GLib.Identity (...)
	return ...
end

I = GLib.Identity

function GLib.Threading.CallSelfAsAsync (callbackParameterIndex)
	local currentThread = GLib.GetCurrentThread ()
	local tls = currentThread:GetThreadLocalStorage ()
	if not tls.CallbackEvent then
		tls.CallbackEvent = GLib.Threading.Event ()
		tls.CallbackEvent:SetAutoReset (false)
	end
	
	-- Get call information
	local info = debug.getinfo (2)
	local arguments, argumentCount = GetArgumentList (3, info.nparams)
	
	-- Add callback argument
	local ret = nil
	callbackParameterIndex = callbackParameterIndex or argumentCount
	arguments [callbackParameterIndex] = function (...)
		ret = {...}
		tls.CallbackEvent:Fire ()
	end
	
	-- Invoke function with callback
	info.func (unpack (arguments, 1, argumentCount))
	
	-- Wait for callback
	currentThread:WaitForSingleObject (tls.CallbackEvent)
	tls.CallbackEvent:Reset ()
	
	-- Return callback arguments
	return unpack (ret, 1, table.maxn (ret))
end

function GLib.Threading.CallSelfAsSync ()
	-- Get call information
	local info = debug.getinfo (2)
	local arguments, argumentCount = GetArgumentList (3, info.nparams)
	
	-- Get callback
	local callback = arguments [argumentCount]
	argumentCount = argumentCount - 1
	
	-- Bail out if there is no callback
	if not callback then return false end
	
	if GLib.InThread () then
		-- Invoke function without callback
		local ret = { info.func (unpack (arguments, 1, argumentCount)) }
		
		-- Call callback with return values
		callback (unpack (ret, 1, table.maxn (ret)))
	else
		GLib.CallAsync (
			function ()
				-- Invoke function without callback
				local ret = { info.func (unpack (arguments, 1, argumentCount)) }
				
				-- Call callback with return values
				callback (unpack (ret, 1, table.maxn (ret)))
			end
		)
	end
	
	return true
end

function GLib.Threading.CallSelfInThread ()
	-- Abort if we're already in a thread.
	if GLib.InThread () then return false end
	
	local info = debug.getinfo (2)
	
	-- Invoke
	local arguments, argumentCount = GetArgumentList (3, info.nparams)
	local thread = GLib.CallAsync (info.func, unpack (arguments, 1, argumentCount))
	GLib.Threading.ThreadRunner:RunThread (thread)
	
	return true
end

GLib.CallSelfAsAsync  = GLib.Threading.CallSelfAsAsync
GLib.CallSelfAsSync   = GLib.Threading.CallSelfAsSync
GLib.CallSelfInThread = GLib.Threading.CallSelfInThread