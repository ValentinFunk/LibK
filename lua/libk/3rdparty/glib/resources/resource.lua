local self = {}
GLib.Resources.Resource = GLib.MakeConstructor (self)

--[[
	Events:
		StateChanged (ResourceState state)
			Fired when the resource state has changed.
]]

function self:ctor (namespace, id)
	self.Namespace = namespace or "Default"
	self.Id = id or "Unknown"
	self.VersionHash = nil
	
	self.State = GLib.Resources.ResourceState.Unknown
	
	self.Cacheable = true
	
	self.LastAccessTime = 0
	
	self.Data = nil
	self.CompressedData = nil
	self.LocalPath = nil
	
	GLib.EventProvider (self)
end

function self:ClearMemoryCache ()
	if not self.LocalPath then return end
	if not self.Data then return end
	
	self.Data = nil
end

function self:GetCompressedData ()
	if self.CompressedData then return self.CompressedData end
	
	local data = self:GetData ()
	if not data then return nil end
	
	local startTime = SysTime ()
	self.CompressedData = util.Compress (data)
	MsgN ("GLib.Resources : Compressing resource " .. self.Namespace .. "/" .. self.Id .. " took " .. GLib.FormatDuration (SysTime () - startTime) .. " (" .. GLib.FormatFileSize (#data) .. " to " .. GLib.FormatFileSize (#self.CompressedData) .. ").")
	
	return self.CompressedData
end

function self:GetData ()
	self.LastAccessTime = SysTime ()
	
	if self.Data then return self.Data end
	
	if not self.LocalPath then return nil end
	
	local f = file.Open (self.LocalPath, "rb", "GAME")
	if not f then return nil end
	
	self.Data = f:Read (f:Size ())
	f:Close ()
	
	self:UpdateVersionHash (self.Data or "")
	return self.Data
end

function self:GetId ()
	return self.Id
end

function self:GetLastAccessTime ()
	return self.LastAccessTime
end

function self:GetNamespace ()
	return self.Namespace
end

function self:GetLocalPath ()
	return self.LocalPath
end

function self:GetState ()
	return self.State
end

function self:GetVersionHash ()
	if not self.VersionHash and self:IsAvailable () then
		self:UpdateVersionHash ()
	end
	return self.VersionHash
end

function self:IsAvailable ()
	return self.State == GLib.Resources.ResourceState.Available
end

function self:IsCacheable ()
	return self.Cacheable
end

function self:IsCachedInMemory ()
	return self.Data ~= nil
end

function self:SetCacheable (cacheable)
	self.Cacheable = cacheable
end

function self:SetData (data)
	if self.Data == data then return end
	
	self.Data = data
	self.CompressedData = nil
	
	self:UpdateVersionHash (self.Data)
end

function self:SetLocalPath (localPath)
	self.LocalPath = localPath
end

function self:SetState (state)
	if self.State == state then return end
	
	self.State = state
	
	self:DispatchEvent ("StateChanged", self.State)
end

function self:SetVersionHash (versionHash)
	self.VersionHash = versionHash
end

-- Internal, do not call
function self:UpdateVersionHash (data)
	data = data or self:GetData () or ""
	
	self.VersionHash = string.format ("%08x", tonumber (util.CRC (data)) or 0)
end