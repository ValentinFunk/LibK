local self = {}
GLib.Matrix = GLib.MakeConstructor (self)

local emptyTable = {}

function GLib.Matrix.RotationFromAngle (angle)
	-- Roll, then pitch, then yaw
	
	-- Roll
	-- Anticlockwise about the x axis, looking from position x towards the origin
	-- Clockwise about the x axis, looking out from the origin
	-- Rotates the camera clockwise about its axis
	local r = math.rad (angle.r)
	local cosr = math.cos (r)
	local sinr = math.sin (r)
	
	-- R = [1,     0,      0;
    --      0, cos r, -sin r;
    --      0, sin r,  cos r]
	
	-- Pitch
	-- Anticlockwise about the y axis, looking from positive y towards the origin
	-- Tilts the camera down
	local p = math.rad (angle.p)
	local cosp = math.cos (p)
	local sinp = math.sin (p)
	
	-- P = [ cos p, 0, sin p;
	--           0, 1,     0;
	--      -sin p, 0, cos p]
	
	-- Yaw
	-- Anticlockwise about the z axis, looking from above (positive z towards down towards the origin)
	-- Turns the camera left
	local y = math.rad (angle.y)
	local cosy = math.cos (y)
	local siny = math.sin (y)
	
	-- Y = [cos y, -sin y, 0;
	--      sin y,  cos y, 0;
	--          0,      0, 1]
	
	-- A = [ cos p * cos y, sin p * sin r * cos y - cos r * sin y, cos r * sin p * cos y + sin r * sin y;
	--       cos p * sin y, sin p * sin r * sin y + cos r * cos y, cos r * sin p * sin y - sin r * cos y;
	--              -sin p,                         cos p * sin r,                         cos p * cos r]
	
	return GLib.Matrix (3, 3,
		 cosp * cosy, sinp * sinr * cosy - cosr * siny, cosr * sinp * cosy + sinr * siny,
		 cosp * siny, sinp * sinr * siny + cosr * cosy, cosr * sinp * siny - sinr * cosy,
		       -sinp,                      cosp * sinr,                      cosp * cosr
	)
end

function GLib.Matrix.FromVMatrix (vmatrix, out)
	return GLib.VMatrix.ToMatrix (vmatrix, out)
end

function GLib.Matrix.Identity (size)
	local matrix = GLib.Matrix (size, size)
	for i = 0, size - 1 do
		matrix [1 + i * matrix.Width + i] = 1
	end
	
	return matrix
end

function self:ctor (w, h, m1, ...)
	self.Width  = w or 0
	self.Height = h or 0
	
	local elements = m1 and { m1, ... } or emptyTable
	for i = 1, self.Width * self.Height do
		self [i] = elements [i] or 0
	end
	
	if self:IsSquare () then
		for k = 0, self.Width - 1 do
			self [1 + k * k] = elements [1 + k * k] or 1
		end
	end
end

function self:Clone (clone)
	clone = clone or self.__ictor ()
	
	clone:Copy (self)
	
	return clone
end

function self:Copy (source)
	self.Width  = source.Width
	self.Height = source.Height
	
	for i = 1, source:GetElementCount () do
		self [i] = source [i]
	end
	
	return self
end

function self:Add (b, out)
	if self.Width  ~= b.Width or
	   self.Height ~= b.Height then
		GLib.Error ("Matrix:Add : Left matrix has dimensions " .. self.Width .. "x" .. self.Height .. " and right matrix has incompatible dimensions " .. b.Width .. "x" .. b.Height .. ".")
		return nil
	end
	
	out = out or GLib.Matrix (self.Width, self.Height)
	out.Width  = self.Width
	out.Height = self.Height
	
	for i = 1, self.Width * self.Height do
		out [i] = self [i] + b [i]
	end
	
	return out
end

function self:Adjugate (out)
	if not self:IsSquare () then
		GLib.Error ("Matrix:Determinant : Matrix is not square.")
		return nil
	end
	
	if out == self then out = nil end
	
	out = out or GLib.Matrix (self.Width, self.Height)
	out.Width  = self.Width
	out.Height = self.Height
	
	if self.Width == 1 then
		out [1] = self [1]
	elseif self.Width == 2 then
		out [1] =  self [4]
		out [2] = -self [2]
		out [3] = -self [3]
		out [4] =  self [1]
	else
		for y = 0, self.Height - 1 do
			for x = 0, self.Width - 1 do
				out [1 + y * out.Width + x] = self:Cofactor (x, y)
			end
		end
	end
	
	return out
