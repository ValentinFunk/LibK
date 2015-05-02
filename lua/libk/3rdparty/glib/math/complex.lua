local self = {}
GLib.Complex = GLib.MakeConstructor (self)

function GLib.Complex.Add (r1, i1, r2, i2)
	return r1 + r2, i1 + i1
end

function GLib.Complex.Conjugate (r, i)
	return r, -i
end

function GLib.Complex.FromPolar (r, theta)
	return r * math.cos (theta),
	       r * math.sin (theta)
end

function GLib.Complex.Multiply (r1, i1, r2, i2)
	return r1 * r2 - i1 * i2,
	       i1 * r2 + i2 * r1
end

function self:ctor (r, i)
	self [1] = r or 0
	self [2] = i or 0
end

function self:Add (b, out)
	if isnumber (b) then
		return self:RealAdd (b, out)
	else
		return self:ComplexAdd (b, out)
	end
end

function self:Subtract (b, out)
	if isnumber (b) then
		return self:RealSubtract (b, out)
	else
		return self:ComplexSubtract (b, out)
	end
end

function self:Arg ()
	return math.atan2 (self [2], self [1])
end

function self:ComplexAdd (b, out)
	out = out or GLib.Complex (0, 0)
	
	out [1] = self [1] + b [1]
	out [2] = self [2] + b [2]
	
	return out
end

function self:ComplexDivide (b, out)
	out = out or GLib.Complex (0, 0)
	
	local r1     = self:Magnitude ()
	local theta1 = self:Arg ()
	local r2     = b:Magnitude ()
	local theta2 = b:Arg ()
	
	local r     = r1 / r2
	local theta = theta1 - theta2
	
	out [1] = r * math.cos (theta)
	out [2] = r * math.sin (theta)
	
	return out
end

function self:ComplexExponentiate (b, out)
	out = out or GLib.Complex (0, 0)
	
	local r = self:Magnitude ()
	local theta = self:Arg ()
	
	-- c1 ^ c2 = (r exp (i theta)) ^ (a + bi)
	--         = r ^ (a + bi) exp (i theta (a + bi))
	--         = r^a r^bi exp (i a theta) exp (-b theta)
	--         = r^a exp (i b ln r) exp (i a theta) exp (-b theta)
	--         = r^a exp (-b theta) exp (i (b ln r + a theta))
	
	local r1     = r ^ b [1] * math.exp (-b [2] * theta)
	local theta1 = b [2] * math.log (r) + b [1] * theta
	
	out [1] = r1 * math.cos (theta1)
	out [2] = r1 * math.sin (theta1)
	
	return out
end

function self:ComplexMultiply (b, out)
	if out == self then out = nil end
	if out == b    then out = nil end
	
	out = out or GLib.Complex (0, 0)
	
	out [1] = self [1] * b [1] - self [2] * b [2]
	out [2] = self [1] * b [2] + self [2] * b [1]
	
	return out
end

function self:ComplexSubtract (b, out)
	out = out or GLib.Complex (0, 0)
	
	out [1] = self [1] - b [1]
	out [2] = self [2] - b [2]
	
	return out
end

function self:Conjugate (out)
	out = out or GLib.Complex (0, 0)
	
	out [1] =  self [1]
	out [2] = -self [2]
	
	return out
end

function self:Divide (b, out)
	if isnumber (b) then
		return self:RealDivide (b, out)
	else
		return self:ComplexDivide (b, out)
	end
end

function self:Exponentiate (b, out)
	if isnumber (b, out) then
		return self:RealExponentiate (b, out)
	else
		return self:ComplexExponentiate (b, out)
	end
end

function self:Magnitude ()
	return math.sqrt (self [1] * self [1] + self [2] * self [2])
end

function self:MagnitudeSquared ()
	return self [1] * self [1] + self [2] * self [2]
end
self.Abs           = self.Magnitude
self.Length        = self.Magnitude
self.LengthSquared = self.MagnitudeSquared

function self:Multiply (b, out)
	if isnumber (b) then
		return self:RealMultiply (b, out)
	else
		return self:ComplexMultiply (b, out)
	end
end

function self:Negate (out)
	out = out or GLib.Complex (0, 0)
	
	out [1] = -self [1]
	out [2] = -self [2]
	
	return out
end

function self:RealAdd (b, out)
	out = out or GLib.Complex (0, 0)
	
	out [1] = self [1] + b
	out [2] = self [2]
	
	return out
end

function self:RealDivide (b, out)
	out = out or GLib.Complex (0, 0)
	
	out [1] = self [1] / b
	out [2] = self [2] / b
	
	return out
end

function self:RealExponentiate (b, out)
	out = out or GLib.Complex (0, 0)
	
	local r = self:Magnitude ()
	local theta = self:Arg ()
	
	-- (r exp (i theta)) ^ k = r^k exp (i k theta)
	r = r ^ b
	theta = b * theta
	
	out [1] = r * math.cos (theta)
	out [2] = r * math.sin (theta)
	
	return out
end

function self:RealMultiply (b, out)
	out = out or GLib.Complex (0, 0)
	
	out [1] = self [1] * b
	out [2] = self [2] * b
	
	return out
end

function self:RealSubtract (b, out)
	out = out or GLib.Complex (0, 0)
	
	out [1] = self [1] - b
	out [2] = self [2]
	
	return out
end

function self:ToString ()
	local a = self [1]
	local b = self [2]
	a = tostring (a)
	if math.abs (b) == 1 then
		b = ""
	else
		b = tostring (math.abs (b))
	end
	
	if self [2] < 0 or 1 / self [2] < 0 then
		return a .. " - " .. b .. "i"
	end
	return a .. " + " .. b .. "i"
end

self.__add = function (a, b)
	if isnumber (a) then return b:Add (a) end
	return a:Add (b)
end

self.__sub = function (a, b)
	if isnumber (a) then
		return GLib.Complex (a - b [1], -b [2])
	end
	return a:Subtract (b)
end

self.__mul = function (a, b)
	if isnumber (a) then return b:Multiply (a) end
	return a:Multiply (b)
end

self.__div = function (a, b)
	if isnumber (a) then a = GLib.Complex (a) end
	return a:Divide (b)
end

self.__pow = function (a, b)
	if isnumber (a) then a = GLib.Complex (a) end
	return a:Exponentiate (b)
end

self.__unm = self.Negate

self.__tostring = self.ToString