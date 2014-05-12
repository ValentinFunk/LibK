local self = {}

function self:Init ()
	self:SetTitle ("Open...")
	self:SetVerb ("Open")
	
	self:SetFileMustExist (true)
end

vgui.Register ("VFSOpenFileDialog", self, "VFSFileDialog")

--- Displays a file selection dialog which can only select existing files.
-- @param callback A callback function taking a path and its corresponding IFile.
function VFS.OpenOpenFileDialog (dialogId, callback)
	local dialog = vgui.Create ("VFSOpenFileDialog")
	dialog:SetDialogId (dialogId)
	dialog:ImportSavedPath ()
	dialog:SetCallback (callback)
	dialog:SetVisible (true)
	dialog:SelectAll ()
	
	return dialog
end