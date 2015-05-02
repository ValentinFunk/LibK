local self = {}
GLib.Containers.BinarySetOperatorController = GLib.MakeConstructor (self)

GLib.Containers.SetIntersectionController = function (...) return GLib.Containers.BinarySetOperatorController (function (left, right) return left and     right end, ...) end
GLib.Containers.SetUnionController        = function (...) return GLib.Containers.BinarySetOperatorController (function (left, right) return left or      right end, ...) end
GLib.Containers.SetSubtractionController  = function (...) return GLib.Containers.BinarySetOperatorController (function (left, right) return left and not right end, ...) end
GLib.Containers.SetXorController          = function (...) return GLib.Containers.BinarySetOperatorController (function (left, right) return left ~=      right end, ...) end

function self:ctor (membershipFunction, left, right, result)
	self.MembershipFunction = function (leftContains, rightContains, item) return false end
	
	self.Left   = nil
	self.Right  = nil
	self.Result = nil
	
	self:SetLeft (left)
	self:SetRight (right)
	self:SetMembershipFunction (membershipFunction)
	self:SetResult (result)
end

function self:dtor ()
	self:SetResult (nil)
	self:SetLeft (nil)
	self:SetRight (nil)
end

function self:GetLeft ()
	return self.Left
end

function self:GetRight ()
	return self.Right
end

function self:GetMembershipFunction ()
	return self.MembershipFunction
end

function self:GetResult ()
	return self.Result
end

function self:SetLeft (left)
	if self.Left == left then return self end
	
	local lastLeft = self.Left
	
	self:UnhookSet (self.Left)
	self.Left = left
	self:HookSet (self.Left)
	
	self:TestUpdateItems (lastLeft)
	self:TestUpdateItems (self.Left)
	
	return self
end

function self:SetRight (right)
	if self.Right == right then return self end
	
	local lastRight = self.Right
	
	self:UnhookSet (self.Right)
	self.Right = right
	self:HookSet (self.Right)
	
	self:TestUpdateItems (lastRight)
	self:TestUpdateItems (self.Right)
	
	return self
end

function self:SetMembershipFunction (membershipFunction)
	if self.MembershipFunction == membershipFunction then return self end
	
	self.MembershipFunction = membershipFunction or function (leftContains, rightContains, item) return false end
	
	self:TestUpdateItems (self.Left)
	self:TestUpdateItems (self.Right)
	
	return self
end

function self:SetResult (result)
	if self.Result == result then return self end
	
	self.Result = result
	
	self:TestUpdateItems (self.Left)
	self:TestUpdateItems (self.Right)
	
	return self
end

-- Internal, do not call
function self:HookSet (set)
	if not set then return end
	
	set:AddEventListener ("ItemAdded", "BinarySetOperatorController." .. self:GetHashCode (),
		function (_, item)
			self:TestUpdateItem (item)
		end
	)
	
	set:AddEventListener ("ItemRemoved", "BinarySetOperatorController." .. self:GetHashCode (),
		function (_, item)
			self:TestUpdateItem (item)
		end
	)
end

function self:UnhookSet (set)
	if not set then return end
	
	set:RemoveEventListener ("ItemAdded",   "BinarySetOperatorController." .. self:GetHashCode ())
	set:RemoveEventListener ("ItemRemoved", "BinarySetOperatorController." .. self:GetHashCode ())
end

function self:TestUpdateItem (item)
	if not self.Result then return end
	
	if self.MembershipFunction (self.Left and self.Left:Contains (item) or false, self.Right and self.Right:Contains (item) or false, item) then
		self.Result:Add (item)
	else
		self.Result:Remove (item)
	end
end

function self:TestUpdateItems (enumerable)
	if not enumerable then return end
	if not self.Result then return end
	
	for item in enumerable:GetEnumerator () do
		self:TestUpdateItem (item)
	end
end