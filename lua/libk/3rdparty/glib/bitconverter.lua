GLib.BitConverter = {}

function GLib.BitConverter.FloatToUInt32 (f)
	-- 1 / f is needed to check for -0
	local n = 0
	if f < 0 or 1 / f < 0 then
		n = n + 0x80000000
		f = -f
	end
	
	local mantissa = 0
	local biasedExponent = 0
	
	if f == math.huge then
		biasedExponent = 0xFF
	elseif f ~= f then
		biasedExponent = 0xFF
		mantissa = 1
	elseif f == 0 then
		biasedExponent = 0x00
	else
		mantissa, biasedExponent = math.frexp (f)
		biasedExponent = biasedExponent + 126
		
		if biasedExponent <= 0 then
			-- Denormal
			mantissa = math.floor (mantissa * 2 ^ (23 + biasedExponent) + 0.5)
			biasedExponent = 0
		else
			mantissa = math.floor ((mantissa * 2 - 1) * 2 ^ 23 + 0.5)
		end
	end
	
	n = n + bit.lshift (bit.band (biasedExponent, 0xFF), 23)
	n = n + bit.band (mantissa, 0x007FFFFF)
	
	return n
end

function GLib.BitConverter.DoubleToUInt32s (f)
	-- 1 / f is needed to check for -0
	local high = 0
	local low = 0
	if f < 0 or 1 / f < 0 then
		high = high + 0x80000000
		f = -f
	end
	
	local mantissa = 0
	local biasedExponent = 0
	
	if f == math.huge then
		biasedExponent = 0x07FF
	elseif f ~= f then
		biasedExponent = 0x07FF
		mantissa = 1
	elseif f == 0 then
		biasedExponent = 0x00
	else
		mantissa, biasedExponent = math.frexp (f)
		biasedExponent = biasedExponent + 1022
		
		if biasedExponent <= 0 then
			-- Denormal
			mantissa = math.floor (mantissa * 2 ^ (52 + biasedExponent) + 0.5)
			biasedExponent = 0
		else
			mantissa = math.floor ((mantissa * 2 - 1) * 2 ^ 52 + 0.5)
		end
	end
	
	low = mantissa % 4294967296
	high = high + bit.lshift (bit.band (biasedExponent, 0x07FF), 20)
	high = high + bit.band (math.floor (mantissa / 4294967296), 0x000FFFFF)
	
	return low, high
end

function GLib.BitConverter.UInt32ToFloat (n)
	-- 1 sign bit
	-- 8 biased exponent bits (bias of 127, biased value of 0 if 0 or denormal)
	-- 23 mantissa bits (implicit 1, unless biased exponent is 0)
	
	local negative = false
	
	if n >= 0x80000000 then
		negative = true
		n = n - 0x80000000
	end
	
	local biasedExponent = bit.rshift (bit.band (n, 0x7F800000), 23)
	local mantissa = bit.band (n, 0x007FFFFF) / (2 ^ 23)
	
	local f
	if biasedExponent == 0x00 then
		f = mantissa == 0 and 0 or math.ldexp (mantissa, -126)
	elseif biasedExponent == 0xFF then
		f = mantissa == 0 and math.huge or (math.huge - math.huge)
	else
		f = math.ldexp (1 + mantissa, biasedExponent - 127)
	end
	
	return negative and -f or f
end

function GLib.BitConverter.UInt32sToDouble (low, high)
	-- 1 sign bit
	-- 11 biased exponent bits (bias of 127, biased value of 0 if 0 or denormal)
	-- 52 mantissa bits (implicit 1, unless biased exponent is 0)
	
	local negative = false
	
	if high >= 0x80000000 then
		negative = true
		high = high - 0x80000000
	end
	
	local biasedExponent = bit.rshift (bit.band (high, 0x7FF00000), 20)
	local mantissa = (bit.band (high, 0x000FFFFF) * 4294967296 + low) / 2 ^ 52
	
	local f
	if biasedExponent == 0x0000 then
		f = mantissa == 0 and 0 or math.ldexp (mantissa, -1022)
	elseif biasedExponent == 0x07FF then
		f = mantissa == 0 and math.huge or (math.huge - math.huge)
	else
		f = math.ldexp (1 + mantissa, biasedExponent - 1023)
	end
	
	return negative and -f or f
end