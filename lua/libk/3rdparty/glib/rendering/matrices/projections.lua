local self = {}
GLib.Rendering.Matrices.Projections = GLib.MakeConstructor (self)

-- Returns a projection matrix with (0, 0) at the top left of the screen,
-- positive x rightwards and positive y downwards
function GLib.Rendering.Matrices.Projections.OrthographicLeftHanded (width, height, near, far)
	return GLib.Matrix (4, 4,
		2 / width,           0,                   0, -1,
		        0, -2 / height,                   0,  1,
				0,           0,    1 / (far - near),  0,
				0,           0, near / (near - far),  1
	)
end

-- Returns a projection matrix with (0, 0) at the centre of the screen,
-- positive x rightwards and positive y upwards
function GLib.Rendering.Matrices.Projections.OrthographicLeftHanded2 (width, height, near, far)
	return GLib.Matrix (4, 4,
		2 / width,          0,                   0,  0,
		        0, 2 / height,                   0,  0,
				0,          0,    1 / (far - near),  0,
				0,          0, near / (near - far),  1
	)
end