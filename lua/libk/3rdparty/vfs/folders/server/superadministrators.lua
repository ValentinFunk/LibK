VFS.Root:CreateFolder (GAuth.GetSystemId (), "Super Admins",
	function (returnCode, folder)
		folder:SetDeletable (false)
		folder:GetPermissionBlock ():SetInheritPermissions (GAuth.GetSystemId (), false)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "Read",        GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "View Folder", GAuth.Access.Allow)
		
		folder:CreateFolder (GAuth.GetSystemId (), "shared",
			function (returnCode, folder)
				folder:SetDeletable (false)
				folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "Create Folder", GAuth.Access.Allow)
				folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "Delete",        GAuth.Access.Allow)
				folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "Rename",        GAuth.Access.Allow)
				folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Super Administrators", "Write",         GAuth.Access.Allow)
			end
		)
	end
)