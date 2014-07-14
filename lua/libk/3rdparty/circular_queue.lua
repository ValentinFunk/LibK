--[[
The MIT License (MIT)

Copyright (c) 2014 David Mentler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--


--[[
	= Circular Queue =
	   
	Store queued objects efficiently. This utility saves memory by tricking lua
	 to store the queue using backing arrays, making it way faster than
	 inserting into a tables first index.
	   
	queue = CircularQueue( <size = 8> )
 
	queue:Add( entry )
 
	queue:Peek()
	queue:Pop()
 
	queue:IsEmpty()
	queue:Count()
]]--
 
local META = {}
	META.__index = META
	   
function META:Add( entry )
	local index = self.writeIndex
	   
	-- Catched up with readIndex
	if ( self.readIndex == index and self[index] != nil ) then	 
		local size		  = self.capacity
		local toCopy	= size - index
		   
		-- Copy the remairing data to the end of the queue
		for offset = 0, toCopy do
			self[size  +offset +1]  = self[index + offset] 
			self[index +offset]		 = nil
		end
		   
		self.readIndex  = size +1
		self.capacity   = self.capacity + toCopy +1
	end
	   
	-- Set
	self[index] = entry
	   
	-- Increase (Wrap around) index
	index = index +1
	   
	if ( index > self.capacity ) then
		index = 1
	end
	   
	self.writeIndex = index
end
 
function META:Peek()
	return self[ self.readIndex ]
end
 
function META:IsEmpty()
	return self.readIndex == self.writeIndex
end
 
function META:Pop()
	if ( self:IsEmpty() ) then return end
	   
	local index	 = self.readIndex
	   
	-- Pop
	local value	 = self[ index ]
		self[ index ] = nil
 
	-- Increase (Wrap around) index
	index = index +1
	   
	if ( index > self.capacity ) then
		index = 1
	end
	   
	self.readIndex = index
	   
	-- Return popped
	return value
end
 
function META:Count()  
	if ( self.writeIndex < self.readIndex ) then
		return self.writeIndex + self.capacity - self.readIndex
	end
	   
	return self.writeIndex - self.readIndex
end
 
function CircularQueue( size )
	local obj = {}
		obj.readIndex   = 1
		obj.writeIndex  = 1
	   
		obj.capacity	= size or 8
	   
	return setmetatable( obj, META )
end