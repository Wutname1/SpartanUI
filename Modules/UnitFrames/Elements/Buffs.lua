local UF = SUI.UF

function UF:Aura_OnClick()
	local keyDown = IsShiftKeyDown() and 'SHIFT' or IsAltKeyDown() and 'ALT' or IsControlKeyDown() and 'CTRL'
	if not keyDown then
		return
	end

	if self.data and keyDown then
		if keyDown == 'CTRL' then
			for k, v in pairs(self.data) do
				print(k .. ' = ' .. tostring(v))
			end
		elseif keyDown == 'SHIFT' then
		--TODO: Add a way to add spells to the whitelist or blacklist
		end
	end
end

---@param frame table
---@param DB table
local function Build(frame, DB)
	--Buff Icons
	local Buffs = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame)
	Buffs.PostUpdateButton = function(self, button, unit, data, position)
		button.data = data
	end
	Buffs.PostCreateButton = function(self, button)
		button:SetScript('OnClick', UF.Aura_OnClick)
	end

	---@param unit UnitId
	---@param data UnitAuraInfo
	local FilterAura = function(element, unit, data)
		return UF.Auras:Filter(element, unit, data, element.DB.rules)
	end
	Buffs.FilterAura = FilterAura
	frame.Buffs = Buffs
end

---@param frame table
local function Update(frame)
	local DB = frame.Buffs.DB
	if (DB.enabled) then
		frame.Buffs:Show()
	else
		frame.Buffs:Hide()
	end

	local Buffs = frame.Buffs
	Buffs.size = DB.auraSize
	Buffs.initialAnchor = DB.initialAnchor
	Buffs['growth-x'] = DB.growthx
	Buffs['growth-y'] = DB.growthy
	Buffs.spacing = DB.spacing
	Buffs.showType = DB.showType
	Buffs.num = DB.number
	Buffs.onlyShowPlayer = DB.onlyShowPlayer
	Buffs.PostCreateIcon = UF.Auras.PostCreateAura
	Buffs.PostUpdateIcon = UF.Auras.PostUpdateAura
	Buffs:SetPoint(SUI:InverseAnchor(DB.position.anchor), frame, DB.position.anchor, DB.position.x, DB.position.y)
	local w = (DB.number / DB.rows)
	if w < 1.5 then
		w = 1.5
	end
	Buffs:SetSize((DB.auraSize + DB.spacing) * w, (DB.spacing + DB.auraSize) * DB.rows)
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
	auraSize = 20,
	spacing = 1,
	showType = true,
	width = false,
	initialAnchor = 'BOTTOMLEFT',
	growthx = 'RIGHT',
	growthy = 'DOWN',
	rows = 2,
	position = {
		anchor = 'TOPLEFT',
		relativePoint = 'BOTTOMLEFT',
		y = -10
	},
	config = {
		type = 'Auras'
	},
	rules = {
		duration = {
			enabled = true,
			maxTime = 180,
			minTime = 1
		},
		isBossAura = true,
		showPlayers = true
	}
}
UF.Elements:Register('Buffs', Build, Update, Options, Settings)
