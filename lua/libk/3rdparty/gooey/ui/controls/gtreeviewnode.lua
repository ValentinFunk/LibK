local PANEL = {}

function PANEL:Init ()
	self.TreeView = nil
	self.Id = "Unknown"

	-- Code copied from DTree_Node
	self.Label = vgui.Create ("DTree_Node_Button", self)
	self.Label.DoClick = function () self:InternalDoClick () end
	self.Label.DoDoubleClick = function () self:InternalDoClick () end
	self.Label.DoRightClick = function () self:InternalDoRightClick () end
	self.Label.DragHover = function (s, t) self:DragHover (t) end

	self.Expander = vgui.Create ("DExpandButton", self)
	self.Expander.DoClick = function () self:SetExpanded (not self.m_bExpanded) end
	self.Expander:SetVisible (false)
	
	self.Icon = vgui.Create ("GImage", self)
	
	self:SetTextColor (Color (0, 0, 0, 255))
	
	self.animSlide = Derma_Anim ("Anim", self, self.AnimSlide)
	
	self.fLastClick = SysTime ()
	
	self:SetDrawLines (false)
	self:SetLastChild (false)

	self.Children = {}       -- set of children
	self.SortedChildren = {} -- sorted array of children
	
	self.ChildNodes = nil
	self.ChildNodeCount = 0

	self.Populated = false
	self.ExpandOnPopulate = false
	
	self.ShouldSuppressLayout = false
	self:SetIcon ("icon16/folder.png")
end

