local self = {}
VFS.IResource = VFS.MakeConstructor (self)

function VFS.Resource (uri)
	if type (uri) == "string" then
		if string.find (uri, "^https?://") then
			return VFS.HTTPResource (uri)
		else
			return VFS.FileResource (uri)
		end
	else
		return VFS.FileResource (uri)
	end
end

function self:ctor ()
	VFS.EventProvider (self)
end

function self:GetExtension ()
	local extension = string.match (self:GetName (), "%.([^%.]*)$")
	if not extension then return "" end
	
	local questionMarkPosition = string.find (extension, "?")
	if questionMarkPosition then
		extension = string.sub (extension, 1, questionMarkPosition - 1)
	end
	
	return extension
end

function self:GetDisplayName ()
	return self:GetName ()
end

function self:GetDisplayUri ()
	return self:GetUri ()
end

function self:GetFile ()
	return nil
end

function self:GetFolderUri ()
	return ""
end

function self:GetName ()
	return ""
end

function self:GetNameWithoutExtension ()
	return string.gsub (self:GetName (), "%.[^%.]*$", "")
end

function self:GetUri ()
	return ""
end

function self:IsHttpResource ()
	return false
end

function self:Open (authId, openFlags, callback)
	VFS.Error ("IResource:Open : Not implemented")
	return callback (VFS.ReturnCode.AccessDenied)
end