local self = {}
GLib.Threading.Thread = GLib.MakeConstructor (self, GLib.Threading.IWaitable)

--[[
	StateChanged (ThreadState state, bool suspended)
		Fired when this Thread's state has changed.
	Terminated ()
		Fired when this Thread has terminated.
	ExecutionSliceEnded ()
		Fired when this Thread's execution slice has ended.
	ExecutionSliceStarted ()
		Fired when this Thread's execution slice has started.
]]

function self:ctor ()
	-- Identity
	self.Name = nil
	
	-- Thread
	self.ThreadRunner = nil
	self.Coroutine = nil
	
	self.YieldTimeSliceAllowed = true
	
	-- Thread local storage
	self.ThreadLocalStorage = nil
	
	-- State
	self.State = GLib.Threading.ThreadState.Unstarted
	self.Suspended = false -- Suspension can occur on top of running, waiting and sleeping
	
	self.StartTime = 0
	self.EndTime   = 0
	
	-- Waiting
	self.WaitObjects = {}
	self.WaitAbortionTime = 0
	self.WaitEndReason = GLib.Threading.WaitEndReason.Success
	
	-- Wait resolution
	self.WaitResolutionAbortionTime = math.huge
	
	-- Sleeping
	self.SleepEndTime = 0
	
	GLib.EventProvider (self)
end

-- IWaitable
function self:IsResolvableWaitable ()
	return true
end

function self:ResolveWait (timeout)
	if self:IsTerminated () then return true end
	
	timeout = timeout or math.huge
	
	local waitResolutionAbortionTime = SysTime () + timeout
	self.WaitResolutionAbortionTime = waitResolutionAbortionTime
	
	-- Ensure that this thread's state is set to Running.
	local resolutionSucceeded = true
	if self:IsSleeping () then
		if self.SleepEndTime > self.WaitResolutionAbortionTime then
			return false
		end
		resolutionSucceeded = self:ResolveSleep ()
	elseif self:IsWaiting () then
		resolutionSucceeded = self:ResolveWaits (timeout)
	end
	
	-- The sleep or wait didn't resolve fully, bail.
	if not resolutionSucceeded then
		self.WaitResolutionAbortionTime = math.huge
		return false
	end
	
	-- Unsuspend thread??
	if self:IsSuspended () then
		self:Resume ()
	end
	
	local canYieldTimeSlice = self:CanYieldTimeSlice ()
	self:SetYieldTimeSliceAllowed (false)
	self.ThreadRunner:RunThread (self)
	self:SetYieldTimeSliceAllowed (canYieldTimeSlice)
	
	if SysTime () > self.WaitResolutionAbortionTime then
		self.WaitResolutionAbortionTime = math.huge
		return false
	end
	
	self.WaitResolutionAbortionTime = math.huge
	if not self:IsTerminated () then
		GLib.Error ("Thread:WaitForSingleObject : Thread " .. self:GetName () .. " did not run until completion.")
		return false
	end
	
	return true
end

function self:WaitCallback (callback)
	if self:IsTerminated () then
		callback (GLib.Threading.WaitEndReason.Success)
	else
		self:AddEventListener ("Terminated",
			function ()
				callback (GLib.Threading.WaitEndReason.Success)
			end
		)
	end
end

-- Identity
function self:GetId ()
	return self:GetHashCode ()
end

function self:GetName ()
	return self.Name or self:GetId ()
end

function self:SetName (name)
	self.Name = name
	return self
end

function self:GetCoroutine ()
	return self.Coroutine
end

function self:GetEndTime ()
	return self.EndTime
end

function self:GetStartTime ()
	return self.StartTime
end

-- Thread
function self:GetThreadRunner ()
	return self.ThreadRunner
end

function self:IsMainThread ()
	return false
end

function self:SetThreadRunner (threadRunner)
	if self.ThreadRunner == threadRunner then return self end
	
	if self.ThreadRunner then
		self.ThreadRunner:RemoveThread (self)
	end
	
	self.ThreadRunner = threadRunner
	
	if self.ThreadRunner then
		self.ThreadRunner:AddThread (self)
	end
	
	return self
end

-- Thread local storage
function self:GetThreadLocalStorage ()
	self.ThreadLocalStorage = self.ThreadLocalStorage or {}
	return self.ThreadLocalStorage
end

function self:GetTLS ()
	self.ThreadLocalStorage = self.ThreadLocalStorage or {}
	return self.ThreadLocalStorage
end

