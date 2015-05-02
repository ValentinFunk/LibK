local self = {}
GLib.Enumerable = GLib.MakeConstructor (self, GLib.IEnumerable)

function GLib.Enumerable.FromArray (array)
	return GLib.Enumerable (GLib.Enumerator.ArrayEnumerator, array)
end

function GLib.Enumerable.FromEnumeratorFactory (enumeratorFactory, argument1)
	return GLib.Enumerable (enumeratorFactory, argument1)
end

function GLib.Enumerable.FromKeys (t)
	return GLib.Enumerable (GLib.Enumerator.KeyEnumerator, t)
end

function GLib.Enumerable.FromValues (t)
	return GLib.Enumerable (GLib.Enumerator.ValueEnumerator, t)
end

function GLib.ToEnumerable (x)
	if x.GetEnumerator then return x end
	return GLib.Enumerable (GLib.Enumerator.ArrayEnumerator, x)
end

function self:ctor (enumeratorFactory, argument1)
	self.EnumeratorFactory = enumeratorFactory
	self.Argument1         = argument1
end

function self:GetEnumerator ()
	return self.EnumeratorFactory (self.Argument1)
end