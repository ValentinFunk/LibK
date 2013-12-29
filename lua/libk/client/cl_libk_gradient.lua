local GRADIENT_HORIZONTAL, GRADIENT_VERTICAL = 0, 1
local GRADIENT_HSV, GRADIENT_LERP = 0, 1
function draw.LinearGradientHSV( x, y, w, h, from, to, dir )
	local hsvFrom = {ColorToHSV( from )}
	local hsvTo = {ColorToHSV( to )}
	local diff = {hsvTo[1] - hsvFrom[1], hsvTo[2] - hsvFrom[2], hsvTo[3] - hsvFrom[3]}
	for i = 0, h, 0.05 do
		local r, g, b = HSVToColor( hsvFrom[1] + ( i / h ) * diff[1], hsvFrom[2] + ( i / h ) * diff[2], hsvFrom[3] + ( i / h ) * diff[3] )
		surface.SetDrawColor( r, g, b )
		if dir == GRADIENT_VERTICAL then
			surface.DrawRect( x, i, w, h )
		else
			surface.DrawRect( i, y, w, h )
		end
	end
end


function draw.LinearGradient( x, y, w, h, from, to, dir )
	for i = 0, h, 0.05 do
		local r, g, b = Lerp( i / h, from.r, to.r ), Lerp( i/h, from.g, to.g ), Lerp( i/h, from.b, to.b )
		surface.SetDrawColor( r, g, b )
		if dir == GRADIENT_VERTICAL then
			surface.DrawRect( x, i, w, h )
		else
			surface.DrawRect( i, y, w, h )
		end
	end
end

local function createGradientTexture( strName, w, h, color_start, color_end, dir, method )
	local rt = GetRenderTarget( strName, w, h, false )
	local oldRT = render.GetRenderTarget( )
	local method = method or GRADIENT_LERP
	local oldW, oldH = ScrW(), ScrH( )
	render.SetRenderTarget( rt )
		render.SetViewPort( 0, 0, w, h )
		render.Clear( 0, 0, 0, 255, true )
		cam.Start2D( )
			if method == GRADIENT_LERP then
				draw.LinearGradient( 0, 0, w, h, color_start, color_end, dir )
			else
				draw.LinearGradientHSV( 0, 0, w, h, color_start, color_end, dir )
			end
		cam.End2D( )
	render.SetRenderTarget( oldRt )
	render.SetViewPort( 0, 0, oldW, oldH )
	return rt
end

function createGradientMaterial( strName, w, h, color_start, color_end, dir, method )
	local rt = createGradientTexture( strName, w, h, color_start, color_end, dir, method )
	local mat = CreateMaterial( strName, "UnlitGeneric", {
		/*Proxies = {
			Sine = {
				resultVar =	"$color", // The shader parameter to be manipulated
				sineperiod =	8,
				sinemin		= 0,
				sinemax		= 1,
			}
		}*/
	} )
	mat:SetTexture( "$basetexture", rt )
	return mat
end

function drawGradientBar( mat, x, y, w, h )
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial( mat )
	surface.DrawTexturedRectUV( x, y, w, h, 0, 0, w, 1 )
end

local materials = {}
LibK.mat = materials
function draw.GradientBox( id, x, y, w, h, from, to, dir, pulse, pulseColorFrom, pulseColorTo, pulseSpeed, method )
	dir = dir or GRADIENT_VERTICAL
	pulse = pulse or false
	pulseColorFrom = pulseColorFrom or Color( 100, 100, 100 )
	pulseColorTo = pulseColorTo or Color( 255, 255, 255 )
	pulseSpeed = pulseSpeed or 1/2
	if not materials[id] then
		if not GAMEMODE.CanRender then
			return
		end
		if dir == GRADIENT_VERTICAL then
			materials[id] = createGradientMaterial( id, 1, h, from, to, dir, method )
		else
			materials[id] = createGradientMaterial( id, w, 1, from, to, dir, method )
		end
	end
	if pulse then
		local fact = ( math.cos( CurTime( ) * pulseSpeed ) + 1 ) / 2
		local r, g, b = Lerp( fact, pulseColorFrom.r, pulseColorTo.r ), Lerp( fact, pulseColorFrom.g, pulseColorTo.g ), Lerp( fact, pulseColorFrom.b, pulseColorTo.b )
		color = Vector( r, g, b )
		materials[id]:SetVector( "$color", color )
	end
	
	surface.SetMaterial( materials[id] )
	surface.SetDrawColor( 255, 255, 255, 255 )
	if dir == GRADIENT_VERTICAL then
		surface.DrawTexturedRectUV( x, y, w, h, 0, 0, w, 1 )
	else
		surface.DrawTexturedRectUV( x, y, w, h, 0, 0, 1, h )
	end
end

hook.Add( "HUDPaint", "TestMaterial", function( ) 
	GAMEMODE.CanRender = true
end )