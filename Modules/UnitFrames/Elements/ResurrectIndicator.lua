local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local ResurrectIndicator = frame:CreateTexture(nil, 'OVERLAY')
	frame.ResurrectIndicator = ResurrectIndicator
end

---@param frame table
local function Update(frame)
	local element = frame.ResurrectIndicator
	local DB = element.DB
	element:SetSize(DB.size, DB.size)
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.ResurrectIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.ResurrectIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('ResurrectIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.ResurrectIndicator
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 20,
	config = {
		type = 'Indicator',
		DisplayName = 'Resurrect',
	},
}

UF.Elements:Register('ResurrectIndicator', Build, Update, Options, Settings)
