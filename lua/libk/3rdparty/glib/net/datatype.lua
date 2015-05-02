GLib.Net.DataType = GLib.Enum (
	{
		UInt8	   = 0,
		UInt16	   = 1,
		UInt32	   = 2,
		UInt64	   = 3,
		Int8	   = 4,
		Int16	   = 5,
		Int32	   = 6,
		Int64	   = 7,
		Float	   = 8,
		Double	   = 9,
		Vector     = 10,
		Char       = 11,
		Bytes      = 12,
		String	   = 13,
		LongString = 14,
		Boolean	   = 15,
	}
)

GLib.Net.DataTypeSizes =
{
	Boolean    =  1,
	UInt8      =  1,
	UInt16     =  2,
	UInt32     =  4,
	UInt64     =  8,
	Int8       =  1,
	Int16      =  2,
	Int32      =  4,
	Int64      =  8,
	Float      =  4,
	Double     =  8,
	Vector     = 12,
	Char       =  1,
	Bytes      = function (data) return #data    end,
	String     = function (str)  return #str + 1 end,
	LongString = function (str)  return #str + 4 end
}