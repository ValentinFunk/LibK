local self = {}
VFS.FileType = VFS.MakeConstructor (self)

function self:ctor (name)
	self.Name = name
	self.Extensions = {}
end

function self:AddExtension (extension)
	self.Extensions [extension:lower ()] = true
end

function self:GetName ()
	return self.Name
end

function self:IsEnabled ()
	return true
end

function self:IsMatchingContent (fileStream, callback)
	callback (VFS.ReturnCode.Success, true)
end

function self:IsMatchingPath (path)
	return true
end

function self:IsMatchingExtension (extension)
	return self.Extensions [extension:lower ()] or self.Extensions ["*"] or false
end

function self:Open (node)
	VFS.Error ("FileType:Open () : Not implemented.")
end

function self:UsesContentMatching ()
	return false
end