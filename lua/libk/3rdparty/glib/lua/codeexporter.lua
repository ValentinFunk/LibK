local self = {}
GLib.Lua.CodeExporter = GLib.MakeConstructor (self)

function self:ctor (sourceSystemName, sourceFolderName, destinationSystemName, destinationFolderName)
	self.SourceSystemName             = sourceSystemName
	self.SourceFolderName             = sourceFolderName
	
	self.DestinationSystemName        = destinationSystemName
	self.DestinationFolderName        = destinationFolderName
	
	self.OutputFolderName             = self.SourceFolderName
	
	self.AuxiliarySystemNames         = GLib.Containers.OrderedSet ()
	
	self.TableNames                   = GLib.Containers.OrderedSet ()
	
	-- Options
	self.IncludeSourceInformation     = true
	self.IncludeAddCSLuaFileCalls     = true
	
	-- Functions
	self.Functions                    = GLib.Containers.OrderedSet ()
	self.FunctionNames                = GLib.Containers.OrderedSet ()
	
	self.ClientsideFunctions          = GLib.Containers.OrderedSet ()
	self.ClientsideFunctionNames      = GLib.Containers.OrderedSet ()
	
	self.CustomCode                   = {}
	
	-- Resources
	self.ByteMap                      = nil
	self.Resources                    = {}
	
	-- Files
	self.Files                        = GLib.Containers.OrderedSet ()
	self.ClientsideFiles              = GLib.Containers.OrderedSet ()
	
	-- Output
	self.IncludeFiles                 = GLib.Containers.OrderedSet ()
	self.ClientsideIncludeFiles       = GLib.Containers.OrderedSet ()
	self.FinalizedFunctions           = GLib.Containers.OrderedSet ()
	self.FinalizedClientsideFunctions = GLib.Containers.OrderedSet ()
	self.FinalizedTableNames          = GLib.Containers.OrderedSet ()
end

-- Input
function self:AddAuxiliarySystemName (auxiliarySystemName)
	self.AuxiliarySystemNames:Add (auxiliarySystemName)
end

