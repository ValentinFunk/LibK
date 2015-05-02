local self = debug.getregistry ().VMatrix
GLib.VMatrix = {}

local v = Vector ()
function GLib.VMatrix.FromMatrix (matrix, out)
	-- This better be a 3d affine transformation matrix
	if matrix.Width ~= 3 and matrix.Width ~= 4 then
		GLib.Error ("VMatrix.FromMatrix : This matrix is " .. matrix.Height .. " by " .. matrix.Width .. "!")
	elseif matrix.Height ~= 3 and matrix.Height ~= 4 then
		GLib.Error ("VMatrix.FromMatrix : This matrix is " .. matrix.Height .. " by " .. matrix.Width .. "!")
	end
	
	out = out or Matrix ()
	
	-- First 3 rows
	out:SetForward (matrix:GetColumn (1, v))
	
	v = matrix:GetColumn (2, v)
	v.x = -v.x
	v.y = -v.y
	v.z = -v.z
	out:SetRight (v)
	
	out:SetUp (matrix:GetColumn (3, v))
	if matrix.Width == 4 then
		out:SetTranslation (matrix:GetColumn (4, v))
	end
	
	-- Last row
	out:SetField (4, 1, matrix:GetElement (4, 1))
	out:SetField (4, 2, matrix:GetElement (4, 2))
	out:SetField (4, 3, matrix:GetElement (4, 3))
	out:SetField (4, 4, matrix:GetElement (4, 4))
	
	return out
end

function GLib.VMatrix.ToMatrix (vmatrix, out)
	out = out or GLib.Matrix (4, 4)
	out.Width  = 4
	out.Height = 4
	
	-- First 3 rows
	out:SetColumn (1, vmatrix:GetForward ())
	
	local right = vmatrix:GetRight ()
	right.x = -right.x
	right.y = -right.y
	right.z = -right.z
	out:SetColumn (2, right)
	
	out:SetColumn (3, vmatrix:GetUp ())
	out:SetColumn (4, vmatrix:GetTranslation ())
	
	-- Last row
	out:SetElement (4, 1, vmatrix:GetField (4, 1))
	out:SetElement (4, 2, vmatrix:GetField (4, 2))
	out:SetElement (4, 3, vmatrix:GetField (4, 3))
	out:SetElement (4, 4, vmatrix:GetField (4, 4))
	
	return out
end

function self:ToMatrix (out)
	return GLib.VMatrix.ToMatrix (self, out)
end

function self:ToString ()
	return self:ToMatrix ():ToString ()
end

local self = debug.getregistry ().Vector

function self:ToColumnVector (out)
	out = out or GLib.ColumnVector (3)
	
	out [1] = self.x
	out [2] = self.y
	out [3] = self.z
	
	return out
end

function self:ToRowVector (out)
	out = out or GLib.RowVector (3)
	
	out [1] = self.x
	out [2] = self.y
	out [3] = self.z
	
	return out
end