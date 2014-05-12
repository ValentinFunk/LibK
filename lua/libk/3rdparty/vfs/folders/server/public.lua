VFS.Root:CreateFolder (GAuth.GetSystemId (), "Public",
	function (returnCode, folder)
		folder:SetDeletable (false)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Read",        GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "View Folder", GAuth.Access.Allow)
		
		VFS.RealRoot:GetChild (GAuth.GetSystemId (), "data/adv_duplicator/=Public Folder=",
			function (returnCode, node)
				folder:Mount ("adv_duplicator", node, "adv_duplicator")
			end
		)
		
		folder:CreateFolder (GAuth.GetSystemId (), "shared",
			function (returnCode, folder)
				folder:SetDeletable (false)
				folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Create Folder", GAuth.Access.Allow)
				folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Delete",        GAuth.Access.Allow)
				folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Rename",        GAuth.Access.Allow)
				folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "Write",         GAuth.Access.Allow)
			end
		)
	end
)