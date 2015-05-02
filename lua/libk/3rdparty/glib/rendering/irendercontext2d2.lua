local self = {}
GLib.Rendering.IRenderContext2d2 = GLib.MakeConstructor (self, GLib.Rendering.IRenderContext2d)

function self:ctor ()
	self.AntiAliasingStack = GLib.Containers.Stack ()
end

function self:PushAntiAliasing (antiAliasing)
	self.AntiAliasingStack:Push (self:GetAntiAliasing ())
	self:SetAntiAliasing (antiAliasing)
end

function self:PopAntiAliasing ()
	self:SetAntiAliasing (self.AntiAliasingStack:Pop ())
end