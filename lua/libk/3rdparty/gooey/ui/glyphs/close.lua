local crossPoly1 =
{
	{ x = 0, y = 0 },
	{ x = 2, y = 0 },
	{ x = 8, y = 7 },
	{ x = 8, y = 8 },
	{ x = 7, y = 8 },
	{ x = 0, y = 2 }
}

local crossPoly2 =
{
	{ x = 8, y = 0 },
	{ x = 7, y = 0 },
	{ x = 0, y = 7 },
	{ x = 0, y = 8 },
	{ x = 2, y = 8 },
	{ x = 8, y = 2 }
}

Gooey.Glyphs.Register ("close",
	function (renderContext, color, x, y, w, h)
		renderContext:PushRelativeViewPort (x + w * 0.5 - 4, y + h * 0.5 - 4)
		
		surface.SetTexture (-1)
		surface.DrawPoly (crossPoly1)
		surface.DrawPoly (crossPoly2)
		
		renderContext:PopViewPort ()
	end
)