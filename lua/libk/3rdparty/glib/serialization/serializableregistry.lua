local self = {}
GLib.Serialization.SerializableRegistry = GLib.MakeConstructor (self)

function self:ctor ()
	self.StringTable = GLib.StringTable ()
	self.Classes = {}
end

function self:GetClassId (className)
	return self.StringTable:HashFromString (className)
end

function self:GetClassName (classId)
	return self.StringTable:StringFromHash (classId)
end

function self:GetConstructor (className)
	return self.Classes [className]:GetConstructor ()
end

function self:GetSerializationInfo (className)
	return self.Classes [className]
end

function self:MergeInto (serializableRegistry)
	for className, constructor in pairs (self.Classes) do
		serializableRegistry:Register (className)
	end
end

function self:Register (className, constructor)
	local serializationInfo = GLib.Serialization.SerializationInfo (className, constructor)
	
	self.Classes [className] = serializationInfo
	self.StringTable:Add (className)
	
	serializationInfo:SetClassId (self.StringTable:HashFromString (className))
	
	return serializationInfo
end

function self:RegisterCustom (className, customSerializationInfo)
	customSerializationInfo = customSerializationInfo or GLib.Serialization.CustomSerializationInfo (className)
	
	self.Classes [className] = customSerializationInfo
	self.StringTable:Add (className)
	
	customSerializationInfo:SetClassId (self.StringTable:HashFromString (className))
	
	return customSerializationInfo
end

function self:Unregister (className)
	self.Classes [className] = nil
end