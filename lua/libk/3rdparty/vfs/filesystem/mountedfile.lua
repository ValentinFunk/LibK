local self = {}
VFS.MountedFile = VFS.MakeConstructor (self, VFS.IFile, VFS.MountedNode)

function self:ctor (nameOverride, mountedNode, parentFolder)
end

function self:GetSize ()
	return self.MountedNode:GetSize ()
end

function self:Open (authId, openFlags, callback)
	callback = callback or VFS.NullCallback
	openFlags = VFS.SanitizeOpenFlags (openFlags)
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Read") then callback (VFS.ReturnCode.AccessDenied) return end
	if bit.band (openFlags, VFS.OpenFlags.Write) ~= 0 and not self:GetPermissionBlock ():IsAuthorized (authId, "Write") then callback (VFS.ReturnCode.AccessDenied) return end

	self.MountedNode:Open (authId, openFlags,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				callback (returnCode, VFS.MountedFileStream (self, fileStream))
			else
				callback (returnCode, fileStream)
			end
		end
	)
end