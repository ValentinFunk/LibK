local self = {}
GLib.Serialization.ISerializable = GLib.MakeConstructor (self)

function self:ctor ()
end

function self:Deserialize (inBuffer)
end

function self:Serialize (outBuffer)
end