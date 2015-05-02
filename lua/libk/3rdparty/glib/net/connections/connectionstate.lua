GLib.Net.ConnectionState = GLib.Enum (
	{
		Opening = 1, -- Awaiting first packet
		Open    = 2, -- First packet received
		Closing = 4, -- Needs to send closure packet
		Closed  = 8  -- Closure packet sent
	}
)