local self = {}
GLib.Geometry.BezierSpline = GLib.MakeConstructor (self, GLib.Geometry.IParametricCurve)

function self:ctor (dimensions)
	dimensions = dimensions or 3
	
	self.Dimensions = dimensions
	
	self.BezierMatrix = nil
	self.GeometryMatrix = GLib.Matrix (self.Dimensions, self:GetDegree () + 1)
	
	self.CMatrix = GLib.Matrix (self:GetDegree () + 1, self:GetDegree () + 1)
	self.CMatrixValid = false
end

function self:GetCMatrix ()
	if not self.CMatrixValid then
		self.BezierMatrix:Multiply (self.GeometryMatrix, self.CMatrix)
		self.CMatrixValid = true
	end
	
	return self.CMatrix
end

function self:GetControlPoint (i, out)
	out = out or GLib.RowVector (self:GetDimensions ())
	
	return self.GeometryMatrix:GetRow (i, out)
end

function self:GetDimensions ()
	return self.Dimensions
end

function self:SetControlPoint (i, vector)
	self.GeometryMatrix:SetRow (i, vector)
	self.CMatrixValid = false
end

function self:Evaluate (t, out)
	if type (t) ~= "table" then
		t = GLib.Geometry.CreateParameterVector (self:GetDegree (), t, out)
	end
	
	out = out or GLib.RowVector ()
	return t:Multiply (self:GetCMatrix (), out)
end

function self:EvaluateTangent (t, out)
	if type (t) ~= "table" then
		t = GLib.Geometry.CreateParameterTangentVector (self:GetDegree (), t, out)
	end
	
	out = out or GLib.RowVector ()
	return t:Multiply (self:GetCMatrix (), out)
end