local self = {}
GLib.IDisposable = GLib.MakeConstructor (self)

--[[
	Events:
		Disposed ()
			Fired when this object has been disposed.
]]

function self:ctor ()
	self.Disposed = false
end

function self:dtor ()
	self:Dispose ()
end

function self:Dispose ()
	if self:IsDisposed () then return end
	
	self.Disposed = true
	
	if self.DispatchEvent then
		self:DispatchEvent ("Disposed")
	end
	
	self:dtor ()
end

function self:IsDisposed ()
	return self.Disposed
end

function self:IsValid ()
	return not self.Disposed
end