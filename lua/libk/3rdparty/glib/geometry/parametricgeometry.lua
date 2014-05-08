function GLib.Geometry.CreateParameterVector (degree, t, out)
	if degree == 1 then return t end
	
	out = out or GLib.RowVector (degree + 1)
	
	local element = 1
	for i = degree + 1, 1, -1 do
		out [i] = element
		element = element * t
	end
	
	return out
end

function GLib.Geometry.CreateParameterTangentVector (degree, t, out)
	if degree == 1 then return 1 end
	
	out = out or GLib.RowVector (degree + 1)
	
	for i = 1, degree do
		out [i] = (degree - i + 1) * t ^ (degree - i)
	end
	
	return out
end