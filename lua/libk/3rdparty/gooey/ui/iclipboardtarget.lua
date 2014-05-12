local self = {}
Gooey.IClipboardTarget = Gooey.MakeConstructor (self)

--[[
	Events:
		CanCopyChanged (canCopy)
			Fired when the copy command's state has changed.
		CanPasteChanged (canPaste)
			Fired when the paste command's state has changed.
]]

function self:ctor ()
	Gooey.EventProvider (self)
end

function self:CanCopy ()
	return false
end

function self:CanPaste ()
	return false
end

function self:Copy ()
	self:DispatchEvent ("Copy")
end

function self:Cut ()
	self:DispatchEvent ("Cut")
end

function self:Paste ()
	self:DispatchEvent ("Paste")
end