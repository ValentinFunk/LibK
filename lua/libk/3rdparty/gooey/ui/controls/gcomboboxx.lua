local PANEL = {}

function PANEL:Init ()	
	self.Autocompletion = vgui.Create ("GListBox", self)
	self.Autocompletion:SetMouseInputEnabled (true)
	self.Autocompletion:SetMultiple (false)
	self.Autocompletion:SetVisible (false)
	self.Autocompletion.Think = function (comboBox)
		if not self:IsValid () then
			comboBox:Remove ()
			return
		end
		if not self:IsFocused () and not self.Autocompletion:IsFocused () and not self.Autocompletion:IsHovered () and self.AutocompletionVisible then
			self.Autocompletion:SetParent (self)
			self.AutocompletionVisible = false
			self.Autocompletion:SetVisible (false)
		end
	end
	
	self.Autocompletion:AddEventListener ("ItemSelected", function (comboBox, item)
		if item then
			self:SetText (item:GetText ())
			self:DispatchEvent ("TextChanged", self:GetText ())
		end
	end)
	self.AutocompletionVisible = false
	
	self.LastAutocompletedText = nil
	self.LastShowable = false
	self.AutocompletionCache = {}
	self.Autocompleter = nil
end

function PANEL:HideAutocompletion ()
	if self.AutocompletionVisible then
		self.Autocompletion:SetParent (self)
		self.AutocompletionVisible = false
		self.Autocompletion:SetVisible (false)
	end
end

function PANEL:LayoutAutocompletion ()
	local x, y = self:LocalToScreen (0, self:GetTall () + 4)
	local dx, dy = self.Autocompletion:GetParent ():LocalToScreen (0, 0)
	x = x - dx
	y = y - dy
	self.Autocompletion:SetPos (x, y)
	self.Autocompletion:SetSize (self:GetWide (), 256)
end

function PANEL:OnTextChanged ()
	self:UpdateAutocompletion ()
	self:DispatchEvent ("TextChanged", self:GetText ())
end

function PANEL:SetAutocompleter (autocompleter)
	self.Autocompleter = autocompleter
	
	-- reset caching
	self.AutocompletionCache = {}
	self.LastAutocompletedText = nil
end

function PANEL:ShowAutocompletion ()
	if not self.AutocompletionVisible then
		local topLevelParent = self:GetParent ()
		while topLevelParent:GetParent ():GetParent () do
			topLevelParent = topLevelParent:GetParent ()
		end
		self.Autocompletion:SetParent (topLevelParent)
		self.AutocompletionVisible = true
		self.Autocompletion:SetVisible (true)
		
		self:LayoutAutocompletion ()
	end
end

function PANEL:Think ()
	if self:IsFocused () or self.Autocompletion:IsFocused () or self.Autocompletion:IsHovered () then
		if not self.AutocompletionVisible then
			self:UpdateAutocompletion (self.LastShowable == false)
		end
		self.LastShowable = true
	else
		if self.AutocompletionVisible then
			self:HideAutocompletion ()
		end
		self.LastShowable = false
	end
end

function PANEL:UpdateAutocompletion (forceRegeneration)
	if not forceRegeneration and self:GetText () == self.LastAutocompletedText then
		return
	end

	if self.Autocompleter == nil then
		return
	end
	
	local results = nil
	
	if self.AutocompletionCache [self:GetText ()] then
		results = self.AutocompletionCache [self:GetText ()]
	else
		results = self.Autocompleter
		if type (self.Autocompleter) == "function" then
			results = self.Autocompleter (self:GetText ())
		end
		
		self.AutocompletionCache [self:GetText ()] = results
	end
	
	local show = true
	if #results == 0 then
		show = false
	end
	if #results == 1 and results [1] == self:GetText () then
		show = false
	end
	
	if show then
		self:ShowAutocompletion ()
		
		-- avoid repopulating if the dropdown already has the items we want
		if self.LastAutocompletedText ~= self:GetText () then			
			-- try to reuse controls.
			-- ugly, but fast code ahead
			local i = 1
			local toremove = {}
			local controls = self.Autocompletion.Items
			for k, v in pairs (controls) do
				if i > #results then
					-- hide the lines we don't need
					while k ~= nil do
						controls [k]:SetVisible (false)
						k = next (controls, k)
					end
					break
				end
				
				v:SetVisible (true)
				v:SetText (results [i])
				i = i + 1
			end
			
			-- add extra lines
			while i < #results do
				self.Autocompletion:AddItem (results [i])
				i = i + 1
			end
			
			self.Autocompletion:InvalidateLayout ()
		end
	else
		self:HideAutocompletion ()
	end
	self.LastAutocompletedText = self:GetText ()
	
	return show
end

Gooey.Register ("GComboBoxX", PANEL, "DTextEntry")