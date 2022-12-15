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
	--Buff Icons
	local element = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame.raised)
	element.PostUpdateButton = function(self, button, unit, data, position)
		button.data = data
		button.unit = unit
	end
	element.PostCreateButton = function(self, button)
		UF.Auras:PostCreateButton('Buffs', button)
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
	frame.Buffs = element
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.Buffs
	local DB = settings or element.DB

	if DB.enabled then
		element:Show()
	else
		element:Hide()
	end

	updateSettings(element)
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.Buffs[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Buffs[option] = val
		--Update the screen
		UF.Unit[unitName]:ElementUpdate('Buffs')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Buffs
end

---@type SUI.UF.Elements.Settings
local Settings = {
	number = 10,
	size = 20,
	spacing = 1,
	showType = true,
	width = false,
	growthx = 'RIGHT',
	growthy = 'DOWN',
	rows = 2,
	position = {
		anchor = 'TOPLEFT',
		relativePoint = 'BOTTOMLEFT',
	},
	config = {
		type = 'Auras',
	},
	rules = {
		duration = {
			enabled = true,
			maxTime = 180,
			minTime = 1,
		},
		isBossAura = true,
		showPlayers = true,
	},
}
UF.Elements:Register('Buffs', Build, Update, Options, Settings)
