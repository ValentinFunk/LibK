GLib.AddCSLuaPackSystem ("GLibAddons")
GLib.AddCSLuaPackFolderRecursive ("glib_addons")

GLib.IncludeDirectory ("glib_addons")
GLib.IncludeDirectory ("glib_addons/" .. (SERVER and "server" or "client"))
