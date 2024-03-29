local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidTargetIndicator = frame.raised:CreateTexture(nil, 'BORDER')
end

---@param frame table
local function Update(frame)
	local element = frame.RaidTargetIndicator
	local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
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

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 20,
	position = {
		anchor = 'LEFT',
		relativePoint = 'LEFT',
		x = 0,
		y = 0,
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Raid Target Icon',
	},
}

UF.Elements:Register('RaidTargetIndicator', Build, Update, Options, Settings)
