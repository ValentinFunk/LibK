local self = {}
Gooey.LiveSmoothingInterpolator = Gooey.MakeConstructor (self, Gooey.LiveAdditiveInterpolator)

function self:ctor ()
	self.DefaultDuration = 1
end

function self:GetDefaultDuration ()
	return self.DefaultDuration
end

function self:GetTargetValue ()
	return self:GetFinalValue ()
end

function self:SetDefaultDuration (defaultDuration)
	self.DefaultDuration = defaultDuration
end

function self:SetTargetValue (targetValue, duration)
	duration = duration or self:GetDefaultDuration ()
	
	local deltaValue = targetValue - self:GetTargetValue ()
	if deltaValue == 0 then return end
	
	self:AddInterpolator (
		Gooey.ScaledTimeInterpolator (
			Gooey.AccelerationDecelerationInterpolator (),
			duration,
			deltaValue
		)
	)
end