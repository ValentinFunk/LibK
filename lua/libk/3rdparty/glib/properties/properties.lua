function GLib.PropertyGetter (self, property)
	self [property.GetterName] = function (self)
		return self [property.Name]
	end
end

function GLib.PropertySetter (self, property)
	self [property.SetterName] = function (self, value)
		self [property.Name] = value
		return self
	end
end

function GLib.PropertySetterWithCallback (self, property, callback)
	if type (callback) == "function" then
		self [property.SetterName] = function (self, value)
			if self [property.Name] == value then return self end
			
			self [property.Name] = value
			
			callback (self, value)
			
			return self
		end
	else
		self [property.SetterName] = function (self, value)
			if self [property.Name] == value then return self end
			
			self [property.Name] = value
			
			self [callback] (self, value)
			
			return self
		end
	end
end

function GLib.EventedPropertyGetter (self, property)
	GLib.PropertyGetter (self, property)
end

function GLib.EventedPropertySetter (self, property)
	self [property.SetterName] = function (self, value)
		if self [property.Name] == value then return self end
		
		self [property.Name] = value
		
		self:DispatchEvent (property.EventName, self [property.Name])
		
		return self
	end
end

function GLib.EventedPropertySetterWithCallback (self, property, callback)
	if type (callback) == "function" then
		self [property.SetterName] = function (self, value)
			if self [property.Name] == value then return self end
			
			self [property.Name] = value
			
			callback (self, value)
			
			self:DispatchEvent (property.EventName, self [property.Name])
			
			return self
		end
	else
		self [property.SetterName] = function (self, value)
			if self [property.Name] == value then return self end
			
			self [property.Name] = value
			
			self [callback] (self, valuevalue)
			
			self:DispatchEvent (property.EventName, self [property.Name])
			
			return self
		end
	end
end

function GLib.Property (self, propertyName, type)
	self._Properties = self._Properties or {}
	self.Properties  = self.Properties  or self._Properties
	
	local property = {
		Name       = propertyName,
		Type       = type,
		
		EventName  = propertyName .. "Changed",
		GetterName = (type == "Boolean" and "Is" or "Get") .. propertyName,
		SetterName = "Set" .. propertyName
	}
	
	self.Properties [#self.Properties + 1] = property
	
	GLib.PropertyGetter (self, property)
	GLib.PropertySetter (self, property)
	
	return property
end

function GLib.EventedProperty (self, propertyName, type)
	self._Properties = self._Properties or {}
	self.Properties  = self.Properties  or self._Properties
	
	local property = {
		Name       = propertyName,
		Type       = type,
		
		EventName  = propertyName .. "Changed",
		GetterName = (type == "Boolean" and "Is" or "Get") .. propertyName,
		SetterName = "Set" .. propertyName
	}
	
	self.Properties [#self.Properties + 1] = property
	
	GLib.EventedPropertyGetter (self, property)
	GLib.EventedPropertySetter (self, property)
	
	return property
end