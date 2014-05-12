if not CLIENT then return end

local editorsUpdated = VFS.WeakKeyTable ()
local Expression2EditorFrame = {}

-- This gets overridden with the version from the editor
local function GetPreferredTitles (displayPath, code)
	return displayPath or "[Unknown]"
end

local function ModifyEditor (editor, name, path, displayPath)
	if not editor or not editor:IsValid () then return end
	
	for k, v in pairs (Expression2EditorFrame) do
		editor ["_" .. k] = editor ["_" .. k] or editor [k]
		editor [k] = v
	end
	GetPreferredTitles = VFS.FindUpValue (editor._LoadFile, "getPreferredTitles") or GetPreferredTitles
	
	VFS.Debug ("[VFS] Editor " .. name .. " never asked for this (" .. path .. ")")
	editor:InstallFileSystemBrowserOverride (path, displayPath)
end

local function InstallFileSystemBrowserOverride ()
	ModifyEditor (wire_expression2_editor, "wire_expression2_editor", GAuth.GetLocalId () .. "/Expression2", LocalPlayer ():Name () .. "/Expression2")
	ModifyEditor (ZCPU_Editor,             "ZCPU_Editor",             GAuth.GetLocalId () .. "/CPUChip",     LocalPlayer ():Name () .. "/CPUChip")
	ModifyEditor (ZGPU_Editor,             "ZGPU_Editor",             GAuth.GetLocalId () .. "/GPUChip",     LocalPlayer ():Name () .. "/GPUChip")
	ModifyEditor (ZSPU_Editor,             "ZSPU_Editor",             GAuth.GetLocalId () .. "/SPUChip",     LocalPlayer ():Name () .. "/SPUChip")
	if SF and SF.Editor then
		ModifyEditor (SF.Editor.editor,        "SF.Editor.editor",        GAuth.GetLocalId () .. "/Starfall",    LocalPlayer ():Name () .. "/Starfall")
	end
	
	local panelFactory = VFS.FindUpValue (vgui.Register, "PanelFactory")
	if panelFactory and panelFactory ["Expression2EditorFrame"] then
		local editor = panelFactory ["Expression2EditorFrame"]
		for k, v in pairs (Expression2EditorFrame) do
			editor ["_" .. k] = editor ["_" .. k] or editor [k]
			editor [k] = v
		end
		GetPreferredTitles = VFS.FindUpValue (editor._LoadFile, "getPreferredTitles") or GetPreferredTitles
	else
		GLib.CallDelayed (InstallFileSystemBrowserOverride)
	end
end

-- Delay updating the editors, since the filesystem hasn't fully initialized yet.
timer.Simple (1, InstallFileSystemBrowserOverride)

-- Expression2EditorFrame
function Expression2EditorFrame:Init ()
	self:_Init ()
	self:InstallFileSystemBrowserOverride ()
end

