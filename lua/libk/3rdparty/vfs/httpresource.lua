local self = {}
VFS.HTTPResource = VFS.MakeConstructor (self, VFS.IResource)

function self:ctor (uri)
	uri = string.gsub (uri, "^https://", "http://")
	
	self.Uri = uri
	self.FolderUri = string.sub (self.Uri, 1, string.find (self.Uri, "/[^/]*$"))
	
	self.Name = string.match (self.Uri, "/([^/]*)$") or self.Uri
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

function self:IsHttpResource ()
	return true
end

function self:Open (authId, openFlags, callback)
	openFlags = VFS.SanitizeOpenFlags (openFlags)
	
	if bit.band (openFlags, VFS.OpenFlags.Write) ~= 0 then
		callback (VFS.ReturnCode.AccessDenied)
		return
	end
	
	-- Rewrite URI
	local uri = self.Uri
	-- pastebin.com/([a-zA-Z0-9]*) to pastebin.com/raw.php?i=%1
	uri = string.gsub (uri, "pastebin.com/([a-zA-Z0-9]*)$", "pastebin.com/raw.php?i=%1")
	
	http.Fetch (uri,
		function (data)
			local fileStream = VFS.MemoryFileStream (data)
			fileStream:SetDisplayPath (self:GetDisplayUri ())
			fileStream:SetPath (self:GetUri ())
			callback (VFS.ReturnCode.Success, fileStream)
		end,
		function (error)
			callback (VFS.ReturnCode.AccessDenied)
		end
	)
end