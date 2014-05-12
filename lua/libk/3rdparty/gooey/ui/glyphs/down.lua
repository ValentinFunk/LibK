local arrow =
{
	{ x = 0,   y = 1 },
	{ x = 7,   y = 1 },
	{ x = 3.5, y = 5 }
}

local shiftedArrow =
{
	{ x = 0,   y = 2 },
	{ x = 7,   y = 2 },
	{ x = 3.5, y = 6 }
}

Gooey.Glyphs.Register ("down",
	function (renderContext, color, x, y, w, h)
		renderContext:PushRelativeViewPort (x + w * 0.5 - 3, y + h * 0.5 - 3)
		
		surface.SetTexture (-1)
		local alpha = color.a
		color.a = color.a * 0.5
		surface.SetDrawColor (color)
		surface.DrawPoly (shiftedArrow)
		color.a = alpha
		surface.SetDrawColor (color)
		surface.DrawPoly (arrow)
		
		renderContext:PopViewPort ()
	end
)