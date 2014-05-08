if GLib.Stage2 then return end
GLib.Stage2 = true

include ("colors.lua")

include ("coroutine.lua")
include ("glue.lua")

include ("memoryusagereport.lua")
include ("stringtable.lua")

include ("unicode/unicodecategory.lua")
include ("unicode/wordtype.lua")
include ("unicode/utf8.lua")
include ("unicode/unicode.lua")
include ("unicode/unicodecategorytable.lua")
include ("unicode/transliteration.lua")

-- Serialization
GLib.Serialization = {}
include ("serialization/iserializable.lua")
include ("serialization/serializationinfo.lua")
include ("serialization/customserializationinfo.lua")
include ("serialization/serializableregistry.lua")
include ("serialization/serialization.lua")

-- Networking
include ("networking/networkable.lua")
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
include ("containers/queue.lua")
include ("containers/stack.lua")
include ("containers/tree.lua")

-- Networking Containers
include ("containers/networkable/list.lua")

-- Threading
GLib.Threading = {}
include ("threading/threading.lua")
include ("threading/thread.lua")
include ("threading/threadstate.lua")

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

-- Interfaces
GLib.Interfaces = {}
include ("interfaces/interfaces.lua")