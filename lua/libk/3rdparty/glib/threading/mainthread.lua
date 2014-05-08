local self = {}
GLib.Threading.MainThread = GLib.MakeConstructor (self, GLib.Threading.Thread)

function self:ctor ()
	self:SetName ("Main")
	self:SetState (GLib.Threading.ThreadState.Running)
	self:SetYieldTimeSliceAllowed (false)
end

-- Thread
function self:IsMainThread ()
	return true
end

-- Thread control
function self:Suspend ()
end

function self:Start (f, ...)
end

function self:Terminate ()
	GLib.Error ("MainThread:Terminate : You can't stop the signal.")
end

-- Waits
function self:Wait (callback)
	GLib.Error ("MainThread:Wait : This method should never be called.")
	
	if callback then
		callback (GLib.Threading.WaitEndReason.Success)
	end
	
	return
end

-- IWaitable
function self:IsResolvableWaitable ()
	return false
end

-- Cooperative threading
function self:CanYield ()
	return false
end

function self:CanYieldTimeSlice ()
	return false
end

function self:CheckYield ()
	return false
end

function self:Yield ()
	GLib.Error ("MainThread:Yield : This method should never be called.")
end

GLib.Threading.MainThread = GLib.Threading.MainThread ()