end

function self:Cofactor (cx, cy)
	if not self:IsSquare () then
		GLib.Error ("Matrix:Cofactor : Matrix is not square.")
		return nil
	end
	
	return self:Subdeterminant ((cx + 1) % self.Width, (cy + 1) % self.Height, self.Width - 1)
end

function self:Determinant ()
	if not self:IsSquare () then
		GLib.Error ("Matrix:Determinant : Matrix is not square.")
		return nil
	end
	
	if self.Width == 1 then
		return self [1]
	elseif self.Width == 2 then
		return self [1] * self [4] - self [2] * self [3]
	elseif self.Width == 3 then
		return self [1] * (self [5] * self [9] - self [6] * self [8]) + self [2] * (self [6] * self [7] - self [4] * self [9]) + self [3] * (self [4] * self [8] - self [5] * self [7])
	else
		return self:Subdeterminant (0, 0, self.Width)
	end
end

function self:GetColumn (x, columnVector)
	columnVector = columnVector or GLib.ColumnVector (self.Height)
	columnVector.Width  = 1
	columnVector.Height = self.Height
	
	for y = 0, self.Height - 1 do
		columnVector [1 + y] = self [1 + y * self.Width + x - 1]
	end
	
	return columnVector
end

function self:GetDiagonal (vector)
	local diagonalSize = math.min (self.Width, self.Height)
	vector = vector or GLib.ColumnVector (diagonalSize)
	vector:SetElementCount (diagonalSize)
	
	for k = 0, diagonalSize - 1 do
		vector [1 + k] = self [1 + k * k]
	end
	
	return vector
end

function self:GetElement (y, x)
	local index = 1 + (y - 1) * self.Width + (x - 1)
	return self [index]
end

function self:GetElementCount ()
	return self.Width * self.Height
end

function self:GetWidth ()
	return self.Width
end

function self:GetHeight ()
	return self.Height
end

function self:GetRow (y, rowVector)
	rowVector = rowVector or GLib.RowVector (self.Width)
	rowVector.Width  = self.Width
	rowVector.Height = 1
	
	for x = 0, self.Width - 1 do
		rowVector [1 + x] = self [1 + (y - 1) * self.Width + x]
	end
	
	return rowVector
end

function self:IsSquare ()
	return self.Width == self.Height
end

function self:MatrixMultiply (b, out)
	if out == self then out = nil end
	if out == b    then out = nil end
	
	if self.Width ~= b.Height then
		GLib.Error ("Matrix:Multiply : Left matrix has dimensions " .. self.Width .. "x" .. self.Height .. " and right matrix has incompatible dimensions " .. b.Width .. "x" .. b.Height .. ".")
		return nil
	end
	
	out = out or GLib.Matrix (b.Width, self.Height)
	out.Width  = b.Width
	out.Height = self.Height
	
	local element = 0
	for y = 0, self.Height - 1 do
		for x = 0, b.Width - 1 do
			element = 0
			for k = 0, self.Width - 1 do
				element = element + self [1 + y * self.Width + k] * b [1 + k * b.Width + x]
			end
			out [1 + y * out.Width + x] = element
		end
	end
	
	return out
end

function self:Multiply (b, out)
	if isnumber (b) then
		return self:ScalarMultiply (b, out)
	else
		return self:MatrixMultiply (b, out)
	end
end

function self:Negate (out)
	out = out or GLib.Matrix (self.Height, self.Width)
	
	for y = 0, self.Height - 1 do
		for x = 0, self.Width - 1 do
			out [1 + y * out.Width + x] = -self [1 + y * self.Width + x]
		end
	end
	
	return out
end

