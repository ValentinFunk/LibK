local PANEL = {}

AccessorFunc( PANEL, "Spacing", "Spacing" )
AccessorFunc( PANEL, "Padding", "Padding" ) 
AccessorFunc( PANEL, "Ratio", "Ratio" ) 

function PANEL:Init( )
	self:SetLeft( vgui.Create( "DPanel" ) )
	self.left.Paint = function( ) end
	self:SetRight( vgui.Create( "DPanel" ) )
	self.right.Paint = function( ) end
	self:SetSpacing( 5 )
	self:SetPadding( 0 )
	self:SetRatio( 0.5 )
end

function PANEL:SetLeft( panel )
	if IsValid( self.left ) then
		self.left:Remove( )
	end
	
	self.left = panel
	self.left:SetParent( self )
	self.left:Dock( LEFT )
end

function PANEL:SetRight( panel )
	if IsValid( self.right ) then
		self.right:Remove( )
	end
	
	self.right = panel
	self.right:SetParent( self )
	self.right:Dock( RIGHT )
end

function PANEL:PerformLayout( )
	self.left:DockMargin( self.Padding, self.Padding, 0, self.Padding )
	self.right:DockMargin( 0, self.Padding, self.Padding, self.Padding )
	local w = self:GetWide( ) - self.Spacing
	self.left:SetWide( w * self.Ratio )
	self.right:SetWide( w * ( 1- self.Ratio ) )
end

Derma_Hook( PANEL, "Paint", "Paint", "InnerPanel" )

vgui.Register( "DSplitPanel", PANEL, "DPanel" )