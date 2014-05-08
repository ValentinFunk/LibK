function GLib.BindCustomProperty (destinationObject, setterName, sourceObject, getterName, eventName, eventId)
	destinationObject [setterName] (destinationObject, sourceObject [getterName] (sourceObject))
	
	if not eventName then return end
	eventId = eventId or tostring (destinationObject)
	
	if not sourceObject.AddEventListener then return end
	
	sourceObject:AddEventListener (eventName, eventId,
		function ()
			destinationObject [setterName] (destinationObject, sourceObject [getterName] (sourceObject))
		end
	)
end

function GLib.BindProperty (destinationObject, sourceObject, propertyName, eventId)
	local setterName = "Set" .. propertyName
	local getterName = "Get" .. propertyName
	if not sourceObject [getterName] then
		getterName = "Is" .. propertyName
	end
	local eventName = propertyName .. "Changed"
	
	GLib.BindCustomProperty (destinationObject, setterName, sourceObject, getterName, eventName, eventId)
end

function GLib.UnbindCustomProperty (destinationObject, setterName, sourceObject, getterName, eventName, eventId)
	if not eventName then return end
	eventId = eventId or tostring (destinationObject)
	
	if not sourceObject.RemoveEventListener then return end
	
	sourceObject:RemoveEventListener (eventName, eventId)
end

function GLib.UnbindProperty (destinationObject, sourceObject, propertyName, eventId)
	local setterName = "Set" .. propertyName
	local getterName = "Get" .. propertyName
	if not sourceObject [getterName] then
		getterName = "Is" .. propertyName
	end
	local eventName = propertyName .. "Changed"
	
	GLib.UnbindCustomProperty (destinationObject, setterName, sourceObject, getterName, eventName, eventId)
end