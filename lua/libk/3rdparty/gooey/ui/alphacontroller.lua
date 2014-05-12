local self = {}
Gooey.AlphaController = Gooey.MakeConstructor (self, Gooey.LiveLinearInterpolator)

--[[
	Events:
		FadeCompleted ()
			Fired when the fade has completed.
]]

function self:ctor ()
	self.Controls = {}
	
	self:SetAlpha (255)
	self:SetTargetAlpha (255)
	self:SetFadeRate (1024)
	
	self:AddEventListener ("InterpolationCompleted",
		function ()
			self:DispatchEvent ("FadeCompleted")
		end
	)
end

function self:AddControl (control)
	if not control or not control:IsValid () then return end
	
	self.Controls [control] = true
	control:SetAlpha (self:GetAlpha ())
end

function self:GetAlpha ()
	return self:GetValue ()
end

function self:GetTargetAlpha ()
	return self:GetTargetValue ()
end

function self:RemoveControl (control)
	self.Controls [control] = nil
end

function self:SetAlpha (alpha)
	self:SetValue (alpha)
end

function self:SetFadeRate (fadeRate)
	self:SetRate (fadeRate)
end

function self:SetTargetAlpha (targetAlpha)
	self:SetTargetValue (targetAlpha)
end

function self:Tick ()
	local alpha = self:GetAlpha ()
	for control, _ in pairs (self.Controls) do
		if control:IsValid () then
			control:SetAlpha (alpha)
		else
			self.Controls [control] = nil
		end
	end
end