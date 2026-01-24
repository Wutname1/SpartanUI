local _G, SUI, L, LSM = _G, SUI, SUI.L, SUI.Lib.LSM
local module = SUI:NewModule('Tooltips', 'AceHook-3.0') ---@type SUI.Module
module.description = 'SpartanUI tooltip skining'
local unpack = unpack
----------------------------------------------------------------------------------------------------
local targetList = {}
local tooltips = {
	GameTooltip,
	ItemRefTooltip,
	ItemRefShoppingTooltip1,
	ItemRefShoppingTooltip2,
	ItemRefShoppingTooltip3,
	AutoCompleteBox,
	FriendsTooltip,
	ConsolidatedBuffsTooltip,
	ShoppingTooltip1,
	ShoppingTooltip2,
	ShoppingTooltip3,
	WorldMapTooltip,
	WorldMapCompareTooltip1,
	WorldMapCompareTooltip2,
	WorldMapCompareTooltip3,
	DropDownList1MenuBackdrop,
	DropDownList2MenuBackdrop,
	DropDownList3MenuBackdrop,
	BNToastFrame,
	PetBattlePrimaryAbilityTooltip,
	PetBattlePrimaryUnitTooltip,
	BattlePetTooltip,
	FloatingBattlePetTooltip,
	FloatingPetBattleAbilityTooltip,
	FloatingGarrisonFollowerTooltip,
	GarrisonMissionMechanicTooltip,
	GarrisonFollowerTooltip,
	GarrisonMissionMechanicFollowerCounterTooltip,
	GarrisonFollowerAbilityTooltip,
	SmallTextTooltip,
	BrowserSettingsTooltip,
	QueueStatusFrame,
	EventTraceTooltip,
	ItemSocketingDescription,
}
local whitebg = { bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga', tile = false, edgeSize = 3, insets = { left = 0, right = 1, top = 0, bottom = 1 } }
local ilvlTempData = {}

---Check if the modifier key condition is met for spell ID display
---@param setting string The modifier setting ('NONE', 'SHIFT', 'CTRL', 'ALT', 'ALL')
---@return boolean
local function IsModifierConditionMet(setting)
	if setting == 'ALL' then
		return true
	elseif setting == 'NONE' then
		return false
	elseif setting == 'SHIFT' then
		return IsShiftKeyDown()
	elseif setting == 'CTRL' then
		return IsControlKeyDown()
	elseif setting == 'ALT' then
		return IsAltKeyDown()
	end
	return false
end

function module:OnInitialize()
	---@class SUI.Tooltip.Settings
	local defaults = {
		Styles = {
			metal = {
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\metal',
				tile = false,
			},
			smooth = {
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2',
				tile = false,
			},
			smoke = {
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\textures\\smoke',
				tile = false,
			},
			none = {
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
				tile = false,
			},
		},
		Rule1 = {
			Status = 'All',
			Combat = false,
			OverrideLoc = false,
			Anchor = { onMouse = false, Moved = false, AnchorPos = {} },
		},
		Rule2 = {
			Status = 'All',
			Combat = false,
			OverrideLoc = false,
			Anchor = { onMouse = false, Moved = false, AnchorPos = {} },
		},
		Background = 'Blizzard Dialog Background Dark',
		onMouse = false,
		VendorPrices = true,
		Override = {},
		ColorOverlay = true,
		Color = { 0, 0, 0, 0.4 },
		SuppressNoMatch = true,
		SpellID = {
			enabled = false,
			modifierKey = 'NONE',
		},
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Tooltips', { profile = defaults })
	module.DB = module.Database.profile ---@type SUI.Tooltip.Settings
end

local onShow = function(self)
	if not self.SUITip then
		return
	end

	-- Clear tooltip backdrop - SUITip layer provides the background
	if self.SetBackdrop then
		self:SetBackdrop(nil)
	end

	-- Update SUITip background texture
	local bgTexture = LSM:Fetch('background', module.DB.Background)
	if bgTexture and bgTexture ~= '' then
		self.SUITip.bgTexture:SetTexture(bgTexture)
	end

	-- Apply color based on settings
	local r, g, b, a = unpack(module.DB.Color)
	if module.DB.Background == 'none' or module.DB.ColorOverlay then
		-- Color overlay mode: apply user's color at full opacity (the color itself provides darkness)
		self.SUITip.bgTexture:SetVertexColor(r, g, b, 1)
	else
		-- Standard mode: show texture as-is with user's alpha transparency
		self.SUITip.bgTexture:SetVertexColor(1, 1, 1, a)
	end

	self.SUITip:SetFrameLevel(0)
end

local onHide = function(self)
	self.SUITip.border:Hide()
	self.SUITip:ClearColors()
end

local TipCleared = function(self)
	onShow(self)
	self.SUITip:ClearColors()
	self.SUITip.border:Hide()
	self.itemCleared = nil
end

local setPoint = function(self, parent)
	if parent then
		if module.DB.onMouse then
			self:SetOwner(parent, 'ANCHOR_CURSOR')
		end
	end
end

local SetBorderColor = function(self, r, g, b, hasStatusBar)
	self.SUITip.border:Show()
	self.SUITip.border[1]:SetVertexColor(r, g, b, 1)
	self.SUITip.border[2]:SetVertexColor(r, g, b, 1)
	self.SUITip.border[3]:SetVertexColor(r, g, b, 1)
	self.SUITip.border[4]:SetVertexColor(r, g, b, 1)

	if self.NineSlice then
		SUI.Skins.RemoveTextures(self.NineSlice)
	end
end

local ClearColors = function(SUITip)
	SUITip.border[1]:SetVertexColor(0, 0, 0, 0)
	SUITip.border[2]:SetVertexColor(0, 0, 0, 0)
	SUITip.border[3]:SetVertexColor(0, 0, 0, 0)
	SUITip.border[4]:SetVertexColor(0, 0, 0, 0)
end

local function ApplySkin(tooltip)
	if not tooltip.SUITip then
		local SUITip = CreateFrame('Frame', nil, tooltip)
		SUITip:SetAllPoints(tooltip)
		SUITip:SetFrameLevel(0)

		-- Create background texture manually
		SUITip.bgTexture = SUITip:CreateTexture(nil, 'BACKGROUND')
		SUITip.bgTexture:SetAllPoints(SUITip)

		-- Apply background from LSM
		local bgTexture = LSM:Fetch('background', module.DB.Background)
		if bgTexture and bgTexture ~= '' then
			SUITip.bgTexture:SetTexture(bgTexture)
		end

		-- Apply color based on settings
		local r, g, b, a = unpack(module.DB.Color)
		if module.DB.Background == 'none' or module.DB.ColorOverlay then
			-- Color overlay mode: apply user's color at full opacity (the color itself provides darkness)
			SUITip.bgTexture:SetVertexColor(r, g, b, 1)
		else
			-- Standard mode: show texture as-is with user's alpha transparency
			SUITip.bgTexture:SetVertexColor(1, 1, 1, a)
		end

		-- Create border container
		SUITip.border = CreateFrame('Frame', nil, SUITip)
		SUITip.border:SetAllPoints(SUITip)
		SUITip.border:SetFrameLevel(1)

		--TOP
		SUITip.border[1] = SUITip.border:CreateTexture(nil, 'OVERLAY')
		SUITip.border[1]:SetPoint('TOPLEFT', SUITip, 'TOPLEFT')
		SUITip.border[1]:SetPoint('TOPRIGHT', SUITip, 'TOPRIGHT')
		SUITip.border[1]:SetHeight(2)
		SUITip.border[1]:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')
		--BOTTOM
		SUITip.border[2] = SUITip.border:CreateTexture(nil, 'OVERLAY')
		SUITip.border[2]:SetPoint('BOTTOMLEFT', SUITip, 'BOTTOMLEFT')
		SUITip.border[2]:SetPoint('BOTTOMRIGHT', SUITip, 'BOTTOMRIGHT')
		SUITip.border[2]:SetHeight(2)
		SUITip.border[2]:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')
		--RIGHT
		SUITip.border[3] = SUITip.border:CreateTexture(nil, 'OVERLAY')
		SUITip.border[3]:SetPoint('TOPRIGHT', SUITip, 'TOPRIGHT')
		SUITip.border[3]:SetPoint('BOTTOMRIGHT', SUITip, 'BOTTOMRIGHT')
		SUITip.border[3]:SetWidth(2)
		SUITip.border[3]:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')
		--LEFT
		SUITip.border[4] = SUITip.border:CreateTexture(nil, 'OVERLAY')
		SUITip.border[4]:SetPoint('TOPLEFT', SUITip, 'TOPLEFT')
		SUITip.border[4]:SetPoint('BOTTOMLEFT', SUITip, 'BOTTOMLEFT')
		SUITip.border[4]:SetWidth(2)
		SUITip.border[4]:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank.tga')

		SUITip.ClearColors = ClearColors
		SUITip.border:Hide()

		tooltip.SUITip = SUITip
		tooltip.SetBorderColor = SetBorderColor

		-- Hook scripts for show/hide handling
		tooltip:HookScript('OnShow', onShow)
		tooltip:HookScript('OnHide', onHide)
	end

	-- Remove default Blizzard styling
	if tooltip.NineSlice then
		SUI.Skins.RemoveTextures(tooltip.NineSlice)
	end

	-- Clear tooltip backdrop - SUITip layer provides the background
	if tooltip.SetBackdrop then
		tooltip:SetBackdrop(nil)
	end

	tooltip.skined = true
end

local TooltipSetGeneric = function(self, tooltipData)
	if self.NineSlice then
		SUI.Skins.RemoveTextures(self.NineSlice)
	end

	ApplySkin(self)
end

---Enhanced spell tooltip handler with spell ID display
---@param self any The tooltip frame
---@param tooltipData any The tooltip data
local TooltipSetSpell = function(self, tooltipData)
	-- Apply standard skin
	if self.NineSlice then
		SUI.Skins.RemoveTextures(self.NineSlice)
	end
	ApplySkin(self)

	-- Add spell ID if enabled and conditions are met
	if module.DB.SpellID.enabled and tooltipData and tooltipData.id then
		local shouldShowID = IsModifierConditionMet(module.DB.SpellID.modifierKey)

		if shouldShowID then
			-- Use ElvUI-style formatting for consistency
			local IDLine = '|cFFCA3C3C%s:|r %d'
			self:AddLine(string.format(IDLine, 'ID', tooltipData.id))
			self:Show()
		end
	end
end

local TooltipSetItem = function(tooltip, tooltipData)
	local itemLink = nil
	if tooltip.GetItem then
		itemLink = select(2, tooltip:GetItem())
	elseif tooltipData and tooltipData.guid and C_Item and C_Item.GetItemLinkByGUID then
		itemLink = C_Item.GetItemLinkByGUID(tooltipData.guid)
	else
		return
	end

	if itemLink then
		local quality = select(3, C_Item.GetItemInfo(itemLink))

		-- Update SUITip background texture for special item types
		if tooltip.SUITip and tooltip.SUITip.bgTexture then
			local bgTexture = 'Interface/Tooltips/UI-Tooltip-Background'

			if C_AzeriteEmpoweredItem and C_AzeriteItem and (C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemLink) or C_AzeriteItem.IsAzeriteItemByID(itemLink)) then
				bgTexture = 'Interface/Tooltips/UI-Tooltip-Background-Azerite'
			end

			tooltip.SUITip.bgTexture:SetTexture(bgTexture)

			-- Apply color based on settings
			local r, g, b, a = unpack(module.DB.Color)
			if module.DB.Background == 'none' or module.DB.ColorOverlay then
				-- Color overlay mode: apply user's color at full opacity (the color itself provides darkness)
				tooltip.SUITip.bgTexture:SetVertexColor(r, g, b, 1)
			else
				-- Standard mode: show texture as-is with user's alpha transparency
				tooltip.SUITip.bgTexture:SetVertexColor(1, 1, 1, a)
			end
		end

		if quality and tooltip.SetBorderColor then
			local r, g, b = C_Item.GetItemQualityColor(quality)
			if r and g and b then
				r, g, b = (r * 0.5), (g * 0.5), (b * 0.5)
				tooltip:SetBorderColor(r, g, b)
			end
		end
		tooltip.itemCleared = true

		-- Add item ID if enabled and conditions are met
		if module.DB.SpellID.enabled and tooltipData and tooltipData.id then
			local shouldShowID = IsModifierConditionMet(module.DB.SpellID.modifierKey)

			if shouldShowID then
				-- Use ElvUI-style formatting for consistency
				local IDLine = '|cFFCA3C3C%s:|r %d'
				tooltip:AddLine(string.format(IDLine, 'ID', tooltipData.id))
				tooltip:Show()
			end
		end
	end
end

local TooltipSetUnit = function(self, data)
	if self ~= GameTooltip or self:IsForbidden() then
		return
	end

	local unit = select(2, self:GetUnit())
	if not unit or not (SUI.BlizzAPI.canaccessvalue(unit)) then
		return
	end

	local unitLevel = UnitLevel(unit)
	local className, classToken = UnitClass(unit)
	local colors, lvlColor, totColor, lvlLine
	local line = 2
	local creatureClassColors = {
		worldboss = format('|cffAF5050World Boss%s|r', BOSS),
		rareelite = format('|cffAF5050RARE-ELITE%s|r', ITEM_QUALITY3_DESC),
		elite = '|cffAF5050ELITE|r',
		rare = format('|cffAF5050RARE%s|r', ITEM_QUALITY3_DESC),
	}

	if UnitIsPlayer(unit) then
		local uName, uRealm = UnitName(unit)
		local gName, _, _, gRealm = GetGuildInfo(unit)
		local realmRelation = UnitRealmRelationship(unit)
		colors = _G.RAID_CLASS_COLORS[classToken]
		local nameString = UnitPVPName(unit) or uName

		if uRealm and uRealm ~= '' then
			local tmp = ''
			if gRealm ~= uRealm then
				tmp = ' ' .. uRealm
			end

			if realmRelation == LE_REALM_RELATION_COALESCED then
				nameString = nameString .. FOREIGN_SERVER_LABEL .. tmp
			elseif realmRelation == LE_REALM_RELATION_VIRTUAL then
				nameString = nameString .. INTERACTIVE_SERVER_LABEL .. tmp
			elseif gRealm ~= uRealm then
				nameString = nameString .. '-' .. uRealm
			end
		end

		if colors then
			if UnitIsAFK(unit) then
				GameTooltipTextLeft1:SetFormattedText('|cffFF0000%s|r |c%s%s|r', L['AFK'], colors.colorStr, nameString)
			elseif UnitIsDND(unit) then
				GameTooltipTextLeft1:SetFormattedText('|cffFFA500%s|r |c%s%s|r', L['DND'], colors.colorStr, nameString)
			else
				GameTooltipTextLeft1:SetFormattedText('|c%s%s|r', colors.colorStr, nameString)
			end
		else
			GameTooltipTextLeft1:SetText(nameString)
		end

		if gName then
			if gRealm then
				gName = gName .. '-' .. gRealm
			end
			GameTooltipTextLeft2:SetText(('|cff008000%s|r'):format(gName))

			local iLvl = ilvlTempData[uName .. '-' .. (uRealm or GetRealmName())] or C_PaperDollInfo.GetInspectItemLevel('mouseover')
			if iLvl == 0 then
				NotifyInspect('mouseover')
			elseif iLvl then
				self:AddLine(format('|cffFED000iLvl:|r %s', iLvl))
			end

			line = line + 1
		end

		if SUI:IsTimerunner() then
			local cloakData = C_UnitAuras.GetAuraDataBySpellName(unit, "Timerunner's Advantage")
			if cloakData ~= nil then
				local total = 0
				for i = 1, 9 do
					total = total + cloakData.points[i]
				end
				self:AddLine('\n|cff00FF98Threads |cffFFFFFF' .. SUI.Font:comma_value(total))
			end
		end
	end

	for i = 2, self:NumLines() do
		local tip = _G['GameTooltipTextLeft' .. i]
		if tip and tip:GetText() and tip:GetText():find(LEVEL) then
			lvlLine = tip
		end
	end

	if lvlLine then
		local creatureClassification = UnitClassification(unit)
		local creatureType = UnitCreatureType(unit)
		local race, englishRace = UnitRace(unit)
		local factionGroup = UnitFactionGroup(unit) or 'Neutral'

		race = (race or '') .. ' ' .. (className or '')
		if factionGroup and englishRace == 'Pandaren' then
			race = factionGroup .. ' ' .. race
		end
		if GENDER_INFO then
			if gender then
				race = race .. ' ' .. gender
			end
		end

		if UnitIsWildBattlePet and (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			unitLevel = UnitBattlePetLevel(unit) ---@type integer
			local ab = C_PetJournal.GetPetTeamAverageLevel()
			if ab then
				lvlColor = GetRelativeDifficultyColor(ab, unitLevel)
			else
				lvlColor = GetQuestDifficultyColor(unitLevel)
			end
		else
			lvlColor = GetCreatureDifficultyColor(unitLevel)
		end
		if creatureType == nil then
			creatureType = ''
		end

		lvlLine:SetFormattedText(
			'|cff%02x%02x%02x%s|r %s %s',
			lvlColor.r * 255,
			lvlColor.g * 255,
			lvlColor.b * 255,
			unitLevel > 0 and unitLevel or '|TInterface\\TARGETINGFRAME\\UI-TargetingFrame-Skull.blp:16:16|t',
			race or creatureClassColors[creatureClassification] or '',
			creatureType
		)
	end

	local unitTarget = unit .. 'target'
	if unit ~= 'player' and UnitExists(unitTarget) then
		if UnitIsPlayer(unitTarget) and (SUI.IsRetail and not UnitHasVehicleUI(unitTarget)) then
			totColor = RAID_CLASS_COLORS[select(2, UnitClass(unitTarget))]
		else
			totColor = FACTION_BAR_COLORS[UnitReaction(unitTarget, 'player')]
		end
		self:AddDoubleLine(TARGET .. ':', format('|cff%02x%02x%02x%s|r', totColor.r * 255, totColor.g * 255, totColor.b * 255, UnitName(unitTarget)))
	end

	local inittest = IsInRaid() and 'raid1' or 'party1'
	if IsInGroup() and (SUI.BlizzAPI.canaccesstable(inittest)) then
		for i = 1, GetNumGroupMembers() do
			local groupedUnit = IsInRaid() and 'raid' .. i or 'party' .. i
			if UnitIsUnit(groupedUnit .. 'target', unit) then
				local _, classToken = UnitClass(groupedUnit)
				_G.tinsert(targetList, format('|c%s%s|r', RAID_CLASS_COLORS[classToken].colorStr, UnitName(groupedUnit)))
			end
		end
		local maxTargets = #targetList
		if maxTargets > 0 and targetList ~= nil then
			self:AddLine(format('%s (|cffffffff%d|r): %s', L['Targeted By'], maxTargets, table.concat(targetList, ', ')), nil, nil, nil, true)
			wipe(targetList)
		end
	end

	if self.NineSlice then
		SUI.Skins.RemoveTextures(self.NineSlice)
	end
end

local function ApplyTooltipSkins()
	GameTooltipStatusBarTexture:SetTexture('Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2')

	GameTooltipStatusBar:ClearAllPoints()
	GameTooltipStatusBar:SetPoint('TOPLEFT', GameTooltip, 'BOTTOMLEFT', 0, 0)
	GameTooltipStatusBar:SetPoint('TOPRIGHT', GameTooltip, 'BOTTOMRIGHT', 0, 0)

	GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil, 'BACKGROUND')
	GameTooltipStatusBar.bg:SetColorTexture(0.3, 0.3, 0.3, 0.6)
	GameTooltipStatusBar.bg:SetAllPoints(GameTooltipStatusBar)

	for i, tooltip in pairs(tooltips) do
		if not tooltip then
			return
		end
		ApplySkin(tooltip)
	end
end

function module:ZONE_CHANGED()
	ilvlTempData = {}
end

function module:INSPECT_READY()
	if UnitIsPlayer('mouseover') then
		local uName, uRealm = UnitName('mouseover')
		local ilvl = C_PaperDollInfo.GetInspectItemLevel('mouseover')
		if ilvl ~= 0 then
			ilvlTempData[uName .. '-' .. (uRealm or GetRealmName())] = ilvl
		end
	end
end

function module:UpdateBG()
	for _, tooltip in pairs(tooltips) do
		if tooltip.SUITip and tooltip.SUITip.bgTexture then
			-- Update background texture
			local bgTexture = LSM:Fetch('background', module.DB.Background)
			if bgTexture and bgTexture ~= '' then
				tooltip.SUITip.bgTexture:SetTexture(bgTexture)
			end

			-- Apply color based on settings
			local r, g, b, a = unpack(module.DB.Color)
			if module.DB.Background == 'none' or module.DB.ColorOverlay then
				-- Color overlay mode: apply user's color at full opacity (the color itself provides darkness)
				tooltip.SUITip.bgTexture:SetVertexColor(r, g, b, 1)
			else
				-- Standard mode: show texture as-is with user's alpha transparency
				tooltip.SUITip.bgTexture:SetVertexColor(1, 1, 1, a)
			end
		end

		if tooltip.NineSlice then
			SUI.Skins.RemoveTextures(tooltip.NineSlice)
		end
	end
end

function module:OnEnable()
	module:BuildOptions()
	if SUI:IsModuleDisabled('Tooltips') then
		return
	end
	module:RegisterEvent('INSPECT_READY')
	module:RegisterEvent('ZONE_CHANGED')

	--Do Setup
	ApplyTooltipSkins()
	hooksecurefunc('GameTooltip_SetDefaultAnchor', setPoint)
	hooksecurefunc('GameTooltip_SetDefaultAnchor', function(tooltip)
		ApplySkin(tooltip)
	end)

	hooksecurefunc('SharedTooltip_SetBackdropStyle', function(self)
		ApplySkin(self)
	end)

	GameTooltip:HookScript('OnTooltipCleared', TipCleared)

	-- TooltipDataProcessor is Retail-only (10.0.2+), use old-style hooks for Classic
	if TooltipDataProcessor then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, TooltipSetItem)
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, TooltipSetUnit)
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, TooltipSetSpell)
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Mount, TooltipSetGeneric)
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Quest, TooltipSetGeneric)
	else
		-- Classic compatibility: use old-style tooltip hooks
		GameTooltip:HookScript('OnTooltipSetItem', TooltipSetItem)
		GameTooltip:HookScript('OnTooltipSetUnit', TooltipSetUnit)
		GameTooltip:HookScript('OnTooltipSetSpell', TooltipSetSpell)
	end
