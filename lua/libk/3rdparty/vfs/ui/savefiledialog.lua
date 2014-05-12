local self = {}

function self:Init ()
	self:SetTitle ("Save as...")
	self:SetVerb ("Save")
	
	self:SetFileMustExist (false)
end

vgui.Register ("VFSSaveFileDialog", self, "VFSFileDialog")

--- Displays a file selection dialog.
-- @param callback A callback function taking a path and its corresponding IFile if it exists.
function VFS.OpenSaveFileDialog (dialogId, callback)
	local dialog = vgui.Create ("VFSSaveFileDialog")
	dialog:SetDialogId (dialogId)
	dialog:ImportSavedPath ()
	dialog:SetCallback (callback)
	dialog:SetVisible (true)
	dialog:SelectAll ()
	
	return dialog
end