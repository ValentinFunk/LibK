local self = {}
GLib.TableFormatter = GLib.MakeConstructor (self)

function self:ctor ()
	self.ColumnWidths = {}
	self.Columns = {}
	
	self.RowCount = 0
end

function self:Append (...)
	local cells = {...}
	
	self.RowCount = self.RowCount + 1
	for k, v in ipairs (cells) do
		self.Columns [k] = self.Columns [k] or {}
		
		v = tostring (v)
		self.Columns [k] [self.RowCount] = v
		
		self.ColumnWidths [k] = math.max (self.ColumnWidths [k] or 0, GLib.UTF8.Length (v))
	end
	
	return self
end

function self:Clear ()
	self.ColumnWidths = {}
	self.Columns = {}
	
	self.RowCount = 0
end

function self:GetColumnCount ()
	return #self.Columns
end

function self:ToString ()
	local table = GLib.StringBuilder ()
	
	local totalWidth = (self:GetColumnCount () - 1) * 3
	for i = 1, self:GetColumnCount () do
		totalWidth = totalWidth + self.ColumnWidths [i]
	end
	
	for i = 1, self.RowCount do
		for j = 1, self:GetColumnCount () do
			local cell = self.Columns [j] [i] or ""
			table:Append (cell)
			table:Append (string.rep (" ", self.ColumnWidths [j] - #cell))
			
			if j < self:GetColumnCount () then
				table:Append (" | ")
			end
		end
		table:Append ("\n")
		
		-- if i < self.RowCount then
		-- 	table:Append (string.rep ("-", totalWidth))
		-- 	table:Append ("\n")
		-- end
	end
	
	return table:ToString ()
end

self.__tostring = self.ToString