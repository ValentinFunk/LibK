local self = {}

function self:Init ()
	self:SetTitle ("Select file...")

	self:SetSize (ScrW () * 0.5, ScrH () * 0.5)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:MakePopup ()
	
	self.SuggestedName = ""
	self.Callback = VFS.NullCallback
	
	self.Folders = vgui.Create ("VFSFolderTreeView", self)
	self.Folders:AddEventListener ("SelectedFolderChanged",
		function (_, folder)
			self.Files:SetFolder (folder)
		end
	)
	
	self.Files = vgui.Create ("VFSFolderListView", self)
	self.Files:SetSelectionMode (Gooey.SelectionMode.One)
	self.Files:AddEventListener ("SelectedFileChanged",
		function (_, file)
			if not file then return end
			self:SetFileName (file:GetName ())
		end
	)
	self.Files:AddEventListener ("NodeOpened",
		function (_, node)
			if node:IsFolder () then
				self:SetFolder (node)
			else
				self:SetFileName (node:GetName ())
				self.Done:DispatchEvent ("Click")
			end
		end
	)
	
	self.SplitContainer = vgui.Create ("GSplitContainer", self)
	self.SplitContainer:SetPanel1 (self.Folders)
	self.SplitContainer:SetPanel2 (self.Files)
	self.SplitContainer:SetSplitterFraction (0.3)
	self.SplitContainer:SetSplitterThickness (7)
	
	self.FileName = vgui.Create ("GTextEntry", self)
	self.FileName.OnEnter = function ()
		self.Done:DispatchEvent ("Click")
		self.FileName:Focus ()
	end
	self.FileName:Focus ()
	
	self.ErrorText = vgui.Create ("DLabel", self)
	self.ErrorText:SetTextColor (Color (255, 128, 128, 255))
	self.ErrorText:SetText ("")
	
	self.Done = vgui.Create ("GButton", self)
	self.Done:SetText ("Save")
	self.Done:AddEventListener ("Click",
		function (_)
			-- Check for http uri
			local uri = self:GetRawFileName ()
			if string.find (uri, "^https?://") then
				self.Callback (uri, VFS.HTTPResource (uri))
				self.Callback = VFS.NullCallback -- Don't call it again
				self:Remove ()
				return
			end
			
			local path = VFS.Path (self:GetFolder ():GetPath () .. "/" .. self:GetFileName ()):GetPath ()
			VFS.Root:GetChild (GLib.GetLocalId (), path,
				function (returnCode, node)
					if returnCode == VFS.ReturnCode.Success then
						if node:IsFolder () then
							self:SetFolder (node)
							self.FileName:SetText (self:GetSuggestedName ())
							self:SelectAll ()
							self:ClearError ()
						else
							self.Callback (path, VFS.FileResource (node))
							self.Callback = VFS.NullCallback -- Don't call it again in PANEL:Remove ()
							self:Remove ()
						end
					elseif returnCode == VFS.ReturnCode.NotFound then
						if not self.FileMustExist then
							self.Callback (path, nil)
							self.Callback = VFS.NullCallback -- Don't call it again in PANEL:Remove ()
							self:Remove ()
						end
					elseif returnCode == VFS.ReturnCode.AccessDenied then
						self:Error ("Access denied.")
					else
						self:Error ("Unknown error.")
					end
				end
			)
		end
	)
	
	self.Cancel = vgui.Create ("GButton", self)
	self.Cancel:SetText ("Cancel")
	self.Cancel:AddEventListener ("Click",
		function (_)
			self.Callback (nil, nil)
			self.Callback = GAuth.NullCallback -- Don't call it again in PANEL:Remove ()
			self:Remove ()
		end
	)
	
	self:PerformLayout ()
	
	VFS:AddEventListener ("Unloaded", self:GetHashCode (), function ()
		self:Remove ()
	end)
	
	self.FileMustExist = false
	self.DialogId = nil
	
	self:SetPath (VFS.GetLocalHomeDirectory ())
end

function self:ClearError ()
	self.ErrorText:SetText ("")
end

