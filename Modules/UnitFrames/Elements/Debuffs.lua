local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	--Debuff Icons
	local Debuffs = CreateFrame('Frame', frame.unitOnCreate .. 'Debuffs', frame)
	Debuffs.PostCreateButton = function(self, button)
		UF.Auras:PostCreateButton('Debuffs', button)
	end

	---@param unit UnitId
	local CustomFilter = function(
		element,
		unit,
		button,
		name,
		icon,
		count,
		debuffType,
		duration,
		expiration,
		source,
		isStealable,
		nameplateShowPersonal,
		spellID,
		canApplyAura,
		isBossDebuff,
		castByPlayer,
		nameplateShowAll,
		modRate,
		effect1,
		effect2,
		effect3)
		---@type UnitAuraInfo
		local data = {
			spellId = spellID,
			name = name,
			icon = icon,
			count = count,
			duration = duration,
			isBossAura = isBossDebuff,
			isPlayer = castByPlayer,
			nameplateShowAll = nameplateShowAll,
			expirationTime = expiration,
			debuffType = debuffType,
			isStealable = isStealable,
			canApplyAura = canApplyAura,
			sourceUnit = source
		}
		return UF.Auras:Filter(element, unit, data, element.DB.rules)
	end
	Debuffs.CustomFilter = CustomFilter

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
	Debuffs.size = DB.auraSize
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
	Debuffs:SetSize((DB.auraSize + DB.spacing) * w, (DB.spacing + DB.auraSize) * DB.rows)
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
	auraSize = 20,
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
