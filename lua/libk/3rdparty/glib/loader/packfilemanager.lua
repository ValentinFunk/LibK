local self = {}
GLib.Loader.PackFileManager = GLib.MakeConstructor (self)

function self:ctor ()
	self.MergedPackFileSystem = GLib.Loader.PackFileSystem ()
	self.MergedPackFileSystem:SetName ("Server")
	
	self.CurrentPackFileSystem = nil
	self.PackFileSystems = {}
	self.PackFileSystemsById = {}
	self.PackFileSystemResources = {}
end

function self:AddSystemTable (systemTableName)
	self.MergedPackFileSystem:AddSystemTable (systemTableName)
	if self.CurrentPackFileSystem then
		self.CurrentPackFileSystem:AddSystemTable (systemTableName)
	end
end

function self:CreatePackFileSystem (id)
	if self.PackFileSystemsById [id] then
		return self.PackFileSystemsById [id]
	end
	
	local packFileSystem = GLib.Loader.PackFileSystem ()
	packFileSystem:SetName (id)
	self.PackFileSystems [#self.PackFileSystems + 1] = packFileSystem
	self.PackFileSystemsById [id] = packFileSystem
	return packFileSystem
end

function self:GenerateResources ()
	-- This is done in two loops, since each step
	-- generates debug messages and we want similar
	-- messages to be grouped together for legibility.
	
	-- Force generation of serialized pack files
	self.MergedPackFileSystem:GetSerializedPackFile ()
	for packFileSystem in self:GetPackFileSystemEnumerator () do
		packFileSystem:GetSerializedPackFile ()
	end
	
	-- Register resources
	self.PackFileSystemResources [self.MergedPackFileSystem] = GLib.Resources.RegisterData ("LuaPack", "Server", self.MergedPackFileSystem:GetSerializedPackFile ())
	for packFileSystem in self:GetPackFileSystemEnumerator () do
		self.PackFileSystemResources [packFileSystem] = GLib.Resources.RegisterData ("LuaPack", packFileSystem:GetName (), packFileSystem:GetSerializedPackFile ())
	end
end

function self:GetCurrentPackFileSystem ()
	return self.CurrentPackFileSystem
end

function self:GetFileCount ()
	return self.MergedPackFileSystem:GetFileCount ()
end

function self:GetMergedPackFileSystem ()
	return self.MergedPackFileSystem
end

function self:GetPackFileSystem (index)
	return self.PackFileSystems [index]
end

function self:GetPackFileSystemById (id)
	return self.PackFileSystemsById [id]
end

function self:GetPackFileSystemCount ()
	return #self.PackFileSystems
end

function self:GetPackFileSystemEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.PackFileSystems [i]
	end
end

function self:MergeInto (packFileManager)
	self:GetMergedPackFileSystem ():MergeInto (packFileManager:GetMergedPackFileSystem ())
	
	for packFileSystem in self:GetPackFileSystemEnumerator () do
		packFileManager:CreatePackFileSystem (packFileSystem:GetName ())
		packFileSystem:MergeInto (packFileManager:GetPackFileSystemById (packFileSystem:GetName ()))
	end
end

function self:SerializeManifest (outBuffer)
	for packFileSystem in self:GetPackFileSystemEnumerator () do
		local resource = self.PackFileSystemResources [packFileSystem]
		
		outBuffer:String (resource:GetId ())
		outBuffer:String (resource:GetVersionHash ())
	end
	
	outBuffer:String ("")
end

function self:SetCurrentPackFileSystem (id)
	self.CurrentPackFileSystem = self.PackFileSystemsById [id]
end

function self:Write (path, data)
	self.MergedPackFileSystem:Write (path, data)
	if self.CurrentPackFileSystem then
		self.CurrentPackFileSystem:Write (path, data)
	end
end

local previousPackFileManager = GetGLibPackFileManager and GetGLibPackFileManager ()
local currentPackFileManager = GLib.Loader.PackFileManager ()
GLib.Loader.PackFileManager = currentPackFileManager
if previousPackFileManager then
	previousPackFileManager:MergeInto (currentPackFileManager)
end

function GetGLibPackFileManager ()
	return currentPackFileManager
end