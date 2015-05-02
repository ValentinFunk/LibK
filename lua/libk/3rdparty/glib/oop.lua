--[[
	OOP Overview
	
	Static table metatable
	{
		__call                 - Invokes the ctor static method of the static table.
		                         The ctor static method should create and return an instance of the class.
		                         
		SetInstanceConstructor - Sets the instance constructor for this class.
		                         This method should not be overridden or called.
	}
	
	Static tables (callable to construct an instance)
	{
		ctor                   - Creates and returns an instance of the class.
		                         This static method is overrideable.
		                         
		__ictor                - Instance constructor static method.
		                         Creates and returns an instance of the class.
		                         This static method should not be overridden.
		                         
		__static               - A boolean whose value is always true.
		                         This field should not be overridden.
		                         
		GetInstanceMetatable   - Returns the instance metatable for this class.
		                         This method should not be overridden.
	}
	
	Instance metatable
	{
		ctor                   - The constructor method for a given class.
		                         Does not call base class constructors.
		                         
		dtor                   - The destructor method for a given class.
		                         Does not call base class destructors.
		                         
		__index                - This metatable itself.
		                         
		__ictor                - Instance constructor static method.
		                         Creates and returns an instance of the class.
		                         This static method should not be overridden.
		                         
		__ctor                 - The constructor method for a given class.
		                         Calls all base class constructors.
		                         This method should not be overridden.
		                         
		__dtor                 - The destructor method for a given class.
		                         Calls all base class destructors.
		                         This method should not be overridden.
		                         
		__base                 - The instance metatable of the base class.
		                         This field should not be overridden.
		                         
		__GetStaticTable       - Returns the static table for this class.
		                         This method should not be overridden.
		                         
		__GetType              - Returns the type table for this class.
		                         This method should not be overridden.
	}
	
	Type table
	{
		__bases                - Array of instance metatables of all base classes.
		                         This field should not be overridden or modified.
		                        
		__basemethods          - Map of inherited method names to the instance metatables they come from
		                         This field should not be overridden or modified.
		                         
		GetStaticTable         - Returns the static table for this class.
		                         This method should not be overridden.
	}
	
	Instance table
	{
		dtor                   - The destructor method for a given class.
		                         Calls all base class destructors.
		                        
		__HashCode             - Stores a cached copy of the object's hash code.
		                         This field should not be overridden unless GetHashCode has been overridden.
	}
]]

local self = {}
local Object = self
self.__index = self

function self:GetHashCode ()
	if not self.__HashCode then
		self.__HashCode = string.sub (string.format ("%p", self), 3)
	end
	
	return self.__HashCode
end

function self:Is (typeConstructor)
	if type (typeConstructor) == "table" then
		typeConstructor = typeConstructor.__ictor
	end
	
	local metatable = self
	if metatable.__ictor == typeConstructor then return true end
	
	return Object.IsDerivedFrom (self, typeConstructor)
end

function self:IsDerivedFrom (typeConstructor)
	if type (typeConstructor) == "table" then
		typeConstructor = typeConstructor.__ictor
	end
	
	local metatable = self
	for _, basetable in ipairs (metatable:__GetType ().__bases) do
		if self.Is (basetable, typeConstructor) then return true end
	end
	
	return false
end

local self = {}
local StaticTableMetatable = self
self.__index = self

function self:SetInstanceConstructor (ictor)
	if self.__ictor == ictor then return self end
	
	if self.ctor == ictor then
		self.ctor = nil
	end
	
	self.__ictor = ictor
	self.ctor    = self.ctor or self.__ictor
	
	return self
end

function self:__call (...)
	return self.ctor (...)
end

function GLib.CreateStaticTable (ictor, out)
	local staticTable = out or {}
	staticTable.__ictor  = ictor
	staticTable.__static = true
	staticTable.ctor     = ictor
	
	setmetatable (staticTable, StaticTableMetatable)
	return staticTable
end

function GLib.GetMetaTable (typeConstructor)
	if GLib.IsStaticTable (typeConstructor) and
	   type (typeConstructor.GetInstanceMetatable) == "function" then
		return typeConstructor:GetInstanceMetatable ()
	elseif type (typeConstructor) == "table" and
	       type (typeConstructor.__GetStaticTable) == "function" then
		return typeConstructor:__GetStaticTable ():GetInstanceMetatable ()
	end
	
	return nil
end

function GLib.IsStaticTable (t)
	if not t then return false end
	return rawget (t, "__static") == true
end

