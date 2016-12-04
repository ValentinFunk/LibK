GLib.Resources = {}
GLib.Resources.Resources = {}

local DEBUG = false

local function DebugPrint (...)
	if not (DEBUG or LibK.Debug) then return end

	print (...)
end

function GLib.Resources.Get (namespace, id, versionHashOrCallback, callback)
	namespace = namespace or ""

	local versionHash = ""
	if isstring (versionHashOrCallback) then
		versionHash = versionHashOrCallback
	elseif isfunction (versionHashOrCallback) then
		callback = versionHashOrCallback
	end
	callback = callback or GLib.NullCallback

	local resource = GLib.Resources.Resources [namespace .. "/" .. id]
	if resource then
		-- Resource has already been requested.
		-- Resource may or may not be fully received.

		if resource:IsAvailable () then
			callback (true, resource:GetData ())
			return
		elseif resource:GetState () == GLib.Resources.ResourceState.Unavailable then
			callback (false)
			return
		end

		-- Otherwise we're waiting for a response from the server or
		-- in the process of receiving the resource
	else
		-- Server has nowhere to request resources from.
		if SERVER then callback (false) return end

		-- Clients should request the resource from the server.
		resource = GLib.Resources.Resource (namespace, id)
		GLib.Resources.Resources [namespace .. "/" .. id] = resource

		-- Check if the resource is cached.
		if GLib.Resources.ResourceCache:IsResourceCached (namespace, id, versionHash) then
			DebugPrint ("GLib.Resources : Using cached resource " .. namespace .. "/" .. id .. " (" .. versionHash .. ").")
			resource:SetLocalPath ("data/" .. GLib.Resources.ResourceCache:GetCachePath (namespace, id, versionHash))
			resource:SetState (GLib.Resources.ResourceState.Available)

			GLib.Resources.ResourceCache:UpdateLastAccessTime (namespace, id, versionHash)

			callback (true, resource:GetData ())
			return
		end

		-- Prepare transfer request arguments
		local outBuffer = GLib.StringOutBuffer ()
		outBuffer:String (namespace)
		outBuffer:String (id)
		outBuffer:String (versionHash or "")

		-- Send transfer request
		DebugPrint ("GLib.Resources : Requesting resource " .. namespace .. "/" .. id .. "...")
		local transfer = GLib.Transfers.Request ("Server", "GLib.Resources", outBuffer:GetString ())
		transfer:AddEventListener ("Finished",
			function (_)
				local inBuffer = GLib.StringInBuffer (transfer:GetData ())
				local namespace = inBuffer:String ()
				local id = inBuffer:String ()
				local versionHash = inBuffer:String ()

				local startTime = SysTime ()
				local compressed = inBuffer:LongString ()
				local data = util.Decompress (compressed)

				DebugPrint ("GLib.Resources : Received resource " .. namespace .. "/" ..id .. " (" .. GLib.FormatFileSize (#compressed) .. " decompressed to " .. GLib.FormatFileSize (#data) .. " in " .. GLib.FormatDuration (SysTime () - startTime) .. ").")

				resource:SetData (data)
				resource:SetState (GLib.Resources.ResourceState.Available)

				if resource:IsCacheable () then
					GLib.Resources.ResourceCache:CacheResource (resource:GetNamespace (), resource:GetId (), resource:GetVersionHash (), data)
					resource:SetLocalPath ("data/" .. GLib.Resources.ResourceCache:GetCachePath (resource:GetNamespace (), resource:GetId (), resource:GetVersionHash ()))
				end
			end
		)
		transfer:AddEventListener ("RequestRejected",
			function (_, rejectionData)
				DebugPrint ("GLib.Resources : Request for resource " .. namespace .. "/" .. id .. " has been rejected.")
				resource:SetState (GLib.Resources.ResourceState.Unavailable)
			end
		)
	end

	resource:AddEventListener ("StateChanged",
		function (resource, state)
			if state == GLib.Resources.ResourceState.Unavailable then
				callback (false)
			elseif state == GLib.Resources.ResourceState.Available then
				callback (true, resource:GetData ())
			end
		end
	)
end

function GLib.Resources.RegisterData (namespace, id, data)
	local resource = GLib.Resources.Resources [namespace .. "/" .. id]
	if not resource then
		resource = GLib.Resources.Resource (namespace, id)
		GLib.Resources.Resources [namespace .. "/" .. id] = resource
		DebugPrint ("GLib.Resources : Resource " .. namespace .. "/" .. id .. " registered (" .. GLib.FormatFileSize (#data) .. ").")
	end

	resource:SetData (data)
	resource:SetState (GLib.Resources.ResourceState.Available)

	return resource
end

function GLib.Resources.RegisterFile (namespace, id, localPath)
	if not file.Exists (localPath, "GAME") then return nil end

	local resource = GLib.Resources.Resources [namespace .. "/" .. id]
	if not resource then
		resource = GLib.Resources.Resource (namespace, id)
		GLib.Resources.Resources [namespace .. "/" .. id] = resource
		DebugPrint ("GLib.Resources : Resource " .. namespace .. "/" .. id .. " registered (" .. localPath .. ").")
	end

	resource:SetLocalPath (localPath)
	resource:SetState (GLib.Resources.ResourceState.Available)

	return resource
end

GLib.Transfers.RegisterHandler ("GLib.Resources", GLib.NullCallback)

GLib.Transfers.RegisterRequestHandler ("GLib.Resources",
	function (userId, data)
		local inBuffer = GLib.StringInBuffer (data)
		local namespace = inBuffer:String ()
		local id = inBuffer:String ()

		local resource = GLib.Resources.Resources [namespace .. "/" .. id]
		if not resource then
			-- Resource not found.
			-- I'm sorry, Dave. I'm afraid I can't do that.
			DebugPrint ("GLib.Resources : Rejecting resource request for " .. namespace .. "/" .. id .. " from " .. userId .. ".")
			return false
		end

		DebugPrint ("GLib.Resources : Sending resource " .. namespace .. "/" .. id .. " to " .. userId .. ".")
		local outBuffer = GLib.StringOutBuffer (data)
		outBuffer:String (namespace)
		outBuffer:String (id)
		outBuffer:String (resource:GetVersionHash ())
		outBuffer:LongString (resource:GetCompressedData ())
		return true, outBuffer:GetString ()
	end
)

GLib.Transfers.RegisterInitialPacketHandler ("GLib.Resources",
	function (userId, data)
		local inBuffer = GLib.StringInBuffer (data)
		local namespace = inBuffer:String ()
		local id = inBuffer:String ()
		local versionHash = inBuffer:String ()

		local resource = GLib.Resources.Resources [namespace .. "/" .. id]
		if not resource then
			-- We never asked for this.
			-- Cancel the transfer.
			return false
		end

		resource:SetVersionHash (versionHash)
		resource:SetState (GLib.Resources.ResourceState.Receiving)

		if GLib.Resources.ResourceCache:IsResourceCached (namespace, id, versionHash) then
			resource:SetLocalPath ("data/" .. GLib.Resources.ResourceCache:GetCachePath (namespace, id, versionHash))
			resource:SetState (GLib.Resources.ResourceState.Available)

			GLib.Resources.ResourceCache:UpdateLastAccessTime (namespace, id, versionHash)

			-- We've got the resource cached locally.
			-- Cancel the transfer.
			DebugPrint ("GLib.Resources : Resource " .. namespace .. "/" .. id .. " found in local cache, cancelling resource download.")
			return false
		end
	end
)

timer.Create ("GLib.Resources.FlushCache", 60, 0,
	function ()
		for _, resource in pairs (GLib.Resources.Resources) do
			if resource:IsCachedInMemory () and
			   SysTime () - resource:GetLastAccessTime () > 60 then
				resource:ClearMemoryCache ()
			end
		end
	end
)