function self:AddCustomCode (code)
	self.CustomCode [#self.CustomCode + 1] = code
end

function self:AddTableName (tableName)
	self.TableNames:Add (tableName)
end

function self:AddTableNames (enumerable)
	for tableName in GLib.ToEnumerable (enumerable):GetEnumerator () do
		self:AddTableName (tableName)
	end
end

function self:AddFunction (f)
	if isfunction (f) then
		self.Functions:Add (f)
	elseif isstring (f) then
		self.FunctionNames:Add (f)
	else
		GLib.Error ("CodeExporter:AddFunction : Expected a function or string, got a " .. type (f) .. "!")
	end
end

function self:AddClientsideFunction (f)
	if isfunction (f) then
		self.ClientsideFunctions:Add (f)
	elseif isstring (f) then
		self.ClientsideFunctionNames:Add (f)
	else
		GLib.Error ("CodeExporter:AddClientsideFunction : Expected a function or string, got a " .. type (f) .. "!")
	end
end

function self:AddFunctions (enumerable)
	for f in GLib.ToEnumerable (enumerable):GetEnumerator () do
		self:AddFunction (f)
	end
end

function self:AddClientsideFunctions (enumerable)
	for f in GLib.ToEnumerable (enumerable):GetEnumerator () do
		self:AddClientsideFunction (f)
	end
end

function self:AddFile (filePath)
	self.Files:Add (filePath)
end

function self:AddClientsideFile (filePath)
	self.ClientsideFiles:Add (filePath)
end

function self:AddFiles (enumerable)
	for filePath in GLib.ToEnumerable (enumerable):GetEnumerator () do
		self:AddFile (filePath)
	end
end

function self:AddClientsideFiles (enumerable)
	for filePath in GLib.ToEnumerable (enumerable):GetEnumerator () do
		self:AddClientsideFile (filePath)
	end
end

function self:AddResource (namespace, id, sourcePath, destinationPath)
	self.Resources [#self.Resources + 1] =
	{
		Namespace       = namespace,
		Id              = id,
		SourcePath      = sourcePath,
		DestinationPath = destinationPath
	}
end

-- Options
function self:GetOutputFolderName ()
	return self.OutputFolderName
end

function self:ShouldIncludeSourceInformation ()
	return self.IncludeSourceInformation
end

function self:ShouldIncludeAddCSLuaFileCalls ()
	return self.IncludeAddCSLuaFileCalls
end

function self:SetIncludeSourceInformation (includeSourceInformation)
	self.IncludeSourceInformation = includeSourceInformation
	return self
end

function self:SetIncludeAddCSLuaFileCalls (includeAddCSLuaFileCalls)
	self.IncludeAddCSLuaFileCalls = includeAddCSLuaFileCalls
	return self
end

function self:SetOutputFolderName (outputFolderName)
	self.OutputFolderName = outputFolderName
	return self
end

function self:GenerateCode ()
	self:ClearOutput ()
	
	if not file.Exists (self:GetAddonPath (), "GAME") then
		print ("CodeExporter:GenerateCode : Failed: " .. self:GetAddonPath () .. " not found!")
		return
	end
	
	local mainOutputFileName = self.OutputFolderName .. "_import"
	local codegenFolderName  = self.OutputFolderName .. "_codegen"
	local importFolderName   = self.OutputFolderName .. "_imported"
	
	if not self:ShouldIncludeSourceInformation () then
		mainOutputFileName = "import"
		codegenFolderName  = "codegen"
		importFolderName   = "imported"
	end
	
	-- Batch script
	file.CreateDir (self:GetOutputPath ())
	file.Write (self.DestinationFolderName .. "/" .. mainOutputFileName .. ".bat.txt",
		"for /R "  .. codegenFolderName .. " %%x in (*.lua) do erase \"%%x\"\r\n" ..
		"for /R "  .. codegenFolderName .. " %%x in (*.txt) do ren \"%%x\" *.lua\r\n" ..
		"xcopy \"" .. codegenFolderName .. "\\*\" \"..\\..\\addons\\" .. self.DestinationFolderName .. "\\lua\\" .. self.DestinationFolderName .. "\\" .. importFolderName .. "\\\" /s /e /y\r\n" ..
		"erase " .. mainOutputFileName .. ".lua\r\n" ..
		"ren "   .. mainOutputFileName .. ".txt " .. mainOutputFileName .. ".lua\r\n" ..
		"xcopy " .. mainOutputFileName .. ".lua \"..\\..\\addons\\" .. self.DestinationFolderName .. "\\lua\\" .. self.DestinationFolderName .. "\\\" /Y\r\n" ..
		"cmd\r\n"
	)
	
	-- Import files
	for filePath in self.Files:GetEnumerator () do
		self:ProcessFile (filePath, filePath)
		self:AddIncludeFile (filePath)
	end
	
	for filePath in self.ClientsideFiles:GetEnumerator () do
		self:ProcessFile (filePath, filePath)
		self:AddClientsideIncludeFile (filePath)
	end
	
	-- Process resources
	for _, resourceData in ipairs (self.Resources) do
		self:ProcessResource (resourceData.Namespace, resourceData.Id, resourceData.SourcePath, resourceData.DestinationPath)
	end
	
	-- Includer file
	local code = "-- This file is computer-generated.\r\n"
	
	-- Pre-process functions
	self:AddFinalizedFunctions (self.Functions)
	self:AddFinalizedClientsideFunctions (self.ClientsideFunctions)
	
	for functionName in self.FunctionNames:GetEnumerator () do
		local f = GLib.Lua.GetTableValue (functionName)
		self:AddFinalizedFunction (f)
	end
	
	for functionName in self.ClientsideFunctionNames:GetEnumerator () do
		local f = GLib.Lua.GetTableValue (functionName)
		self:AddFinalizedClientsideFunction (f)
	end
	
	-- Pre-process tables
	self:AddFinalizedTableNames (self.TableNames)
	
	-- Functions
	local functionCode = ""
	for f in self.FinalizedFunctions:GetEnumerator () do
		functionCode = functionCode .. self:ProcessCode (GLib.Lua.ToLuaString (f)) .. "\r\n\r\n"
	end
	functionCode = functionCode .. "\r\n"
	
	-- Client-only functions
	if not self.FinalizedClientsideFunctions:IsEmpty () then
		functionCode = functionCode .. "if CLIENT then\r\n"
		for f in self.FinalizedClientsideFunctions:GetEnumerator () do
			functionCode = functionCode .. "\t" .. string.gsub (self:ProcessCode (GLib.Lua.ToLuaString (f)), "\n", "\n\t") .. "\r\n\r\n"
		end
		functionCode = functionCode .. "end\r\n"
	end
	functionCode = functionCode .. "\r\n"
	
	-- Tables
	local maximumTableNameLength = 0
	local tableNames = {}
	for tableName in self.FinalizedTableNames:GetEnumerator () do
		tableNames [#tableNames + 1] = tableName
		maximumTableNameLength = math.max (maximumTableNameLength, #tableName)
	end
	
	table.sort (tableNames)
	for _, tableName in ipairs (tableNames) do
		code = code .. self.DestinationSystemName .. "." .. tableName .. string.rep (" ", maximumTableNameLength - #tableName) .. " = " .. self.DestinationSystemName .. "." .. tableName .. string.rep (" ", maximumTableNameLength - #tableName) .. " or {}\r\n"
	end
	
	code = code .. "\r\n"
	
	-- Functions
	code = code .. functionCode
	
	-- Custom code
	for _, customCode in ipairs (self.CustomCode) do
		code = code .. string.Trim (customCode) .. "\r\n"
	end
	
	-- Includes
	for fileName in self.IncludeFiles:GetEnumerator () do
		code = code .. "include (\"" .. importFolderName .. "/" .. fileName .. "\")\r\n"
	end
	code = code .. "\r\n"
	
	-- Client-only includes
	if not self.ClientsideIncludeFiles:IsEmpty () then
		code = code .. "if CLIENT then\r\n"
		for fileName in self.ClientsideIncludeFiles:GetEnumerator () do
			code = code .. "\tinclude (\"" .. importFolderName .. "/" .. fileName .. "\")\r\n"
		end
		code = code .. "end\r\n"
		code = code .. "\r\n"
	end
	
	-- Clientside lua files
	if self:ShouldIncludeAddCSLuaFileCalls () then
		code = code .. "if SERVER then\r\n"
		code = code .. "	AddCSLuaFile (\"" .. mainOutputFileName .. ".lua\")\r\n"
		
		for fileName in self.IncludeFiles:GetEnumerator () do
			code = code .. "	AddCSLuaFile (\"" .. importFolderName .. "/" .. fileName .. "\")\r\n"
		end
		
		for fileName in self.ClientsideIncludeFiles:GetEnumerator () do
			code = code .. "	AddCSLuaFile (\"" .. importFolderName .. "/" .. fileName .. "\")\r\n"
		end
		
		code = code .. "end\r\n"
		code = code .. "\r\n"
	end
	
	file.Write (self.DestinationFolderName .. "/" .. mainOutputFileName .. ".txt", code)
end

function self:ProcessFile (sourcePath, destinationPath)
	local fullSourcePath = "addons/" .. self.SourceFolderName .. "/lua/" .. self.SourceFolderName .. "/" .. sourcePath
	
	if not file.Exists (fullSourcePath, "GAME") then
		print ("CodeExporter:ProcessFile : Failed: " .. fullSourcePath .. " not found!")
		return false
	end
	
	local code = file.Read (fullSourcePath, "GAME")
	code = self:ProcessCode (code, sourcePath)
	
	destinationPath = string.gsub (destinationPath, "[\\/]+", "/")
	destinationPath = string.gsub (destinationPath, "%.lua$", ".txt")
	destinationPath = self:GetOutputPath () .. "/" .. destinationPath
	
	file.CreateDir (string.gsub (destinationPath, "/[^/]*$", ""))
	file.Write (destinationPath, code)
	
	print ("CodeExporter:ProcessFile : Success: " .. fullSourcePath .. " -> data/" .. destinationPath)
	
	return true
end

function self:ProcessCode (code, sourcePath)
	code = string.gsub (code, self.SourceSystemName .. "%.", self.DestinationSystemName .. ".")
	code = string.gsub (code, self.SourceSystemName .. "_",  self.DestinationSystemName .. "_")
	code = string.gsub (code, self.SourceSystemName,         self.DestinationSystemName       )
	code = string.gsub (code, self.SourceFolderName .. "_",  self.DestinationFolderName .. "_")
	
	for auxiliarySystemName in self.AuxiliarySystemNames:GetEnumerator () do
		code = string.gsub (code, auxiliarySystemName .. "%.", self.DestinationSystemName .. ".")
		code = string.gsub (code, auxiliarySystemName .. "_",  self.DestinationSystemName .. "_")
		code = string.gsub (code, auxiliarySystemName,         self.DestinationSystemName       )
	end
	
	if sourcePath and self:ShouldIncludeSourceInformation () then
		code = "-- Generated from: " .. self.SourceFolderName .. "/lua/" .. self.SourceFolderName .. "/" .. sourcePath .. "\r\n" ..
			   "-- Original:       https://github.com/notcake/" .. self.SourceFolderName .. "/blob/master/lua/" .. self.SourceFolderName .. "/" .. sourcePath .. "\r\n" ..
			   "-- Timestamp:      " .. os.date ("%Y-%m-%d %H:%M:%S") .. "\r\n" ..
			   code
	else
		code = "-- Timestamp: " .. os.date ("%Y-%m-%d %H:%M:%S") .. "\r\n" ..
			   code
	end
	
	-- Auto-detect table names
	for tableName in string.gmatch (code, self.DestinationSystemName .. "%.([a-zA-Z_0-9%.]+)%.[a-zA-Z_][a-zA-Z_0-9]*[ ]*[%(=]") do
		self:AddFinalizedTableName (tableName)
	end
	
	return code
end

-- Resources
function self:GetByteMap ()
	if not self.ByteMap then
		self.ByteMap = {}
		
		for i = 0, 255 do
			self.ByteMap [string.char (i)] = string.format ("\\x%02x", i)
		end

		for i = 32, 126 do
			self.ByteMap [string.char (i)] = string.char (i)
		end
		
		self.ByteMap ["\\"] = "\\\\"
		self.ByteMap ["\""] = "\\\""
	end
	
	return self.ByteMap
end

function self:ProcessResource (namespace, id, sourcePath, destinationPath)
	local realSourcePath = self:GetAddonPath () .. "/" .. sourcePath
	
	if not file.Exists (realSourcePath, "GAME") then
		print ("CodeExporter:ProcessResource : Failed: " .. realSourcePath .. " not found!")
		return false
	end
	
	local data = file.Read (realSourcePath, "GAME")
	data = util.Compress (data)
	
	local chunks = {}
	local chunkSize  = 16384
	local chunkCount = math.ceil (#data / chunkSize)
	
	-- Split data into chunks
	for i = 1, chunkCount do
		chunks [#chunks + 1] = string.sub (data, (i - 1) * chunkSize + 1, i * chunkSize)
	end
	
	-- Encode chunks
	for i = 1, #chunks do
		chunks [i] = string.gsub (chunks [i], ".", self:GetByteMap ())
	end
	
	-- Output
	destinationPath = string.gsub (destinationPath, "[\\/]+", "/")
	destinationPath = "resources/" .. destinationPath
	
	file.CreateDir (self:GetOutputPath () .. "/" .. string.gsub (destinationPath, "/[^/]*$", ""))
	
	for i = 1, #chunks do
		local filePath = destinationPath .. "_" .. string.format ("%02d", i - 1)
		local code = "-- This file is computer-generated.\r\n" ..
		             self.DestinationSystemName .. ".Resources.Append (\"" .. namespace .. "\", \"" .. id .. "_compressed\", \r\n" ..
		             "	\"" .. chunks [i] .. "\"\r\n" ..
					 ")"
		file.Write (self:GetOutputPath () .. "/" .. filePath .. ".txt", code)
		self:AddIncludeFile (filePath .. ".lua")
		
		print ("CodeExporter:ProcessResource : Success: " .. realSourcePath .. " -> data/" .. self:GetOutputPath () .. "/" .. filePath .. ".txt")
	end
	
	-- Final file
	local filePath = destinationPath .. "_final"
	local code = "-- This file is computer-generated.\r\n" ..
				 self.DestinationSystemName .. ".Resources.Commit (\"" .. namespace .. "\", \"" .. id .. "_compressed\")\r\n" ..
				 "\r\n" ..
				 self.DestinationSystemName .. ".Resources.Get (\"" .. namespace .. "\", \"" .. id .. "_compressed\",\r\n" ..
				 "	function (success, data)\r\n" ..
				 "		" .. self.DestinationSystemName .. ".Resources.Append (\"" .. namespace .. "\", \"" .. id .. "\", util.Decompress (data))\r\n" ..
				 "		" .. self.DestinationSystemName .. ".Resources.Commit (\"" .. namespace .. "\", \"" .. id .. "\")\r\n" ..
				 "	end\r\n" ..
				 ")"
	file.Write (self:GetOutputPath () .. "/" .. filePath .. ".txt", code)
	self:AddIncludeFile (filePath .. ".lua")
	
	print ("CodeExporter:ProcessResource : Success: " .. realSourcePath .. " -> data/" .. self:GetOutputPath () .. "/" .. filePath .. ".txt")
	
	return fileList
end

function self:GetAddonPath ()
	return "addons/" .. self.SourceFolderName
end

function self:GetAddonLuaPath ()
	return "addons/" .. self.SourceFolderName .. "/lua/" .. self.SourceFolderName
end

function self:GetOutputPath ()
	if self:ShouldIncludeSourceInformation () then
		return self.DestinationFolderName .. "/" .. self.OutputFolderName .. "_codegen"
	else
		return self.DestinationFolderName .. "/codegen"
	end
end

-- Output
function self:ClearOutput ()
	self.IncludeFiles:Clear ()
	self.ClientsideIncludeFiles:Clear ()
	self.FinalizedFunctions:Clear ()
	self.FinalizedClientsideFunctions:Clear ()
	self.FinalizedTableNames:Clear ()
end

function self:AddIncludeFile (filePath)
	self.IncludeFiles:Add (filePath)
end

function self:AddClientsideIncludeFile (filePath)
	self.ClientsideIncludeFiles:Add (filePath)
end

function self:AddFinalizedFunction (f)
	self.FinalizedFunctions:Add (f)
end

function self:AddFinalizedClientsideFunction (f)
	self.FinalizedClientsideFunctions:Add (f)
end

function self:AddFinalizedFunctions (enumerable)
	for f in GLib.ToEnumerable (enumerable):GetEnumerator () do
		self:AddFinalizedFunction (f)
	end
end


function self:AddFinalizedClientsideFunctions (enumerable)
	for f in GLib.ToEnumerable (enumerable):GetEnumerator () do
		self:AddFinalizedClientsideFunction (f)
	end
end

function self:AddFinalizedTableName (tableName)
	self.FinalizedTableNames:Add (tableName)
end

function self:AddFinalizedTableNames (enumerable)
	for tableName in GLib.ToEnumerable (enumerable):GetEnumerator () do
		self:AddFinalizedTableName (tableName)
	end
end

function self:__call (destinationSystemName, destinationFolderName)
	local codeExporter = GLib.Lua.CodeExporter (self.SourceSystemName, self.SourceFolderName, destinationSystemName, destinationFolderName)
	
	for auxiliarySystemName in self.AuxiliarySystemNames:GetEnumerator () do
		codeExporter:AddAuxiliarySystemName (auxiliarySystemName)
	end
	
	return codeExporter
end