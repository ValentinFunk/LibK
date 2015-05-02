function GLib.Enumerator.Join (enumerator1, enumerator2, enumerator3, ...)
	if not enumerator2 then
		return enumerator1
	elseif not enumerator3 then
		local i = 1
		return function ()
			local a, b, c, d, e, f = nil
			if i == 1 then
				a, b, c, d, e, f = enumerator1 ()
				if a == nil then i = i + 1 end
			end
			if i == 2 then
				a, b, c, d, e, f = enumerator2 ()
				if a == nil then i = i + 1 end
			end
			
			return a, b, c, d, e, f
		end
	else
		local i = 1
		local enumerators = { enumerator1, enumerator2, enumerator3, ... }
		return function ()
			local a, b, c, d, e, f = nil
			
			while a == nil do
				local enumerator = enumerators [i]
				if not enumerator then return nil end
				a, b, c, d, e, f = enumerator ()
				if a == nil then i = i + 1 end
			end
			
			return a, b, c, d, e, f
		end
	end
end