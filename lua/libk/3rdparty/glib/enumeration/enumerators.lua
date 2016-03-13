function GLib.Enumerator.ArrayEnumerator (tbl, maxIndex)
	maxIndex = maxIndex or math.huge
	
	if maxIndex == math.huge then
		local i = 0
		return function ()
			i = i + 1
			return tbl [i]
		end
	else
		local i = 0
		return function ()
			i = i + 1
			if i > maxIndex then return nil end
			return tbl [i]
		end
	end
end

function GLib.Enumerator.KeyEnumerator (tbl)
	local next, tbl, key = pairs (tbl)
	return function ()
		key = next (tbl, key)
		return key
	end
end

function GLib.Enumerator.ValueEnumerator (tbl)
	local next, tbl, key = pairs (tbl)
	return function ()
		key = next (tbl, key)
		return tbl [key]
	end
end

function GLib.Enumerator.KeyValueEnumerator (tbl)
	local next, tbl, key = pairs (tbl)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

function GLib.Enumerator.ValueKeyEnumerator (tbl)
	local next, tbl, key = pairs (tbl)
	return function ()
		key = next (tbl, key)
		return tbl [key], key
	end
end

function GLib.Enumerator.NullEnumerator ()
	return GLib.NullCallback
end

function GLib.Enumerator.SingleValueEnumerator (v)
	local done = false
	return function ()
		if done then return nil end
		done = true
		return v
	end
end

function GLib.Enumerator.YieldEnumerator (f)
	local thread = coroutine.create (f)
	return function (...)
		if coroutine.status (thread) == "dead" then return nil end
		local success, a, b, c, d, e, f = coroutine.resume (thread, ...)
		if not success then
			GLib.Error (a)
			return nil
		end
		return a, b, c, d, e, f
	end
end

function GLib.Enumerator.YieldEnumeratorFactory (f)
	return function (...)
		local arguments = {...}
		local argumentCount = table.maxn (arguments)
		
		return GLib.Enumerator.YieldEnumerator (
			function ()
				return f (unpack (arguments, 1, argumentCount))
			end
		)
	end
end

GLib.ArrayEnumerator        = GLib.Enumerator.ArrayEnumerator
GLib.KeyEnumerator          = GLib.Enumerator.KeyEnumerator
GLib.ValueEnumerator        = GLib.Enumerator.ValueEnumerator
GLib.KeyValueEnumerator     = GLib.Enumerator.KeyValueEnumerator
GLib.ValueKeyEnumerator     = GLib.Enumerator.ValueKeyEnumerator
GLib.NullEnumerator         = GLib.Enumerator.NullEnumerator
GLib.SingleValueEnumerator  = GLib.Enumerator.SingleValueEnumerator
GLib.YieldEnumerator        = GLib.Enumerator.YieldEnumerator
GLib.YieldEnumeratorFactory = GLib.Enumerator.YieldEnumeratorFactory