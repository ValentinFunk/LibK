local self = {}
VFS.FileDialogPaths = VFS.MakeConstructor (self)

function self:ctor ()
	self.NeedsSaving = false
	self.DialogPaths = {}
	
	timer.Create ("VFS.FileDialogPaths.Save", 10, 0,
		function ()
			if not self.NeedsSaving then return end
			self:Save ()
		end
	)
	
	self:Load ()
end

function self:dtor ()
	timer.Destroy ("VFS.FileDialogPaths.Save")
	
	if not self.NeedsSaving then return end
	self:Save ()
end

function self:GetPath (dialogId)
	return self.DialogPaths [dialogId]
end

function self:SetPath (dialogId, path)
	if self.DialogPaths [dialogId] == path then return end
	self.DialogPaths [dialogId] = path
	self.NeedsSaving = true
end

function self:Load ()
	local data = file.Read ("vfs_filedialog_paths.txt") or ""
	if data == "" then return end
	local inBuffer = VFS.StringInBuffer (data)
	local dialogId = inBuffer:String ()
	while dialogId ~= "" do
		local path = inBuffer:String ()
		self:SetPath (dialogId, path)
		
		inBuffer:Char () -- discard newline
		dialogId = inBuffer:String ()
	end
	self.NeedsSaving = false
end

function self:Save ()
	self.NeedsSaving = false
	
	local outBuffer = VFS.StringOutBuffer ()
	for dialogId, path in pairs (self.DialogPaths) do
		outBuffer:String (dialogId)
		outBuffer:String (path)
		outBuffer:Char ("\n")
	end
	outBuffer:String ("")
	
	file.Write ("vfs_filedialog_paths.txt", outBuffer:GetString ())
end

VFS.FileDialogPaths = VFS.FileDialogPaths ()