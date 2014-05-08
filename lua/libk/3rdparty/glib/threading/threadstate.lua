GLib.Threading.ThreadState = GLib.Enum (
	{
		Unstarted  = 1,
		Running    = 2, -- Runnable
		Waiting    = 3, -- Not runnable
		Sleeping   = 4, -- Not runnable
		Terminated = 5
	}
)