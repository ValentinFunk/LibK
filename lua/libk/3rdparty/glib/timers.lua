local delayedCalls = {}
GLib.SlowDelayedCalls = {}

function GLib.CallDelayed (callback)
	if not callback then return end
	if type (callback) ~= "function" then
		GLib.Error ("GLib.CallDelayed : callback must be a function!")
		return
	end
	
	delayedCalls [#delayedCalls + 1] = callback
end

function GLib.PolledWait (interval, timeout, predicate, callback)
	if not callback then return end
	if not predicate then return end
	
	if predicate () then
		callback ()
		return
	end
	
	if timeout < 0 then return end
	
	timer.Simple (interval,
		function ()
			GLib.PolledWait (interval, timeout - interval, predicate, callback)
		end
	)
end

hook.Add ("Think", "GLib.DelayedCalls",
	function ()
		local lastCalled = nil
		local startTime = SysTime ()
		while SysTime () - startTime < 0.005 and #delayedCalls > 0 do
			lastCalled = delayedCalls [1]
			xpcall (delayedCalls [1], GLib.Error)
			table.remove (delayedCalls, 1)
		end
		
		if SysTime () - startTime > 0.2 and lastCalled then
			MsgN ("GLib.DelayedCalls : " .. tostring (lastCalled) .. " took " .. GLib.FormatDuration (SysTime () - startTime) .. ".")
			GLib.SlowDelayedCalls [#GLib.SlowDelayedCalls + 1] = lastCalled
		end
	end
)