function self:Error (message)
	self.ErrorText:SetText (message)
end

function self:GetDialogId ()
	return self.DialogId
end

function self:GetFileName ()
	return self.FileName:GetText ():gsub ("[\r\n\t:*?|<>\"]", "_")
end

function self:GetFolder ()
	return self.Folders:GetSelectedFolder ()
end

function self:GetFolderPath ()
	if not self:GetFolder () then return "" end
	return self:GetFolder ():GetPath ()
end

function self:GetRawFileName ()
	return self.FileName:GetText ()
end

function self:GetSuggestedName ()
	return self.SuggestedName
end

function self:ImportSavedPath (dialogId)
	dialogId = dialogId or self.DialogId
	if not dialogId then return end
	
	local path = VFS.FileDialogPaths:GetPath (dialogId)
	if not path then return end
	
	self:SetPath (path)
end

function self:PerformLayout ()
	DFrame.PerformLayout (self)
	if self.SplitContainer then
		self.Cancel:SetSize (80, 24)
		self.Done:SetSize (80, 24)
		
		if self:GetTall () < self.Cancel:GetTall () + self.Done:GetTall () + 44 then
			self:SetTall (self.Cancel:GetTall () + self.Done:GetTall () + 44)
		end
		
		self.Cancel:SetPos (self:GetWide () - self.Cancel:GetWide () - 8, self:GetTall () - self.Cancel:GetTall () - 8)
		self.Done:SetPos (self:GetWide () - self.Done:GetWide () - 8, self:GetTall () - self.Cancel:GetTall () - self.Done:GetTall () - 16)
		
		self.FileName:SetPos (8, self:GetTall () - self.Cancel:GetTall () - self.Done:GetTall () - 16)
		self.FileName:SetSize (self:GetWide () - 24 - self.Done:GetWide (), self.Done:GetTall ())
		
		self.ErrorText:SetPos (8, self:GetTall () - self.Cancel:GetTall () - 8)
		self.ErrorText:SetSize (self:GetWide () - 24 - self.Cancel:GetWide (), self.Cancel:GetTall ())
		self.ErrorText:SetContentAlignment (4)
		
		self.SplitContainer:SetPos (8, 30)
		self.SplitContainer:SetSize (self:GetWide () - 16, self:GetTall () - 54 - self.Done:GetTall () - self.Cancel:GetTall ())
	end
end

function self:SelectAll ()
	GLib.CallDelayed (
		function ()
			if not self or not self:IsValid () then return end
			if not self.FileName or not self.FileName:IsValid () then return end
			
			self.FileName:SelectAll ()
			self.FileName:SetCaretPos (GLib.UTF8.Length (self.FileName:GetText ()))
		end
	)
end

function self:SetCallback (callback)
	self.Callback = callback or VFS.NullCallback
end

function self:SetDialogId (dialogId)
	self.DialogId = dialogId
end

function self:SetFileMustExist (fileMustExist)
	self.FileMustExist = fileMustExist
end

function self:SetFileName (name)
	self.FileName:SetText (name)
	return self
end

function self:SetFolder (folder)
	if not folder:IsFolder () then folder = folder:GetParentFolder () end
	self.Folders:SetPath (folder:GetPath ())
	self.Files:SetFolder (folder)
	return self
end

function self:SetPath (path)
	self.Folders:SetPath (path)
	self.Files:SetPath (path)
	return self
end

function self:SetSuggestedName (suggestedName)
	self.SuggestedName = suggestedName
	self:SetFileName (suggestedName)
	return self
end

function self:SetVerb (verb)
	self.Done:SetText (verb)
end

-- Event handlers
function self:OnRemoved ()
	self.Callback (nil, nil)
	
	if self:GetDialogId () then
		VFS.FileDialogPaths:SetPath (self:GetDialogId (), self:GetFolderPath ())
	end

	if self.Folders then self.Folders:Remove () end
	if self.Files   then self.Files:Remove ()   end
	VFS:RemoveEventListener ("Unloaded", self:GetHashCode ())
end

vgui.Register ("VFSFileDialog", self, "GFrame")