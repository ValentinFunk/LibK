function GLib.String.DumpHex (str, bytesPerLine)
	bytesPerLine = bytesPerLine or 16
	
	local lines = {}
	local i = 1
	
	while i <= #str do
		local line = string.sub (str, i, i + bytesPerLine - 1)
		local left = ""
		local right = ""
		
		for j = 1, #line do
			local char = string.byte (line, j)
			left  = left .. string.format ("%02x ", char)
			
			if char >= 32 and char < 127 then
				right = right .. string.sub (line, j, j)
			else
				right = right .. "."
			end
		end
		
		if #left < 3 * bytesPerLine then
		    left = left .. string.rep (" ", 3 * bytesPerLine - #left)
		end
		
		lines [#lines + 1] = left .. "| " .. right
		
	    i = i + bytesPerLine
	end
	
	return table.concat (lines, "\n")
end

function GLib.String.GetLines (str)
	return GLib.String.Split (str, "\n")
end

function GLib.String.LineIterator (str)
	return GLib.String.SplitIterator (str, "\n")
end

function GLib.String.Split (str, separator)
	if #separator == 0 then
		return GLib.String.ToCharArray (str)
	end
	
	local parts = {}
	local stringLength = #str
	local separatorLength = #separator
	local lastSeparatorEndPos = 1
	
	while lastSeparatorEndPos <= stringLength do
		local nextSeparatorStartPos = string.find (str, separator, lastSeparatorEndPos, true)
		if not nextSeparatorStartPos then break end
		
		parts [#parts + 1] = string.sub (str, lastSeparatorEndPos, nextSeparatorStartPos - 1)
		lastSeparatorEndPos = nextSeparatorStartPos + separatorLength
	end
	parts [#parts + 1] = string.sub (str, lastSeparatorEndPos)
	
	return parts
end

function GLib.String.SplitIterator (str, separator)
	if #separator == 0 then
		return GLib.UTF8.Iterator (str)
	end
	
	local stringLength = #str
	local separatorLength = #separator
	local lastSeparatorEndPos = 1
	
	return function ()
		if lastSeparatorEndPos > stringLength + 1 then return nil end
		
		local nextSeparatorStartPos = string.find (str, separator, lastSeparatorEndPos, true)
		local ret
		if nextSeparatorStartPos then
			ret = string.sub (str, lastSeparatorEndPos, nextSeparatorStartPos - 1)
			lastSeparatorEndPos = nextSeparatorStartPos + separatorLength
		else
			ret = string.sub (str, lastSeparatorEndPos)
			lastSeparatorEndPos = stringLength + 2
		end
		
		return ret
	end
end

function GLib.String.ToCharArray (str)
	local chars = {}
	for c in GLib.UTF8.Iterator (str) do
		chars [#chars + 1] = c
	end
	return chars
end