local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local SummonIndicator = frame.raised:CreateTexture(nil, 'OVERLAY')
	frame.SummonIndicator = SummonIndicator
end

---@param frame table
local function Update(frame)
	-- local element = frame.SummonIndicator
	-- local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.SummonIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.SummonIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('SummonIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.SummonIndicator
end

---@type ElementSettings
local Settings = {
	config = {
		type = 'Indicator',
		DisplayName = 'Summon',
		NoBulkUpdate = false
	}
}

UF.Elements:Register('SummonIndicator', Build, Update, Options, Settings)
