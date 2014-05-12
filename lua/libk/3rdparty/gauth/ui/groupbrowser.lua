local self = {}
local ctor = GAuth.MakeConstructor (self)
local instance = nil

function GAuth.GroupBrowser ()
	if not instance then
		instance = ctor ()
		
		GAuth:AddEventListener ("Unloaded", function ()
			instance:dtor ()
			instance = nil
		end)
	end
	return instance
end

function self:ctor ()
	self.Panel = vgui.Create ("GAuthGroupBrowserFrame")
end

function self:dtor ()
	if self.Panel and self.Panel:IsValid () then
		self.Panel:Remove ()
	end
end

function self:GetFrame ()
	return self.Panel
end

concommand.Add ("gauth_show_groupbrowser", function ()
	GAuth.GroupBrowser ():GetFrame ():SetVisible (true)
end)