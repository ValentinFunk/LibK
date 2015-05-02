local self = {}
GLib.DurationParser = GLib.MakeConstructor (self, GLib.StringParser)

local string_lower = string.lower

function GLib.DurationParser.Parse (str)
	local parser = GLib.DurationParser (str)
	local duration, success = parser:Parse (str)
	
	if success then
		return duration, success
	else
		return duration, success, parser:GetPosition ()
	end
end

function self:Parse ()
	self:AcceptWhitespace ()
	
	if self:AcceptLiteralCaseInsensitive ("forever") or
	   self:AcceptLiteralCaseInsensitive ("permanent") or
	   self:AcceptLiteralCaseInsensitive ("permanently") then
		self:AcceptWhitespace ()
		return math.huge, self:IsEndOfInput ()
	end
	
	local t = self:DurationPart ()
	if not t then return 0, false end
	
	while true do
		--  ?, ?
		--  ?, ?and 
		--      and 
		local separatorFound = false
		local expectingPart  = false
		separatorFound = separatorFound or self:AcceptWhitespace ()
		expectingPart  = expectingPart  or self:AcceptLiteral (",")
		separatorFound = separatorFound or self:AcceptWhitespace ()
		if self:AcceptLiteralCaseInsensitive ("and") then
			if not self:AcceptWhitespace () then
				return t, false
			end
			
			expectingPart = true
		end
		separatorFound = separatorFound or expectingPart
		
		if not separatorFound and
		   not self:PeekPattern ("[0-9%.]") then
			break
		end
		
		local dt = self:DurationPart ()
		if not dt then
			if expectingPart then return t, false end
			break
		end
		
		t = t + dt
	end
	
	return t, self:IsEndOfInput ()
end

function self:DurationPart ()
	-- a <singular>
	-- one <singular>
	-- 0 <plural>
	-- 2 <plural>
	
	-- kiloday <si prefix><unit>
	-- kday    <si prefix abbreviation><unit>
	-- day     <unit>
	-- ks      <si prefix abbreviation><si unit abbreviation>
	-- d       <unit abbreviation>
	
	self:SavePosition ()
	
	local count = nil
	if self:AcceptLiteralCaseInsensitive ("an") or
	   self:AcceptLiteralCaseInsensitive ("a") then
		self:AcceptWhitespace ()
		count = 1
	else
		count = self:Number ()
   	end
   	
   	count = count or 1
   	self:AcceptWhitespace ()
	
	-- kiloday <si prefix><unit>
	self:SavePosition ()
	local prefixMultiplier = self:SIPrefix ()
	if prefixMultiplier then
		local duration = self:Period (count == 1)
		if duration then
			self:CommitPosition ()
			self:CommitPosition ()
			return count * prefixMultiplier * duration
		end
	end
	self:RestorePosition ()
	
	-- kday    <si prefix abbreviation><unit>
	self:SavePosition ()
	local prefixMultiplier = self:AbbreviatedSIPrefix ()
	if prefixMultiplier then
		local duration = self:Period (count == 1)
		if duration then
			self:CommitPosition ()
			self:CommitPosition ()
			return count * prefixMultiplier * duration
		end
	end
	self:RestorePosition ()
	
	-- day     <unit>
	local duration = count == 1 and self:SingularPeriod () or self:PluralPeriod ()
	if duration then
		self:CommitPosition ()
		return count * duration
	end
	
	-- ks      <si prefix abbreviation><si unit abbreviation>
	self:SavePosition ()
	local prefixMultiplier = self:AbbreviatedSIPrefix ()
	if prefixMultiplier then
		local duration = self:AbbreviatedSIPeriod ()
		if duration then
			self:CommitPosition ()
			self:CommitPosition ()
			return count * prefixMultiplier * duration
		end
	end
	self:RestorePosition ()
	
	-- d       <unit abbreviation>
	local duration = self:AbbreviatedPeriod ()
	if duration then
		self:CommitPosition ()
		return count * duration
	end
	
	self:RestorePosition ()
end

local siPrefixes =
{
	{ Prefix = "pico",  Abbreviation = "p", Multiplier = 1e-12 },
	{ Prefix = "nano",  Abbreviation = "n", Multiplier = 1e-9  },
	{ Prefix = "micro", Abbreviation = GLib.UTF8.Char (0x03BC), Multiplier = 1e-6 },
	{ Prefix = "micro", Abbreviation = "u", Multiplier = 1e-6  },
	{ Prefix = "milli", Abbreviation = "m", Multiplier = 1e-3  },
	{ Prefix = "kilo",  Abbreviation = "k", Multiplier = 1e3   },
	{ Prefix = "mega",  Abbreviation = "M", Multiplier = 1e6   },
	{ Prefix = "giga",  Abbreviation = "G", Multiplier = 1e9   },
	{ Prefix = "tera",  Abbreviation = "T", Multiplier = 1e12  },
	{ Prefix = "peta",  Abbreviation = "P", Multiplier = 1e15  }
}

function self:SIPrefix ()
	for _, prefixData in ipairs (siPrefixes) do
		if self:AcceptLiteralCaseInsensitive (prefixData.Prefix) then return prefixData.Multiplier end
	end
	
	return nil
end

