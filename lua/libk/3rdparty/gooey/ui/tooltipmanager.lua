local self = {}
Gooey.ToolTipManager = Gooey.MakeConstructor (self)

function self:ctor ()
	self.ToolTips = {}
	
	Gooey:AddEventListener ("Unloaded",
		function ()
			self:dtor ()
		end
	)
end

function self:dtor ()
	for toolTip, _ in pairs (self.ToolTips) do
		toolTip:Remove ()
	end
end

function self:GetToolTip ()
	for toolTip, _ in pairs (self.ToolTips) do
		if toolTip:IsFree () then
			toolTip:SetVisible (false) -- reset tooltip state
			return toolTip
		end
	end
	
	local toolTip = vgui.Create ("GToolTip")
	self.ToolTips [toolTip] = true
	toolTip:SetVisible (false)
	return toolTip
end

Gooey.ToolTipManager = Gooey.ToolTipManager ()