end

function module:BuildOptions()
	SUI.opt.args['Modules'].args['Tooltips'] = {
		type = 'group',
		name = L['Tooltips'],
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
		end,
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		args = {
			Background = {
				name = L['Background'],
				type = 'select',
				order = 1,
				dialogControl = 'LSM30_Background',
				values = SUI.Lib.LSM:HashTable('background'),
			},
			color = {
				name = L['Color'],
				type = 'color',
				hasAlpha = true,
				order = 10,
				width = 'full',
				get = function(info)
					return unpack(module.DB.Color)
				end,
				set = function(info, r, g, b, a)
					module.DB.Color = { r, g, b, a }
					module:UpdateBG()
				end,
			},
			ColorOverlay = {
				name = L['Color Overlay'],
				type = 'toggle',
				order = 11,
				desc = L['Apply the color to the texture or put it over the texture'],
			},
			onMouse = {
				name = L['Display on mouse?'],
				type = 'toggle',
				order = 12,
				desc = L['TooltipOverrideDesc'],
			},
			spellIDGroup = {
				name = 'Spell/Item IDs',
				type = 'group',
				order = 20,
				inline = true,
				get = function(info)
					return module.DB.SpellID[info[#info]]
				end,
				set = function(info, val)
					module.DB.SpellID[info[#info]] = val
				end,
				args = {
					enabled = {
						name = 'Show Spell IDs',
						desc = 'Display spell IDs in tooltips',
						type = 'toggle',
						order = 1,
					},
					modifierKey = {
						name = 'Modifier Key',
						desc = 'Modifier key required to show spell IDs',
						type = 'select',
						order = 2,
						values = {
							NONE = 'Never',
							ALL = 'Always',
							SHIFT = 'Shift',
							CTRL = 'Ctrl',
							ALT = 'Alt',
						},
						disabled = function()
							return not module.DB.SpellID.enabled
						end,
					},
				},
			},
		},
	}
end
