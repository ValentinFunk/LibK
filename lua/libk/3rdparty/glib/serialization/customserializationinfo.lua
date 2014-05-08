local self = {}
GLib.Serialization.CustomSerializationInfo = GLib.MakeConstructor (self, GLib.Serialization.SerializationInfo)

function self:ctor (className, constructor)
	self.DeserializerInvocationList = { GLib.NullCallback }
	self.SerializerInvocationList   = { GLib.NullCallback }
end

function self:SetDeserializer (deserializer)
	self.DeserializerInvocationList [1] = deserializer
	return self
end

function self:SetSerializer (serializer)
	self.SerializerInvocationList [1] = serializer
	return self
end