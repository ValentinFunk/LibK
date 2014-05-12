local self = {}
Gooey.NormalizedTimeInterpolator = Gooey.MakeConstructor (self, Gooey.TimeInterpolator)

function self:ctor ()
end

function self:GetDuration ()
	return 1
end

function self:GetFinalValue ()
	return 1
end

function self:GetInitialValue ()
	return 0
end

function self:GetValue (t)
	return 0
end