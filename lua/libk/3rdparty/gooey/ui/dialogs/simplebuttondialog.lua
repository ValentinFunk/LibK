local PANEL = {}

function PANEL:Init ()
	self:SetTitle ("Dialog")
	
	self:SetSize (300, 128)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:SetKeyboardInputEnabled (true)
	self:MakePopup ()
	
	self:SetMaximizable (false)
	self:SetSizable (false)
	
	self.Buttons = {}
	self.TextLabel = vgui.Create ("DLabel", self)
	self.TextLabel:SetContentAlignment ("7")
	
	self.Callback = Gooey.NullCallback
	
	self:SetKeyboardMap (Gooey.KeyboardMap ())
	self:GetKeyboardMap ():Register ({ KEY_ESCAPE },
		function (self, key, ctrl, shift, alt)
			self:Remove ()
			gui.HideGameUI ()
		end
	)
	
	self:AddEventListener ("TextChanged",
		function (_, text)
			self.TextLabel:SetText (text)
		end
	)
	
	Gooey:AddEventListener ("Unloaded", self:GetHashCode (),
		function ()
			self:Remove ()
		end
	)
end

function PANEL:AddButton (text)
	local button = vgui.Create ("GButton", self)
	self.Buttons [#self.Buttons + 1] = button
	
	button:SetSize (80, 24)
	button:SetText (text)
	button:AddEventListener ("Click",
		function ()
			self.Callback (text)
			self.Callback = Gooey.NullCallback -- Don't call callback again in PANEL:Remove ()
			self:Remove ()
		end
	)
	
	self:InvalidateLayout ()
end

function PANEL:PerformLayout ()
	DFrame.PerformLayout (self)
	
	if self.Buttons then
		self.TextLabel:SetPos (8, 28)
		self.TextLabel:SetSize (self:GetWide () - 16, self:GetTall ())
	
		local x = self:GetWide ()
		for i = #self.Buttons, 1, -1 do
			x = x - 8 - self.Buttons [i]:GetWide ()
			self.Buttons [i]:SetPos (x, self:GetTall () - self.Buttons [i]:GetTall () - 8)
		end
	end
end

function PANEL:SetCallback (callback)
	self.Callback = callback or Gooey.NullCallback
	return self
end

function PANEL:SetTitle (title)
	DFrame.SetTitle (self, title)
	return self
end

function PANEL:OnRemoved ()
	self.Callback (nil)

	Gooey:RemoveEventListener ("Unloaded", self:GetHashCode ())
end

Gooey.Register ("GSimpleButtonDialog", PANEL, "GFrame")

function Gooey.YesNoDialog (callback)
	callback = callback or Gooey.NullCallback
	
	local dialog = vgui.Create ("GSimpleButtonDialog")
	dialog:SetCallback (callback)
	dialog:AddButton ("Yes")
	dialog:AddButton ("No")
	dialog:AddButton ("Cancel")
	
	return dialog
end