-- ThreadRunner
function self:CheckSleep ()
	if not self:IsSleeping () then return end
	
	if SysTime () > self.SleepEndTime then
		self.SleepEndTime = 0
		self:SetState (GLib.Threading.ThreadState.Running)
	end
end

function self:CheckWait ()
	if not self:IsWaiting () then return end
	
	if SysTime () > self.WaitAbortionTime then
		self.WaitAbortionTime = 0
		self:AbortWait ()
	end
end

-- Thread control
function self:GetExecutionTime ()
	if not self:IsStarted () then return 0 end
	
	if self:IsTerminated () then
		return self.EndTime - self.StartTime
	end
	
	return SysTime () - self.StartTime
end

function self:GetState ()
	return self.State
end

function self:IsRunnable ()
	return not self.Suspended and self.State == GLib.Threading.ThreadState.Running
end

function self:IsRunning ()
	return GLib.Threading.CurrentThread == self
end

function self:IsSleeping ()
	return self.State == GLib.Threading.ThreadState.Sleeping
end

function self:IsStarted ()
	return self.State ~= GLib.Threading.ThreadState.Unstarted
end

function self:IsSuspended ()
	return self.Suspended
end

function self:IsTerminated ()
	return self.State == GLib.Threading.ThreadState.Terminated
end

function self:IsWaiting ()
	return self.State == GLib.Threading.ThreadState.Waiting
end

function self:Resume ()
	if not self:IsSuspended () then return self end
	
	self.Suspended = false
	
	self:DispatchEvent ("StateChanged", self.State, self.Suspended)
	
	return self
end

function self:Start (f, ...)
	if self.State ~= GLib.Threading.ThreadState.Unstarted then return self end
	
	self.ThreadRunner = self.ThreadRunner or GLib.Threading.ThreadRunner
	self.ThreadRunner:AddThread (self)
	
	self:SetState (GLib.Threading.ThreadState.Running)
	
	f = GLib.Curry (f, ...)
	
	self.Coroutine = coroutine.create (
		function ()
			self.StartTime = SysTime ()
			xpcall (f, GLib.Error)
			self:Terminate (true)
		end
	)
	
	return self
end

function self:Suspend ()
	if self:IsSuspended () then return self end
	
	self.Suspended = true
	
	self:DispatchEvent ("StateChanged", self.State, self.Suspended)
	
	return self
end

function self:Terminate (doNotYield)
	if self.State == GLib.Threading.ThreadState.Terminated then return self end
	
	if self:IsWaiting () then
		self:AbortWaits ()
	end
	
	self.EndTime = SysTime ()
	self:SetState (GLib.Threading.ThreadState.Terminated)
	
	if not doNotYield then
		self:Yield ()
	end
	
	return self
end

-- Sleeping
function self:Sleep (durationInMilliseconds)
	self.SleepEndTime = SysTime () + durationInMilliseconds * 0.001
	self:SetState (GLib.Threading.ThreadState.Sleeping)
	
	-- Yield if we're the running thread
	if self:IsRunning () then
		if GLib.Threading.CanYieldTimeSlice () then
			self:Yield ()
		else
			if durationInMilliseconds > 5000 then
				GLib.Error ("Thread:Sleep : Clamping sleep duration to 5 seconds.")
				self.SleepEndTime = SysTime () + 5
			end
			
			-- Attempt to carry out the sleep, but yield if we cannot complete it
			-- (our state should still be Sleeping)
			if not self:ResolveSleep () then
				self:Yield ()
			end
		end
	end
end

