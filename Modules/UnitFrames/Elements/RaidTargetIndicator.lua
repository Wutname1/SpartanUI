local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidTargetIndicator = frame:CreateTexture(nil, 'ARTWORK')
end

---@param frame table
local function Update(frame)
	local element = frame.RaidTargetIndicator
	local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.RaidTargetIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.RaidTargetIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('RaidTargetIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.RaidTargetIndicator
end

---@type ElementSettings
local Settings = {
	enabled = true,
	size = 20,
	position = {
		anchor = 'BOTTOMRIGHT',
		relativePoint = 'CENTER',
		x = 0,
		y = 0
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Raid Target Icon'
	}
}

UF.Elements:Register('RaidTargetIndicator', Build, Update, Options, Settings)
