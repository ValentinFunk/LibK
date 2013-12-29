surface.CreateFont('PS_Tab', { font = 'Roboto', size = 27, weight = 500 })
local PANEL = {}
--[[---------------------------------------------------------
   Name: Init
-----------------------------------------------------------]]
function PANEL:Setup( label, pPropertySheet, pPanel, strMaterial )
	self:SetText( label )
	self:SetFont( "PS_Tab" )
	self:SetPropertySheet( pPropertySheet )
	self:SetPanel( pPanel )
	self:SetContentAlignment( 5 )
	self:SetTextInset( 0, 0 )
	
	if ( strMaterial ) then
		self.Image = vgui.Create( "DImage", self )
		self.Image:SetImage( strMaterial )
		self.Image:SizeToContents()
		self:InvalidateLayout()
	end
end

function PANEL:PerformLayout( )
	self.Image:SetPos( 4, (self:GetTall() - self.Image:GetTall()) * 0.5 )
	self:SetTextInset( self.Image:GetWide() + 20, 0 )
end

Derma_Hook( PANEL, "Paint", "Paint", "KPropertySheetTab" )

function PANEL:ApplySchemeSettings()
	local w, h = self:GetContentSize( )
	w = math.Clamp( w, 100, w )
	self:SetSize( w + 10, h + 5 )
	
	local skin = self:GetSkin( )
	self:SetColor( skin.Colours.Tab.Active.Normal )
		
	DLabel.ApplySchemeSettings( self )
end

derma.DefineControl( "KTab", "A Tab for use on the PropertySheet in Inv", PANEL, "DTab" )


local PANEL = {}

function PANEL:Init()
	self:SetPadding( 0 )
	self:DockPadding( 5, 0, 0, 0 )
	self:DockMargin( 0, 0, 0, 0 )
	self:SetShowIcons( true )
	
	if IsValid( self.tabScroller ) then
		self.tabScroller:Remove( )
	end
	
	self.tabScroller = vgui.Create( "DIconLayout", self )
	self.tabScroller:DockMargin( 0, 0, 0, 5 )
	self.tabScroller:Dock( TOP )
	self.tabScroller:SetSpaceX( 10 )
	self.tabScroller:SetTall( 50 )
	
	function self.tabScroller:LayoutIcons_TOP()
		local x			= self.m_iBorder
		local y			= self.m_iBorder
		local RowHeight = 0;
		local MaxWidth	= self:GetWide() - self.m_iBorder * 2;

		local chld = self:GetChildren()
		table.sort( chld, function( p1, p2 ) 
			return table.KeyFromValue( chld, p1 ) > table.KeyFromValue( chld, p2 )
		end )
		for k, v in pairs( chld ) do
		
			if ( !v:IsVisible() ) then continue end
		
			local w, h = v:GetSize()
			if ( x + w > MaxWidth || ( v.OwnLine && x > self.m_iBorder ) ) then
			
				x = self.m_iBorder
				y = y + RowHeight + self.m_iSpaceY
				RowHeight = 0;
			
			end
		
			v:SetPos( x, y )
			
			x = x + v:GetWide() + self.m_iSpaceX
			RowHeight = math.max( RowHeight, v:GetTall() )
			
			-- Start a new line if this panel is meant to be on its own line
			if ( v.OwnLine ) then
				x = MaxWidth + 1
			end
		
		end
		
	end
	
	self.panels = vgui.Create( "DPanel", self )
	self.panels:DockMargin( 0, 0, 0, 0 )
	self.panels:Dock( FILL )
	function self.panels:Paint( )
	end

	self:SetFadeTime( 0.1 )
		
	self.animFade = Derma_Anim( "Fade", self, self.CrossFade )
	
	self.Items = {}
	
end



function PANEL:SetActiveTab( active ) 
	self.BaseClass.SetActiveTab( self, active )
end

--[[---------------------------------------------------------
   Name: AddSheet
-----------------------------------------------------------]]
function PANEL:AddSheet( label, panel, material, NoStretchX, NoStretchY, Tooltip )

	if ( !IsValid( panel ) ) then return end

	local Sheet = {}
	
	Sheet.Name = label;

	Sheet.Tab = self.tabScroller:Add( "KTab", self )
	Sheet.Tab:SetTooltip( Tooltip )
	Sheet.Tab:Setup( label, self, panel, material )
	Sheet.Tab:SizeToContentsX( )
	
	Sheet.Panel = panel
	Sheet.Panel.NoStretchX = NoStretchX
	Sheet.Panel.NoStretchY = NoStretchY
	Sheet.Panel:SetVisible( false )
	
	panel:SetParent( self.panels )
	
	table.insert( self.Items, Sheet )
	
	if ( !self:GetActiveTab() ) then
		self:SetActiveTab( Sheet.Tab )
		Sheet.Panel:SetVisible( true )
	end
	
	return Sheet;

end

function PANEL:Paint( w, h )
end

--[[---------------------------------------------------------
   Name: PerformLayout
-----------------------------------------------------------]]
function PANEL:PerformLayout()

	--self.tabScroller:SizeToContents( )
	self:SetPadding( self.tabScroller:GetTall( ) )

	local ActiveTab = self:GetActiveTab()
	local Padding = self:GetPadding()
	
	if ( !ActiveTab ) then return end
	
	-- Update size now, so the height is definitiely right.
	ActiveTab:InvalidateLayout( true )
		
	--self.tabScroller:StretchToParent( Padding, 0, Padding, nil )
	--self.tabScroller:SetTall( ActiveTab:GetTall() )
	--self.tabScroller:SizeToContents( )
	
	
	
	local ActivePanel = ActiveTab:GetPanel()
	for k, v in pairs( self.Items ) do
		if ( v.Tab:GetPanel() == ActivePanel ) then
			v.Tab:GetPanel():SetVisible( true )
			v.Tab:SetZPos( 100 )
		else
			v.Tab:GetPanel():SetVisible( false )	
			v.Tab:SetZPos( 1 )
		end
		v.Tab:ApplySchemeSettings()
	end
	
	if ( !ActivePanel.NoStretchX ) then 
		ActivePanel:SetWide( self:GetWide() - Padding * 2 ) 
	else
		ActivePanel:CenterHorizontal()
	end
	
	if ( !ActivePanel.NoStretchY ) then 
		ActivePanel:Dock( FILL )
	else
		ActivePanel:CenterVertical()
	end
	
	ActivePanel:InvalidateLayout()

	-- Give the animation a chance
	self.animFade:Run()
end
derma.DefineControl( "KPropertySheet", "", PANEL, "DPropertySheet" )