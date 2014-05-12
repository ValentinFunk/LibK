local self = {}
Gooey.SilkiconTextRenderer = Gooey.MakeConstructor (self, Gooey.TextRenderer)

function self:ctor ()
	self.IconScale = 1
end

function self:GetIconScale ()
	return self.IconScale
end

function self:SetIconScale (iconScale)
	iconScale = iconScale or 1
	if self.IconScale == iconScale then return end
	
	self.IconScale = iconScale
	self:InvalidateCache ()
end

function self:RebuildCache (cache)
	if not self:GetFont () then return end
	if not self:GetText () then return end
	
	cache = {}
	cache.Parts = self:ParseText (self:GetText ())
	cache.RenderParts = {}
	
	surface.SetFont (self:GetFont ())
	
	local _, tabHeight = surface.GetTextSize ("WWWW")
	for i = 1, #cache.Parts do
		local part = cache.Parts [i]
		local type = part.Type
		if type == "Text" then
			part.Width, part.Height = surface.GetTextSize (part.Value:gsub ("&", "#"))
		elseif type == "Icon" then
			part.Image = Gooey.ImageCache:GetImage (part.Value)
			part.Width  = part.Image:GetWidth ()  * self.IconScale
			part.Height = part.Image:GetHeight () * self.IconScale
		elseif type == "Newline" then
			part.Width  = 0
			part.Height = 0
		elseif type == "Tab" then
			part.Width = 0
			part.Height = tabHeight
		end
	end
	
	local w = self:PerformWordWrap (cache)
	self:SetWidth (w)
	
	local lineHeight = self:CalculateLineHeight (cache.RenderParts, 1, #cache.RenderParts)
	lineHeight = math.max (lineHeight, 16)
	self:VerticalAlignParts (cache.RenderParts, 1, #cache.RenderParts, lineHeight)
	
	self:SetHeight (#cache.RenderParts > 0 and (cache.RenderParts [#cache.RenderParts].Y + lineHeight) or lineHeight)
	
	return cache
end

function self:RenderFromCache (renderContext, x, y, textColor, cache)
	if not cache then return end
	
	surface.SetFont (self:GetFont ())
	surface.SetTextColor (textColor)
	for i = 1, #cache.RenderParts do
		local part  = cache.RenderParts [i]
		local type  = part.Type
		local value = part.Value
		if type == "Text" then
			surface.SetTextPos (x + part.X, y + part.Y)
			surface.DrawText (part.Value)
		elseif type == "Icon" then
			local image = Gooey.ImageCache:GetImage (part.Value)
			local w = image:GetWidth ()  * self.IconScale
			local h = image:GetHeight () * self.IconScale
			render.PushFilterMin (TEXFILTER.POINT)
			render.PushFilterMag (TEXFILTER.POINT)
			image:DrawEx (renderContext, x + part.X, y + part.Y, w, h, 255, 255, 255, textColor.a)
			render.PopFilterMin ()
			render.PopFilterMag ()
		end
	end
end

-- Internal, do not call
function self:ParseText (text)
	local parts = {}
	
	local text = self:GetText ()
	local spanStart = 1
	local currentOffset = 1
	while currentOffset < #text do
		local character = string.sub (text, currentOffset, currentOffset)
		if character == "\r" or character == "\n" or character == "\t" then
			-- Commit last span
			local spanText = text:sub (spanStart, currentOffset - 1)
			if spanText ~= "" then
				parts [#parts + 1] =
				{
					Type  = "Text",
					Value = spanText
				}
			end
			
			-- Normalize line breaks
			if character == "\r" and string.sub (text, currentOffset + 1, currentOffset + 1) == "\n" then
				currentOffset = currentOffset + 1
				character = "\n"
			end
			
			parts [#parts + 1] =
			{
				Type  = character == "\n" and "Newline" or "Tab",
				Value = character
			}
			spanStart = currentOffset + 1
			currentOffset = currentOffset + 1
		elseif character == ":" then
			-- Check if this is a valid icon
			local match = text:match ("^:([a-zA-Z0-9_]+):", currentOffset)
			local matchLength = match and #match or 0
			if match then
				match = match:lower ()
				if match == "gaybow" then match = "rainbow"
				elseif match == "gay" then match = "rainbow" end
				if not file.Exists ("materials/icon16/" .. match .. ".png", "GAME") then
					match = nil
				end
			end
			
			if match then
				-- Commit last span
				local spanText = text:sub (spanStart, currentOffset - 1)
				if spanText ~= "" then
					parts [#parts + 1] =
					{
						Type  = "Text",
						Value = spanText
					}
				end
				parts [#parts + 1] =
				{
					Type  = "Icon",
					Value = "icon16/" .. match .. ".png"
				}
				
				currentOffset = currentOffset + matchLength + 2
				spanStart = currentOffset
			elseif not match then
				-- Nope, not an icon
				currentOffset = text:find ("[:\n\t]", currentOffset + 1) or (#text + 1)
			end
		else
			currentOffset = text:find ("[:\n\t]", currentOffset) or (#text + 1)
		end
	end
	
	-- Commit last span
	if spanStart <= #text then
		parts [#parts + 1] =
		{
			Type  = "Text",
			Value = string.sub (text, spanStart)
		}
	end
	
	return parts
end

function self:CalculateLineHeight (partArray, startIndex, endIndex)
	local lineHeight = 0
	for i = startIndex, endIndex do
		if partArray [i].Height > lineHeight then
			lineHeight = partArray [i].Height
		end
	end
	return lineHeight
end

function self:PerformWordWrap (cache)
	local wordWrapWidth = self:GetWordWrap () and self:GetWordWrapWidth () or math.huge
	
	local x = 0
	local w = 0
	local line = 0
	local previousType = nil
	
	local tabWidth, tabHeight = surface.GetTextSize ("WWWW")
	
	for i = 1, #cache.Parts do
		local part = cache.Parts [i]
		local type = part.Type
		
		part.X = x
		part.Line = line
		
		cache.RenderParts [#cache.RenderParts + 1] = part
		if type == "Text" then
			if previousType == "Icon" then
				x = x + 2
				part.X = x
			end
			if x + part.Width > wordWrapWidth then
				cache.RenderParts [#cache.RenderParts] = nil
				
				local words = ""
				local wordsWidth = 0
				for word, wordType in GLib.UTF8.WordIterator (part.Value) do
					local wordWidth = surface.GetTextSize (word:gsub ("&", "#"))
					
					if x + wordsWidth + wordWidth > wordWrapWidth and wordType ~= GLib.WordType.Whitespace then
						-- Addition of this word will overflow the line
						
						if wordWidth > wordWrapWidth then
							-- Word is wider than the maximum allowable width
							-- Do a character wrap
							for c in GLib.UTF8.Iterator (word) do
								-- Note: c could be a combining character
								local newWords = words .. c
								local newWordsWidth = surface.GetTextSize (newWords:gsub ("&", "#"))
								
								if x + newWordsWidth > wordWrapWidth then
									-- Commit
									local newPart = {}
									newPart.X = x
									newPart.Line = line
									newPart.Width = wordsWidth
									newPart.Height = part.Height
									newPart.Type = "Text"
									newPart.Value = words
									cache.RenderParts [#cache.RenderParts + 1] = newPart
									
									w = math.max (w, x + wordsWidth)
									
									x = 0
									line = line + 1
									
									words = c
									wordsWidth = surface.GetTextSize (c:gsub ("&", "#"))
								else
									words = newWords
									wordsWidth = newWordsWidth
								end
							end
						else
							-- The word fits on the next line
							-- Commit the current word span
							local newPart = {}
							newPart.X = x
							newPart.Line = line
							newPart.Width = wordsWidth
							newPart.Height = part.Height
							newPart.Type = "Text"
							newPart.Value = words
							cache.RenderParts [#cache.RenderParts + 1] = newPart
							
							w = math.max (w, x + wordsWidth)
							
							x = 0
							line = line + 1
							
							words = word
							wordsWidth = wordWidth
						end
					else
						-- Addition of this word will not overflow the line
						words = words .. word
						wordsWidth = wordsWidth + wordWidth
					end
				end
				
				if words ~= "" then
					-- Commit
					local newPart = {}
					newPart.X = x
					newPart.Line = line
					newPart.Width = wordsWidth
					newPart.Height = part.Height
					newPart.Type = "Text"
					newPart.Value = words
					cache.RenderParts [#cache.RenderParts + 1] = newPart
					x = x + wordsWidth
				end
			else
				x = x + part.Width
			end
		elseif type == "Icon" then
			if previousType == "Text" then
				x = x + 2
				part.X = x
			end
			if previousType and x + part.Width > wordWrapWidth then
				x = 0
				line = line + 1
				part.X = x
				part.Line = line
			end
			x = x + part.Width
		elseif type == "Newline" then
			x = 0
			line = line + 1
			previousType = nil
		elseif type == "Tab" then
			part.Width = tabWidth - x % tabWidth
			x = x + part.Width
		end
		
		w = math.max (w, x)
		
		previousType = type
	end
	
	return w
end

function self:VerticalAlignParts (partArray, startIndex, endIndex, lineHeight)
	for i = startIndex, endIndex do
		partArray [i].Y = partArray [i].Line * lineHeight + lineHeight * 0.5 - partArray [i].Height * 0.5
	end
end