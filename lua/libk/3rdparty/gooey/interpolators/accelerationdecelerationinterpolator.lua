local self = {}
Gooey.AccelerationDecelerationInterpolator = Gooey.MakeConstructor (self, Gooey.NormalizedTimeInterpolator)

function self:ctor ()
end

function self:GetValue (t)
	if t < 0 then return self:GetInitialValue () end
	if t > 1 then return self:GetFinalValue () end
	return t - math.sin (2 * math.pi * t) / (2 * math.pi)
end