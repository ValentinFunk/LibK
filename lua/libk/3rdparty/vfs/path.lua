local self = {}
VFS.Path = VFS.MakeConstructor (self)

function self:ctor (path)
	path = path or ""
	
	if type (path) == "table" then
		self.Path = path.Path
		self.Segments = table.Copy (path.Segments)
	elseif type (path) == "string" then
		path = path:gsub ("\\", "/")
		path = path:gsub ("//+", "/")
		if path:sub (1, 1) == "/" then path = path:sub (2) end
		if path:sub (-1, -1) == "/" then path = path:sub (1, -2) end
		
		self.Path = path
		local needsReformatting = false
		self.Segments = {}
		if self.Path ~= "" then
			for _, segment in ipairs (self.Path:Split ("/")) do
				if segment == "." then
					needsReformatting = true
				elseif segment == ".." then
					if #self.Segments == 0 then
						self.Segments [#self.Segments + 1] = segment
					else
						needsReformatting = true
						self.Segments [#self.Segments] = nil
					end
				else
					self.Segments [#self.Segments + 1] = segment
				end
			end
		end
		
		if needsReformatting then
			self.Path = table.concat (self.Segments, "/")
		end
	else
		VFS.Error ("Path:ctor : Invalid argument (" .. type (path) .. ") passed to constructor!")
	end
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Segments [i]
	end
end

function self:GetPath ()
	return self.Path
end

function self:GetSegment (index)
	return self.Segments [index + 1]
end

function self:GetSegmentCount ()
	return #self.Segments
end

function self:IsEmpty ()
	return self:GetSegmentCount () == 0
end

function self:RemoveFirstSegment ()
	if self:IsEmpty () then return end
	
	local i = 1
	local segment = self.Segments [1]
	self.Path = self.Path:sub (segment:len () + 2)
	while self.Segments [i] do
		self.Segments [i] = self.Segments [i + 1]
		i = i + 1
	end
end

function self:ToString ()
	return self.Path
end