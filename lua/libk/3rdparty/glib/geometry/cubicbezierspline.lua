local self = {}
GLib.Geometry.CubicBezierSpline = GLib.MakeConstructor (self, GLib.Geometry.BezierSpline)

GLib.Geometry.CubicBezierMatrix = GLib.Matrix (4, 4,
	-1,  3, -3,  1,
	 3, -6,  3,  0,
	-3,  3,  0,  0,
	 1,  0,  0,  0
)

function self:ctor (dimensions)
	self.BezierMatrix = GLib.Geometry.CubicBezierMatrix
end

function self:GetDegree ()
	return 3
end