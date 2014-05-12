local arrow =
{
	{ x = 0,   y = 5 },
	{ x = 7,   y = 5 },
	{ x = 3.5, y = 1 }
}

local shiftedArrow =
{
	{ x = 0,   y = 4 },
	{ x = 7,   y = 4 },
	{ x = 3.5, y = 0 }
}

Gooey.Glyphs.Register ("up",
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