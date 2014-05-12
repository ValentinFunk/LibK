local self = {}
Gooey.LiveLinearInterpolator = Gooey.MakeConstructor (self, Gooey.LiveAdditiveInterpolator)

function self:ctor ()
	self.Rate = 100
end

function self:GetRate ()
	return self.Rate
end

function self:GetTargetValue ()
	return self:GetFinalValue ()
end

function self:SetTargetValue (targetValue, duration)
	local deltaValue = targetValue - self:GetTargetValue ()
	if deltaValue == 0 then return end
	
	if not duration then
		duration = math.abs (deltaValue / self.Rate)
	end
	
	self:AddInterpolator (
		Gooey.ScaledTimeInterpolator (
			Gooey.LinearInterpolator (),
			duration,
			deltaValue
		)
	)
end

function self:SetRate (rate)
	if self.Rate == rate then return end
	if rate < 0 then rate = -rate end
	
	self.Rate = rate
end