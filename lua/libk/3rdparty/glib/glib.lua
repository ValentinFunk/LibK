include ("glib/stage1.lua")

if SERVER or
   file.Exists ("glib/stage2.lua", "LUA") or
   file.Exists ("glib/stage2.lua", "LCL") and GetConVar ("sv_allowcslua"):GetBool () then
	include ("glib/stage2.lua")
end