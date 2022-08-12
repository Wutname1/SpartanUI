local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.QuestMobIndicator = frame:CreateTexture(nil, 'OVERLAY')
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.QuestMobIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.QuestMobIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('QuestMobIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.QuestMobIndicator
end

---@type ElementSettings
local Settings = {
	position = {
		anchor = 'RIGHT'
	},
	config = {
		DisplayName = 'Quest',
		type = 'Indicator'
	}
}

UF.Elements:Register('QuestMobIndicator', Build, nil, Options, Settings)
