local UF = SUI.UF

---@param element any
---@param unit? UnitId
---@param isFullUpdate? boolean
local function updateSettings(element, unit, isFullUpdate)
	local DB = element.DB
	element.size = DB.size or 20
	element.initialAnchor = DB.position.anchor
	element['growth-x'] = DB.growthx
	element['growth-y'] = DB.growthy
	-- Buffs.spacing = DB.spacing
	element.showType = DB.showType
	element.num = DB.number or 10
	element.onlyShowPlayer = DB.onlyShowPlayer
end

---@param element any
local function SizeChange(element)
	local DB = element.DB
	local w = (DB.number / DB.rows)
	if w < 1.5 then w = 1.5 end
	element:SetSize((DB.size + DB.spacing) * w, (DB.spacing + DB.size) * DB.rows)
end

---@param frame table
---@param DB table
local function Build(frame, DB)
	--Debuff Icons
	local element = CreateFrame('Frame', frame.unitOnCreate .. 'Debuffs', frame.raised)
	element.PostUpdateButton = function(self, button, unit, data, position)
		button.data = data
		button.unit = unit
	end
	element.PostCreateButton = function(self, button)
		UF.Auras:PostCreateButton('Debuffs', button)
	end

	---@param unit UnitId
	---@param data UnitAuraInfo
	local FilterAura = function(element, unit, data)
		return UF.Auras:Filter(element, unit, data, element.DB.rules)
	end
	local PreUpdate = function(self)
		updateSettings(element)
	end

	element.displayReasons = {}
	element.FilterAura = FilterAura
	element.PreUpdate = PreUpdate
	element.SizeChange = SizeChange

	frame.Debuffs = element
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.Debuffs
	local DB = settings or element.DB

	if DB.enabled then
		element:Show()
	else
		element:Hide()
	end

	updateSettings(element)
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.Debuffs[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Debuffs[option] = val
		--Update the screen
		UF.Unit[unitName]:ElementUpdate('Debuffs')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Debuffs
end

---@type SUI.UF.Elements.Settings
local Settings = {
	number = 10,
	size = 20,
	spacing = 1,
	width = false,
	ShowBoss = true,
	showType = true,
	growthx = 'LEFT',
	growthy = 'UP',
	rows = 2,
	position = {
		anchor = 'TOPRIGHT',
		relativePoint = 'BOTTOMRIGHT',
	},
	rules = {
		duration = {
			enabled = true,
			maxTime = 180,
			minTime = 1,
		},
		isBossAura = true,
	},
	config = {
		type = 'Auras',
	},
}
UF.Elements:Register('Debuffs', Build, Update, Options, Settings)
