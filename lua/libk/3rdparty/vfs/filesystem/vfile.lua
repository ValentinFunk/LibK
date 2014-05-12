local self = {}
VFS.VFile = VFS.MakeConstructor (self, VFS.IFile, VFS.VNode)

function self:ctor (name, parentFolder)
	self.Size = 0

	self.Contents = ""
	self:SetSize (0)
end

function self:GetSize ()
	return self.Size
end

function self:Open (authId, openFlags, callback)
	callback = callback or VFS.NullCallback
	openFlags = VFS.SanitizeOpenFlags (openFlags)
	
	if not self:GetPermissionBlock ():IsAuthorized (authId, "Read") then callback (VFS.ReturnCode.AccessDenied) return end
	if bit.band (openFlags, VFS.OpenFlags.Write) ~= 0 and not self:GetPermissionBlock ():IsAuthorized (authId, "Write") then callback (VFS.ReturnCode.AccessDenied) return end

	callback (VFS.ReturnCode.Success, VFS.VFileStream (self, openFlags))
end

function self:SetSize (size)
	if self.Size == size then return end
	self.Size = size
	
	self:DispatchEvent ("Updated", VFS.UpdateFlags.Size)
	if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self, VFS.UpdateFlags.Size) end
end