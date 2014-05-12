local self = VFS.FileTypes:Register ("Advanced Duplicator")
self:AddExtension ("txt")

function self:IsEnabled ()
	return dupeshare and VFS.Net.IsChannelOpen ("vfs_session_data")
end

function self:IsMatchingPath (path)
	path = VFS.Path (path)
	return path:GetSegment (1):lower () == "adv_duplicator"
end

function self:Open (node)
	RunConsoleCommand ("tool_adv_duplicator")
	RunConsoleCommand ("vfs_adv_duplicator_open", node:GetPath ())
end