function Expression2EditorFrame:InstallFileSystemBrowserOverride (path, displayPath)
	if editorsUpdated [self] then return end
	editorsUpdated [self] = true
	
	-- Imported from wire/clients/wire_expression2_editor.lua : Editor:InitComponents ()
	local browserWidth = 227
	local browserRight = self.C ["Browser"].x + browserWidth
	self.C ["Browser"].w = browserWidth
	self.C ["Val"].x = browserRight + 3
	self.C ["Btoggle"].x = browserRight + 3
	self.C ["Sav"].x = self.C ["Btoggle"].x + self.C ["Btoggle"].w + 1
	self.C ["NewTab"].x = self.C ["Sav"].x + self.C ["Sav"].w + 1
	self.C ["CloseTab"].x = self.C ["NewTab"].x + self.C ["NewTab"].w + 1
	self.C ["TabHolder"].x = browserRight - 2
	self.C ["Btoggle"].panel.Think = function (button)
		if not button.toggle then return end
		if button.hide and self.C ["Btoggle"].x > 10 then
			self.C ["Btoggle"].x   = self.C ["Btoggle"].x   - button.anispeed
			self.C ["Sav"].x       = self.C ["Sav"].x       - button.anispeed
			self.C ["NewTab"].x    = self.C ["NewTab"].x    - button.anispeed
			self.C ["CloseTab"].x  = self.C ["CloseTab"].x  - button.anispeed
			self.C ["TabHolder"].x = self.C ["TabHolder"].x - button.anispeed
			self.C ["Val"].x       = self.C ["Val"].x       - button.anispeed
			self.C ["Browser"].w   = self.C ["Browser"].w   - button.anispeed
		elseif not button.hide and self.C ["Btoggle"].x < browserRight + 3 then
			self.C ["Btoggle"].x   = self.C ["Btoggle"].x   + button.anispeed
			self.C ["Sav"].x       = self.C ["Sav"].x       + button.anispeed
			self.C ["NewTab"].x    = self.C ["NewTab"].x    + button.anispeed
			self.C ["CloseTab"].x  = self.C ["CloseTab"].x  + button.anispeed
			self.C ["TabHolder"].x = self.C ["TabHolder"].x + button.anispeed
			self.C ["Val"].x       = self.C ["Val"].x       + button.anispeed
			self.C ["Browser"].w   = self.C ["Browser"].w   + button.anispeed
		end

		if self.C ["Browser"].panel:IsVisible () and self.C ["Browser"].w <= 0 then
			self.C ["Browser"].panel:SetVisible (false)
			self.C ["Browser"].w = 0
		elseif not self.C ["Browser"].panel:IsVisible() and self.C ["Browser"].w > 0 then
			self.C ["Browser"].panel:SetVisible (true)
		end
		
		if button.hide then
			if self.C ["Btoggle"].x > 10 or self.C ["Sav"].x > 30 or self.C ["Val"].x < browserRight + 3 or self.C ["Browser"].w > 0 then
				self.C ["Browser"].panel:SuppressLayout (true)
			else
				button.toggle = false
				self.C ["Browser"].panel:SuppressLayout (false)
			end
		else
			if self.C ["Btoggle"].x < browserRight + 3 or self.C ["Sav"].x < browserRight + 23 or self.C ["Val"].x < browserRight + 3 or self.C ["Browser"].w < browserRight - 17 then
				self.C ["Browser"].panel:SuppressLayout (true)
			else
				button.toggle = false
				self.C ["Browser"].w = browserWidth
				self.C ["Browser"].panel:SuppressLayout (false)
			end
		end
		self:InvalidateLayout ()
	end
	
	self.C ["Browser"].panel:SetWide (self.C ["Browser"].w)
	self.C ["Val"].panel:SetPos (self.C ["Val"].x, self.C ["Val"].y)
	self.C ["Btoggle"].panel:SetPos (self.C ["Btoggle"].x, self.C ["Btoggle"].y)
	self.C ["Sav"].panel:SetPos (self.C ["Sav"].x, self.C ["Sav"].y)
	self.C ["NewTab"].panel:SetPos (self.C ["NewTab"].x, self.C ["NewTab"].y)
	self.C ["CloseTab"].panel:SetPos (self.C ["CloseTab"].x, self.C ["CloseTab"].y)
	
	local componentEntry = self.C ["Browser"]
	local oldBrowser = componentEntry.panel
	local newBrowser = vgui.Create ("VFSFolderTreeView", self)
	componentEntry.panel = newBrowser
	componentEntry.panel:SetShowFiles (true)
	newBrowser:SetVisible (oldBrowser:IsVisible ())
	newBrowser:SetPos (oldBrowser:GetPos ())
	newBrowser:SetSize (oldBrowser:GetSize ())
	oldBrowser:Remove ()
	
	newBrowser.UpdateFolders = VFS.NullCallback
	newBrowser.Setup = VFS.NullCallback
	newBrowser:SelectPath (path or GAuth.GetLocalId ())
	self.VFSLocation = path or GAuth.GetLocalId ()
	self.DisplayLocation = displayPath or path or LocalPlayer ():GetName ()
	
	newBrowser:AddEventListener ("FileOpened",
		function (_, file)
			if not file:GetPermissionBlock ():IsAuthorized (GAuth.GetLocalId (), "Read") then return end
			self:LoadFile (file:GetPath ())
		end
	)
	
	-- Fixup tab paths
	for i = 1, self:GetNumTabs () do
		if not self:GetEditor (i).vfs_enabled then
			ErrorNoHalt (self:GetEditor (i).chosenfile .. "\n")
			if self:GetEditor (i).chosenfile and self:GetEditor (i).chosenfile ~= "generic" then
				self:GetEditor (i).displaypath = LocalPlayer ():Name () .. "/" .. self:GetEditor (i).chosenfile
				self:GetEditor (i).chosenfile = GAuth.GetLocalId () .. "/" .. self:GetEditor (i).chosenfile
				self:GetEditor (i).vfs_enabled = true
			end
		end
	end
	
	self:InvalidateLayout ()
end

function Expression2EditorFrame:ChosenFile (path, displayPath)
	displayPath = displayPath or path
	self:GetCurrentEditor ().chosenfile = path
	self:GetCurrentEditor ().displaypath = displayPath
	self:GetCurrentEditor ().vfs_enabled = true
	if displayPath then
		self:SubTitle("Editing: " .. displayPath)
	else
		self:SubTitle()
	end
