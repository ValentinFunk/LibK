local self = {}
VFS.FileResource = VFS.MakeConstructor (self, VFS.IResource)

function self:ctor (uriOrFile)
	self.File = nil
	self.FileResolved = false
	
	if type (uriOrFile) == "string" then
		self.Uri = uriOrFile
		self.FolderUri = string.sub (self.Uri, 1, (string.find (self.Uri, "/[^/]*$") or 0) - 1)
		self.Name = string.match (self.Uri, "/([^/]*)$") or self.Uri
		
		self.DisplayName = self.Name
		self.DisplayUri  = self.Uri
		
		VFS.Root:GetChild (GLib.GetLocalId (), self.Uri,
			function (returnCode, file)
				self.FileResolved = true
				
				if returnCode ~= VFS.ReturnCode.Success then
					self:DispatchEvent ("FileResolved")
					return
				end
				
				if not file:IsFile () then
					self:DispatchEvent ("FileResolved")
					return
				end
				
				self:SetFile (file)
				self:DispatchEvent ("FileResolved", self.File)
			end
		)
	else
		self:SetFile (uriOrFile)
	end
end

function self:GetDisplayName ()
	return self.DisplayName
end

function self:GetDisplayUri ()
	return self.DisplayUri
end

function self:GetFile ()
	return self.File
end

function self:GetFolderUri ()
	return self.FolderUri
end

function self:GetName ()
	return self.Name
end

function self:GetUri ()
	return self.Uri
end

function self:Open (authId, openFlags, callback)
	if not self.File then
		if self.FileResolved then
			callback (VFS.ReturnCode.AccessDenied)
			return
		end
		
		self:AddEventListener ("FileResolved",
			function (_, file)
				self:Open (authId, openFlags, callback)
			end
		)
		return
	end
	
	self.File:Open (authId, openFlags, callback)
end

function self:SetFile (file)
	self.File = file
	self.FileResolved = true
	self.DisplayName = self.File:GetDisplayName ()
	self.DisplayUri  = self.File:GetDisplayPath ()
	self.FolderUri   = self.File:GetParentFolder () and self.File:GetParentFolder ():GetPath () or ""
	self.Name        = self.File:GetName ()
	self.Uri         = self.File:GetPath ()
end