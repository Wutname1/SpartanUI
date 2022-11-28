local UF = SUI.UF
-- local AuraFilter = UF.AuraFilter

-- function UF:AuraBars_UpdateBar(bar)
-- 	local bars = bar:GetParent()
-- 	bar.db = bars.db

-- 	bar:SetReverseFill(bars.reverseFill)
-- 	bar.spark:ClearAllPoints()
-- 	bar.spark:Point(bars.reverseFill and 'LEFT' or 'RIGHT', bar:GetStatusBarTexture())
-- 	bar.spark:Point('BOTTOM')
-- 	bar.spark:Point('TOP')

-- 	AuraBars.spellTimeFont = SUI.Font:GetFontFace('Player')
-- 	AuraBars.spellNameFont = SUI.Font:GetFontFace('Player')
-- 	UF:Update_FontString(bar.timeText)
-- 	UF:Update_FontString(bar.nameText)
-- end

---@param frame table
---@param DB table
local function Build(frame, DB)
	local AuraBars = CreateFrame('Frame', '$parent_AuraBars', frame)

	AuraBars.spellTimeFont = SUI.Font:GetFont('Player')
	AuraBars.spellNameFont = SUI.Font:GetFont('Player')
	AuraBars.PostCreateButton = function(self, button)
		UF.Auras:PostCreateButton('Buffs', button)
	end

	---@param unit UnitId
	---@param data UnitAuraInfo
	local FilterAura = function(element, unit, data)
		return UF.Auras:Filter(element, unit, data, element.DB.rules)
	end
	AuraBars.FilterAura = FilterAura

	local function PostCreateBar(_, bar)
		bar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))

		bar.spark:SetTexture(UF:FindStatusBarTexture(DB.texture))
		bar.spark:SetVertexColor(1, 1, 1, 0.4)
		bar.spark:SetSize(2, DB.size)

		bar.bg = bar:CreateTexture(nil, 'BORDER')
		bar.bg:SetAllPoints(bar)
		bar.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
		bar.bg:SetVertexColor(0, 0, 0, 0.4)
		bar.bg:Show()
	end
	AuraBars.PostCreateBar = PostCreateBar
	AuraBars.CustomFilter = function(
		element,
		unit,
		bar,
		name,
		texture,
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
		local data = {}
		if (source == 'player' or source == 'vehicle' or isBossDebuff) and duration ~= 0 and duration <= 900 then
			return true
		end
	end

	AuraBars.initialAnchor = 'BOTTOMRIGHT'

	frame.AuraBars = AuraBars
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.AuraBars
	if not frame.AuraBars then
		return
	end
	local DB = settings or element.DB

	if (DB.enabled) then
		element:Show()
	else
		element:Hide()
	end

	element.anchoredBars = DB.anchoredBars or 0
	element.width = (DB.width or frame:GetWidth()) - DB.size
	element.size = DB.size or 14
	element.sparkEnabled = DB.sparkEnabled or true
	element.spacing = DB.spacing or 2
	element.initialAnchor = DB.initialAnchor or 'BOTTOMLEFT'
	element.growth = DB.growth or 'UP'
	element.maxBars = DB.maxBars or 32
	element.barSpacing = DB.barSpacing or 2
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.AuraBars[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.AuraBars[option] = val
		--Update the screen
		UF.Unit[unitName]:ElementUpdate('AuraBars')
	end
	--local DB = UF.CurrentSettings[unitName].elements.AuraBars

	OptionSet.args.Layout = {
		name = '',
		type = 'group',
		order = 100,
		inline = true,
		args = {}
	}
end

---@type SUI.UF.Elements.Settings
local Settings = {
	size = 14,
	width = false,
	sparkEnabled = true,
	spacing = 2,
	initialAnchor = 'BOTTOMLEFT',
	growth = 'UP',
	maxBars = 32,
	fgalpha = 1,
	bgalpha = 1,
	spellNameSize = 10,
	spellTimeSize = 10,
	gap = 1,
	scaleTime = false,
	icon = true,
	position = {
		anchor = 'BOTTOMLEFT',
		relativePoint = 'TOPLEFT',
		x = 7,
		y = 20
	},
	rules = {
		showPlayers = true
	},
	config = {
		type = 'Auras',
		DisplayName = 'Aura Bars'
	}
}

UF.Elements:Register('AuraBars', Build, Update, Options, Settings)
