Gooey.Glyphs = {}
Gooey.Glyphs.Renderers = {}

function Gooey.Glyphs.Draw (name, renderContext, color, x, y, w, h)
	if not Gooey.Glyphs.Renderers [name] then
		surface.SetDrawColor (color)
		surface.DrawRect (x, y, w, h)
		return
	end
	
	surface.SetDrawColor (color)
	xpcall (Gooey.Glyphs.Renderers [name], Gooey.Error, renderContext, color, x, y, w, h)
end

function Gooey.Glyphs.Register (name, renderer)
	Gooey.Glyphs.Renderers [name] = renderer
end