function PANEL:AddNode (name)
	self:CreateChildNodes()
	
	local node = vgui.Create ("GTreeViewNode", self)
	node:SetTreeView (self:GetTreeView ())
	node:SetId (name)
	node:SetText (name)
	node:SetParentNode (self)
	node:SetRoot (self:GetRoot ())
	
	self.ChildNodes:Add (node)
	
	self.Children [node] = true
	self.SortedChildren [#self.SortedChildren + 1] = node
	self.ChildNodeCount = self.ChildNodeCount + 1
	self:InvalidateLayout ()
	
	if self.ExpandOnPopulate then
		self.ExpandOnPopulate = false
		self:SetExpanded (true)
	end
	
	self:LayoutRecursive ()
	
	return node
end

function PANEL:Clear ()
	if not self.ChildNodes then return end
	self.ChildNodes:Clear ()
	self.ChildNodeCount = 0
	if not self:IsRoot () then
		self:SetExpanded (false)
		self:SetExpandable (false)
		self:MarkUnpopulated ()
	end
	
	self:LayoutRecursive ()
end

function PANEL:CreateChildNodes ()
	DTree_Node.CreateChildNodes (self)
	
	self.ChildNodes.OnChildRemoved = function (listLayout, ...)
		self:OnChildRemoved (...)
	end
	
	self.ChildNodes.PerformLayout = function (listLayout)
		listLayout:SizeToChildren (false, true)
		local y = 0
		for k, v in ipairs (self.SortedChildren) do
			v:SetPos (0, y)
			y = y + v:GetTall ()
		end
	end
end

function PANEL:ExpandTo (expanded)
	self:SetExpanded (expanded)
	self:GetParentNode():ExpandTo (expanded)
end

function PANEL:FindChild (id)
	if not self.ChildNodes then
		return nil
	end
	for _, item in pairs (self.ChildNodes:GetChildren ()) do
		if item:GetId () == id then
			return item
		end
	end
	return nil
end

function PANEL:GetChildCount ()
	return self.ChildNodeCount
end

function PANEL:GetComparator ()
	return self.Comparator or self.DefaultComparator or self:GetParentNode ():GetComparator ()
end

function PANEL:GetIcon ()
	return self.Icon and self.Icon.ImageName or nil
end

function PANEL:GetId ()
	return self.Id
end

function PANEL:GetText ()
	return self.Label:GetValue ()
end

function PANEL:GetTreeView ()
	return self.TreeView
end

function PANEL:IsExpandable ()
	return self:HasChildren () or self:GetForceShowExpander ()
end

function PANEL:IsExpanded ()
	return self.m_bExpanded
end

function PANEL:IsPopulated ()
	return self.Populated
end

function PANEL:IsRoot ()
	return self == self:GetRoot ().RootNode
end

function PANEL:IsSelected ()
	return self:GetRoot ().m_pSelectedItem == self or self.Label:IsSelected ()
end

function PANEL:LayoutRecursive ()
	if not self.ShouldSuppressLayout then
		if self.ChildNodes then
			self.ChildNodes:InvalidateLayout (true)
		end
		self:InvalidateLayout (true)
		self:GetParentNode ():LayoutRecursive ()
	end
end

function PANEL:MarkUnpopulated ()
	self.Populated = false
end

function PANEL:Populate ()
	self.Populated = true
	if self:GetRoot ():GetPopulator () then
		self:GetRoot ():GetPopulator () (self)
	end
end

function PANEL:RemoveNode (node)
	if not self.ChildNodes then return end
	if not node or not node:IsValid () then return end
	if node:GetParent () ~= self.ChildNodes then return end
	node:Remove ()
end

function PANEL:Select ()
	self:GetRoot ():SetSelectedItem (self)
end

function PANEL:SetExpandable (expandable)
	self:SetForceShowExpander (expandable)
	self.Expander:SetVisible (self:HasChildren () or expandable)
	
	if not expandable then
		self:SetExpanded (false, true)
	end
end

function PANEL:SetExpanded (expanded, suppressAnimation)
	if self:IsExpanded () == expanded then return end
	if expanded and
		not self.Populated and
		self:IsExpandable () then
		self:SetExpandOnPopulate (true)
		self:Populate ()
	end
	if self:IsExpanded () == expanded then return end
	DTree_Node.SetExpanded (self, expanded, suppressAnimation)
end

function PANEL:SetExpandOnPopulate (expand)
	self.ExpandOnPopulate = expand
end

function PANEL:SetIcon (icon)
	self.Icon:SetImage (icon)
end

function PANEL:SetId (id)
	self.Id = id
end

function PANEL:SetTextColor (color)
	self.Label:SetColor (color)
end

function PANEL:SetTreeView (treeView)
	self.TreeView = treeView
end

function PANEL:SortChildren (comparator)
	comparator = comparator or self:GetComparator ()
	table.sort (self.SortedChildren,
		function (a, b)
			if a == nil then return false end
			if b == nil then return true end
			return comparator (a, b)
		end
	)
	
	for _, v in ipairs (self.SortedChildren) do
		v:MoveToFront ()
	end
	
	if self.ChildNodes then
		self.ChildNodes:InvalidateLayout ()
	end
end

function PANEL:SuppressLayout (suppress)
	self.ShouldSuppressLayout = suppress
end

-- Event handlers
function PANEL:DoRightClick ()
	self:GetRoot ():SetSelectedItem (self)
end

function PANEL:InternalDoClick ()
	local expanded = self:IsExpanded ()
	local wasSelected = self:IsSelected ()
	self:GetRoot ():SetSelectedItem (self)

	if self:DoClick () then return end
	if self:GetRoot ():DoClick (self) then return end
	
	if not expanded or wasSelected then
		self:SetExpanded (not expanded)
	end
end

function PANEL:OnChildRemoved (childNode)
	if not self.Children [childNode] then return end
	
	self.Children [childNode] = nil
	for k, v in ipairs (self.SortedChildren) do
		if v == childNode then
			table.remove (self.SortedChildren, k)
			break
		end
	end
	self.ChildNodeCount = self.ChildNodeCount - 1
	if self.ChildNodeCount == 0 and not self:IsRoot () then
		self:SetExpandable (false)
	end
	
	self:GetRoot ():LayoutRecursive ()
end

function PANEL:OnMouseWheel (delta, x, y)
	self:GetTreeView ():OnMouseWheeled (delta)
end

function PANEL:OnRemoved ()	
	-- Remove children first, so selection can bubble up to us.
	if self.ChildNodes then
		for _, item in pairs (self.ChildNodes:GetChildren ()) do
			item:Remove ()
		end
	end
	
	-- Now bubble selection upwards.
	if self.Label:IsSelected () then
		self:GetRoot ():SetSelectedItem (self:GetParentNode ())
	end
end

-- Import other functions from DTree_Node
local startTime = SysTime ()
local function TryImport ()
	if not DTree_Node then
		if SysTime () - startTime > 60 then
			Gooey.Register ("GTreeViewNode", PANEL, "GPanel")
			return
		end
		GLib.CallDelayed (TryImport)
		return
	end
	
	for k, v in pairs (DTree_Node) do
		if not PANEL [k] then PANEL [k] = v end
	end
	Gooey.Register ("GTreeViewNode", PANEL, "GPanel")
end
TryImport ()