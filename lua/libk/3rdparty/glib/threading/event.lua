local self = {}
GLib.Threading.Event = GLib.MakeConstructor (self, GLib.Threading.IWaitable)

function self:ctor ()
	self.AutoReset = true
	self.Fired     = false
	
	self.Waiters   = {}
end

function self:Fire ()
	if self:IsFired () then return end
	
	if not self:IsResetAutomatically () then
		self.Fired = true
	end
	
	local waiters = self.Waiters
	self.Waiters = {}
	
	for _, callback in pairs (waiters) do
		callback (GLib.Threading.WaitEndReason.Success)
	end
end

function self:IsFired ()
	return self.Fired
end

function self:IsResetAutomatically ()
	return self.AutoReset
end

function self:Reset ()
	self.Fired = false
end

function self:SetAutoReset (autoReset)
	if self.AutoReset == autoReset then return self end
	
	self.AutoReset = autoReset
	
	if self.AutoReset and self.Fired then
		self.Fired = false
	end
	
	return self
end

function self:WaitCallback (callback)
	if self:IsFired () then
		callback (GLib.Threading.WaitEndReason.Success)
		return
	end
	
	self.Waiters [#self.Waiters + 1] = callback
end