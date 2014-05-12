local self = {}
Gooey.TickProvider = Gooey.MakeConstructor (self)

--[[
	Events:
		Tick ()
			Fired when a tick has occurred.
]]

function self:ctor ()
	Gooey.EventProvider (self)
end

function self:Tick ()
	self:DispatchEvent ("Tick")
end