end

function Expression2EditorFrame:GetChosenDisplayPath ()
	return self:GetCurrentEditor ().displaypath or self:GetChosenFile ()
end

function Expression2EditorFrame:LoadFile (path, newTab, callback)
	callback = callback or VFS.NullCallback
	
	VFS.Root:OpenFile (GAuth.GetLocalId (), path, VFS.OpenFlags.Read,
		function (returnCode, fileStream)
			if returnCode ~= VFS.ReturnCode.Success then callback (returnCode) return end
			fileStream:Read (fileStream:GetLength (),
				function (returnCode, data)
					if returnCode == VFS.ReturnCode.Progress then return end
				
					local displayPath = fileStream:GetDisplayPath ()
					fileStream:Close ()
					
					if data then
						-- Imported from wire/client/wire_expression2_editor : Editor:LoadFile
						self:AutoSave()
						if not newTab then
							for i = 1, self:GetNumTabs () do
								if self:GetEditor (i).chosenfile == path then
									self:SetActiveTab (i)
									self:SetCode (data)
									return
								elseif self:GetEditor (i):GetValue () == data then
									self:SetActiveTab (i)
									return
								end
							end
						end
						if not self.chip then
							local title, tabtext = GetPreferredTitles (displayPath, data)
							local tab
							if self.NewTabOnOpen:GetBool () or newTab then
								tab = self:CreateTab (tabtext).Tab
							else
								tab = self:GetActiveTab ()
								tab:SetText (tabtext)
								self.C ['TabHolder'].panel:InvalidateLayout ()
							end
							self:SetActiveTab (tab)
							self:ChosenFile (path, displayPath)
						end
						self:SetCode (data)
					end
					
					callback (returnCode)
				end
			)
		end
	)
end

-- Imported from wire/client/wire_expression2_editor.lua : Editor:OpenOldTabs
function Expression2EditorFrame:OpenOldTabs (callback)
	callback = callback or VFS.NullCallback

	if not file.Exists ("data/" .. self.Location .. "/_tabs_.txt", "GAME") then callback (VFS.ReturnCode.Finished) return end
	
	-- Read file
	local tabs = file.Read ("data/" .. self.Location .. "/_tabs_.txt", "GAME")
	if not tabs or tabs == "" then callback (VFS.ReturnCode.Finished) return end
	
	-- Explode around ;
	tabs = tabs:Split (";")
	if not tabs or #tabs == 0 then callback (VFS.ReturnCode.Finished) return end
	
	-- Temporarily remove fade time
	self:FixTabFadeTime ()
	
	local is_first = true
	local tabsDone = 0
	for _, filePath in ipairs (tabs) do
		if filePath and filePath ~= "" then
			if file.Exists ("data/" .. filePath, "GAME") then
				-- Open it in a new tab
				self:LoadFile (LocalPlayer ():Name () .. "/" .. filePath, true,
					function (returnCode)
						tabsDone = tabsDone + 1
						if tabsDone >= #tabs then callback (VFS.ReturnCode.Finished) end
					end
				)
				
				-- If this is the first loop, close the initial tab.
				if is_first then
					GLib.CallDelayed (
						function ()
							self:CloseTab (1)
						end
					)
					is_first = false
				end
			else
				VFS.Root:GetChild (GAuth.GetLocalId (), filePath,
					function (returnCode)
						if returnCode == VFS.ReturnCode.Success then
							self:LoadFile (filePath, true,
								function (returnCode)
									tabsDone = tabsDone + 1
									if tabsDone >= #tabs then callback (VFS.ReturnCode.Finished) end
								end
							)
							if is_first then
								GLib.CallDelayed (
									function ()
										self:CloseTab (1)
									end
								)
								is_first = false
							end
						end
					end
				)
			end
		end
	end
end

