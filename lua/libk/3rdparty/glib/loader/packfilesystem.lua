local self = {}
GLib.Loader.PackFileSystem = GLib.MakeConstructor (self)

function self:ctor ()
	self.Revision = 0
	
	self.Name = ""
	
	self.FileCount = 0
	
	self.Root = {}
	self.SystemTableNames = {}
	self.SystemTableNameSet = {}
	
	self.CachedFunctions = {}
	
	self.PackFile = ""
	self.CompressedPackFile = ""
	self.PackFileRevision = -1
end

function self:AddSystemTable (systemTableName)
	if not systemTableName or systemTableName == "" then return end
	if self.SystemTableNameSet [systemTableName] then return end
	
	self.Revision = self.Revision + 1
	self.SystemTableNames [#self.SystemTableNames + 1] = systemTableName
	self.SystemTableNameSet [systemTableName] = true
end

function self:Exists (path)
	local path = self:NormalizePath (path)
	return self:GetNode (path) and true or false
end

function self:Find (path)
	local path = self:NormalizePath (path)
	
	local parts = path:Split ("/")
	parts [#parts] = nil
	path = table.concat (parts, "/")
	local folder = self:GetNode (path)
	local files   = {}
	local folders = {}
	for name, data in pairs (folder or {}) do
		if type (data) == "string" then
			files [#files + 1] = name
		else
			folders [#folders + 1] = name
		end
	end
	return files, folders
end

function self:GetCompressedSerializedPackFile ()
	if self.PackFileRevision ~= self.Revision then
		self:BuildPackFile ()
	end
	if not self.CompressedPackFile then
		local startTime = SysTime ()
		Msg ("GLib.Loader : Compressing pack file \"" .. self:GetName () .. "\" (" .. table.concat (self.SystemTableNames, ", ") .. ")...")
		self.CompressedPackFile = util.Compress (self.PackFile)
		MsgN (" done (" .. self:GetFileCount () .. " total files, " .. GLib.FormatFileSize (#self.PackFile) .. " compressed to " .. GLib.FormatFileSize (#self.CompressedPackFile) .. ", " .. GLib.FormatDuration (SysTime () - startTime) .. ")")
	end
	return self.CompressedPackFile
end

function self:GetFileCount ()
	return self.FileCount
end

function self:GetName ()
	return self.Name
end

function self:GetRevision ()
	return self.Revision
end

function self:GetSerializedPackFile ()
	if self.PackFileRevision ~= self.Revision then
		self:BuildPackFile ()
	end
	return self.PackFile
end

function self:GetSystemTableCount ()
	return #self.SystemTableNames
end

function self:GetSystemTableName (index)
	return self.SystemTableNames [index]
end

function self:MergeInto (packFileSystem)
	for i = 1, #self.SystemTableNames do
		packFileSystem:AddSystemTable (self.SystemTableNames [i])
	end
	
	self:EnumerateFolder ("", self.Root,
		function (path, data)
			packFileSystem:Write (path, data)
		end
	)
	
	for path, compiledFunction in pairs (self.CachedFunctions) do
		packFileSystem.CachedFunctions [path] = compiledFunction
	end
end

function self:Read (path)
	path = self:NormalizePath (path)
	local parts = path:Split ("/")
	local folder = self.Root
	for i = 1, #parts do
		folder = folder [parts [i]]
		if not folder then return nil end
	end
	return tostring (folder), self.CachedFunctions [path]
end

function self:SetName (name)
	self.Name = name
end

function self:Write (path, data)
	self.Revision = self.Revision + 1
	
	path = self:NormalizePath (path)
	data = data or ""
	local parts = path:Split ("/")
	local folder = self.Root
	for i = 1, #parts - 1 do
		-- Create subdirectory
		folder [parts [i]] = folder [parts [i]] or {}
		folder = folder [parts [i]]
	end
	
	if type (folder [parts [#parts]]) ~= "string" then
		self.FileCount = self.FileCount + 1
	end
	folder [parts [#parts]] = data
	self.CachedFunctions [path] = nil
end

-- Internal, do not call
function self:BuildPackFile ()
	if self.PackFileRevision == self.Revision then return end
	
	local startTime = SysTime ()
	local outBuffer = GLib.StringOutBuffer ()
	for i = 1, #self.SystemTableNames do
		outBuffer:String (self.SystemTableNames [i])
	end
	outBuffer:String ("")
	
	self:SerializeDirectory ("", self.Root, outBuffer)
	outBuffer:String ("")
	
	self.PackFile = outBuffer:GetString ()
	self.CompressedPackFile = nil
	self.PackFileRevision = self.Revision
	
	-- #YOLO
	if SysTime () - startTime > 0.015 then
		MsgN ("GLib.Loader : Built pack file \"" .. self:GetName () .. "\" (" .. table.concat (self.SystemTableNames, ", ") .. ") (" .. self:GetFileCount () .. " total files, " .. GLib.FormatFileSize (#self.PackFile) .. ", " .. GLib.FormatDuration (SysTime () - startTime) .. ")")
	end
end

function self:Deserialize (data, compressed, callback)
	local compressedData = nil
	if compressed then
		compressedData = data
		data = util.Decompress (data)
	end
	local decompressedSize = #data
	
	local inBuffer = GLib.StringInBuffer (data)
	
	local originalRevision = self.Revision
	
	local systemTableName = inBuffer:String ()
	while systemTableName ~= "" do
		self:AddSystemTable (systemTableName)
		systemTableName = inBuffer:String ()
	end
	
	local unpackSome
	function unpackSome ()
		local startTime = SysTime ()
		while SysTime () - startTime < 0.005 do
			local path = inBuffer:String ()
			if path == "" then
				-- Finished
				
				if originalRevision == 0 then
					-- We started off blank, it's
					-- okay to use the data as the
					-- serialized pack file.
					self.PackFile = data
					self.CompressedPackFile = compressedData
					self.PackFileRevision = self.Revision
				end
				
				callback (decompressedSize)
				return
			end
			local data = inBuffer:LongString ()
			path = self:NormalizePath (path)
			self:Write (path, data)
			local compiled = GLib.Loader.CompileString (data, path, false)
			if type (compiled) == "function" then
				self.CachedFunctions [path] = compiled
			end
		end
		GLib.CallDelayed (unpackSome)
	end
	unpackSome ()
end

function self:EnumerateFolder (folderPath, folder, callback)
	for name, data in pairs (folder) do
		if type (data) == "string" then
			callback (folderPath .. name, data)
		else
			self:EnumerateFolder (folderPath .. name .. "/", data, callback)
		end
	end
end

function self:GetNode (path)
	local parts = self:NormalizePath (path):Split ("/")
	local folder = self.Root
	for i = 1, #parts do
		folder = folder [parts [i]]
		if not folder then return nil end
	end
	return folder
end

function self:NormalizePath (path)
	path = path:lower ()
	path = path:gsub ("\\", "/")
	path = path:gsub ("/+", "/")
	if path:sub (1, 1) == "/" then path = path:sub (2) end
	return path
end

function self:SerializeDirectory (fullPath, folderTable, outBuffer)
	for name, data in pairs (folderTable) do
		if type (data) == "string" then
			outBuffer:String (fullPath .. name)
			outBuffer:LongString (data)
		else
			self:SerializeDirectory (fullPath .. name .. "/", data, outBuffer)
		end
	end
end