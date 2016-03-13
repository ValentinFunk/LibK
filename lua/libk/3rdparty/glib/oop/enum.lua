function GLib.Enum (enum)
	if not next (enum) then
		GLib.Error ("GLib.Enum : This enum appears to be empty!")
	end
	
	GLib.InvertTable (enum, enum)
	return enum
end