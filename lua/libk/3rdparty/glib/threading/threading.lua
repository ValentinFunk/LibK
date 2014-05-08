GLib.Threading.Threads = {}
GLib.Threading.CurrentThread = nil
GLib.Threading.LastThreadResumeTime = 0

function GLib.CallAsync (f, ...)
	GLib.Threading.Thread ():Start (f, ...)
end

function GLib.CheckYield ()
	if not GLib.Threading.CurrentThread then return end
	
	if SysTime () - GLib.Threading.LastThreadResumeTime > 0.005 then
		coroutine.yield ()
	end
end

function GLib.Curry (f, ...)
	local arguments = {...}
	if #arguments == 0 then return f end
	return function ()
		f (unpack (arguments))
	end
end

hook.Add ("Think", "GLib.Threading",
	function ()
		if not GLib.Threading then
			hook.Remove ("Think", "GLib.Threading")
			return
		end
		
		GLib.Threading.LastThreadResumeTime = SysTime ()
		
		for thread, _ in pairs (GLib.Threading.Threads) do
			if SysTime () - GLib.Threading.LastThreadResumeTime > 0.005 then
				break
			end
			
			if not thread:IsSuspended () and not thread:IsWaiting () then
				local success, error = coroutine.resume (thread:GetCoroutine ())
				if not success then
					thread:Terminate ()
					ErrorNoHalt (error)
				end
			end
		end
	end
)