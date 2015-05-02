local self = {}
GLib.Threading.ThreadRunner = GLib.MakeConstructor (self)

function self:ctor ()
	self.Threads = {}
	self.RunnableThreads = {}
	self.SleepingWaitingThreads = {}
	
	self.CurrentThreadStackSet = {}
	self.CurrentThreadStack    = {}
	self.CurrentThread = nil
	
	self:SetCurrentThread (GLib.Threading.MainThread)
	
	self.ExecutionSliceEndTime = 0
	
	hook.Add ("Think", "GLib.Threading",
		function ()
			self.ExecutionSliceEndTime = SysTime () + 0.005
			
			for thread, _ in pairs (self.SleepingWaitingThreads) do
				if thread:IsSleeping () then
					thread:CheckSleep ()
				else
					thread:CheckWait ()
				end
			end
			
			for thread, _ in pairs (self.RunnableThreads) do
				if SysTime () > self.ExecutionSliceEndTime then
					break
				end
				
				self:SetCurrentThread (thread)
				
				thread:DispatchEvent ("ExecutionSliceStarted")
				
				local success, error = coroutine.resume (thread:GetCoroutine ())
				if not success then
					self:SetCurrentThread (GLib.Threading.MainThread)
					
					thread:Terminate ()
					ErrorNoHalt ("GLib.Threading.ThreadRunner: Thread " .. thread:GetName () .. " (terminated): " .. error .. "\n")
				end
				
				thread:DispatchEvent ("ExecutionSliceEnded")
				
				if thread:IsTerminated () then
					thread:DispatchEvent ("Terminated")
				end
			end
			
			self:SetCurrentThread (GLib.Threading.MainThread)
			self.ExecutionSliceEndTime = SysTime () + 0.005
		end
	)
	
	GLib:AddEventListener ("Unloaded", "GLib.Threading",
		function ()
			self:dtor ()
		end
	)
end

function self:dtor ()
	hook.Remove ("Think", "GLib.Threading")
end

-- Threads
function self:AddThread (thread)
	if thread:IsTerminated () then return end
	
	if thread:IsMainThread () then
		thread:SetThreadRunner (self)
		return
	end
	
	self.Threads [thread] = thread
	
	if thread:IsRunnable () then
		self.RunnableThreads [thread] = true
	elseif thread:IsSleeping () or thread:IsWaiting () then
		self.SleepingWaitingThreads [thread] = true
	end
	
	self:HookThread (thread)
end

function self:RemoveThread (thread)
	self.Threads [thread] = nil
	self.RunnableThreads [thread] = nil
	self.SleepingWaitingThreads [thread] = nil
	
	self:UnhookThread (thread)
end

-- Execution
function self:GetCurrentThread ()
	return self.CurrentThread
end

function self:GetExecutionSliceEndTime ()
	return self.ExecutionSliceEndTime
end

function self:IsCurrentThread (thread)
	if self.CurrentThreadStackSet [thread] then return true end
	if self.CurrentThread == thread   then return true end
	return false
end

function self:RunThread (thread)
	if not thread:IsRunnable () then return end
	if thread:IsMainThread () then return end
	if self:IsCurrentThread (thread) then
		GLib.Error ("ThreadRunner:RunThread : This IS the thread that's currently executing, what are you doing?")
		return
	end
	
	self.ExecutionSliceEndTime = SysTime () + 0.005
	
	self:PushCurrentThread (thread)
	
	thread:DispatchEvent ("ExecutionSliceStarted")
	
	local success, error = coroutine.resume (thread:GetCoroutine ())
	self:PopCurrentThread ()
	
	if not success then
		ErrorNoHalt ("GLib.Threading.ThreadRunner: Thread " .. thread:GetName () .. " (terminated): " .. error .. "\n")
		thread:Terminate ()
	end
	
	thread:DispatchEvent ("ExecutionSliceEnded")
	
	if thread:IsTerminated () then
		thread:DispatchEvent ("Terminated")
	end
end

-- Internal, do not call
function self:PopCurrentThread ()
	local currentThread = self.CurrentThread
	
	self:SetCurrentThread (self.CurrentThreadStack [#self.CurrentThreadStack])
	self.CurrentThreadStackSet [self.CurrentThreadStack [#self.CurrentThreadStack]] = nil
	self.CurrentThreadStack [#self.CurrentThreadStack] = nil
	
	return currentThread
end
function self:PushCurrentThread (thread)
	self.CurrentThreadStackSet [self.CurrentThread] = true
	self.CurrentThreadStack [#self.CurrentThreadStack + 1] = self.CurrentThread
	self:SetCurrentThread (thread)
end

function self:SetCurrentThread (thread)
	if self.CurrentThread == thread then return end
	
	self.CurrentThread = thread
	GLib.Threading.CurrentThread = self.CurrentThread
	GLib.CurrentThread = self.CurrentThread
end

function self:HookThread (thread)
	if not thread then return end
	
	thread:AddEventListener ("StateChanged", self:GetHashCode (),
		function (_, state, suspended)
			if thread:IsRunnable () then
				self.RunnableThreads [thread] = true
				self.SleepingWaitingThreads [thread] = nil
			else
				self.RunnableThreads [thread] = nil
				if thread:IsSleeping () or thread:IsWaiting () then
					self.SleepingWaitingThreads [thread] = true
				end
			end
			
			if thread:IsTerminated () then
				self:RemoveThread (thread)
			end
		end
	)
end

function self:UnhookThread (thread)
	if not thread then return end
	
	thread:RemoveEventListener ("StateChanged", self:GetHashCode())
end

GLib.Threading.ThreadRunner = GLib.Threading.ThreadRunner ()