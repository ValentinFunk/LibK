local self = {}
GLib.Lua.Parameter = GLib.MakeConstructor (self, GLib.Serialization.ISerializable)

function self:ctor (parameterList, name)
	self.ParameterList = parameterList
	
	self.Name = name
	self.Variadic = false
	
	self.FrameIndex = nil
end

-- ISerializable
function self:Serialize (outBuffer)
	outBuffer:StringN32 (self.Name    )
	outBuffer:Boolean   (self.Variadic)
	outBuffer:Int32     (self.FrameIndex or 0)
	
	return outBuffer
end

function self:Deserialize (inBuffer)
	self.Name       = inBuffer:StringN32 ()
	self.Variadic   = inBuffer:Boolean   ()
	self.FrameIndex = inBuffer:Int32     ()
	
	return self
end

-- Parameter
function self:GetFrameIndex ()
	return self.FrameIndex
end

function self:GetName ()
	return self.Name
end

function self:GetParameterList ()
	return self.ParameterList
end

function self:IsVariadic ()
	return self.Variadic
end

function self:SetFrameIndex (frameIndex)
	self.FrameIndex = frameIndex
	return self
end

function self:SetName (name)
	self.Name = name
	return self
end

function self:SetVariadic (isVariadic)
	self.Variadic = isVariadic
	return self
end

function self:ToString ()
	if self:IsVariadic () then return "..." end
	
	return self.Name
end