local self = {}
GLib.Serialization.ISerializable = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:Deserialize (inBuffer)
	GLib.Error ("ISerializable:Deserialize : Not implemented.")
end

function self:Serialize (outBuffer)
	GLib.Error ("ISerializable:Serialize : Not implemented.")
end