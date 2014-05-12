local self = {}

function self:Init ()
	self:SetTitle ("Filesystem Browser")

	self:SetSize (ScrW () * 0.8, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.Folder = nil
	self.Path = ""
	
	self.FolderTree = vgui.Create ("VFSFolderTreeView", self)
	self.FolderTree:AddEventListener ("SelectedFolderChanged",
		function (_, folder)
			if not folder then return end
			self:SetFolder (folder)
		end
	)
	
	self.FileList = vgui.Create ("VFSFolderListView", self)	
	self.FileList:AddEventListener ("NodeOpened", function (_, node)
		if node:IsFolder () then
			self:SetFolder (node)
		else
			VFS.FileTypes:Open (node)
		end
	end)
	
	self.SplitContainer = vgui.Create ("GSplitContainer", self)
	self.SplitContainer:SetPanel1 (self.FolderTree)
	self.SplitContainer:SetPanel2 (self.FileList)
	self.SplitContainer:SetSplitterFraction (0.3)
	self.SplitContainer:SetSplitterThickness (7)
	
	self:SetFolder (VFS.Root)
	self:PerformLayout ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.SplitContainer then
		self.SplitContainer:SetPos (8, 30)
		self.SplitContainer:SetSize (self:GetWide () - 16, self:GetTall () - 38)
	end
end

function self:SetFolder (folder)
	if self.Folder == folder then return end
	self.Folder = folder
	self.Path = folder:GetPath ()
	
	self.FolderTree:SelectPath (self.Path)	
	self.FileList:SetFolder (folder)
end

function self:SetPath (path)
	if self.Path == path then return end
	self.Folder = nil
	self.Path = path

	self.FolderTree:SelectPath (self.Path)
	self.FileList:SetPath (path)
end

vgui.Register ("VFSFileSystemBrowserFrame", self, "GFrame")