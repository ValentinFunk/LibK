local self = {}
GLib.Containers.BinaryTreeNode = GLib.MakeConstructor (self)

function self:ctor ()
	self.Tree = nil
	
	self.Parent = nil
	self.Left   = nil
	self.Right  = nil
	
	self.Height = 1
	self.ChildStatisticsValid = true
	
	-- AVL tree data
	self.BalanceFactor = 0
end

-- Balancing
function self:BalancePostInsertion ()
	local balanceFactor = self:GetBalanceFactor ()
	if balanceFactor <= -2 then
		local rightBalanceFactor = self.Right:GetBalanceFactor ()
		if rightBalanceFactor == -1 then
			self:RotateLeft ()
		elseif rightBalanceFactor == 1 then
			self.Right:RotateRight ()
			self:RotateLeft ()
		end
	elseif balanceFactor >= 2 then
		local leftBalanceFactor = self.Left:GetBalanceFactor ()
		if leftBalanceFactor == 1 then
			self:RotateRight ()
		elseif leftBalanceFactor == -1 then
			self.Left:RotateLeft ()
			self:RotateRight ()
		end
	elseif self.Parent then
		self.Parent:BalancePostInsertion ()
	end
end

function self:CalculateChildStatistics ()
	if self.ChildStatisticsValid then return end
	
	local leftHeight = self.Left and self.Left:GetHeight () or 0
	local rightHeight = self.Right and self.Right:GetHeight () or 0
	
	self.Height = math.max (leftHeight, rightHeight) + 1
	self.HeightValid = true
	
	self.BalanceFactor = leftHeight - rightHeight
	self.ChildStatisticsValid = true
end

function self:GetBalanceFactor ()
	if not self.ChildStatisticsValid then
		self:CalculateChildStatistics ()
	end
	return self.BalanceFactor
end

function self:GetHeight ()
	if not self.ChildStatisticsValid then
		self:CalculateChildStatistics ()
	end
	return self.Height
end

-- Basic querying
function self:GetLeft ()
	return self.Left
end

function self:GetLeftmost ()
	local node = self
	while node.Left do
		node = node.Left
	end
	return node
end

function self:GetNext ()
	if self.Right then
		return self.Right:GetLeftmost ()
	end
	
	local node = self
	local nodeParent = node.Parent
	while nodeParent and node == nodeParent.Right do
		node = nodeParent
		nodeParent = node.Parent
	end
	return nodeParent
end

function self:GetParent ()
	return self.Parent
end

function self:GetPrevious ()
	if self.Left then
		return self.Left:GetLeftmost ()
	end
	
	local node = self
	local nodeParent = node.Parent
	while nodeParent and node == nodeParent.Left do
		node = nodeParent
		nodeParent = node.Parent
	end
	return nodeParent
end

function self:GetTree ()
	local node = self
	while node.Parent do
		node = node.Parent
	end
	return node.Tree
end

function self:GetRight ()
	return self.Right
end

function self:GetRightmost ()
	local node = self
	while node.Right do
		node = node.Right
	end
	return node
end

--[[
	Insertion
	
	There are 4 cases:
		1      2      3       4
		x Left x This x Right x
	
	InsertLeftmost
	InsertBefore
	InsertAfter
	InsertRightmost
]]
function self:InsertAfter (node)
	if not self.Right then
		self.Right = node
		self.Right.Parent = self
		
		self:InvalidateAggregateCacheUpwards ()
		self:BalancePostInsertion ()
	else
		self.Right:InsertLeftmost (node)
	end
end

function self:InsertBefore (node)
	if not self.Left then
		self.Left = node
		self.Left.Parent = self
		
		self:InvalidateAggregateCacheUpwards ()
		self:BalancePostInsertion ()
	else
		self.Left:InsertRightmost (node)
	end
end

function self:InsertLeftmost (node)
	local parent = self
	while parent.Left do
		parent = parent.Left
	end
	parent.Left = node
	parent.Left.Parent = parent
	
	parent:InvalidateAggregateCacheUpwards ()
	parent:BalancePostInsertion ()
end

function self:InsertRightmost (node)
	local parent = self
	while parent.Right do
		parent = parent.Right
	end
	parent.Right = node
	parent.Right.Parent = parent
	
	parent:InvalidateAggregateCacheUpwards ()
	parent:BalancePostInsertion ()
end

-- Cache invalidation
function self:InvalidateAggregateCache ()
end

function self:InvalidateCache ()
end

