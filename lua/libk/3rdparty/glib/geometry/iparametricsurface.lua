local self = {}
GLib.Geometry.IParametricSurface = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:Evaluate (t1, t2, out)
	GLib.Error ("IParametricSurface:Evaluate : Not implemented.")
end

function self:GetDegree ()
	GLib.Error ("IParametricCurve:GetDegree : Not implemented.")
	return 2
end

function self:GetParameter1Minimum ()
	return 0
end

function self:GetParameter1Maximum ()
	return 1
end

function self:GetParameter2Minimum ()
	return 0
end

function self:GetParameter2Maximum ()
	return 1
end

function self:GetParameter1Range ()
	return self:GetParameter1Minimum (), self:GetParameter1Maximum ()
end

function self:GetParameter2Range ()
	return self:GetParameter2Minimum (), self:GetParameter2Maximum ()
end