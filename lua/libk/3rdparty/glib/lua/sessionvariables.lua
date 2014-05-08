local sessionVariables = {}

if GetGLibSessionVariables then
	sessionVariables = GetGLibSessionVariables ()
end

function GetGLibSessionVariables ()
	return sessionVariables
end

function GLib.GetSessionVariable (namespace, name, defaultValue)
	sessionVariables [namespace] = sessionVariables [namespace] or {}
	
	if sessionVariables [namespace] [name] == nil then
		sessionVariables [namespace] [name] = defaultValue
	end
	
	return sessionVariables [namespace] [name]
end

function GLib.SetSessionVariable (namespace, name, value)
	sessionVariables [namespace] = sessionVariables [namespace] or {}
	sessionVariables [namespace] [name] = value
	
	return sessionVariables [namespace] [name]
end