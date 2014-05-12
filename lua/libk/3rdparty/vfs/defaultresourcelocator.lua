local self = {}
VFS.DefaultResourceLocator = VFS.MakeConstructor (self, VFS.IResourceLocator)

function self:ctor ()
end

function self:FindResource (baseResource, resourcePath, callback)
	callback = callback or VFS.NullCallback
	
	if not baseResource then callback (false) return end
	if not resourcePath then callback (false) return end
	
	if baseResource:GetFile () then
		local folder = baseResource:GetFile ():GetParentFolder ()
		if not folder then
			callback (false)
			return
		end
		
		folder:GetChild (GLib.GetLocalId (), resourcePath,
			function (returnCode, node)
				if returnCode ~= VFS.ReturnCode.Success or
				   not node:IsFile () then
					callback (false)
					return
				end
				callback (true, VFS.Resource (node))
			end
		)
	else
		callback (true, VFS.Resource (baseResource:GetFolderUri () .. "/" .. resourcePath))
	end
end

VFS.DefaultResourceLocator = VFS.DefaultResourceLocator ()