function self:InvalidateAggregateCacheUpwards ()
	self.ChildStatisticsValid = false
	self:InvalidateAggregateCache ()
	
	if self.Parent then
		self.Parent:InvalidateAggregateCacheUpwards ()
	end
end

function self:InvalidateCacheUpwards ()
	self:InvalidateCache ()
	self:InvalidateAggregateCacheUpwards ()
end

function self:InvalidateChildStatistics ()
	self.ChildStatisticsValid = false
	
	if self.Parent then
		self.Parent:InvalidateChildStatistics ()
	end
end

function self:IsLeftChild ()
	if not self.Parent then return false end
	return self.Parent.Left == self
end

function self:IsRightChild ()
	if not self.Parent then return false end
	return self.Parent.Right == self
end

function self:IsRoot ()
	return self.Parent == nil
end

-- Deletion
function self:Orphan ()
	if not self.Parent then
		self.Tree = nil
		return
	end
	
	if self.Parent.Left == self then
		self.Parent.Left = nil
	else
		self.Parent.Right = nil
	end
	self.Parent:InvalidateAggregateCacheUpwards ()
	
	self.Parent = nil
end

function self:Remove ()
	if self.Left == nil then
		self:ReplaceWith (self.Right)
	elseif self.Right == nil then
		self:ReplaceWith (self.Left)
	else
		local next = self.Right:GetLeftmost ()
		if next.Parent ~= self then
			next:ReplaceWith (next.Right)
			next.Right = self.Right
			next.Right.Parent = next
		end
		self:ReplaceWith (next)
		next.Left = self.Left
		next.Left.Parent = next
	end
end

function self:ReplaceWith (node)
	if self.Parent then
		if self.Parent.Left == self then
			self.Parent.Left = node
		else
			self.Parent.Right = node
		end
		if node then
			node:Orphan ()
			node.Parent = self.Parent
		end
		self.Parent:InvalidateAggregateCacheUpwards ()
		self.Parent = nil
	elseif self.Tree then
		self.Tree.Root = node
		
		if node then
			node:Orphan ()
			node.Parent = nil
			node.Tree = self.Tree
		end
		self.Tree = nil
	end
	
	self:InvalidateAggregateCacheUpwards ()
end

function self:RotateLeft ()
	if not self.Right then return end
	
	local right = self.Right
	local rightLeft = self.Right.Left
	
	-- Make right child's left child our right child
	self.Right = rightLeft
	if rightLeft then rightLeft.Parent = self end
	
	-- Parent us to our original right child
	right.Left = self
	right.Parent = self.Parent
	if self.Parent then
		if self.Parent.Left == self then
			self.Parent.Left = right
		else
			self.Parent.Right = right
		end
	else
		right.Tree = self.Tree
		if self.Tree then
			self.Tree.Root = right
			self.Tree = nil
		end
	end
	self.Parent = right
	
	self:InvalidateAggregateCacheUpwards ()
end

function self:RotateRight ()
	if not self.Left then return end
	
	local left = self.Left
	local leftRight = self.Left.Right
	
	-- Make left child's right child our left child
	self.Left = leftRight
	if leftRight then leftRight.Parent = self end
	
	-- Parent us to our original left child
	left.Right = self
	left.Parent = self.Parent
	if self.Parent then
		if self.Parent.Left == self then
			self.Parent.Left = left
		else
			self.Parent.Right = left
		end
	else
		left.Tree = self.Tree
		if self.Tree then
			self.Tree.Root = left
			self.Tree = nil
		end
	end
	self.Parent = left
	
	self:InvalidateAggregateCacheUpwards ()
end

function self:SetTree (tree)
	if self.Tree == tree then return end
	
	self.Tree = tree
end

function self:ToString ()
	return ""
end

function self:ToStringRecursive ()
	local tree = "{\n"
	tree = tree .. "\t" .. self:ToString ():gsub ("\n", "\n\t") .. "\n"
	if self.Left or self.Right then
		if self.Left then
			tree = tree .. "\tLeft " .. self.Left:ToStringRecursive ():gsub ("\n", "\n\t") .. ",\n"
		else
			tree = tree .. "\tLeft: [nil],\n"
		end
		if self.Right then
			tree = tree .. "\tRight " .. self.Right:ToStringRecursive ():gsub ("\n", "\n\t") .. "\n"
		else
			tree = tree .. "\tRight: [nil]\n"
		end
	end
	tree = tree .. "}"
	return tree
end