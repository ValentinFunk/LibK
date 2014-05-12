VFS.ReturnCode = VFS.Enum (
	{
		Success         = 0,
		AccessDenied    = 1,
		TimedOut        = 2,
		EndOfBurst      = 3,
		Finished        = 4,
		NotFound        = 5,
		NotAFile        = 6,
		NotAFolder      = 7,
		AlreadyExists   = 8,
		Progress        = 9
	}
)