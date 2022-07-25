local UF = SUI.UF
local PostCreateAura = UF.PostCreateAura
local PostUpdateAura = UF.PostUpdateAura
local InverseAnchor = UF.InverseAnchor
-- local AuraFilter = UF.AuraFilter

-- function UF:AuraBars_UpdateBar(bar)
-- 	local bars = bar:GetParent()
-- 	bar.db = bars.db

-- 	bar:SetReverseFill(bars.reverseFill)
-- 	bar.spark:ClearAllPoints()
-- 	bar.spark:Point(bars.reverseFill and 'LEFT' or 'RIGHT', bar:GetStatusBarTexture())
-- 	bar.spark:Point('BOTTOM')
-- 	bar.spark:Point('TOP')

-- 	AuraBars.spellTimeFont = SUI:GetFontFace('Player')
-- 	AuraBars.spellNameFont = SUI:GetFontFace('Player')
-- 	UF:Update_FontString(bar.timeText)
-- 	UF:Update_FontString(bar.nameText)
-- end

---@param frame table
---@param DB table
local function Build(frame, DB)
	local AuraBars = CreateFrame('Frame', '$parent_AuraBars', frame)

	AuraBars.spellTimeFont = SUI:GetFontFace('Player')
	AuraBars.spellNameFont = SUI:GetFontFace('Player')

	local function PostCreateBar(_, bar)
		bar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))

		bar.spark:SetTexture(UF:FindStatusBarTexture(DB.texture))
		bar.spark:SetVertexColor(1, 1, 1, 0.4)
		bar.spark:SetSize(2, DB.height)

		bar.bg = bar:CreateTexture(nil, 'BORDER')
		bar.bg:SetAllPoints(bar)
		bar.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
		bar.bg:SetVertexColor(0, 0, 0, 0.4)
		bar.bg:Show()
	end

	-- AuraBars.PreSetPosition = SortAuras
	AuraBars.PostCreateBar = PostCreateBar
	-- AuraBars.PostUpdateBar = PostUpdateBar_AuraBars
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
		if (source == 'player' or source == 'vehicle' or isBossDebuff) and duration ~= 0 and duration <= 900 then
			return true
		end
	end

	AuraBars.initialAnchor = 'BOTTOMRIGHT'

	frame.AuraBars = AuraBars
end

---@param frame table
local function Update(frame)
	if not frame.AuraBars then
		return
	end

	local AuraBars = frame.AuraBars
	local DB = frame.AuraBars.DB
	if DB.enabled then
		AuraBars.anchoredBars = DB.anchoredBars or 0
		AuraBars.width = (DB.width or frame:GetWidth()) - DB.height
		AuraBars.height = DB.height or 12
		AuraBars.sparkEnabled = DB.sparkEnabled or true
		AuraBars.spacing = DB.spacing or 2
		AuraBars.initialAnchor = DB.initialAnchor or 'BOTTOMLEFT'
		AuraBars.growth = DB.growth or 'UP'
		AuraBars.maxBars = DB.maxBars or 32
		AuraBars.barSpacing = DB.barSpacing or 2
	else
		frame:DisableElement('AuraBars')
		AuraBars:Hide()
	end
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
end

---@type ElementSettings
local Settings = {
	height = 14,
	width = false,
	sparkEnabled = true,
	spacing = 2,
	initialAnchor = 'BOTTOMLEFT',
	growth = 'UP',
	maxBars = 32,
	texture = nil,
	fgalpha = 1,
	bgalpha = 1,
	spellNameSize = 10,
	spellTimeSize = 10,
	gap = 1,
	scaleTime = false,
	icon = true,
	position = {
		anchor = 'BOTTOM',
		relativePoint = 'TOP',
		x = 7,
		y = 20
	},
	filters = {
		showPlayers = true
	},
	config = {
		type = 'Auras'
	}
}

UF.Elements:Register('AuraBars', Build, Update, Options, Settings)
