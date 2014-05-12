local PANEL = {}

function PANEL:Init ()
	self:SetMouseInputEnabled (true)
	self:SetKeyboardInputEnabled (true)
	self:SetTextInset (3, 0)

	self.TextEntry = vgui.Create ("GTextEntry", self)
	self.TextEntry:SetText (self:GetText ())
	self.TextEntry:SetVisible (false)
	
	self.DoNotHideTextEntry = false
	self.TextEntry:AddEventListener ("MouseEnter",
		function (_)
			self.DoNotHideTextEntry = false
		end
	)
	self.TextEntry:AddEventListener ("MouseLeave",
		function (_)
			if self:ShouldHideTextEntry () then
				self:HideTextEntry ()
			end
		end
	)
	self.TextEntry:AddEventListener ("TextChanged",
		function ()
			if not self:IsTextEntryVisible () then
				return
			end
			self:SetText (textEntry:GetText ())
		end
	)
	
	self.PreviousText = nil
end

function PANEL:HideTextEntry ()
	if not self.TextEntry:IsVisible () then
		return
	end
	if self:GetText () ~= self.PreviousText then
		self:DispatchEvent ("TextChanged", self.PreviousText, self:GetText ())
	end
	self.TextEntry:SetVisible (false)
end

function PANEL:IsTextEntryVisible ()
	return self.TextEntry:IsVisible ()
end

function PANEL:OnCursorEntered ()
	self:ShowTextEntry ()
end

function PANEL:OnCursorExited ()
	if self:ShouldHideTextEntry () then
		self:HideTextEntry ()
	end
	self.DoNotHideTextEntry = false
end

function PANEL:PerformLayout ()
	self.TextEntry:SetPos (0, 0)
	self.TextEntry:SetSize (self:GetWide (), self:GetTall ())
end

function PANEL:SetFont (font)
	self.TextEntry:SetFont (font)
	debug.getregistry ().Panel.SetFont (self, font)
end

function PANEL:SetText (text)
	if self:GetText () == text then
		return
	end
	if not self:IsTextEntryVisible () then
		self.TextEntry:SetText (text)
	end
	
	debug.getregistry ().Panel.SetText (self, text)
end

function PANEL:ShouldHideTextEntry ()
	if self.Hovered or self.TextEntry.Hovered or self.TextEntry:IsFocused () then
		return false
	end
	if self.DoNotHideTextEntry then
		return false
	end
	return true
end

function PANEL:ShowTextEntry ()
	self.DoNotHideTextEntry = true
	self.TextEntry:SetVisible (true)
end

function PANEL:Think ()
	if self:IsTextEntryVisible () and self:ShouldHideTextEntry () then
		self:HideTextEntry ()
	end
end

Gooey.Register ("GEditableLabel", PANEL, "DLabel")