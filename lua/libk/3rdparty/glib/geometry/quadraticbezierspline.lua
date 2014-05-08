local self = {}
GLib.Geometry.QuadraticBezierSpline = GLib.MakeConstructor (self, GLib.Geometry.BezierSpline)

GLib.Geometry.QuadraticBezierMatrix = GLib.Matrix (3, 3,
	 1, -2,  1,
	-2,  2,  0,
	 1,  0,  0
)

function self:ctor (dimensions)
	self.BezierMatrix = GLib.Geometry.QuadraticBezierMatrix
end

function self:GetDegree ()
	return 2
end