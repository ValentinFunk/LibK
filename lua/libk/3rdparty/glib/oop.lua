--[[
	OOP Overview
	
	Static table metatable
	{
		__call     - Invokes the ctor static method of the static table.
		             The ctor static method should create and return an instance of the class.
	}
	
	Static tables
	{
		ctor       - Creates and returns an intance of the class.
		             This static method is overrideable.
		           
		__ictor    - Instance constructor static method.
		             Creates and returns an instance of the class.
				     This static method should not be overridden.
					 
		__static   - A boolean whose value is always true.
		             This field should not be overridden.
	}
	
	Instance metatable
	{
		ctor       - The constructor method for a given class.
		             Does not call base class constructors.
		           
		dtor       - The destructor method for a given class.
		             Does not call base class destructors.
		           
		__index    - This metatable itself.
		           
		__ictor    - Instance constructor static method.
		             Creates and returns an instance of the class.
				     This static method should not be overridden.
		           
		__ctor     - The constructor method for a given class.
		             Calls all base class constructors.
				     This method should not be overridden.
				     
		__dtor     - The destructor method for a given class.
		             Calls all base class destructors.
				     This method should not be overridden.
		           
		__base     - The instance metatable of the base class.
				     This field should not be overridden.
		           
		__base2    - The instance metatable of the second base class.
				     This field should not be overridden.
	}
	
	Instance table
	{
		dtor       - The destructor method for a given class.
		             Calls all base class destructors.
				  
		__HashCode - Stores a cached copy of the object's hash code.
		             This field should not be overridden unless GetHashCode has been overridden.
	}
]]

function GLib.GetMetaTable (typeConstructor)
	if GLib.IsStaticTable (typeConstructor) then
		typeConstructor = typeConstructor.__ictor
	end
	
	if type (typeConstructor) ~= "function" then
		return nil
	end
	
	local name, basetable = debug.getupvalue (typeConstructor, 1)
	return basetable
end

function GLib.IsStaticTable (t)
	if not t then return false end
	return rawget (t, "__static") == true
end

local function Object_GetHashCode (self)
	if not self.__HashCode then
		self.__HashCode = string.sub (string.format ("%p", self), 3)
	end
	
	return self.__HashCode
end

local function Object_Is (self, typeConstructor)
	if type (typeConstructor) == "table" then
		typeConstructor = typeConstructor.__ictor
	end
	
	local metatable = self
	while metatable do
		if metatable.__ictor == typeConstructor then return true end
		if metatable.__base2 and self.Is (metatable.__base2, typeConstructor) then return true end
		
		metatable = metatable.__base
	end
	
	return false
end

local StaticTableMetatable =
{
	__call = function (self, ...)
		return self.ctor (...)
	end
}

--[[
	GLib.MakeConstructor (metatable, base, base2)
		Returns: () -> Object
		
		Produces a constructor for the object defined by metatable.
		base may be nil or the constructor of a base class.
		base2 may be nil or the constructor of another base class.
		The second base class must not be a class with inheritance.
]]
function GLib.MakeConstructor (metatable, base, base2)
	metatable.__index = metatable
	
	-- Instance constructor, what this function returns
	local ictor
	
	if base then
		-- 1st base class
		local basetable = GLib.GetMetaTable (base)
		metatable.__tostring = metatable.__tostring or basetable.__tostring
		metatable.__base = basetable
		setmetatable (metatable, basetable)
		
		-- 2nd base class
		if base2 then
			local base2table = GLib.GetMetaTable (base2)
			
			-- Copy everything but the metamethods / metafields
			for k, v in pairs (base2table) do
				if string.sub (k, 1, 2) ~= "__" then metatable [k] = v end
			end
			metatable.__base2 = base2table
			metatable.ctor2 = base2table.ctor
		end
	else
		-- No base class
		metatable.GetHashCode = metatable.GetHashCode or Object_GetHashCode
		metatable.Is = metatable.Is or Object_Is
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
				ctors [#ctors + 1] = rawget (base, "ctor")
				ctors [#ctors + 1] = rawget (base, "ctor2")
				dtors [#dtors + 1] = rawget (base, "dtor")
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
		
		-- 2000 years ago
		-- my race created you.
		-- We turned you loose in space,
		-- now a polluted zoo
		return object
	end
	
	-- Instance constructor
	metatable.__ictor = ictor
	
	-- Static table
	local staticTable = {}
	staticTable.__ictor = ictor
	staticTable.__static = true
	staticTable.ctor = ictor
	setmetatable (staticTable, StaticTableMetatable)
	
	return staticTable
end