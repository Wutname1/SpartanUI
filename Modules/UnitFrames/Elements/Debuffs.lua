local UF = SUI.UF
local PostCreateAura = UF.PostCreateAura
local PostUpdateAura = UF.PostUpdateAura
local InverseAnchor = UF.InverseAnchor

---@param frame table
---@param DB table
local function Build(frame, DB)
	--Debuff Icons
	local Debuffs = CreateFrame('Frame', frame.unitOnCreate .. 'Debuffs', frame)
	-- Debuffs.PostUpdate = PostUpdateAura
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
	Debuffs.PostCreateIcon = PostCreateAura
	Debuffs.PostUpdateIcon = PostUpdateAura
	Debuffs:SetPoint(InverseAnchor(DB.position.anchor), frame, DB.position.anchor, DB.position.x, DB.position.y)
	local w = (DB.number / DB.rows)
	if w < 1.5 then
		w = 1.5
	end
	Debuffs:SetSize((DB.auraSize + DB.spacing) * w, (DB.spacing + DB.auraSize) * DB.rows)

	frame:UpdateAllElements('ForceUpdate')
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

---@type SUI.UnitFrame.Element.Settings
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
		duration = {},
		isPlayerAura = true,
		isBossAura = true
	},
	config = {
		type = 'Auras'
	}
}
UF.Elements:Register('Debuffs', Build, Update, Options, Settings)
