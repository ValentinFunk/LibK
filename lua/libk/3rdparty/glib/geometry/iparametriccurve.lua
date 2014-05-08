local self = {}
GLib.Geometry.IParametricCurve = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:Evaluate (t, out)
	GLib.Error ("IParametricCurve:Evaluate : Not implemented.")
end

function self:GetDegree ()
	GLib.Error ("IParametricCurve:GetDegree : Not implemented.")
	return 2
end

function self:GetParameterMinimum ()
	return 0
end

function self:GetParameterMaximum ()
	return 1
end

function self:GetParameterRange ()
	return self:GetParameterMinimum (), self:GetParameterMaximum ()
end