local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	--Debuff Icons
	local Debuffs = CreateFrame('Frame', frame.unitOnCreate .. 'Debuffs', frame.raised)
	Debuffs.PostUpdateButton = function(self, button, unit, data, position)
		button.data = data
		button.unit = unit
	end
	Debuffs.PostCreateButton = function(self, button)
		UF.Auras:PostCreateButton('Debuffs', button)
	end

	---@param unit UnitId
	---@param data UnitAuraInfo
	local FilterAura = function(element, unit, data)
		return UF.Auras:Filter(element, unit, data, element.DB.rules)
	end
	Debuffs.FilterAura = FilterAura

	frame.Debuffs = Debuffs
end

---@param frame table
local function Update(frame)
	local DB = frame.Debuffs.DB
	if (DB.enabled) then
		frame.Debuffs:Show()
	else
		frame.Debuffs:Hide()
	end

	local Debuffs = frame.Debuffs
	Debuffs.size = DB.size
	Debuffs.initialAnchor = DB.initialAnchor
	Debuffs['growth-x'] = DB.growthx
	Debuffs['growth-y'] = DB.growthy
	Debuffs.spacing = DB.spacing
	Debuffs.showType = DB.showType
	Debuffs.num = DB.number
	Debuffs.onlyShowPlayer = DB.onlyShowPlayer
	Debuffs.PostCreateIcon = UF.Auras.PostCreateAura
	Debuffs.PostUpdateIcon = UF.Auras.PostUpdateAura
	Debuffs:SetPoint(SUI:InverseAnchor(DB.position.anchor), frame, DB.position.anchor, DB.position.x, DB.position.y)
	local w = (DB.number / DB.rows)
	if w < 1.5 then
		w = 1.5
	end
	Debuffs:SetSize((DB.size + DB.spacing) * w, (DB.spacing + DB.size) * DB.rows)
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
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
	initialAnchor = 'BOTTOMRIGHT',
	growthx = 'LEFT',
	growthy = 'UP',
	rows = 2,
	position = {
		anchor = 'TOPRIGHT',
		relativePoint = 'BOTTOMRIGHT',
		y = -10
	},
	rules = {
		duration = {
			enabled = true,
			maxTime = 180,
			minTime = 1
		},
		isBossAura = true,
		isFromPlayerOrPlayerPet = true
	},
	config = {
		type = 'Auras'
	}
}
UF.Elements:Register('Debuffs', Build, Update, Options, Settings)
