GLib.Lua.OperandType = GLib.Enum (
	{
		None                =  0,
		Variable            =  1,
		DestinationVariable =  2,
		WritableBase        =  3,
		ReadOnlyBase        =  4,
		UpvalueId           =  5,
		Literal             =  6,
		SignedLiteral       =  7,
		Primitive           =  8,
		NumericConstantId   =  9,
		StringConstantId    = 10,
		TableConstantId     = 11,
		FunctionConstantId  = 12,
		CDataConstantId     = 13,
		RelativeJump        = 14
	}
)