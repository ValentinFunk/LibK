local self = {}
local ctor = GLib.MakeConstructor (self, GLib.Vector)

function GLib.ColumnVector (h, ...)
	return ctor (1, h, ...)
end

function self:SetElementCount (elementCount)
	self.Height = elementCount
end