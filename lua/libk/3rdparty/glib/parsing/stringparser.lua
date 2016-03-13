local self = {}
GLib.StringParser = GLib.MakeConstructor (self)

local string_find  = string.find
local string_lower = string.lower
local string_match = string.match
local string_sub   = string.sub

function self:ctor (str)
	self.Data                    = str
	self.DataLowercase           = string_lower (str)
	self.Position                = 1
	
	self.PositionStack           = {}
	
	self.AnchoredEscapedLiterals = {}
	self.AnchoredPatterns        = {}
end

function self:GetPosition ()
	return self.Position
end

function self:AcceptLiteral (str)
	local startPos, endPos = string_find (self.Data, self.AnchoredEscapedLiterals [str] or self:AnchorAndEscapeLiteral (str), self.Position)
	if not startPos then return nil end
	
	self.Position = endPos + 1
	
	return str
end

function self:AcceptLiteralCaseInsensitive (str)
	str = string_lower (str)
	local startPos, endPos = string_find (self.DataLowercase, self.AnchoredEscapedLiterals [str] or self:AnchorAndEscapeLiteral (str), self.Position)
	if not startPos then return nil end
	
	self.Position = endPos + 1
	
	return string_sub (self.Data, startPos, endPos)
end

function self:AcceptPattern (pattern)
	local match = string_match (self.Data, self.AnchoredPatterns [pattern] or self:AnchorPattern (pattern), self.Position)
	if not match then return nil end
	
	self.Position = self.Position + #match
	
	return match
end

function self:AcceptWhitespace ()
	return self:AcceptPattern ("[ \t\r\n]+")
end

function self:CanAcceptLiteral (str)
	local startPos, endPos = string_find (self.Data, self.AnchoredEscapedLiterals [str] or self:AnchorAndEscapeLiteral (str), self.Position)
	return startPos ~= nil
end

function self:CanAcceptPattern (str)
	local startPos, endPos = string_find (self.Data, self.AnchoredPatterns [pattern] or self:AnchorPattern (pattern), self.Position)
	return startPos ~= nil
end

function self:PeekPattern (pattern)
	local match = string_match (self.Data, self.AnchoredPatterns [pattern] or self:AnchorPattern (pattern), self.Position)
	if not match then return nil end
	
	return match
end

function self:IsEndOfInput ()
	return self.Position > #self.Data
end

function self:AnchorAndEscapeLiteral (str)
	if self.AnchoredEscapedLiterals [str] then return self.AnchoredEscapedLiterals [str] end
	
	local anchoredEscapedLiteral = str
	anchoredEscapedLiteral = string.gsub (anchoredEscapedLiteral, "[%[%]%(%)%.%-%+%%]", "%%%1")
	anchoredEscapedLiteral = "^" .. anchoredEscapedLiteral
	
	self.AnchoredEscapedLiterals [str] = anchoredEscapedLiteral
	
	return self.AnchoredEscapedLiterals [str]
end

function self:AnchorPattern (pattern)
	if self.AnchoredPatterns [pattern] then return self.AnchoredPatterns [pattern] end
	
	self.AnchoredPatterns [pattern] = "^" .. pattern
	
	return self.AnchoredPatterns [pattern]
end

function self:SavePosition ()
	self.PositionStack [#self.PositionStack + 1] = self.Position
end

function self:RestorePosition ()
	self.Position = self.PositionStack [#self.PositionStack]
	self.PositionStack [#self.PositionStack] = nil
end

function self:CommitPosition ()
	self.PositionStack [#self.PositionStack] = nil
end
