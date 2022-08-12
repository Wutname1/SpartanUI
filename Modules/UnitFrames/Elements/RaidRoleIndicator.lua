local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidRoleIndicator = frame:CreateTexture(nil, 'ARTWORK')
end

---@param frame table
local function Update(frame)
	local element = frame.RaidRoleIndicator
	local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.RaidRoleIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.RaidRoleIndicator[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('RaidRoleIndicator')
	end
	--local DB = UF.CurrentSettings[unitName].elements.RaidRoleIndicator
end

---@type ElementSettings
local Settings = {
	enabled = true,
	size = 20,
	position = {
		anchor = 'TOP',
		x = 20,
		y = -10
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Raid Role',
		Description = 'Raid assignment (main tank or main assist)'
	}
}

UF.Elements:Register('RaidRoleIndicator', Build, Update, Options, Settings)
