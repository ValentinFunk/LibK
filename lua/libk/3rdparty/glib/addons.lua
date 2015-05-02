GLib.IncludeDirectory ("glib_addons")
GLib.IncludeDirectory ("glib_addons/" .. (SERVER and "server" or "client"))

GLib.AddCSLuaPackSystem ("GLibAddons")
GLib.AddCSLuaPackFolder ("glib_addons")
GLib.AddCSLuaPackFolderRecursive ("glib_addons/client")

GLib:AddEventListener ("PackFileLoaded", "GLibAddonLoader",
	function (_, systemTableName)
		if systemTableName ~= "GLibAddons" then return end
		
		GLib.IncludeDirectory ("glib_addons")
		GLib.IncludeDirectory ("glib_addons/" .. (SERVER and "server" or "client"))
	end
)