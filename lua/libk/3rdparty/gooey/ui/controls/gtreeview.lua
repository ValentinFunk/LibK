local PANEL = {}

--[[
	Events:
		ItemSelected (treeViewNode)
			Fired when the selected tree view node changes.
]]

function PANEL:Init ()
	-- Remove the original root node and replace it with our own
	self.RootNode:Remove ()
	self.RootNode = self:GetCanvas ():Add ("GTreeViewNode")
	self.RootNode:SetTreeView (self)
	self.RootNode:SetRoot (self)
	self.RootNode:SetParentNode (self)
	self.RootNode:Dock (TOP)
	self.RootNode:SetText ("")
	self.RootNode:SetExpanded (true, true)
	
	self.LastClickTime = 0
	
	self.Menu = nil

	self.PopulationMode = "Static"
	self.Populator = nil
	
	self.ShouldSuppressLayout = false
end

function PANEL:AddNode (name)
	return self.RootNode:AddNode (name)
end

function PANEL:Clear ()
	self.RootNode:Clear ()
end

function PANEL.DefaultComparator (a, b)
	return a:GetText () < b:GetText ()
end

function PANEL:FindChild (id)
	if not self.RootNode.ChildNodes then return nil end
	
	for _, item in pairs (self.RootNode.ChildNodes:GetChildren ()) do
		if item:GetId () == id then
			return item
		end
	end
	return nil
end

function PANEL:GetChildCount ()
	return self.RootNode:GetChildCount ()
end

function PANEL:GetComparator ()
	return self.Comparator or self.DefaultComparator
end

function PANEL:GetMenu ()
	return self.Menu
end

function PANEL:GetParentNode ()
	return nil
end

function PANEL:GetPopulator ()
	return self.Populator
end

function PANEL:InvalidateLayout ()
	if not self.ShouldSuppressLayout then debug.getregistry ().Panel.InvalidateLayout (self) end
end

function PANEL:LayoutRecursive ()
	if not self.ShouldSuppressLayout then self:InvalidateLayout () end
end

function PANEL:PerformLayout ()
	if not self.ShouldSuppressLayout then DScrollPanel.PerformLayout (self) end
end

function PANEL:RemoveNode (node)
	if not node or not node:IsValid () then return end
	if node:GetParent () ~= self:GetCanvas () then return end

	self:RemoveItem (node)
	self.ChildNodeCount = self.ChildNodeCount - 1
	self:InvalidateLayout ()
end

function PANEL:SetExpandable (expandable)
	self.RootNode:SetExpandable (expandable)
end

function PANEL:SetMenu (menu)
	self.Menu = menu
end

function PANEL:SetPopulator (populator)
	self.Populator = populator
end

--[[
	GTreeView:SetSelected (selected)
	
		Do not call this, it's used to simulate the behavious of a GTreeViewNode.
]]
function PANEL:SetSelected (selected)
	if selected then
		self:SetSelectedItem (nil)
	end
end

function PANEL:SetSelectedItem (node)
	if self.m_pSelectedItem == node then return end
	DTree.SetSelectedItem (self, node)
	self:DispatchEvent ("ItemSelected", node)
end

function PANEL:SortChildren (comparator)
	self.RootNode:SortChildren (comparator or self.Comparator or self.DefaultComparator)
	self:InvalidateLayout ()
end

function PANEL:SuppressLayout (suppress)
	self.ShouldSuppressLayout = suppress
end

-- Event handlers
function PANEL:DoClick (node)
	if SysTime () - self.LastClickTime < 0.3 then
		self:DoDoubleClick (node)
		self.LastClickTime = 0
	else
		self:DispatchEvent ("Click", node)
		self.LastClickTime = SysTime ()
	end
end

function PANEL:DoDoubleClick (node)
	self:DispatchEvent ("DoubleClick", node)
end

function PANEL:DoRightClick (node)
	if self.Menu then
		self.Menu:Show (self, node)
	end
	self:DispatchEvent ("RightClick", node)
end

function PANEL:OnMouseReleased (mouseCode)
	self:SetSelectedItem (nil)
	if mouseCode == MOUSE_RIGHT then
		self:DoRightClick ()
	end
end

function PANEL:OnRemoved ()
	if self.Menu then self.Menu:dtor () end
end

Gooey.Register ("GTreeView", PANEL, "DTree") 