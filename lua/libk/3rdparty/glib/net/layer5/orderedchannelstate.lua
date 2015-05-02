GLib.Net.Layer5.OrderedChannelState = GLib.Enum (
	{
		Uninitialized = 1, -- No packets received yet
		Initializing  = 2, -- Initial 0.5 second buffering
		Initialized   = 3  -- Normal operation
	}
)