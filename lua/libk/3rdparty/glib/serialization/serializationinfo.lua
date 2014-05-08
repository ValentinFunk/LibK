local self = {}
GLib.Serialization.SerializationInfo = GLib.MakeConstructor (self)

function self:ctor (className, constructor)
	self.ClassName = className
	self.ClassId   = 0xFFFFFFFF
	
	self.Constructor = constructor or GLib.NullCallback
	
	self.DeserializerInvocationList = nil
	self.SerializerInvocationList   = nil
end

function self:GetClassId ()
	return self.ClassId
end

function self:GetClassName ()
	return self.ClassName
end

function self:GetConstructor ()
	return self.Constructor
end

function self:GetDeserializerInvocationList ()
	if not self.DeserializerInvocationList then
		self.DeserializerInvocationList = {}
		
		local reverseDeserializerInvocationList = {}
		local metatable = GLib.GetMetaTable (self.Constructor)
		
		while metatable do
			reverseDeserializerInvocationList [#reverseDeserializerInvocationList + 1] = metatable.Deserialize
			
			metatable = metatable.__base
		end
		
		for i = 1, #reverseDeserializerInvocationList do
			self.DeserializerInvocationList [#reverseDeserializerInvocationList - i + 1] = reverseDeserializerInvocationList [i]
		end
	end
	
	return self.DeserializerInvocationList
end

function self:GetSerializerInvocationList ()
	if not self.SerializerInvocationList then
		self.SerializerInvocationList = {}
		
		local reverseSerializerInvocationList = {}
		local metatable = GLib.GetMetaTable (self.Constructor)
		
		while metatable do
			reverseSerializerInvocationList [#reverseSerializerInvocationList + 1] = metatable.Serialize
			
			metatable = metatable.__base
		end
		
		for i = 1, #reverseSerializerInvocationList do
			self.SerializerInvocationList [#reverseSerializerInvocationList - i + 1] = reverseSerializerInvocationList [i]
		end
	end
	
	return self.SerializerInvocationList
end

function self:SetClassId (classId)
	self.ClassId = classId
end