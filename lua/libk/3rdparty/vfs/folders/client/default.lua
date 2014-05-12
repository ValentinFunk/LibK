local paths =
{
	["game"]  = "GAME",
	["lua"]   = "LUA",
	["luacl"] = CLIENT and "LCL" or nil
}

for folderName, path in pairs (paths) do
	local folder = VFS.Root:MountLocal (folderName, VFS.RealFolder ("", path, ""))
	folder:SetDisplayName (folderName)
	folder:SetDeletable (false)
	folder:SetOwner (GAuth.GetSystemId (), GAuth.GetServerId ())
	folder:GetPermissionBlock ():SetInheritPermissions (GAuth.GetSystemId (), false)
	folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Read",        GAuth.Access.Allow)
	folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "View Folder", GAuth.Access.Allow)
	folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Write",       GAuth.Access.Allow)
end