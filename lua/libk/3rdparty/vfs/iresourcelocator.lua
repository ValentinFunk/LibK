local self = {}
VFS.IResourceLocator = VFS.MakeConstructor (self)

function self:ctor ()
end

function self:FindResource (baseResource, resourcePath, callback)
	callback = callback or VFS.NullCallback
	
	VFS.Error ("IResourceLocator:FindResource : Not implemented.")
	callback (false)
end