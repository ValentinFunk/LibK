local self = {}
VFS.RealNode = VFS.MakeConstructor (self, VFS.INode)

function self:ctor (path, fileSystemPath, name, parentFolder)
	self.Type = "Real" .. (self:IsFolder () and "Folder" or "File")
	
	self.FileSystemPath = fileSystemPath
	
	self.Name = name
	self.ParentFolder = parentFolder
	
	self.ModificationTime = nil
end

function self:GetFileSystemPath ()
	return self.FileSystemPath
end

function self:GetName ()
	return self.Name
end

function self:GetModificationTime ()
	self:UpdateModificationTime ()
	return self.ModificationTime
end

function self:GetParentFolder ()
	return self.ParentFolder
end

function self:GetPermissionBlock ()
	return nil
end

function self:Rename (authId, name, callback)
	callback = callback or VFS.NullCallback
	if self:GetName () == name then callback (VFS.ReturnCode.Success) return end
	if not self:GetParentFolder () then callback (VFS.ReturnCode.AccessDenied) return end

	if self:IsFolder () then callback (VFS.ReturnCode.AccessDenied) return end
	if self:GetPath ():lower ():sub (1, 5) ~= "data/" then callback (VFS.ReturnCode.AccessDenied) return end
	name = VFS.SanitizeNodeName (name)
	if not name then callback (VFS.ReturnCode.AccessDenied) return end
	if name:sub (-4, -1) ~= ".txt" then name = name .. ".txt" end
	
	local oldName = self:GetName ()
	local newPath = self:GetParentFolder ().FolderPath .. name
	if file.Exists (newPath, self.FileSystemPath) then callback (VFS.ReturnCode.AlreadyExists) return end
	file.Write (newPath:sub (6), file.Read (self:GetPath (), self.FileSystemPath))
	if not file.Exists (newPath, self.FileSystemPath) then callback (VFS.ReturnCode.AccessDenied) return end
	file.Delete (self:GetPath ():sub (6), self.FileSystemPath)
	self.Name = name
	
	self:GetParentFolder ():RenameChild (authId, oldName, name)
	self:DispatchEvent ("Renamed", oldName, name)
	callback (VFS.ReturnCode.Success)
end

function self:UpdateModificationTime (suppressEvent)
	suppressEvent = suppressEvent or false
	
	local modificationTime = file.Time (self:GetPath (), self.FileSystemPath) or -1
	self.ModificationTime = self.ModificationTime or modificationTime -- Suppress generation of Updated event on first query
	if self.ModificationTime ~= modificationTime then
		self.ModificationTime = modificationTime
		
		if not suppressEvent then
			self:DispatchEvent ("Updated", VFS.UpdateFlags.ModificationTime)
			if self:GetParentFolder () then self:GetParentFolder ():DispatchEvent ("NodeUpdated", self, VFS.UpdateFlags.ModificationTime) end
		end
	end
end