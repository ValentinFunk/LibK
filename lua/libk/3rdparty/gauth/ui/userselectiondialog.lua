local self = {}

function self:Init ()
	self:SetTitle ("User Selection")

	self:SetSize (ScrW () * 0.4, ScrH () * 0.4)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:MakePopup ()
	
	self.Callback = GAuth.NullCallback
	self.SelectedUsers = {}
	
	self.Users = vgui.Create ("GAuthUserListView", self)
	self.Users:AddEventListener ("UserSelected",
		function (_, userId)
			self.SelectedUserId = userId
		end
	)
	
	self.Done = vgui.Create ("GButton", self)
	self.Done:SetText ("Done")
	self.Done:AddEventListener ("Click",
		function (_)
			if self:GetSelectionMode () == Gooey.SelectionMode.One then
				self.Callback (self:GetSelectedUser ())
			else
				self.Callback (self:GetSelectedUsers ())
			end
			self.Callback = GAuth.NullCallback -- Don't call it again in PANEL:Remove ()
			self:Remove ()
		end
	)
	
	self:PerformLayout ()
	
	GAuth:AddEventListener ("Unloaded", self:GetHashCode (), function ()
		self:Remove ()
	end)
end

function self:GetSelectedUser ()
	return self.Users:GetSelectedUser ()
end

function self:GetSelectedUsers ()
	return self.Users:GetSelectedUsers ()
end

function self:GetSelectionMode ()
	return self.Users:GetSelectionMode ()
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.Users then		
		self.Done:SetSize (80, 32)
		self.Done:SetPos (self:GetWide () - self.Done:GetWide () - 8, self:GetTall () - self.Done:GetTall () - 8)
		
		self.Users:SetPos (8, 30)
		self.Users:SetSize (self:GetWide () - 16, self:GetTall () - 46 - self.Done:GetTall ())
	end
end

function self:SetCallback (callback)
	self.Callback = callback or GAuth.NullCallback
end

function self:SetSelectionMode (selectionMode)
	self.Users:SetSelectionMode (selectionMode)
end

-- Event handlers
function self:OnRemoved ()
	self.Callback (nil)

	if self.Users then self.Users:Remove () end
	GAuth:RemoveEventListener ("Unloaded", self:GetHashCode ())
end

vgui.Register ("GAuthUserSelectionDialog", self, "GFrame")

function GAuth.OpenUserSelectionDialog (callback)
	local dialog = vgui.Create ("GAuthUserSelectionDialog")
	dialog:SetCallback (callback)
	dialog:SetVisible (true)
	
	return dialog
end