function self:AbbreviatedSIPrefix ()
	for _, prefixData in ipairs (siPrefixes) do
		if self:AcceptLiteral (prefixData.Abbreviation) then return prefixData.Multiplier end
	end
	
	return nil
end

local timePeriods =
{
	{ Singular = "second",                     Plural = "seconds",                     Duration = 1,                             Abbreviation = "s", IsSIAbbreviation = true },
	{ Singular = "minute",                     Plural = "minutes",                     Duration = 60,                            Abbreviation = "m" },
	{ Singular = "hour",                       Plural = "hours",                       Duration = 60 * 60,                       Abbreviation = "h" },
	{ Singular = "day",                        Plural = "days",                        Duration = 60 * 60 * 24,                  Abbreviation = "d" },
	{ Singular = "week",                       Plural = "weeks",                       Duration = 60 * 60 * 24 * 7               },
	{ Singular = "month",                      Plural = "months",                      Duration = 60 * 60 * 24 * 30              },
	{ Singular = "year",                       Plural = "years",                       Duration = 60 * 60 * 24 * 365,            Abbreviation = "y" },
	{ Singular = "decade",                     Plural = "decades",                     Duration = 60 * 60 * 24 * 365 * 10        },
	{ Singular = "century",                    Plural = "centuries",                   Duration = 60 * 60 * 24 * 365 * 100       },
	{ Singular = "millenium",                  Plural = "millenia",                    Duration = 60 * 60 * 24 * 365 * 1000      },
	{ Singular = "U-235 half-life",            Plural = "U-235 half-lives",            Duration = 60 * 60 * 24 * 365 * 703800000 },
	{ Singular = "U-235 half life",            Plural = "U-235 half lives",            Duration = 60 * 60 * 24 * 365 * 703800000 },
	{ Singular = "heat death of the universe", Plural = "heat deaths of the universe", Duration = math.huge                      }
}

function self:AbbreviatedPeriod ()
	for _, timePeriodData in pairs (timePeriods) do
		if timePeriodData.Abbreviation then
			if self:AcceptLiteral (timePeriodData.Abbreviation) then return timePeriodData.Duration end
		end
	end
	
	return nil
end

function self:AbbreviatedSIPeriod ()
	for _, timePeriodData in pairs (timePeriods) do
		if timePeriodData.Abbreviation and
		   timePeriodData.IsSIAbbreviation then
			if self:AcceptLiteral (timePeriodData.Abbreviation) then return timePeriodData.Duration end
		end
	end
	
	return nil
end

function self:Period (singular)
	if singular then
		return self:SingularPeriod ()
	else
		return self:PluralPeriod ()
	end
end

function self:SingularPeriod ()
	for _, timePeriodData in pairs (timePeriods) do
		if self:AcceptLiteralCaseInsensitive (timePeriodData.Singular) then return timePeriodData.Duration end
	end
	
	return nil
end

function self:PluralPeriod ()
	for _, timePeriodData in pairs (timePeriods) do
		if self:AcceptLiteralCaseInsensitive (timePeriodData.Plural) then return timePeriodData.Duration end
	end
	
	return nil
end

local singleDigitNumbers =
{
	["one"      ] = 1,
	["two"      ] = 2,
	["three"    ] = 3,
	["four"     ] = 4,
	["five"     ] = 5,
	["six"      ] = 6,
	["seven"    ] = 7,
	["eight"    ] = 8,
	["nine"     ] = 9
}

local exceptionNumbers =
{
	["zero"     ] =  0,
	["ten"      ] = 10,
	["eleven"   ] = 11,
	["twelve"   ] = 12,
	["thirteen" ] = 13,
	["fourteen" ] = 14,
	["fifteen"  ] = 15,
	["sixteen"  ] = 16,
	["seventeen"] = 17,
	["eighteen" ] = 18,
	["nineteen" ] = 19
}

local multiplesOfTenNumbers =
{
	["twenty"   ] = 20,
	["thirty"   ] = 30,
	["forty"    ] = 40,
	["fifty"    ] = 50,
	["sixty"    ] = 60,
	["seventy"  ] = 70,
	["eighty"   ] = 80,
	["ninety"   ] = 90
}

function self:Number ()
	local n = self:AcceptPattern ("[0-9]+%.?[0-9]*") or self:AcceptPattern ("[0-9]*%.[0-9]+")
	if n then
		n = tonumber (n)
		return n
	end
	
	local word = self:PeekPattern ("[a-zA-Z]+")
	if not word then return nil end
	word = string_lower (word)
	
	-- one|two|...|nineteen
	-- twenty|thirty|... (one|two|...|nine)?
	
	if singleDigitNumbers [word] then
		n = singleDigitNumbers [word]
		self:AcceptPattern ("[a-zA-Z]+")
	elseif exceptionNumbers [word] then
		n = exceptionNumbers [word]
		self:AcceptPattern ("[a-zA-Z]+")
	elseif multiplesOfTenNumbers [word] then
		n = multiplesOfTenNumbers [word]
		self:AcceptPattern ("[a-zA-Z]+")
		self:AcceptWhitespace ()
		
		word = self:PeekPattern ("[a-zA-Z]+")
		if word then
			word = string_lower (word)
			if singleDigitNumbers [word] then
				n = n + singleDigitNumbers [word]
				self:AcceptPattern ("[a-zA-Z]+")
			end
		end
	end
	
	return n
end