-- Waiting
function self:WaitForMultipleObjects (...)
	local objectsAndTimeout = {...}
	
	-- Timeout
	local timeout = math.huge
	if type (objectsAndTimeout [#objectsAndTimeout]) == "number" then
		timeout = objectsAndTimeout [#objectsAndTimeout] * 0.001
		objectsAndTimeout [#objectsAndTimeout] = nil
	end
	
	self.WaitAbortionTime = SysTime () + timeout
	
	-- A wait for 0 objects is over immediately
	if #objectsAndTimeout == 0 then return GLib.Threading.WaitEndReason.Success end
	
	self.WaitEndReason = GLib.Threading.WaitEndReason.Success
	
	self:SetState (GLib.Threading.ThreadState.Waiting)
	for _, waitable in ipairs (objectsAndTimeout) do
		self.WaitObjects [waitable] = true
		waitable:Wait (
			function (waitEndReason)
				-- Check that this object is still part of the wait
				if not self.WaitObjects [waitable] then return end
				
				self.WaitObjects [waitable] = nil
				if next (self.WaitObjects) == nil then
					self:SetState (GLib.Threading.ThreadState.Running)
					
					if not GLib.Threading.ThreadRunner:IsCurrentThread (self) then
						GLib.Threading.ThreadRunner:RunThread (self)
					end
				end
			end
		)
	end
	
	
	if self:IsRunning () and not self:IsRunnable () then
		if GLib.Threading.CanYieldTimeSlice () then
			self:Yield ()
		else
			-- Attempt to resolve the waits, but yield if we cannot complete it
			-- (our state should still be Waiting)
			if not self:ResolveWaits (self.WaitResolutionAbortionTime - SysTime ()) then
				self:Yield ()
			end
		end
	end
	
	return self.WaitEndReason
end

function self:WaitForSingleObject (waitable, timeoutInMilliseconds)
	return self:WaitForMultipleObjects (waitable, timeoutInMilliseconds)
end

-- Cooperative threading
function self:CanYield ()
	return true
end

function self:CanYieldTimeSlice ()
	return self.YieldTimeSliceAllowed
end

function self:CheckYield ()
	if not self:IsRunning () then return false end
	
	local t = SysTime ()
	
	if t > self.WaitResolutionAbortionTime and
	   self:CanYield () then
		-- We're currently being resolved, but we've exceeded the timeout.
		-- So we yield.
		self:Yield ()
		return true
	elseif self:CanYieldTimeSlice () and
	   t > self.ThreadRunner:GetExecutionSliceEndTime () then
		self:Yield ()
		return true
	end
	
	return false
end

function self:SetYieldTimeSliceAllowed (yieldTimeSliceAllowed)
	if yieldTimeSliceAllowed == nil then
		yieldTimeSliceAllowed = true
	end
	
	self.YieldTimeSliceAllowed = yieldTimeSliceAllowed
	return self
end

function self:Yield ()
	if not self:IsRunning () then return end
	if not self:CanYield () then
		GLib.Error ("Thread:Yield : Thread " .. self:GetName () .. " is not able to yield.")
		return
	end
	
	return coroutine.yield ()
end

-- Internal, do not call
function self:AbortWait ()
	if not self:IsWaiting () then return end
	
	for waitable, _ in pairs (self.WaitObjects) do
		self.WaitObjects [waitable] = nil
	end
	
	self.WaitEndReason = GLib.Threading.WaitEndReason.Timeout
	self:SetState (GLib.Threading.ThreadState.Running)
end

function self:SetState (state)
	self.State = state
	self:DispatchEvent ("StateChanged", self.State, self.Suspended)
end

-- Wait resolution
function self:ResolveSleep ()
	local abortionTime = math.min (self.WaitResolutionAbortionTime, self.SleepEndTime)
	local abortionTimeDueToSleepEnd = self.SleepEndTime <= self.WaitResolutionAbortionTime
	while SysTime () < abortionTime do end
	
	if abortionTimeDueToSleepEnd then
		self:SetState (GLib.Threading.ThreadState.Running)
	end
	
	return abortionTimeDueToSleepEnd
end

function self:ResolveWaits ()
	local resolutionSucceeded = true
	
	-- Also need to take into account WaitAbortionTime
	-- self.WaitAbortionTime <= self.WaitResolutionAbortionTime
	--     The resolution will never fail, but the wait will.
	-- self.WaitAbortionTime > self.WaitResolutionAbortionTime
	--     The resolution will fail before the wait aborts.
	local abortionTime = math.min (self.WaitResolutionAbortionTime, self.WaitAbortionTime)
	local abortionTimeDueToWaitTimeout = self.WaitAbortionTime <= self.WaitResolutionAbortionTime
	
	for waitable, _ in pairs (self.WaitObjects) do
		if SysTime () > abortionTime then
			-- Mark this thread's wait as aborted if we've overrun the wait timeout.
			if abortionTimeDueToWaitTimeout then
				self:AbortWait ()
			end
			resolutionSucceeded = false
			break
		end
		
		-- These IWaitables better be resolvable.
		if waitable:IsResolvableWaitable () then
			resolutionSucceeded = resolutionSucceeded and waitable:ResolveWait (abortionTime - SysTime ())
		else
			GLib.Error ("Thread:ResolveWaits : Thread " .. self:GetName () .. " cannot resolve its wait.")
			resolutionSucceeded = false
		end
	end
	
	-- Mark this thread's wait as aborted if a resolution failed and we've overrun the wait timeout.
	if not resolutionSucceeded and
	   SysTime () > abortionTime and
	   abortionTimeDueToWaitTimeout then
		self:AbortWait ()
	end
	
	return resolutionSucceeded or abortionTimeDueToWaitTimeout
end