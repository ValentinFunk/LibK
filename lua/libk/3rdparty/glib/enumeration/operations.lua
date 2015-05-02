local function ToFunction (f)
	if isfunction (f) then return f end
	
	return function (x, ...)
		return x [f] (x, ...)
	end
end

function GLib.Enumerator.Concat (enumerator, separator)
	return table.concat (GLib.Enumerator.ToArray (GLib.Enumerator.Map (enumerator, tostring)), separator)
end

function GLib.Enumerator.Filter (enumerator, filterFunction)
	filterFunction = ToFunction (filterFunction)
	
	return function ()
		local a, b, c, d, e, f = nil
		repeat
			a, b, c, d, e, f = enumerator ()
			if a == nil then return nil end
		until filterFunction (a, b, c, d, e, f)
		
		return a, b, c, d, e, f
	end
end

function GLib.Enumerator.Map (enumerator, mapFunction)
	mapFunction = ToFunction (mapFunction)
	
	return function ()
		local a, b, c, d, e, f = enumerator ()
		if a == nil then return nil end
		
		return mapFunction (a, b, c, d, e, f)
	end
end

function GLib.Enumerator.Skip (enumerator, n)
	local skipped = false
	return function ()
		if not skipped then
			for i = 1, n do
				local item = enumerator ()
				if item == nil then return nil end
			end
			skipped = true
		end
		
		return enumerator ()
	end
end

function GLib.Enumerator.Take (enumerator, n)
	local i = 0
	return function ()
		i = i + 1
		if i > n then return nil end
		
		return enumerator ()
	end
end

function GLib.Enumerator.ToArray (enumerator)
	local t = {}
	
	for v in enumerator do
		t [#t + 1] = v
	end
	
	return t
end

function GLib.Enumerator.ToMap (enumerator)
	local t = {}
	
	for k, v in enumerator do
		 t [k] = v
	end
	
	return t
end
GLib.Enumerator.ToTable = GLib.Enumerator.ToMap

function GLib.Enumerator.Unpack (enumerator)
	local value = enumerator ()
	if not value then return end
	return value, GLib.Enumerator.Unpack (enumerator)
end