GLib.BitConverter = {}

local bit_band   = bit.band
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local math_floor = math.floor
local math_frexp = math.frexp
local math_ldexp = math.ldexp
local math_huge  = math.huge

-- Integers
function GLib.BitConverter.UInt8ToUInt8s (n)
	return n
end

function GLib.BitConverter.UInt16ToUInt8s (n)
	return             n        % 256,
	       math_floor (n / 256) % 256
end

function GLib.BitConverter.UInt32ToUInt8s (n)
	return             n             % 256,
	       math_floor (n /      256) % 256,
	       math_floor (n /    65536) % 256,
	       math_floor (n / 16777216) % 256
end

function GLib.BitConverter.UInt64ToUInt8s (n)
	return             n                      % 256,
	       math_floor (n /               256) % 256,
	       math_floor (n /             65536) % 256,
	       math_floor (n /          16777216) % 256,
	       math_floor (n /        4294967296) % 256,
	       math_floor (n /     1099511627776) % 256,
	       math_floor (n /   281474976710656) % 256,
	       math_floor (n / 72057594037927936) % 256
end

function GLib.BitConverter.UInt8sToUInt8(uint80)
	return uint80
end

function GLib.BitConverter.UInt8sToUInt16 (uint80, uint81)
	return uint80 +
	       uint81 * 256
end

function GLib.BitConverter.UInt8sToUInt32 (uint80, uint81, uint82, uint83)
	return uint80 +
	       uint81 * 256 +
	       uint82 * 65536 +
	       uint83 * 16777216
end

function GLib.BitConverter.UInt8sToUInt64 (uint80, uint81, uint82, uint83, uint84, uint85, uint86, uint87)
	return uint80 +
	       uint81 * 256 +
	       uint82 * 65536 +
	       uint83 * 16777216 +
	       uint84 * 4294967296 +
	       uint85 * 1099511627776 +
	       uint86 * 281474976710656 +
	       uint87 * 72057594037927936
end

function GLib.BitConverter.Int8ToUInt8s (n)
	if n < 0 then n = n + 256 end
	return GLib.BitConverter.UInt8ToUInt8s (n)
end

function GLib.BitConverter.Int16ToUInt8s (n)
	if n < 0 then n = n + 65536 end
	return GLib.BitConverter.UInt16ToUInt8s (n)
end

function GLib.BitConverter.Int32ToUInt8s (n)
	if n < 0 then n = n + 4294967296 end
	return GLib.BitConverter.UInt32ToUInt8s (n)
end

function GLib.BitConverter.Int64ToUInt8s (n)
	local uint80, uint81, uint82, uint83 = GLib.BitConverter.UInt32ToUInt8s (n % 4294967296)
	local uint84, uint85, uint86, uint87 = GLib.BitConverter.Int32ToUInt8s (math_floor (n / 4294967296))
	return uint80, uint81, uint82, uint83, uint84, uint85, uint86, uint87
end

function GLib.BitConverter.UInt8sToInt8 (uint80)
	local n = GLib.BitConverter.UInt8sToUInt8 (uint80)
	if n >= 128 then n = n - 256 end
	return n
end

function GLib.BitConverter.UInt8sToInt16 (uint80, uint81)
	local n = GLib.BitConverter.UInt8sToUInt16 (uint80, uint81)
	if n >= 32768 then n = n - 65536 end
	return n
end

function GLib.BitConverter.UInt8sToInt32 (uint80, uint81, uint82, uint83)
	local n = GLib.BitConverter.UInt8sToUInt32 (uint80, uint81, uint82, uint83)
	if n >= 2147483648 then n = n - 4294967296 end
	return n
end

function GLib.BitConverter.UInt8sToInt64 (uint80, uint81, uint82, uint83, uint84, uint85, uint86, uint87)
	local low  = GLib.BitConverter.UInt8sToUInt32 (uint80, uint81, uint82, uint83)
	local high = GLib.BitConverter.UInt8sToInt32 (uint84, uint85, uint86, uint87)
	return low + high * 4294967296
end

-- IEEE floating point numbers
function GLib.BitConverter.FloatToUInt32 (f)
	-- 1 / f is needed to check for -0
	local n = 0
	if f < 0 or 1 / f < 0 then
		n = n + 0x80000000
		f = -f
	end
	
	local mantissa = 0
	local biasedExponent = 0
	
	if f == math_huge then
		biasedExponent = 0xFF
	elseif f ~= f then
		biasedExponent = 0xFF
		mantissa = 1
	elseif f == 0 then
		biasedExponent = 0x00
	else
		mantissa, biasedExponent = math_frexp (f)
		biasedExponent = biasedExponent + 126
		
		if biasedExponent <= 0 then
			-- Denormal
			mantissa = math_floor (mantissa * 2 ^ (23 + biasedExponent) + 0.5)
			biasedExponent = 0
		else
			mantissa = math_floor ((mantissa * 2 - 1) * 2 ^ 23 + 0.5)
		end
	end
	
	n = n + bit_lshift (bit_band (biasedExponent, 0xFF), 23)
	n = n + bit_band (mantissa, 0x007FFFFF)
	
	return n
end

function GLib.BitConverter.DoubleToUInt32s (f)
	-- 1 / f is needed to check for -0
	local high = 0
	local low  = 0
	if f < 0 or 1 / f < 0 then
		high = high + 0x80000000
		f = -f
	end
	
	local mantissa = 0
	local biasedExponent = 0
	
	if f == math_huge then
		biasedExponent = 0x07FF
	elseif f ~= f then
		biasedExponent = 0x07FF
		mantissa = 1
	elseif f == 0 then
		biasedExponent = 0x00
	else
		mantissa, biasedExponent = math_frexp (f)
		biasedExponent = biasedExponent + 1022
		
		if biasedExponent <= 0 then
			-- Denormal
			mantissa = math_floor (mantissa * 2 ^ (52 + biasedExponent) + 0.5)
			biasedExponent = 0
		else
			mantissa = math_floor ((mantissa * 2 - 1) * 2 ^ 52 + 0.5)
		end
	end
	
	low = mantissa % 4294967296
	high = high + bit_lshift (bit_band (biasedExponent, 0x07FF), 20)
	high = high + bit_band (math_floor (mantissa / 4294967296), 0x000FFFFF)
	
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
	
	local biasedExponent = bit_rshift (bit_band (n, 0x7F800000), 23)
	local mantissa = bit_band (n, 0x007FFFFF) / (2 ^ 23)
	
	local f
	if biasedExponent == 0x00 then
		f = mantissa == 0 and 0 or math_ldexp (mantissa, -126)
	elseif biasedExponent == 0xFF then
		f = mantissa == 0 and math_huge or (math_huge - math_huge)
	else
		f = math_ldexp (1 + mantissa, biasedExponent - 127)
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
	
	local biasedExponent = bit_rshift (bit_band (high, 0x7FF00000), 20)
	local mantissa = (bit_band (high, 0x000FFFFF) * 4294967296 + low) / 2 ^ 52
	
	local f
	if biasedExponent == 0x0000 then
		f = mantissa == 0 and 0 or math_ldexp (mantissa, -1022)
	elseif biasedExponent == 0x07FF then
		f = mantissa == 0 and math_huge or (math_huge - math_huge)
	else
		f = math_ldexp (1 + mantissa, biasedExponent - 1023)
	end
	
	return negative and -f or f
end