function self:OrthonormalToVMatrix ()
	-- This better be orthonormal
	
	-- A = [ cos p * cos y, sin p * sin r * cos y - cos r * sin y, cos r * sin p * cos y + sin r * sin y;
	--       cos p * sin y, sin p * sin r * sin y + cos r * cos y, cos r * sin p * sin y - sin r * cos y;
	--              -sin p,                         cos p * sin r,                         cos p * cos r]
	
	local rotation, reflectX = self:ToAngle ()
	
	local matrix = Matrix ()
	matrix:Rotate (rotation)
	
	if reflectX then
		local reflectionMatrix = Matrix ()
		reflectionMatrix:Scale (Vector (-1, 0, 0))
		
		matrix = matrix * reflectionMatrix
	end
	
	return matrix
end

function self:ScalarMultiply (b, out)
	out = out or GLib.Matrix (b.Width, self.Height)
	out.Width  = b.Width
	out.Height = self.Height
	
	for i = 1, self.Width * self.Height do
		out [i] = b * self [i]
	end
	
	return out
end

function self:ScaleToVMatrix ()
	-- This better be a scaling matrix
	
	if self.Width ~= 3 and self.Width ~= 4 then
		GLib.Error ("Matrix:ScaleToVMatrix : This matrix is " .. self.Height .. " by " .. self.Width .. "!")
	elseif self.Height ~= 3 and self.Height ~= 4 then
		GLib.Error ("Matrix:ScaleToVMatrix : This matrix is " .. self.Height .. " by " .. self.Width .. "!")
	end
	
	local matrix = Matrix ()
	matrix:Scale (Vector (self (1, 1), self (2, 2), self (3, 3)))
	
	return matrix
end

function self:SetColumn (x, columnVector, ...)
	if isnumber (columnVector) then
		columnVector = { columnVector, ... }
	end
	
	for y = 0, self.Height - 1 do
		self [1 + y * self.Width + x - 1] = columnVector [1 + y] or 0
	end
	
	return self
end

function self:SetDiagonal (vector)
	local diagonalSize = math.min (self.Width, self.Height, vector:GetElementCount ())
	
	for k = 0, diagonalSize - 1 do
		self [1 + k * k] = vector [1 + k]
	end
	
	return self
end

function self:SetElement (y, x, v)
	local index = 1 + (y - 1) * self.Width + (x - 1)
	self [index] = v
end

function self:SetRow (y, rowVector, ...)
	if isnumber (rowVector) then
		rowVector = { rowVector, ... }
	end
	
	for x = 0, self.Width - 1 do
		self [1 + (y - 1) * self.Width + x] = rowVector [1 + x] or 0
	end
	
	return self
end

function self:SetSubmatrix (startY, startX, matrix)
	startY = startY - 1
	startX = startX - 1
	
	for y = 0, matrix.Height - 1 do
		for x = 0, matrix.Width - 1 do
			self [1 + (startY + y) * self.Width + (startX + x)] = matrix [1 + y * matrix.Width + x]
		end
	end
	
	return self
end

function self:SquareTranspose (out)
	if not self:IsSquare () then
		GLib.Error ("Matrix:SquareTranspose : Matrix is not square.")
		return nil
	end
	
	out = out or GLib.Matrix (self.Height, self.Width)
	
	for y = 0, self.Height - 1 do
		for x = 0, y do
			local element1 = self [1 + y * self.Width + x]
			local element2 = self [1 + x * self.Width + y]
			out [1 + x * out.Width + y] = element1
			out [1 + y * out.Width + x] = element2
		end
	end
	
	return out
end

function self:Subdeterminant (startX, startY, size)
	startX = startX % self.Width
	startY = startY % self.Height
	
	if size == 1 then
		return self [1 + startY * self.Width + startX]
	elseif size == 2 then
		local x1 = (startX + 1) % self.Width
		local y1 = (startY + 1) % self.Height
		return self [1 + startY * self.Width + startX] * self [1 + y1 * self.Width + x1] - self [1 + startY * self.Width + x1] * self [1 + y1 * self.Width + startX]
	end
	
	local subdeterminant = 0
	local nextY = (startY + 1) % self.Height
	for i = 0, size - 1 do
		subdeterminant = subdeterminant + self [1 + startY * self.Width + (startX + i) % self.Width] * self:Subdeterminant ((startX + i + 1) % self.Width, nextY, size - 1)
	end
	
	return subdeterminant
end

