local self = {}
Gooey.Clipboard = Gooey.MakeConstructor (self)

function self:ctor ()
	self.ClipboardText = ""
	
	self.ObtainedClipboardText = false
	self.IgnoreTextChange = true
	
	self.ClipboardControllers = Gooey.WeakKeyTable ()
	
	self.CopyTextEntry  = nil
	self.PasteTextEntry = nil
	--[[
	timer.Create ("Gooey.Clipboard", 0.5, 0,
		function ()
			if not self or not self.PasteTextEntry or not self.PasteTextEntry:IsValid () then return end
			
			self.ObtainedClipboardText = false
			
			self.IgnoreTextChange = true
			self.PasteTextEntry:SetText ("")
			self.IgnoreTextChange = false
			self.PasteTextEntry:PostMessage ("DoPaste", "", "")
			
			timer.Simple (0.2,
				function ()
					if not self or not self.PasteTextEntry or not self.PasteTextEntry:IsValid () then return end
					
					if not self.ObtainedClipboardText then
						self.PasteTextEntry:OnTextChanged ()
					end
				end
			)
		end
	)
	]]
	
	self:CreateTextEntry ()
	
	Gooey:AddEventListener ("Unloaded", self:GetHashCode (),
		function ()
			self:dtor ()
		end
	)
end

function self:dtor ()
	if self.CopyTextEntry and self.CopyTextEntry:IsValid () then
		self.CopyTextEntry:Remove ()
	end
	if self.PasteTextEntry and self.PasteTextEntry:IsValid () then
		self.PasteTextEntry:Remove ()
	end
	
	timer.Destroy ("Gooey.Clipboard")
	timer.Destroy ("Gooey.Clipboard.CreateTextEntry")
end

function self:CreateTextEntry ()
	if DTextEntry then
		self.CopyTextEntry  = vgui.Create ("DTextEntry")
		self.PasteTextEntry = vgui.Create ("DTextEntry")
	else
		timer.Create ("Gooey.Clipboard.CreateTextEntry", 0.5, 1,
			function ()
				self:CreateTextEntry ()
			end
		)
		return
	end
	
	self.CopyTextEntry:SetText ("")
	self.CopyTextEntry:SetVisible (false)
	
	self.PasteTextEntry:SetText ("")
	self.PasteTextEntry:SetVisible (false)
	self.PasteTextEntry.OnTextChanged = function ()
		if self.IgnoreTextChange then return false end
		
		local newClipboardText = self.PasteTextEntry:GetText ()
		if newClipboardText == self.ClipboardText then return end
		
		self.ClipboardText = newClipboardText
		for clipboardController, _ in pairs (self.ClipboardControllers) do
			clipboardController:DispatchEvent ("ClipboardTextChanged", self.ClipboardText)
		end
		
		self.ObtainedClipboardText = true
	end
end

function self:GetText ()
	return self.ClipboardText
end

function self:IsClipboardControllerRegistered (clipboardController)
	return self.ClipboardControllers [clipboardController] or false
end

function self:IsEmpty ()
	return false
	-- return self.ClipboardText == ""
end

function self:RegisterClipboardController (clipboardController)
	self.ClipboardControllers [clipboardController] = true
end

-- TextEntry hack thanks to Python1320
function self:SetText (newClipboardText)
	if not GLib.UTF8.ContainsSequences (newClipboardText) then
		SetClipboardText (newClipboardText)
	else
		local _, newlineCount = string.gsub (newClipboardText, "\n", "")
		newClipboardText = newClipboardText .. string.rep (" ", newlineCount)
		
		self.CopyTextEntry:SetText (newClipboardText)
		self.CopyTextEntry:SelectAllText ()
		self.CopyTextEntry:CutSelected ()
	end
	
	if self.ClipboardText == newClipboardText then return end
	
	self.ClipboardText = newClipboardText
	for clipboardController, _ in pairs (self.ClipboardControllers) do
		clipboardController:DispatchEvent ("ClipboardTextChanged", self.ClipboardText)
	end
	
	self.ObtainedClipboardText = true
end

function self:UnregisterClipboardController (clipboardController)
	self.ClipboardControllers [clipboardController] = nil
end

Gooey.Clipboard = Gooey.Clipboard ()