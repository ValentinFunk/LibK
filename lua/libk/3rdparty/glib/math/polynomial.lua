local self = {}
GLib.Polynomial = GLib.MakeConstructor (self)

local emptyTable = {}

function self:ctor (degree, c0, ...)
	self.Degree = degree
	
	local coefficients = c0 and { c0, ... } or emptyTable
	for i = 0, self.Degree do
		self [i] = coefficients [i + 1] or 0
	end
end

function self:Coefficient (power)
	return self [power]
end

function self:Evaluate (x)
	local y = 0
	local t = 1
	for i = 0, self.Degree do
		y = y + self [i] * t
		t = t * x
	end
	
	return y
end

function self:Roots ()
	if self.Degree == 0 then
		return
	elseif self.Degree == 1 then
		-- c1 x + c0 = 0
		-- c1 x = -c0
		-- x = - c0 / c1
		return -self [0] / self [1]
	elseif self.Degree == 2 then
		-- c2 x^2 + c1 x + c0 = 0
		-- x = -c1 +/- sqrt (c1^2 - 4 c0 c2)
		--     -----------------------------
		--                2 c2
		
		local discriminant = self [1] * self [1] - 4 * self [0] * self [2]
		local rootDiscriminant = discriminant < 0 and (GLib.Complex (discriminant) ^ 0.5) or math.sqrt (discriminant)
		return (-self [1] + rootDiscriminant) / (2 * self [2]), (-self [1] - rootDiscriminant) / (2 * self [2])
	elseif self.Degree == 3 then
		-- ax³ + bx² + cx + d = 0
		-- x_k = - 1 / 3a * (b + u_k C + Δ_0 / (u_k C))
		-- C = cbrt ((Δ_1 + sqrt (Δ_1² - 4 Δ_0³)) / 2)
		-- Δ_0 = b² - 3ac
		-- Δ_1 = 2b³ - 9abc + 27a² d
		
		local a = self [3]
		local b = self [2]
		local c = self [1]
		local d = self [0]
		
		local D0 = b ^ 2 - 3 * a * c
		local D1 = 2 * b ^ 3 - 9 * a * b * c + 27 * a ^ 2 * d
		
		local C = GLib.Complex ((D1 + math.sqrt (D1 ^ 2 - 4 * D0 ^ 3)) / 2) ^ (1 / 3)
		
		local u1 = 1
		local u2 = GLib.Complex (-1 / 2,  math.sqrt (3) / 2)
		local u3 = GLib.Complex (-1 / 2, -math.sqrt (3) / 2)
		
		local x1 = -1 / (3 * a) * (b + u1 * C + D0 / (u1 * C))
		local x2 = -1 / (3 * a) * (b + u2 * C + D0 / (u2 * C))
		local x3 = -1 / (3 * a) * (b + u3 * C + D0 / (u3 * C))
		
		return x1, x2, x3
	else
		GLib.Error ("Polynomial:Roots : Not implemented for degree " .. tostring (self.Degree) .. "!")
	end
end

local superscripts =
{
	["0"] = "⁰",
	["1"] = "¹",
	["2"] = "²",
	["3"] = "³",
	["4"] = "⁴",
	["5"] = "⁵",
	["6"] = "⁶",
	["7"] = "⁷",
	["8"] = "⁸",
	["9"] = "⁹"
}
function self:ToString ()
	local polynomial = ""
	for i = self.Degree, 0, -1 do
		local coefficient = self [i]
		if coefficient ~= 1 then
			if coefficient < 0 or 1 / coefficient < 0 then
				coefficient = -coefficient
				if i == self.Degree then
					polynomial = polynomial .. "-"
				else
					polynomial = polynomial .. " - "
				end
			elseif i ~= self.Degree then
				polynomial = polynomial .. " + "
			end
			polynomial = polynomial .. tostring (coefficient)
		end
		
		if i == 0 then
		elseif i == 1 then
			polynomial = polynomial .. "x"
		else
			local exponent = tostring (i)
			polynomial = polynomial .. "x"
			for i = 1, #exponent do
				polynomial = polynomial .. superscripts [string.sub (exponent, i, i)] or string.sub (exponent, i, i)
			end
		end
	end
	
	return polynomial
end

self.__call     = self.Evaluate
self.__tostring = self.ToString