--[[
	GLib.MakeConstructor (metatable, base, base2)
		Returns: () -> Object
		
		Produces a constructor for the object defined by metatable.
		base may be nil or the constructor of a base class.
		...  may be nil or the constructors of additional base class.
		The additional base classes must not be classes with inheritance.
]]
function GLib.MakeConstructor (metatable, base, ...)
	metatable.__index       = metatable
	
	-- Inheritance
	local statictable = GLib.CreateStaticTable ()
	local typeinfo = {}
	statictable.GetInstanceMetatable = function () return metatable   end
	metatable.__GetStaticTable       = function () return statictable end
	metatable.__GetType              = function () return typeinfo    end
	typeinfo.__bases                 = {}
	typeinfo.__basemethods           = {}
	typeinfo.GetStaticTable          = function () return statictable end
	
	-- Instance constructor, what this function returns
	local ictor
	
	if base then
		-- 1st base class
		local basetable = GLib.GetMetaTable (base)
		metatable.__tostring = metatable.__tostring or basetable.__tostring
		metatable.__base = basetable
		typeinfo.__bases [#typeinfo.__bases + 1] = basetable
		setmetatable (metatable, basetable)
		
		-- Copy in __basemethods from base class
		for methodName, basebasetable in pairs (basetable:__GetType ().__basemethods) do
			typeinfo.__basemethods [methodName] = basebasetable
		end
		
		-- Fill __basemethods with base class methods
		for k, v in pairs (basetable) do
			if isfunction (v) then
				typeinfo.__basemethods [k] = basetable
			end
		end
		
		-- Additional base classes
		if ... then
			for _, base in ipairs ({...}) do
				local basetable = GLib.GetMetaTable (base)
				typeinfo.__bases [#typeinfo.__bases + 1] = basetable
				
				-- Copy everything but the metamethods / metafields
				
				-- Methods directly on base instance table
				for k, v in pairs (basetable) do
					if (not typeinfo.__basemethods [k] or
					    Object.IsDerivedFrom (basetable, typeinfo.__basemethods [k])) and
					   string.sub (k, 1, 2) ~= "__" then
						metatable [k] = v
						typeinfo.__basemethods [k] = basetable
					end
				end
				
				-- Methods inherited by the base class
				for methodName, basebasetable in pairs (basetable:__GetType ().__basemethods) do
					if (not typeinfo.__basemethods [methodName] or
					    Object.IsDerivedFrom (basebasetable, typeinfo.__basemethods [methodName])) and
					   string.sub (methodName, 1, 2) ~= "__" then
						metatable [methodName] = basebasetable [methodName]
						typeinfo.__basemethods [methodName] = basebasetable
					end
				end
			end
		end
	else
		-- No base class
		metatable.GetHashCode   = metatable.GetHashCode   or Object.GetHashCode
		metatable.Is            = metatable.Is            or Object.Is
		metatable.IsDerivedFrom = metatable.IsDerivedFrom or Object.IsDerivedFrom
	end
	
	-- Instance constructor
	ictor = function (...)
		local object = {}
		setmetatable (object, metatable)
		
		-- Create constructor and destructor if they don't already exist
		if not rawget (metatable, "__ctor") or not rawget (metatable, "__dtor") then
			local base = metatable
			local ctors = {}
			local dtors = {}
			
			-- Pull together list of constructors and destructors needing to be called
			while base ~= nil do
				-- ctor and dtor
				ctors [#ctors + 1] = rawget (base, "ctor")
				dtors [#dtors + 1] = rawget (base, "dtor")
				
				-- Additional base class ctors and dtors
				-- No support for additional base class inheritance
				for i = 2, #base:__GetType ().__bases do
					ctors [#ctors + 1] = rawget (base:__GetType ().__bases [i], "ctor")
				end
				
				for i = 2, #base:__GetType ().__bases do
					dtors [#dtors + 1] = rawget (base:__GetType ().__bases [i], "dtor")
				end
				
				base = base.__base
			end
			
			-- Constructor
			function metatable:__ctor (...)
				-- Invoke constructors,
				-- starting from the base classes upwards
				for i = #ctors, 1, -1 do
					ctors [i] (self, ...)
				end
			end
			
			-- Destructor
			function metatable:__dtor (...)
				-- Invoke destructors,
				-- starting from the derived classes downwards
				for i = 1, #dtors do
					dtors [i] (self, ...)
				end
			end
		end
		
		-- Assign destructor
		object.dtor = object.__dtor
		
		-- Invoke constructor
		object:__ctor (...)
		
		return object
	end
	
	-- Instance constructor
	metatable.__ictor = ictor
	
	-- Static table
	statictable:SetInstanceConstructor (ictor)
	return statictable
end