function self:Submatrix (startX, startY, w, h, out)
	if self == out then out = nil end
	
	out = out or GLib.Matrix (w, h)
	out.Width = w
	out.Height = h
	
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			out [1 + y * out.Width + x] = self [1 + (startY + y) * self.Height + (startX + x)]
		end
	end
	
	return out
end

function self:Subtract (b, out)
	if self.Width  ~= b.Width or
	   self.Height ~= b.Height then
		GLib.Error ("Matrix:Subtract : Left matrix has dimensions " .. self.Width .. "x" .. self.Height .. " and right matrix has incompatible dimensions " .. b.Width .. "x" .. b.Height .. ".")
		return nil
	end
	
	out = out or GLib.Matrix (self.Width, self.Height)
	out.Width  = self.Width
	out.Height = self.Height
	
	for i = 1, self.Width * self.Height do
		out [i] = self [i] - b [i]
	end
	
	return out
end

function self:Transpose (out)
	if self:IsSquare () and self == out then
		return self:SquareTranspose (out)
	end
	
	if self == out then out = nil end
	
	out = out or GLib.Matrix (self.Height, self.Width)
	
	for y = 0, self.Height - 1 do
		for x = 0, self.Width - 1 do
			out [1 + x * out.Width + y] = self [1 + y * self.Width + x]
		end
	end
	
	return out
end

function self:ToAngle ()
	-- This better be a rotation matrix.
	
	-- A = [ cos p * cos y, sin p * sin r * cos y - cos r * sin y, cos r * sin p * cos y + sin r * sin y;
	--       cos p * sin y, sin p * sin r * sin y + cos r * cos y, cos r * sin p * sin y - sin r * cos y;
	--              -sin p,                         cos p * sin r,                         cos p * cos r]
	
	if self.Width ~= 3 and self.Width ~= 4 then
		GLib.Error ("Matrix:ToAngle : This matrix is " .. self.Height .. " by " .. self.Width .. "!")
	elseif self.Height ~= 3 and self.Height ~= 4 then
		GLib.Error ("Matrix:ToAngle : This matrix is " .. self.Height .. " by " .. self.Width .. "!")
	end
	
	local determinant = self:Determinant ()
	
	local p = -math.asin (self (3, 1))
	if determinant < 0 then p = -p end
	
	local cosp = math.cos (p)
	
	-- If cos p == 0 then... #yolo.
	local y = math.atan2 (self (2, 1), self (1, 1))
	local r = math.atan2 (self (3, 2), self (3, 3))
	
	return Angle (math.deg (p), math.deg (y), math.deg (r)), determinant < 0
end

function self:ToVMatrix (out)
	return GLib.VMatrix.FromMatrix (self, out)
end

function self:ToString ()
	local columnWidths = {}
	local matrix = GLib.StringBuilder ()
	
	local elements = {}
	for y = 0, self.Height - 1 do
		for x = 0, self.Width - 1 do
			elements [1 + y * self.Width + x] = tostring (math.abs (self [1 + y * self.Width + x]))
			columnWidths [x] = math.max (columnWidths [x] or 0, #elements [1 + y * self.Width + x])
		end
	end
	
	for y = 0, self.Height - 1 do
		if y > 0 then
			matrix:Append ("\n")
		end
		
		matrix:Append ("[ ")
		
		for x = 0, self.Width - 1 do
			if x > 0 then
				matrix:Append ("    ")
			end
			
			local element = self [1 + y * self.Width + x]
			local negative = element < 0 or 1 / element < 0
			matrix:Append (negative and "-" or " ")
			
			local elementString = elements [1 + y * self.Width + x]
			matrix:Append (string.rep (" ", columnWidths [x] - #elementString))
			matrix:Append (elementString)
		end
		matrix:Append ("  ]")
	end
	
	return matrix:ToString ()
end

function self:__call (y, x, v)
	local index = 1 + (y - 1) * self.Width + (x - 1)
	if v then
		self [index] = v
	else
		return self [index]
	end
end

self.__add = self.Add
self.__sub = self.Subtract

self.__mul = function (a, b)
	if isnumber (a) then return b:Multiply (a) end
	return a:Multiply (b)
end

self.__unm = self.Negate

self.__tostring = self.ToString