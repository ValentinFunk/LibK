local self = {}

function self:Init ()
	self:SetTitle ("Group Browser")

	self:SetSize (ScrW () * 0.8, ScrH () * 0.75)
	self:Center ()
	self:SetDeleteOnClose (false)
	self:MakePopup ()
	
	self.Groups = vgui.Create ("GAuthGroupTreeView", self)
	self.Groups:AddEventListener ("SelectedGroupTreeNodeChanged",
		function (_, groupTreeNode)
			self.Users:SetGroup (groupTreeNode)
		end
	)
	
	self.Users = vgui.Create ("GAuthGroupListView", self)
	
	self.SplitContainer = vgui.Create ("GSplitContainer", self)
	self.SplitContainer:SetPanel1 (self.Groups)
	self.SplitContainer:SetPanel2 (self.Users)
	self.SplitContainer:SetSplitterFraction (0.2)
	self.SplitContainer:SetSplitterThickness (7)
	
	self:PerformLayout ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.SplitContainer then
		self.SplitContainer:SetPos (8, 30)
		self.SplitContainer:SetSize (self:GetWide () - 16, self:GetTall () - 38)
	end
end

function self:SetGroupTree (groupTree)
	if not groupTree then return end
	self.Groups:SelectGroup (groupTree)
	self.Users:SetGroup (groupTree)
end

vgui.Register ("GAuthGroupBrowserFrame", self, "GFrame")