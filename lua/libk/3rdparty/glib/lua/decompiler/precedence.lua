GLib.Lua.Precedence = GLib.Enum (
	{
		Lowest            = 0,
        Addition          = 1,
        Subtraction       = 2,
        Multiplication    = 3,
        Division          = 4,
		Modulo            = 5,
        Exponentiation    = 6,
		LeftUnaryOperator = 7,
        Atom              = 8
	}
)

local associativePrecedences =
{
	[GLib.Lua.Precedence.Addition] = true,
	[GLib.Lua.Precedence.Multiplication] = true,
	[GLib.Lua.Precedence.LeftUnaryOperator] = true
}

function GLib.Lua.IsPrecedenceAssociative (precedence)
	return associativePrecedences [precedence] or false
end