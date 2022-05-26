local UF = SUI.UF
local PostCreateAura = UF.PostCreateAura
local PostUpdateAura = UF.PostUpdateAura
local InverseAnchor = UF.InverseAnchor
-- local AuraFilter = UF.AuraFilter

-- function UF:Construct_AuraBars(bar)
-- 	bar:CreateBackdrop(nil, nil, nil, nil, true)
-- 	bar:SetScript('OnMouseDown', UF.Aura_OnClick)
-- 	bar:Point('LEFT')
-- 	bar:Point('RIGHT')

-- 	bar.spark:SetTexture(E.media.blankTex)
-- 	bar.spark:SetVertexColor(1, 1, 1, 0.4)
-- 	bar.spark:Width(2)

-- 	bar.icon:CreateBackdrop(nil, nil, nil, nil, true)
-- 	bar.icon:ClearAllPoints()
-- 	-- bar.icon:Point('RIGHT', bar, 'LEFT', -self.barSpacing, 0)
-- 	-- bar.icon:SetTexCoord(unpack(E.TexCoords))

-- 	-- UF.statusbars[bar] = true
-- 	-- UF:Update_StatusBar(bar)

-- 	-- UF:Configure_FontString(bar.timeText)
-- 	-- UF:Configure_FontString(bar.nameText)

-- 	UF:AuraBars_UpdateBar(bar)

-- 	bar.nameText:SetJustifyH('LEFT')
-- 	bar.nameText:SetJustifyV('MIDDLE')
-- 	bar.nameText:Point('RIGHT', bar.timeText, 'LEFT', -4, 0)
-- 	bar.nameText:SetWordWrap(false)

-- 	bar.bg = bar:CreateTexture(nil, 'BORDER')
-- 	bar.bg:Show()
-- end

-- function UF:AuraBars_UpdateBar(bar)
-- 	local bars = bar:GetParent()
-- 	bar.db = bars.db

-- 	bar:SetReverseFill(bars.reverseFill)
-- 	bar.spark:ClearAllPoints()
-- 	bar.spark:Point(bars.reverseFill and 'LEFT' or 'RIGHT', bar:GetStatusBarTexture())
-- 	bar.spark:Point('BOTTOM')
-- 	bar.spark:Point('TOP')

-- 	UF:Update_FontString(bar.timeText)
-- 	UF:Update_FontString(bar.nameText)
-- end

---@param frame table
---@param DB table
local function Build(frame, DB)
	local AuraBars = CreateFrame('Frame', '$parent_AuraBars', frame)

	AuraBars.spellTimeFont = SUI:GetFontFace('Player')
	AuraBars.spellNameFont = SUI:GetFontFace('Player')

	local function PostCreateBar()
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
		-- print(frame.unitOnCreate)
		-- print(DB.enabled)
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
		UF.frames[unitName]:ElementUpdate('AuraBars')
	end
	--local DB = UF.CurrentSettings[unitName].elements.AuraBars
end

UF.Elements:Register('AuraBars', Build, Update, Options)
