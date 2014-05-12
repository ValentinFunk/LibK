local self = {}
Gooey.LinearInterpolator = Gooey.MakeConstructor (self, Gooey.NormalizedTimeInterpolator)

function self:ctor ()
end

function self:GetValue (t)
	if t < 0 then return self:GetInitialValue () end
	if t > 1 then return self:GetFinalValue () end
	return t
end