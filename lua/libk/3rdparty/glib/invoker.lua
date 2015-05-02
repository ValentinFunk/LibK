local self = {}
GLib.Invoker = GLib.MakeConstructor (self, GLib.Event)

function self:ctor ()
end

function self:dtor ()
	self:Clear ()
end

function self:AddDestructor (nameOrObject, object)
	object = object or nameOrObject
	self:AddListener (nameOrObject,
		function ()
			object:dtor ()
		end
	)
	return self
end

function self:AddFunction (nameOrCallback, callback)
	self:AddListener (nameOrCallback, callback)
	return self
end

function self:AddThreadAbortion (nameOrThread, thread)
	thread = thread or nameOrThread
	self:AddListener (nameOrThread,
		function ()
			thread:Terminate ()
		end
	)
	return self
end

function self:Clear ()
	self:ClearListeners ()
end

function self:Invoke (...)
	return self:Dispatch (...)
end

function self:Remove (nameOrCallback)
	self:RemoveListener (nameOrCallback)
end