-- Imported from wire/client/wire_expression2_editor : Editor:SaveFile
function Expression2EditorFrame:SaveFile (path, close, saveAs)
	local suggestedName = self:GetCode ():match ("@name ([^\r\n]+)") or ""
	suggestedName = suggestedName:gsub ("[ \r\n\t\\/:*?|<>\"]", "_")
	if suggestedName == "" then suggestedName = "filename" end
	if suggestedName:sub (-1, -4):lower () ~= ".txt" then
		suggestedName = suggestedName .. ".txt"
	end
	
	if close and self.chip then
		if not self:Validate (true) then return end
		wire_expression2_upload ()
		self:Close ()
		return
	end
	if not path or path == self.Location .. "/" .. ".txt" or path == "generic" or saveAs then
		if self.C ["Browser"].panel:GetSelectedFolder () then
			path = self.C ["Browser"].panel:GetSelectedFolder ():GetPath ()
		end
		VFS.OpenSaveFileDialog ("Expression2.Editor",
			function (path)
				if not path then return end
				self:SaveFile (path, close)
			end
		)
		:SetPath (path)
		:SetSuggestedName (suggestedName)
		return
	end

	local panel = self.C ["Val"].panel
	local code = self:GetCode ()
	VFS.Root:OpenFile (GAuth.GetLocalId (), path, VFS.OpenFlags.Write + VFS.OpenFlags.Overwrite,
		function (returnCode, fileStream)
			if returnCode == VFS.ReturnCode.Success then
				fileStream:Write (code:len (), code,
					function (returnCode)
						local displayPath = fileStream:GetDisplayPath ()
						fileStream:Close ()
						if returnCode == VFS.ReturnCode.Success then
							self.C ["Val"].panel:SetBGColor (0, 128, 0, 180)
							self.C ["Val"].panel:SetFGColor (255, 255, 255, 128)
							GLib.CallDelayed (
								function ()
									panel:SetText ("   Saved as " .. displayPath)
								end
							)
							surface.PlaySound ("ambient/water/drip3.wav")
							if not self.chip then self:ChosenFile (path, displayPath) end
							if close then
								GAMEMODE:AddNotify ((self.E2 and "Expression" or "Source code") .." saved as " .. displayPath .. ".", NOTIFY_GENERIC, 7)
								self:Close ()
							end
						else
							self.C ["Val"].panel:SetBGColor (128, 0, 0, 180)
							self.C ["Val"].panel:SetFGColor (255, 255, 255, 128)
							GLib.CallDelayed (
								function ()
									panel:SetText ("   Failed to save to " .. path .. " (" .. VFS.ReturnCode [returnCode] .. ")")
								end
							)
							surface.PlaySound ("ambient/water/drip3.wav")
						end
					end
				)
			elseif returnCode == VFS.ReturnCode.AccessDenied then
				self.C ["Val"].panel:SetBGColor (128, 0, 0, 180)
				self.C ["Val"].panel:SetFGColor (255, 255, 255, 128)
				GLib.CallDelayed (
					function ()
						panel:SetText ("   Failed to save to " .. path .. ": Access denied!")
					end
				)
				surface.PlaySound ("ambient/water/drip3.wav")
			else
				self.C ["Val"].panel:SetBGColor (128, 0, 0, 180)
				self.C ["Val"].panel:SetFGColor (255, 255, 255, 128)
				GLib.CallDelayed (
					function ()
						panel:SetText ("   Failed to save to " .. path .. " (" .. VFS.ReturnCode [returnCode] .. ")")
					end
				)
				surface.PlaySound ("ambient/water/drip3.wav")
			end
		end
	)
end

-- Imported from wire/client/wire_expression2_editor : Editor:SetActiveTab
function Expression2EditorFrame:SetActiveTab (tabOrTabIndex)
	if self:GetActiveTab () == tabOrTabIndex then
		tabOrTabIndex:GetPanel():RequestFocus()
		return
	end
	self:SetLastTab (self:GetActiveTab ())
	if type (tabOrTabIndex) == "number" then
		self.C ["TabHolder"].panel:SetActiveTab (self.C ["TabHolder"].panel.Items [tabOrTabIndex].Tab)
		self:GetCurrentEditor ():RequestFocus ()
	elseif tabOrTabIndex and tabOrTabIndex:IsValid () then
		self.C ["TabHolder"].panel:SetActiveTab (tabOrTabIndex)
		tabOrTabIndex:GetPanel ():RequestFocus ()
	end
	
	-- Editor subtitle and tab text
	local title, tabtext = GetPreferredTitles (self:GetChosenDisplayPath (), self:GetCode ())

	if title then self:SubTitle ("Editing: " .. title) else self:SubTitle () end
	if tabtext then
		if self:GetActiveTab ():GetText () ~= tabtext then
			self:GetActiveTab ():SetText (tabtext)
			self.C ["TabHolder"].panel:InvalidateLayout ()
		end
	end
end

function Expression2EditorFrame:Setup (nTitle, nLocation, nEditorType)
	self:_Setup (nTitle, nLocation, nEditorType)
	self.VFSLocation = GAuth.GetLocalId () .. "/" .. nLocation
	self.DisplayLocation = LocalPlayer ():Name () .. "/" .. nLocation
	self.C ["Browser"].panel:SelectPath (self.VFSLocation or GAuth.GetLocalId ())
end