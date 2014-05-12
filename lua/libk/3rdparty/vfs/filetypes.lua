local self = {}
VFS.FileTypes = VFS.MakeConstructor (self)

function self:ctor ()
	self.Types = {}
end

function self:Register (typeName)
	local fileType = VFS.FileType (typeName)
	self.Types [typeName] = fileType
	return fileType
end

function self:Open (node)
	local path = node:GetPath ()
	local extension = path:sub (path:len () - path:reverse ():find (".", 1, true) + 2)
	local matches = {}
	
	for typeName, fileType in pairs (self.Types) do
		if fileType:IsEnabled () and
			fileType:IsMatchingExtension (extension) and
			fileType:IsMatchingPath (path) then
			matches [#matches + 1] = fileType
		end
	end
	
	if #matches > 0 then
		local fileStream = nil
		local fileType = nil
		local i = 1
		local tryContentMatching
		local tryNextMatch
		
		function tryContentMatching ()
			fileStream:Seek (0)
			fileType:IsMatchingContent (fileStream,
				function (returnCode, matching)
					if matching then
						if fileStream then fileStream:Close () end
						fileType:Open (node)
					else
						GLib.CallDelayed (tryNextMatch)
					end
				end
			)
		end
		
		function tryNextMatch ()
			fileType = matches [i]
			i = i + 1
			if not fileType then
				if fileStream then fileStream:Close () end
				self:OpenDefault (node)
				return
			end
			if fileType:UsesContentMatching () then
				if fileStream then
					tryContentMatching ()
				else
					node:Open (GAuth.GetLocalId, VFS.OpenFlags.Read,
						function (returnCode, stream)
							if returnCode ~= VFS.ReturnCode.Success then
							end
							fileStream = stream
							tryContentMatching ()
						end
					)
				end
			else
				if fileStream then fileStream:Close () end
				fileType:Open (node)
				return
			end
		end
		
		tryNextMatch ()
	else
		self:OpenDefault (node)
	end
end

function self:OpenDefault (node)
	if GCompute then
		GCompute.IDE:GetInstance ():OpenResource (VFS.Resource (node),
			function (success, resource, tab)
				if tab then tab:Select () end
				GCompute.IDE:GetInstance ():GetFrame ():SetVisible (true)
				GCompute.IDE:GetInstance ():GetFrame ():MoveToFront ()
			end
		)
	end
end

VFS.FileTypes = VFS.FileTypes ()