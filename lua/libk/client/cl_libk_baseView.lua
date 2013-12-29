NETINSTANCES = {}

local function createClassInstance( netTable, _classInstanceTables )
	_classInstanceTables = _classInstanceTables or {}
	local constructor = getClass(netTable._classname)
	if not constructor or not type( constructor ) == "function" then
		error( "Invalid constructor in StartViewCall: " .. netTable._classname )
	end
	
	local instance = constructor:new( )
	for k, v in pairs( netTable ) do
		if k != "_classname" then
			continue
		end
		instance[k] = v
	end
end

local function isUnresolvedObject( value )
	return type( value ) == "table" and value._classname
end

local function processNetTable( netTable )
	for k, v in pairs( netTable ) do 
		if isUnresolvedObject( v ) then
			local class = getClass(v._classname)
			if not class or not type( class ) == "table" then
				error( "Invalid class in StartViewCall: " .. v._classname )
			end
			local instance = class:new( )
			
			--Copy over all fields except for the _classname one
			for _k, _v in pairs( v ) do
				if _k != "_classname" then
					instance[_k] = _v
				end
			end
			
			--Replace table in the nettable with the object
			netTable[k] = instance
			
			--Recursively check for other objects within the object fields
			processNetTable( netTable[k] )
		elseif istable( v ) and k != "class" then
			processNetTable( v )
		end
	end
end

net.Receive( "StartView", function( len )
	local viewClass = net.ReadString( )
	local vars = net.ReadTable( )
	local func = net.ReadString( )

	--Scan for and Replace class net tables with class instances
	processNetTable( vars )
	
	--Debug log
	local argStrs = {}
	for k, v in pairs( vars ) do
		table.insert( argStrs, tostring( v ) )
	end
	KLogf( 4, "%s:%s( %s ) len %i", viewClass, func, table.concat( argStrs, " ," ), len )

	--Done, start the view
	local viewClass = getClass(viewClass)
	if not viewClass or not type( viewClass ) == "table" then
		error( "Invalid viewConstructor in NetInstance: " .. viewClass or "No Viewclass given" )
	end
	
	local view = viewClass:getInstance( )
	
	if not view[func] then
		error( "Invalid function for view " .. viewClass.name .. ":" .. func )
	end
	view[func]( view, unpack( vars ) )
end )

BaseView = {}

function BaseView:included( class )
	function class.static.getInstance( )
		class.static.instance = class.static.instance or class:new( )
		return class.static.instance
	end
end

function BaseView:controllerAction( strAction, ... )
	if not self.class.static.controller then
		error( "View " .. self.class.name .. " has no associated controller!" )
	end
	net.Start( "ControllerAction" )
		net.WriteString( self.class.static.controller )
		net.WriteString( strAction )
		net.WriteString( self.class.name )
		net.WriteTable( {...} )
	net.SendToServer( )
end

function BaseView:displayError( errorString, errorTitle )
	Derma_Message( errorString, errorTitle )
end

function BaseView:displayInformation( infoString, infoTitle )
	Derma_Message( infoString, infoTitle )
end