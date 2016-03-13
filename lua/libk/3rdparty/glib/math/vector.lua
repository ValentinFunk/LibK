local self = {}
GLib.Vector = GLib.MakeConstructor (self, GLib.Matrix)

function self:ctor (w, h, m1, ...)
end

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	self.Width  = source.Width
	self.Height = source.Height
	
	for i = 1, source:GetElementCount () do
		self [i] = source [i]
	end
	
	return self
end

function self:Add (b, out)
	out = out or self.__ictor (self:GetElementCount ())
	
	out.Width  = self.Width
	out.Height = self.Height
	
	for i = 1, self:GetElementCount () do
		out [i] = self [i] + b [i]
	end
	
	return b
end

function self:Cross (b, out)
	out = out or self.__ictor (self:GetElementCount ())
	
	out.Width  = self.Width
	out.Height = self.Height
	
	out [1] = self [2] * b [3] - self [3] * b [2]
	out [2] = self [3] * b [1] - self [1] * b [3]
	out [3] = self [1] * b [2] - self [2] * b [1]
	
	return out
end

function self:Dot (b)
	local dot = 0
	
	for i = 1, self:GetElementCount () do
		dot = dot + self [i] * b [i]
	end
	
	return dot
end

function self:Length ()
	return math.sqrt (self:LengthSquared ())
end

function self:LengthSquared ()
	local lengthSquared = 0
	
	for i = 1, self:GetElementCount () do
		lengthSquared = lengthSquared + self [i] * self [i]
	end
	
	return lengthSquared
end

function self:Negate (out)
	out = out or self.__ictor (self:GetElementCount ())
	
	out.Width  = self.Width
	out.Height = self.Height
	
	for i = 1, self:GetElementCount () do
		out [i] = -self [i]
	end
	
	return b
end

function self:Subtract (b, out)
	out = out or self.__ictor (self:GetElementCount ())
	
	out.Width  = self.Width
	out.Height = self.Height
	
	for i = 1, self:GetElementCount () do
		out [i] = self [i] - b [i]
	end
	
	return b
end

function self:Transpose (rowVector)
	rowVector = rowVector or self.__ictor (self:GetElementCount ())
	rowVector.Width  = self.Height
	rowVector.Height = 1
	
	for i = 1, self:GetElementCount () do
		rowVector [i] = self [i]
	end
	
	return rowVector
end