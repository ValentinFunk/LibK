local self = {}
GLib.Threading.Thread = GLib.MakeConstructor (self)

function self:ctor ()
	self.Coroutine = nil
	
	self.State = GLib.Threading.ThreadState.Unstarted
	self.Waiting   = false
	self.Suspended = false
	
	self.StartTime = 0
	self.EndTime   = 0
	
	GLib.EventProvider (self)
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

function self:IsSuspended ()
	return self.Suspended
end

function self:IsWaiting ()
	return self.Waiting
end

function self:Resume ()
	self.Suspended = false
end

function self:Start (f, ...)
	if self.State ~= GLib.Threading.ThreadState.Unstarted then return end
	
	self.State = GLib.Threading.ThreadState.Running
	
	GLib.Threading.Threads [self] = true
	
	f = GLib.Curry (f, ...)
	
	self.Coroutine = coroutine.create (
		function ()
			self.StartTime = SysTime ()
			f ()
			self:Terminate ()
		end
	)
end

function self:Suspend ()
	self.Suspended = true
end

function self:Terminate ()
	if self.State == GLib.Threading.ThreadState.Stopped then return end
	
	self.EndTime = SysTime ()
	GLib.Threading.Threads [self] = nil
	self.State = GLib.Threading.ThreadState.Stopped
end