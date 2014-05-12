local self = {}

function self:Init ()
	self:SetTitle ("Group Selection")

	self:SetSize (ScrW () * 0.4, ScrH () * 0.4)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:MakePopup ()
	
	self.Callback = GAuth.NullCallback
	
	self.Groups = vgui.Create ("GAuthGroupTreeView", self)
	
	self.Done = vgui.Create ("GButton", self)
	self.Done:SetText ("Done")
	self.Done:AddEventListener ("Click",
		function (_)
			self.Callback (self:GetSelectedGroup ())
			self.Callback = GAuth.NullCallback -- Don't call it again in PANEL:OnRemoved ()
			self:Remove ()
		end
	)
	
	self:PerformLayout ()
	
	GAuth:AddEventListener ("Unloaded", self:GetHashCode (), function ()
		self:Remove ()
	end)
end

function self:GetSelectedGroup ()
	return self.Groups:GetSelectedGroup ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.Groups then		
		self.Done:SetSize (80, 32)
		self.Done:SetPos (self:GetWide () - self.Done:GetWide () - 8, self:GetTall () - self.Done:GetTall () - 8)
		
		self.Groups:SetPos (8, 30)
		self.Groups:SetSize (self:GetWide () - 16, self:GetTall () - 46 - self.Done:GetTall ())
	end
end

function self:SetCallback (callback)
	self.Callback = callback or GAuth.NullCallback
end

function self:OnRemoved ()
	self.Callback (nil)

	if self.Groups then self.Groups:Remove () end
	GAuth:RemoveEventListener ("Unloaded", self:GetHashCode ())
end

vgui.Register ("GAuthGroupSelectionDialog", self, "GFrame")

function GAuth.OpenGroupSelectionDialog (callback)
	local dialog = vgui.Create ("GAuthGroupSelectionDialog")
	dialog:SetCallback (callback)
	dialog:SetVisible (true)
	
	return dialog
end