local PANEL = {}
Gooey.ToolbarComboBox = Gooey.MakeConstructor (PANEL, Gooey.ToolbarItem)

function PANEL:ctor (text)
	self:Init ()
	
	self.Text = ""
	self.Height = 24
	
	self.ComboBox = vgui.Create ("GComboBox")
	
	self.ComboBox:AddEventListener ("SizeChanged",
		function (_)
			self:SetWidth (self.ComboBox:GetWidth () + 4)
			self:SetHeight (self.ComboBox:GetHeight ())
		end
	)
	
	self:AddEventListener ("ParentChanged",
		function (_, oldParent, parent)
			while parent and
			      type (parent) ~= "Panel" do
				parent = parent:GetParent ()
			end
			
			parent = parent or vgui.GetWorldPanel ()
			
			self.ComboBox:SetParent (parent)
		end
	)
	
	self:AddEventListener ("PositionChanged",
		function (_, x, y)
			self.ComboBox:SetPos (x + 2, y)
		end
	)
	
	self:AddEventListener ("Click",
		function (_, text)
			self:RunAction ()
		end
	)
end

function PANEL:Init ()
end

function PANEL:GetComboBox ()
	return self.ComboBox
end

function PANEL:OnRemoved ()	
	self.ComboBox:Remove ()
end