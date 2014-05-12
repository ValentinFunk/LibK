local self = {}
Gooey.TimeInterpolator = Gooey.MakeConstructor (self)

function self:ctor ()
end

function self:GetDuration ()
	return 0
end

function self:GetFinalValue ()
	return 0
end

function self:GetInitialValue ()
	return 0
end

function self:GetValue (t)
	return 0
end