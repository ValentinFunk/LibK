local self = {}
GLib.PropertySerializable = GLib.MakeConstructor (self, GLib.Serialization.ISerializable)

function self:ctor ()
end

-- ISerializable
function self:Serialize (outBuffer)
	self:SerializeProperties (outBuffer)
	
	return outBuffer
end

function self:Deserialize (inBuffer)
	self:DeserializeProperties (inBuffer)
	
	return self
end

-- PropertySerializable
function self:SerializeProperties (outBuffer)
	for i = 1, #self._Properties do
		local property = self._Properties [i]
		outBuffer [property.Type] (outBuffer, self [property.GetterName] (self))
	end
	
	return outBuffer
end

function self:DeserializeProperties (inBuffer)
	for i = 1, #self._Properties do
		local property = self._Properties [i]
		self [property.SetterName] (self, inBuffer [property.Type] (inBuffer))
	end
	
	return self
end

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	for i = 1, #self._Properties do
		local property = self._Properties [i]
		self [property.SetterName] (self, source [property.GetterName] (source))
	end
	
	return source
end