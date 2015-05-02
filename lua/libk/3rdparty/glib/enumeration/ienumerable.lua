local self = {}
GLib.IEnumerable = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:GetEnumerator ()
	GLib.Error ("IEnumerable:GetEnumerator : Not implemented.")
end

function self:Filter (filterFunction)
	return GLib.Enumerable.FromEnumeratorFactory (
		function ()
			return GLib.Enumerator.Filter (self:GetEnumerator (), filterFunction)
		end
	)
end

function self:Map (mapFunction)
	return GLib.Enumerable.FromEnumeratorFactory (
		function ()
			return GLib.Enumerator.Map (self:GetEnumerator (), mapFunction)
		end
	)
end

function self:Skip (n)
	return GLib.Enumerable.FromEnumeratorFactory (
		function ()
			return GLib.Enumerator.Skip (self:GetEnumerator (), n)
		end
	)
end

function self:Take (n)
	return GLib.Enumerable.FromEnumeratorFactory (
		function ()
			return GLib.Enumerator.Take (self:GetEnumerator (), n)
		end
	)
end

function self:Concat (separator)
	return table.concat (self:ToArray (), separator)
end

function self:ToArray ()
	return GLib.Enumerator.ToArray (self:GetEnumerator ())
end

function self:ToList ()
	return GLib.Containers.List.FromEnumerable (self)
end

function self:Unpack ()
	return unpack (self:ToArray ())
end