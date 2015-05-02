local self = {}
GLib.Containers.ICollection = GLib.MakeConstructor (self, GLib.IEnumerable)

function self:ctor ()
end

function self:Add (item)
	GLib.Error ("ICollection:Add : Not implemented.")
end

function self:AddRange (enumerable)
	for item in enumerable:GetEnumerator () do
		self:Add (item)
	end
end

function self:Clear ()
	GLib.Error ("ICollection:Clear : Not implemented.")
end

function self:Contains (item)
	GLib.Error ("ICollection:Contains : Not implemented.")
end

function self:GetCount ()
	GLib.Error ("ICollection:GetCount : Not implemented.")
end

function self:IsEmpty ()
	GLib.Error ("ICollection:IsEmpty : Not implemented.")
end

function self:Remove (item)
	GLib.Error ("ICollection:Remove : Not implemented.")
end