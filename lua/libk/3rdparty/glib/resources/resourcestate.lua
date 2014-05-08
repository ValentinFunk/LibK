GLib.Resources.ResourceState = GLib.Enum (
	{
		Available        = 1, -- Available locally (may have been received from the server)
		Unknown          = 2, -- Not available locally, may be in cache, request needs to be sent to server
		Requested        = 3, -- Requested from server, waiting for response
		Unavailable      = 4, -- Server does not have the resource
		Receiving        = 5  -- Server is sending the resource to us
	}
)