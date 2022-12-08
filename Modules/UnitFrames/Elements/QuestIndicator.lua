local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local element = frame.raised:CreateTexture(nil, 'OVERLAY')
	element:SetAtlas('SmallQuestBang')

	frame.QuestIndicator = element
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.QuestIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.QuestIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('QuestIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.QuestIndicator
end

---@type SUI.UF.Elements.Settings
local Settings = {
	position = {
		anchor = 'RIGHT'
	},
	config = {
		DisplayName = 'Quest',
		type = 'Indicator'
	}
}

UF.Elements:Register('QuestIndicator', Build, nil, Options, Settings)
