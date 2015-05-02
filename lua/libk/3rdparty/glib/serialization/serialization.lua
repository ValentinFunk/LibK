--[[
	I'm sorry.
	
	I'm so sorry.
]]

local previousSerializableRegistry = GetGLibSerializableRegistry and GetGLibSerializableRegistry ()
local currentSerializableRegistry = GLib.Serialization.SerializableRegistry ()
GLib.Serialization.SerializableRegistry = currentSerializableRegistry
if previousSerializableRegistry then
	previousSerializableRegistry:MergeInto (currentSerializableRegistry)
end

function GetGLibSerializableRegistry ()
	return currentSerializableRegistry
end

-- Registration
function GLib.RegisterSerializable (className, constructor)
	constructor = constructor or GLib.Lua.GetTableValue (className)
	
	GLib.Serialization.SerializableRegistry:Register (className, constructor)
	
	GLib.GetMetaTable (constructor).__className = className
end

function GLib.UnregisterSerializable (className)
	GLib.Serialization.SerializableRegistry:Unregister (className)
end

-- Serialization
function GLib.Serialize (object, outBuffer)
	outBuffer = outBuffer or GLib.StringOutBuffer ()
	
	local className = type (object)
	if className == "table" and
	   object.__className then
		className = object.__className
	end
	
	local serializationInfo = currentSerializableRegistry:GetSerializationInfo (className)
	local serializerInvocationList = serializationInfo:GetSerializerInvocationList ()
	
	outBuffer:UInt32 (serializationInfo:GetClassId ())
	for i = 1, #serializerInvocationList do
		serializerInvocationList [i] (object, outBuffer)
	end
	
	return outBuffer
end

function GLib.Deserialize (inBuffer)
	local classId = inBuffer:UInt32 ()
	local serializationInfo = currentSerializableRegistry:GetSerializationInfo (currentSerializableRegistry:GetClassName (classId))
	local deserializerInvocationList = serializationInfo:GetDeserializerInvocationList ()
	
	local object = serializationInfo:GetConstructor () ()
	for i = 1, #deserializerInvocationList do
		object = deserializerInvocationList [i] (object, inBuffer) or object
	end
	
	return object
end

-- Primitive Serializers
GLib.Serialization.SerializableRegistry:RegisterCustom ("number")
	:SetSerializer (function (number, outBuffer) outBuffer:Double (number) end)
	:SetDeserializer (function (_, inBuffer) return inBuffer:Double () end)

GLib.Serialization.SerializableRegistry:RegisterCustom ("string")
	:SetSerializer (function (str, outBuffer) outBuffer:String (str) end)
	:SetDeserializer (function (_, inBuffer) return inBuffer:String () end)

GLib.Serialization.SerializableRegistry:RegisterCustom ("Angle")
	:SetSerializer (
		function (angle, outBuffer)
			outBuffer:Double (angle.p)
			outBuffer:Double (angle.y)
			outBuffer:Double (angle.r)
		end
	)
	:SetDeserializer (
		function (_, inBuffer)
			local p = inBuffer:Double ()
			local y = inBuffer:Double ()
			local r = inBuffer:Double ()
			return Angle (p, y, r)
		end
	)

GLib.Serialization.SerializableRegistry:RegisterCustom ("Vector")
	:SetSerializer (
		function (angle, outBuffer)
			outBuffer:Double (angle.x)
			outBuffer:Double (angle.y)
			outBuffer:Double (angle.z)
		end
	)
	:SetDeserializer (
		function (_, inBuffer)
			local x = inBuffer:Double ()
			local y = inBuffer:Double ()
			local z = inBuffer:Double ()
			return Angle (x, y, z)
		end
	)