local PANEL = {}

function PANEL:Init ()
	self.Model = nil
	self:SetAutocompleter (function (text)
		text = text:gsub ("%[", "%[")
		text = text:gsub ("%]", "%]")
		text = text:gsub ("%(", "%)")
		text = text:gsub ("%(", "%)")
		text = text:gsub ("%%", "%%")
		text = text:gsub ("%.", "%.")
		text = text:gsub ("%+", "%+")
		text = text:gsub ("%?", "%?")
		text = text:gsub ("%^", "%^")
		text = text:gsub ("%$", "%$")
		text = text:gsub ("*", ".*")
		
		local basedir = string.GetPathFromFilename (text)
		local results = {}
		local subresults
		
		-- files
		subresults = file.Find ("models/" .. text .. "*.mdl", "GAME")
		for _, v in ipairs (subresults) do
			results [#results + 1] = basedir .. v
		end
		
		-- folders
		subresults = file.FindDir ("models/" .. text .. "*", "GAME")
		for _, v in ipairs (subresults) do
			results [#results + 1] = basedir .. v
		end
		
		if text ~= "" and text:sub (-1) ~= "/" and text:sub (-1) ~= "\\" and file.IsDir ("models/" .. text, "GAME") then			
			subresults = file.Find ("models/" .. text .. "/*.mdl", "GAME")
			for _, v in ipairs (subresults) do
				results [#results + 1] = text .. "/" .. v
			end
			
			subresults = file.FindDir ("models/" .. text .. "/*", "GAME")
			for _, v in ipairs (subresults) do
				results [#results + 1] = text .. "/" .. v
			end
		end
		table.sort (results)
		return results
	end)
	self:AddEventListener ("TextChanged", function (multiChoice, text)
		if file.Exists ("models/" .. text, "GAME") and text:lower ():sub (-4) == ".mdl" then
			self:SetModel (text)
		end
	end)
end

function PANEL:GetModel ()
	return self.Model
end

function PANEL:SetModel (model)
	if self.Model == model then
		return
	end
	self.Model = model
	self:DispatchEvent ("ModelChanged", model)
end

Gooey.Register ("GModelChoice", PANEL, "GMultiChoiceX")