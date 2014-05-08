local self = {}
GLib.Geometry.ParametricCurveRenderer = GLib.MakeConstructor (self)

function self:ctor ()
	self.ParameterVectors = {}
	self.ParameterTangentVectors = {}
end

function self:GetParameterVector (degree, t)
	self.ParameterVectors [degree] = GLib.Geometry.CreateParameterVector (degree, t, self.ParameterVectors [degree])
	return self.ParameterVectors [degree]
end

function self:GetParameterTangentVector (degree, t)
	self.ParameterTangentVectors [degree] = GLib.Geometry.CreateParameterTangentVector (degree, t, self.ParameterTangentVectors [degree])
	return self.ParameterTangentVectors [degree]
end

function self:Render (parametricCurve, lineSink)
	local range = parametricCurve:GetParameterMaximum () - parametricCurve:GetParameterMinimum ()
	local interval = range / 100
	
	local degree = parametricCurve:GetDegree ()
	
	local lastPoint = parametricCurve:Evaluate (self:GetParameterVector (degree, parametricCurve:GetParameterMinimum ()))
	local currentPoint
	for t = parametricCurve:GetParameterMinimum () + interval, parametricCurve:GetParameterMaximum (), interval do
		currentPoint = parametricCurve:Evaluate (self:GetParameterVector (degree, t), currentPoint)
		currentPoint:Clone (v2)
		
		lineSink (lastPoint, currentPoint)
		
		local temp = lastPoint
		lastPoint = currentPoint
		currentPoint = temp
	end
end