GLib.Threading.CurrentThread = nil

function GLib.CallAsync (f, ...)
	return GLib.Threading.Thread ():Start (f, ...)
end

function GLib.Curry (f, ...)
	local arguments = {...}
	local argumentCount = table.maxn (arguments)
	
	if argumentCount == 0 then return f end
	
	return function (...)
		return f (unpack (arguments, 1, argumentCount))
	end
end

function GLib.Threading.CanYield ()
	if not GLib.Threading.CurrentThread then
		return coroutine.running () ~= nil
	end
	
	return GLib.Threading.CurrentThread:CanYield ()
end

function GLib.Threading.CanYieldTimeSlice ()
	if not GLib.Threading.CurrentThread then
		return coroutine.running () ~= nil
	end
	
	return GLib.Threading.CurrentThread:CanYieldTimeSlice ()
end

function GLib.Threading.CheckYield ()
	if not GLib.Threading.CurrentThread then return false end
	
	return GLib.Threading.CurrentThread:CheckYield ()
end

function GLib.Threading.GetCurrentThread ()
	return GLib.Threading.CurrentThread
end

function GLib.Threading.InThread ()
	return not GLib.Threading.GetCurrentThread ():IsMainThread ()
end

GLib.Threading.IsInThread = GLib.Threading.InThread

function GLib.Threading.Sleep (durationInMilliseconds)
	if not GLib.Threading.CurrentThread then return false end
	
	return GLib.Threading.CurrentThread:Sleep (durationInMilliseconds)
end

function GLib.Threading.Yield ()
	if not GLib.Threading.CurrentThread then return false end
	
	return GLib.Threading.CurrentThread:Yield ()
end

GLib.CheckYield       = GLib.Threading.CheckYield
GLib.GetCurrentThread = GLib.Threading.GetCurrentThread
GLib.InThread         = GLib.Threading.InThread
GLib.IsInThread       = GLib.Threading.IsInThread
GLib.Sleep            = GLib.Threading.Sleep
GLib.Yield            = GLib.Threading.Yield