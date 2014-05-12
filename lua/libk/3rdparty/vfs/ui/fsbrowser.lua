local self = {}
local ctor = VFS.MakeConstructor (self)
local instance = nil

function VFS.FileSystemBrowser ()
	if not instance then
		instance = ctor ()
		
		VFS:AddEventListener ("Unloaded", function ()
			instance:dtor ()
			instance = nil
		end)
	end
	return instance
end

function self:ctor ()
	self.Panel = vgui.Create ("VFSFileSystemBrowserFrame")
end

function self:dtor ()
	if self.Panel and self.Panel:IsValid () then
		self.Panel:Remove ()
	end
end

function self:GetFrame ()
	return self.Panel
end

concommand.Add ("vfs_show_fsbrowser", function ()
	VFS.FileSystemBrowser ():GetFrame ():SetVisible (true)
end)