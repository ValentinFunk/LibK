local self = {}
GLib.Resources.ResourceCache = GLib.MakeConstructor (self)

function self:ctor ()
	self.LastAccessTimes = {}
	self.NeedsSaving = false
	
	self:LoadLastAccessTimes ()
	
	timer.Create ("GLib.Resources.ResourceCache.PruneCache", 300, 1,
		function ()
			self:PruneCache ()
		end
	)
	
	concommand.Add ("glib_flush_resource_cache_" .. (SERVER and "sv" or "cl"),
		function (ply, _, args)
			if SERVER then
				if ply and ply:IsValid () and not ply:IsAdmin () then return end
			end
			
			self:ClearCache ()
		end
	)
	
	concommand.Add ("glib_prune_resource_cache_" .. (SERVER and "sv" or "cl"),
		function (ply, _, args)
			if SERVER then
				if ply and ply:IsValid () and not ply:IsAdmin () then return end
			end
			
			self:PruneCache ()
		end
	)
end

function self:dtor ()
	timer.Destroy ("GLib.Resources.ResourceCache.PruneCache")
	timer.Destroy ("GLib.Resources.ResourceCache.SaveLastAccessTimes")
end

function self:CacheResource (namespace, id, versionHash, data)
	file.CreateDir ("glib")
	file.CreateDir ("glib/resourcecache")
	file.CreateDir ("glib/resourcecache/" .. string.lower (namespace))
	
	local f = file.Open (self:GetCachePath (namespace, id, versionHash), "wb", "DATA")
	if not f then return end
	
	f:Write (data)
	f:Close ()
	
	self:UpdateLastAccessTime (namespace, id, versionHash)
end

function self:ClearCache ()
	local _, folders = file.Find ("data/glib/resourcecache/*", "GAME")
	
	for _, folderName in ipairs (folders) do
		local files = file.Find ("data/glib/resourcecache/" .. folderName .. "/*", "GAME")
		for _, fileName in ipairs (files) do
			self.LastAccessTimes ["glib/resourcecache/" .. folderName .. "/" .. fileName] = nil
			self:FlagSaveNeeded ()
			
			file.Delete ("glib/resourcecache/" .. folderName .. "/" .. fileName)
			print ("GLib.Resources : Flushing cached resource glib/resourcecache/" .. folderName .. "/" .. fileName .. "...")
		end
	end
end

function self:GetCachePath (namespace, id, versionHash)
	return "glib/resourcecache/" .. string.lower (namespace) .. "/" .. string.lower (id) .. "_" .. versionHash .. ".txt"
end

function self:IsResourceCached (namespace, id, versionHash)
	return file.Exists ("data/" .. self:GetCachePath (namespace, id, versionHash), "GAME") and
	       string.format ("%08x", tonumber (util.CRC (file.Read ("data/" .. self:GetCachePath (namespace, id, versionHash), "GAME"))) or 0) == versionHash
end

function self:PruneCache ()
	local _, folders = file.Find ("data/glib/resourcecache/*", "GAME")
	
	for _, folderName in ipairs (folders) do
		local files = file.Find ("data/glib/resourcecache/" .. folderName .. "/*", "GAME")
		for _, fileName in ipairs (files) do
			local lastAccessTime = self.LastAccessTimes ["glib/resourcecache/" .. folderName .. "/" .. fileName] or 0
			if os.time () - lastAccessTime > 7 * 86400 then
				-- Older than 1 week, delete it
				self.LastAccessTimes ["glib/resourcecache/" .. folderName .. "/" .. fileName] = nil
				self:FlagSaveNeeded ()
				
				file.Delete ("glib/resourcecache/" .. folderName .. "/" .. fileName)
				print ("GLib.Resources : Cached resource glib/resourcecache/" .. folderName .. "/" .. fileName .. " has expired, deleting...")
			end
		end
	end
	
	-- Remove nonexistant files from the last access times table
	for dataPath, _ in pairs (self.LastAccessTimes) do
		if not file.Exists ("data/" .. dataPath, "GAME") then
			self.LastAccessTimes [dataPath] = nil
			self:FlagSaveNeeded ()
		end
	end
end

function self:UpdateLastAccessTime (namespace, id, versionHash)
	self.LastAccessTimes [self:GetCachePath (namespace, id, versionHash)] = os.time ()
	self:FlagSaveNeeded ()
end

-- Internal, do not call
function self:FlagSaveNeeded ()
	self.NeedsSaving = true
	
	timer.Create ("GLib.Resources.ResourceCache.SaveLastAccessTimes", 1, 1,
		function ()
			self:SaveLastAccessTimes ()
		end
	)
end

function self:LoadLastAccessTimes ()
	local inBuffer = GLib.StringInBuffer (file.Read ("data/glib/resourcecache/lastaccesstimes.txt", "GAME") or "")
	
	local path = inBuffer:String ()
	while path ~= "" do
		self.LastAccessTimes [path] = inBuffer:UInt32 ()
		inBuffer:Bytes (1) -- Discard newline
		
		path = inBuffer:String ()
	end
	
	self.NeedsSaving = false
end

function self:SaveLastAccessTimes ()
	local outBuffer = GLib.StringOutBuffer ()
	for path, timestamp in pairs (self.LastAccessTimes) do
		outBuffer:String (path)
		outBuffer:UInt32 (timestamp)
		outBuffer:Bytes ("\n")
	end
	outBuffer:String ("")
	
	file.CreateDir ("glib")
	file.CreateDir ("glib/resourcecache")
	file.Write ("glib/resourcecache/lastaccesstimes.txt", outBuffer:GetString ())
	
	self.NeedsSaving = false
end

GLib.Resources.ResourceCache = GLib.Resources.ResourceCache ()