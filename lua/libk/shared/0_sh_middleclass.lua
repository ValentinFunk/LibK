--Kamshak: This is used for the item classes. For examples consult https://github.com/kikito/middleclass/wiki/
--Modified PrintTable to print instances prettier
function isObject( t )
	--Derma Tables
	if istable( t ) and t.Base and t.Init then
		return false
	end
	--pac parts
	if pac and istable( t ) and t.IsValid and not t:IsValid( ) then
		return false
	end
	return istable( t ) and t.class and istable( t.class ) and t.class.name
end

function PrintTable ( t, indent, done )
	done = done or {}
	indent = indent or 2
	if indent == 2 and isObject( t ) then
		print( "Object Instance " .. t.class.name .. "(" .. tostring(t) .. ")" )
	end

	MsgN( string.rep (" ", indent - 2) .. "{" )
	for key, value in pairs (t) do
		Msg( string.rep (" ", indent) )
		if ispanel(value) and not IsValid( value )then
			Msg( tostring (key) .. " = " )
			Msg( "NULL Panel(" .. type( value ) .. "\n" )
		elseif isObject( value ) and not done[value] then
			done [value] = true
			Msg( tostring(key) .. ": Object Instance " .. value.class.name .. "(" .. tostring(value) .. ")\n" );
			PrintTable (value, indent + 2, done)
		elseif ( istable(value) && !done[value] ) and key != "class" then
			done [value] = true
			Msg( tostring(key) .. ":" .. "\n" );
			PrintTable (value, indent + 2, done)
		else
			Msg( tostring (key) .. " = " )
			Msg( tostring(value) .. "\n" )
		end
	end
	MsgN( string.rep (" ", indent - 2) .. "}" )
end

-- middleclass.lua - v2.0 (2011-09)
-- Copyright (c) 2011 Enrique Garc�a Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- Based on YaciCode, from Julien Patte and LuaObject, from Sebastien Rocca-Serra

local _classes = setmetatable({}, {__mode = "k"})

local function _setClassDictionariesMetatables(klass)
  local dict = klass.__instanceDict
  dict.__index = dict

  local super = klass.super
  if super then
    local superStatic = super.static
    setmetatable(dict, super.__instanceDict)
    setmetatable(klass.static, { __index = function(_,k) return dict[k] or superStatic[k] end })
  else
    setmetatable(klass.static, { __index = function(_,k) return dict[k] end })
  end
end

local function _setClassMetatable(klass)
  setmetatable(klass, {
    __tostring = function() return "class " .. klass.name end,
    __index = klass.static,
    __newindex = klass.__instanceDict,
    __call = function(self, ...) return self:new(...) end
  })
end

local function _createClass(name, super)
  --LibK modification: overwrite existing classes with the same name
  local klass
  for existingClass, bool in pairs( _classes ) do
	if existingClass.name == name then
		klass = existingClass
	end
  end

  klass = klass or { name = name, super = super, static = {}, __mixins = {}, __instanceDict={} }
  klass.subclasses = setmetatable({}, {__mode = "k"})

  _setClassDictionariesMetatables(klass)
  _setClassMetatable(klass)
  _classes[klass] = true

  return klass
end

local function _createLookupMetamethod(klass, name)
  return function(...)
    local method = klass.super[name]
    assert( type(method)=='function', tostring(klass) .. " doesn't implement metamethod '" .. name .. "'" )
    return method(...)
  end
end

local function _setClassMetamethods(klass)
  for _,m in ipairs(klass.__metamethods) do
    klass[m]= _createLookupMetamethod(klass, m)
  end
end

local function _setDefaultInitializeMethod(klass, super)
  klass.initialize = function(instance, ...)
    return super.initialize(instance, ...)
  end
end

local function _includeMixin(klass, mixin)
  assert(type(mixin)=='table', "mixin must be a table")
  for name,method in pairs(mixin) do
    if name ~= "included" and name ~= "static" then klass[name] = method end
  end
  if mixin.static then
    for name,method in pairs(mixin.static) do
      klass.static[name] = method
    end
  end
  if type(mixin.included)=="function" then mixin:included(klass) end
  klass.__mixins[mixin] = true
end

Object = _createClass("Object", nil)

Object.static.__metamethods = { '__add', '__call', '__concat', '__div', '__le', '__lt',
                                '__mod', '__mul', '__pow', '__sub', '__unm' }

function Object.static:allocate()
  assert(_classes[self], "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")
  return setmetatable({ class = self }, self.__instanceDict)
end

function Object.static:new(...)
  local instance = self:allocate()
  instance:initialize(...)
  return instance
end

function Object.static:subclass(name)
  assert(_classes[self], "Make sure that you are using 'Class:subclass' instead of 'Class.subclass'")
  assert(type(name) == "string", "You must provide a name(string) for your class")

  local subclass = _createClass(name, self)
  _setClassMetamethods(subclass)
  _setDefaultInitializeMethod(subclass, self)
  self.subclasses[subclass] = true
  self:subclassed(subclass)

  return subclass
end

function Object.static:subclassed(other) end

function Object.static:include( ... )
  assert(_classes[self], "Make sure you that you are using 'Class:include' instead of 'Class.include'")
  for _,mixin in ipairs({...}) do _includeMixin(self, mixin) end
  return self
end

function Object:initialize() end

function class(name, super, ...)
  super = super or Object
  return super:subclass(name, ...)
end

function instanceOf(aClass, obj)
  if not _classes[aClass] or type(obj) ~= 'table' or not _classes[obj.class] then return false end
  if obj.class == aClass then return true end
  return subclassOf(aClass, obj.class)
end

function subclassOf(other, aClass)
  if not _classes[aClass] or not _classes[other] or aClass.super == nil then return false end
  return aClass.super == other or subclassOf(other, aClass.super)
end

function includes(mixin, aClass)
  if not _classes[aClass] then return false end
  if aClass.__mixins[mixin] then return true end
  return includes(mixin, aClass.super)
end

function getClass( className )
	for k, v in pairs( _classes ) do
		if k.name == className then
			return k
		end
	end
end
