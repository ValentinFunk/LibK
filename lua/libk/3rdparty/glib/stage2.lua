if GLib.Stage2 then return end
GLib.Stage2 = true

include ("bitconverter.lua")

include ("colors.lua")

include ("coroutine.lua")
include ("glue.lua")

include ("memoryusagereport.lua")
include ("stringtable.lua")

-- Threading
GLib.Threading = {}
include ("threading/iwaitable.lua")
include ("threading/waitendreason.lua")

include ("threading/threading.lua")
include ("threading/threadstate.lua")
include ("threading/thread.lua")
include ("threading/mainthread.lua")
include ("threading/threadrunner.lua")

-- Lua
GLib.Lua = {}
include ("lua/lua.lua")
include ("lua/sessionvariables.lua")
include ("lua/backup.lua")
include ("lua/detours.lua")

include ("lua/namecache.lua")

-- Lua Reflection
include ("lua/reflection/function.lua")
include ("lua/reflection/functioncache.lua")
include ("lua/reflection/parameter.lua")
include ("lua/reflection/parameterlist.lua")
include ("lua/reflection/argumentlist.lua")

include ("lua/reflection/stackframe.lua")
include ("lua/reflection/stacktrace.lua")
include ("lua/reflection/stacktracecache.lua")
include ("lua/reflection/stackcaptureoptions.lua")

include ("lua/reflection/variableframe.lua")
include ("lua/reflection/localvariableframe.lua")
include ("lua/reflection/upvalueframe.lua")

function GLib.StackTrace (levels, frameOffset)
	frameOffset = frameOffset or 0
	frameOffset = frameOffset + 1
	return GLib.Lua.StackTrace (levels, frameOffset, GLib.Lua.StackCaptureOptions.Arguments):ToString ()
end

-- Lua Bytecode Decompiler
include ("lua/decompiler/garbagecollectedconstanttype.lua")
include ("lua/decompiler/garbagecollectedconstant.lua")
include ("lua/decompiler/functionconstant.lua")
include ("lua/decompiler/tableconstant.lua")
include ("lua/decompiler/stringconstant.lua")

include ("lua/decompiler/tablekeyvaluetype.lua")

include ("lua/decompiler/operandtype.lua")
include ("lua/decompiler/opcodeinfo.lua")
include ("lua/decompiler/opcodes.lua")
include ("lua/decompiler/opcode.lua")
include ("lua/decompiler/precedence.lua")
include ("lua/decompiler/instruction.lua")
include ("lua/decompiler/loadstore.lua")
include ("lua/decompiler/framevariable.lua")
include ("lua/decompiler/functionbytecodereader.lua")
include ("lua/decompiler/bytecodereader.lua")

-- Unicode
include ("unicode/unicodecategory.lua")
include ("unicode/wordtype.lua")
include ("unicode/utf8.lua")
include ("unicode/unicode.lua")
include ("unicode/unicodecategorytable.lua")
include ("unicode/transliteration.lua")

-- Formatting
include ("formatting/date.lua")
include ("formatting/tableformatter.lua")

-- Serialization
GLib.Serialization = {}
include ("serialization/iserializable.lua")
include ("serialization/serializationinfo.lua")
include ("serialization/customserializationinfo.lua")
include ("serialization/serializableregistry.lua")
include ("serialization/serialization.lua")

-- Networking
GLib.Networking = {}
include ("networking/networkable.lua")
include ("networking/networkablestate.lua")
include ("networking/networkablecontainer.lua")
include ("networking/networkablehost.lua")
include ("networking/subscriberset.lua")

-- Containers
GLib.Containers = {}
include ("containers/binarytree.lua")
include ("containers/binarytreenode.lua")
include ("containers/linkedlist.lua")
include ("containers/linkedlistnode.lua")
include ("containers/list.lua")
include ("containers/orderedset.lua")
include ("containers/queue.lua")
include ("containers/stack.lua")
include ("containers/tree.lua")

-- Networking Containers
include ("containers/networkable/list.lua")

-- Networking
include ("net/net.lua")
include ("net/datatype.lua")
include ("net/outbuffer.lua")
include ("net/netdispatcher.lua")
include ("net/usermessagedispatcher.lua")
include ("net/netinbuffer.lua")
include ("net/usermessageinbuffer.lua")

include ("protocol/protocol.lua")
include ("protocol/channel.lua")
include ("protocol/endpoint.lua")
include ("protocol/endpointmanager.lua")
include ("protocol/session.lua")

-- Math
include ("math/matrix.lua")
include ("math/vector.lua")
include ("math/columnvector.lua")
include ("math/rowvector.lua")

-- Geometry
GLib.Geometry = {}
include ("geometry/parametricgeometry.lua")
include ("geometry/iparametriccurve.lua")
include ("geometry/iparametricsurface.lua")
include ("geometry/bezierspline.lua")
include ("geometry/quadraticbezierspline.lua")
include ("geometry/cubicbezierspline.lua")
include ("geometry/parametriccurverenderer.lua")

-- Interfaces
GLib.Interfaces = {}
include ("interfaces/interfaces.lua")

-- Addons
include ("addons.lua")