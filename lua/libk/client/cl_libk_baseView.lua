NETINSTANCES = {}

local vnet = LibK.GLib.vnet

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
				return false, v._classname -- Invalid class in StartViewCall: %s
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
			local success, err = processNetTable( netTable[k] )
			if not success then
				return success, err
			end
		elseif istable( v ) and k != "class" then
			local success, err = processNetTable( v )
			if not success then
				return success, err
			end
		end
	end
	return true
end
LibK.processNetTable = processNetTable

vnet.Watch( "LibK_StartView", function( packet )
	local len = packet.Size

	local viewClass = packet:String( )
	local func = packet:String()
	local vars = packet:Table()
	if not vars then
		LibK.GLib.Error("Invalid StartView " + viewClass + ":" + func + " - Invalid vars passed")
	end

	--Scan for and Replace class net tables with class instances
	local success, errClass = processNetTable( vars )
	if errClass then
		local errorText = "Error when decoding call " .. viewClass .. ":" .. func .. " -> Invalid class in StartViewCall: " .. errClass
		
		-- Try calling error handler
		local viewClass = getClass( viewClass )
		if not viewClass or not type( viewClass ) == "table" then
			error( errorText .. "\nAdditional Error notifying View: Invalid viewConstructor in NetInstance: " .. viewClass or "No Viewclass given" )
		end

		local view = viewClass:getInstance( )
		if view and view.HandleDecodeError then
			KLogf(2, 'Error decoding net table %s for view %s:%s', errClass, viewClass, func)
			PrintTable(vars)
			view:HandleDecodeError( func, errClass )
			return
		end
		
		error( errorText )
	end
	
	--Debug log
	local argStrs = {}
	for k, v in pairs( vars ) do
		table.insert( argStrs, tostring( v ) )
	end
	KLogf( 4, "%s:%s( %s ) len %i, Compressed: %s", viewClass, func, table.concat( argStrs, " ," ), len, packet.Compressed )

	--Done, start the view
	local viewClass = getClass( viewClass )
	if not viewClass or not type( viewClass ) == "table" then
		error( "Invalid viewConstructor in NetInstance: " .. ( viewClass or "No Viewclass given" ) )
	end
	
	local view = viewClass:getInstance( )
	
	if not view[func] then
		error( "Invalid function for view " .. viewClass.name .. ":" .. func )
	end
	view[func]( view, unpack( vars ) )
end, { vnet.OPTION_WATCH_OVERRIDE } )

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

	local packet = vnet.CreatePacket( "ControllerAction" )
		packet:String( self.class.static.controller )
		packet:String( strAction )
		packet:String( self.class.name )
		packet:Table( {...} )
	packet:AddServer( )
	packet:Send( )
	dp("send ", strAction)
end

function BaseView:controllerTransaction( strAction, ... )
	self.transactions = self.transactions or {}
	
	local def = Deferred( )
	local transactionId = table.insert( self.transactions, def )
	
	local packet = vnet.CreatePacket( "LibK_Transaction" )
		packet:Int( transactionId )
		packet:String( self.class.static.controller )
		packet:String( strAction )
		packet:String( self.class.name )
		packet:Table( { ... } )
	packet:AddServer( )
	packet:Send( )
	dp("send ", strAction)
	
	return def:Promise( )
end

function BaseView:transactionCompleted( transactionId, success, ... )
	local transaction = self.transactions[transactionId]
	if not transaction then 
		KLogf( 2, "[LibK][ERROR] Server tried to resolve invalid transaction with id %i", transactionId )
	end
	
	if success then
		transaction:Resolve( ... )
	else
		transaction:Reject( ... )
	end
	self.transactions[transactionId] = nil
end

function BaseView:displayError( errorString, errorTitle )
	Derma_Message( errorString, errorTitle )
end

function BaseView:displayInformation( infoString, infoTitle )
	Derma_Message( infoString, infoTitle )
end