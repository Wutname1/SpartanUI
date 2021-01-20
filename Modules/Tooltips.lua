local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Component_Tooltips')
module.description = 'SpartanUI tooltip skining'
----------------------------------------------------------------------------------------------------
local targetList = {}
local RuleList = {'Rule1', 'Rule2', 'Rule3'}
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
	ItemSocketingDescription
}
local whitebg = {bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga', tile = false, edgeSize = 3}

function module:OnInitialize()
	if SUI.DB.Tooltips.Rule1 == nil then
		for _, v in ipairs(RuleList) do
			SUI.DB.Tooltips[v] = {
				Status = 'Disabled',
				Combat = false,
				OverrideLoc = false,
				Anchor = {onMouse = false, Moved = false, AnchorPos = {}}
			}
		end
		if SUI.DB.Tooltips.OverrideLoc then
			SUI.DB.Tooltips.Rule1 = {
				Status = 'All',
				Combat = false,
				OverrideLoc = SUI.DB.Tooltips.OverrideLoc,
				Anchor = {
					onMouse = SUI.DB.Tooltips.Anchor.onMouse,
					Moved = SUI.DB.Tooltips.Anchor.Moved,
					AnchorPos = SUI.DB.Tooltips.Anchor.AnchorPos
				}
			}
			SUI.DB.Tooltips.Anchor = nil
		else
			SUI.DB.Tooltips.Rule1 = {
				Status = 'All',
				Combat = false,
				OverrideLoc = false,
				Anchor = {onMouse = false, Moved = false, AnchorPos = {}}
			}
		end
	end
	if SUI.DB.Tooltips.SuppressNoMatch == nil then
		SUI.DB.Tooltips.SuppressNoMatch = true
	end
	local a, b, c, d = unpack(SUI.DB.Tooltips.Color)
	if a == 0 and b == 0 and c == 0 and d == 0.7 then
		SUI.DB.Tooltips.Color = {0, 0, 0, 0.4}
	end
end

local function ActiveRule()
	for _, v in ipairs(RuleList) do
		if SUI.DB.Tooltips[v] and SUI.DB.Tooltips[v].Status ~= 'Disabled' then
			local CombatRule = false
			if InCombatLockdown() and SUI.DB.Tooltips[v].Combat then
				CombatRule = true
			elseif not InCombatLockdown() and not SUI.DB.Tooltips[v].Combat then
				CombatRule = true
			end

			if SUI.DB.Tooltips[v].Status == 'Group' and (IsInGroup() and not IsInRaid()) and CombatRule then
				return v
			elseif SUI.DB.Tooltips[v].Status == 'Raid' and IsInRaid() and CombatRule then
				return v
			elseif SUI.DB.Tooltips[v].Status == 'Instance' and IsInInstance() then
				return v
			elseif SUI.DB.Tooltips[v].Status == 'All' and CombatRule then
				return v
			end
		end
	end
	--Failback of Rule1
	if not SUI.DB.Tooltips.SuppressNoMatch then
		SUI:Print('|cffff0000Error detected')
		SUI:Print(L['None of your custom tooltip conditions have been met. Defaulting to what is specified for Rule 1'])
		SUI:Print(L['You may customize the tooltip settings via'] .. ' /SUI > Modules > Tooltips')
	end
	return 'Rule1'
end

local setPoint = function(self, parent)
	if parent then
		if (SUI.DB.Tooltips[ActiveRule()].Anchor.onMouse) then
			self:SetOwner(parent, 'ANCHOR_CURSOR')
			return
		else
			self:SetOwner(parent, 'ANCHOR_NONE')
		end

		--See If the theme has an anchor and if we are allowed to use it
		local style = SUI:GetModule('Style_' .. (SUI.DB.Artwork.Style or 'War'), true)
		if style and style.TooltipLoc and not SUI.DB.Tooltips[ActiveRule()].OverrideLoc then
			style:TooltipLoc(self, parent)
		else
			self:ClearAllPoints()
			if SUI.DB.Tooltips[ActiveRule()].Anchor.Moved then
				local Anchors = {}
				for key, val in pairs(SUI.DB.Tooltips[ActiveRule()].Anchor.AnchorPos) do
					Anchors[key] = val
				end
				-- self:ClearAllPoints();
				if Anchors.point == nil then
					--Error Catch
					self:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -20, 20)
					SUI.DB.Tooltips[ActiveRule()].Anchor.Moved = false
				else
					self:SetPoint(Anchors.point, UIParent, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
				end
			else
				self:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -20, 20)
			end
		end
	end
end

local onShow = function(self)
	if not self.SetBackdrop then
		Mixin(self, BackdropTemplateMixin)
	end
	self:SetBackdrop(whitebg)
	if
		SUI.DB.Styles[(SUI.DB.Artwork.Style or 'War')].Tooltip ~= nil and
			SUI.DB.Styles[(SUI.DB.Artwork.Style or 'War')].Tooltip.BG and
			not SUI.DB.Tooltip.Override[(SUI.DB.Artwork.Style or 'War')]
	 then
		self.SUITip:SetBackdrop(SUI.DB.Styles[(SUI.DB.Artwork.Style or 'War')].Tooltip.BG)
	else
		self.SUITip:SetBackdrop(SUI.DB.Tooltips.Styles[SUI.DB.Tooltips.ActiveStyle])
	end

	if (SUI.DB.Tooltips.ActiveStyle == 'none' or SUI.DB.Tooltips.ColorOverlay) or (not self.SUITip) then
		self:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
		self.SUITip:SetBackdropColor(1, 1, 1, 1)
	else
		self.SUITip:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
		self:SetBackdropColor(0, 0, 0, 0)
	end

	--check if theme has a location
	if
		SUI.DB.Styles[(SUI.DB.Artwork.Style or 'War')].Tooltip ~= nil and
			SUI.DB.Styles[(SUI.DB.Artwork.Style or 'War')].Tooltip.Custom
	 then
		SUI:GetModule('Style_' .. (SUI.DB.Artwork.Style or 'War')):Tooltip()
	end
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

local SetBorderColor = function(self, r, g, b, hasStatusBar)
	self.SUITip.border:Show()
	self.SUITip.border[1]:SetVertexColor(r, g, b, 1)
	self.SUITip.border[2]:SetVertexColor(r, g, b, 1)
	self.SUITip.border[3]:SetVertexColor(r, g, b, 1)
	self.SUITip.border[4]:SetVertexColor(r, g, b, 1)
end

local ClearColors = function(SUITip)
	SUITip.border[1]:SetVertexColor(0, 0, 0, 0)
	SUITip.border[2]:SetVertexColor(0, 0, 0, 0)
	SUITip.border[3]:SetVertexColor(0, 0, 0, 0)
	SUITip.border[4]:SetVertexColor(0, 0, 0, 0)
end

local TooltipSetItem = function(self)
	local itemLink = select(2, self:GetItem())
	if (itemLink) then
		local quality = select(3, GetItemInfo(itemLink))
		local style = {
			bgFile = 'Interface/Tooltips/UI-Tooltip-Background'
		}
		if SUI.IsRetail then
			if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemLink) or C_AzeriteItem.IsAzeriteItemByID(itemLink) then
				style = {
					bgFile = 'Interface/Tooltips/UI-Tooltip-Background-Azerite',
					overlayAtlasTop = 'AzeriteTooltip-Topper',
					overlayAtlasTopScale = .75,
					overlayAtlasTopYOffset = 1,
					overlayAtlasBottom = 'AzeriteTooltip-Bottom',
					overlayAtlasBottomYOffset = 2
				}
			elseif IsCorruptedItem(itemLink) then
				style = {
					bgFile = 'Interface/Tooltips/UI-Tooltip-Background-Corrupted',
					overlayAtlasTop = 'Nzoth-tooltip-topper',
					overlayAtlasTopScale = .75,
					overlayAtlasTopYOffset = -2
				}
			end
		end

		if SUI.IsClassic and SUI.DB.Tooltips.VendorPrices then
			local _, _, _, _, _, _, _, itemStackCount, _, _, itemSellPrice = GetItemInfo(itemLink)
			if itemSellPrice then
				SetTooltipMoney(self, itemSellPrice, 'STATIC', L['Vendors for:'])
				local itemUnderMouse = GetMouseFocus()
				if itemUnderMouse:GetName() then
					if itemStackCount > 1 and _G[itemUnderMouse:GetName() .. 'Count'] then
						-- local buttonUnderMouse = itemUnderMouse:GetName() and ()
						local count = _G[itemUnderMouse:GetName() .. 'Count']:GetText()
						count = tonumber(count) or 1
						if count <= 1 then
							count = 1
						end

						if count > 1 and count ~= itemStackCount then
							local curValue = count * itemSellPrice
							SetTooltipMoney(self, curValue, 'STATIC', L['Vendors for:'], string.format(L[' (current stack of %d)'], count))
						end
					end
				end
			end
		end

		GameTooltip:SetBackdrop(style)
		GameTooltip:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))

		if (quality) then
			local r, g, b = GetItemQualityColor(quality)
			r, g, b = (r * 0.5), (g * 0.5), (b * 0.5)
			self:SetBorderColor(r, g, b)
		end
		self.itemCleared = true
	end
end

local TooltipSetUnit = function(self)
	if (not self) then
		return
	end

	local unit = select(2, self:GetUnit())
	if not unit then
		local mFocus = GetMouseFocus()
		if mFocus and mFocus:GetAttribute('unit') then
			unit = mFocus:GetAttribute('unit')
		end
		if not unit or not UnitExists(unit) then
			return
		end
	end

	local unitLevel = UnitLevel(unit)
	local className, classToken = UnitClass(unit)
	local colors, lvlColor, totColor, lvlLine
	local line = 2
	local sex = {'', 'Male ', 'Female '}
	local creatureClassColors = {
		worldboss = format('|cffAF5050World Boss%s|r', BOSS),
		rareelite = format('|cffAF5050RARE-ELITE%s|r', ITEM_QUALITY3_DESC),
		elite = '|cffAF5050ELITE|r',
		rare = format('|cffAF5050RARE%s|r', ITEM_QUALITY3_DESC)
	}

	if UnitIsPlayer(unit) then
		local uName, uRealm = UnitName(unit)
		local gName, _, _, gRealm = GetGuildInfo(unit)
		local gender = sex[UnitSex(unit)]
		local realmRelation = UnitRealmRelationship(unit)
		colors = _G.RAID_CLASS_COLORS[classToken]
		local nameString = UnitPVPName(unit) or uName

		if uRealm and uRealm ~= '' then
			local tmp = ''
			if gRealm ~= uRealm then
				tmp = ' ' .. uRealm
			end

			if (realmRelation == LE_REALM_RELATION_COALESCED) then
				nameString = nameString .. FOREIGN_SERVER_LABEL .. tmp
			elseif (realmRelation == LE_REALM_RELATION_VIRTUAL) then
				nameString = nameString .. INTERACTIVE_SERVER_LABEL .. tmp
			elseif gRealm ~= uRealm then
				nameString = nameString .. '-' .. uRealm
			end
		end

		if colors then
			if (UnitIsAFK(unit)) then
				GameTooltipTextLeft1:SetFormattedText('|cffFF0000%s|r |c%s%s|r', L['AFK'], colors.colorStr, nameString)
			elseif (UnitIsDND(unit)) then
				GameTooltipTextLeft1:SetFormattedText('|cffFFA500%s|r |c%s%s|r', L['DND'], colors.colorStr, nameString)
			else
				GameTooltipTextLeft1:SetFormattedText('|c%s%s|r', colors.colorStr, nameString)
			end
		else
			GameTooltipTextLeft1:SetText(nameString)
		end

		if (gName) then
			if gRealm then
				gName = gName .. '-' .. gRealm
			end
			if SUI.IsClassic then
				self:AddLine(('|cff008000<%s>|r'):format(gName))
			else
				GameTooltipTextLeft2:SetText(('|cff008000%s|r'):format(gName))
				line = line + 1
			end
		end
	end

	for i = 2, self:NumLines() do
		local tip = _G['GameTooltipTextLeft' .. i]
		if tip:GetText() and tip:GetText():find(LEVEL) then
			lvlLine = tip
		end
	end

	if (lvlLine) then
		local creatureClassification = UnitClassification(unit)
		local creatureType = UnitCreatureType(unit)
		local race, englishRace = UnitRace(unit)
		local factionGroup = UnitFactionGroup(unit) or 'Neutral'

		race = (race or '') .. ' ' .. (className or '')
		if (factionGroup and englishRace == 'Pandaren') then
			race = factionGroup .. ' ' .. race
		end
		if (GENDER_INFO) then
			if (gender) then
				race = race .. ' ' .. gender
			end
		end

		if SUI.IsRetail and (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			unitLevel = UnitBattlePetLevel(unit)
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
		self:AddDoubleLine(
			TARGET .. ':',
			format('|cff%02x%02x%02x%s|r', totColor.r * 255, totColor.g * 255, totColor.b * 255, UnitName(unitTarget))
		)
	end

	if IsInGroup() then
		for i = 1, GetNumGroupMembers() do
			local groupedUnit = IsInRaid() and 'raid' .. i or 'party' .. i
			if UnitIsUnit(groupedUnit .. 'target', unit) and not UnitIsUnit(groupedUnit, 'player') then
				local _, classToken = UnitClass(groupedUnit)
				_G.tinsert(targetList, format('|c%s%s|r', RAID_CLASS_COLORS[classToken].colorStr, UnitName(groupedUnit)))
			end
		end
		local maxTargets = #targetList
		if maxTargets > 0 and targetList ~= nil then
			self:AddLine(
				format('%s (|cffffffff%d|r): %s', L['Targeted By'], maxTargets, table.concat(targetList, ', ')),
				nil,
				nil,
				nil,
				true
			)
			wipe(targetList)
		end
	end
end

local function ApplyTooltipSkins()
	GameTooltipStatusBarTexture:SetTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')

	GameTooltipStatusBar:ClearAllPoints()
	GameTooltipStatusBar:SetPoint('TOPLEFT', GameTooltip, 'BOTTOMLEFT', 0, 0)
	GameTooltipStatusBar:SetPoint('TOPRIGHT', GameTooltip, 'BOTTOMRIGHT', 0, 0)

	GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil, 'BACKGROUND')
	GameTooltipStatusBar.bg:SetColorTexture(0.3, 0.3, 0.3, 0.6)
	GameTooltipStatusBar.bg:SetAllPoints(GameTooltipStatusBar)

	for i, tooltip in pairs(tooltips) do
		if (not tooltip) then
			return
		end

		if (not tooltip.SUITip) then
			local SUITip = CreateFrame('Frame', nil, tooltip, BackdropTemplateMixin and 'BackdropTemplate')
			SUITip:SetPoint('TOPLEFT', tooltip, 'TOPLEFT', 0, 0)
			SUITip:SetPoint('BOTTOMRIGHT', tooltip, 'BOTTOMRIGHT', 0, 0)
			SUITip:SetFrameLevel(0)

			SUITip.border = CreateFrame('Frame', nil, tooltip)
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

			SUITip:SetBackdrop(SUI.DB.Tooltips.Styles[SUI.DB.Tooltips.ActiveStyle])

			SUITip.ClearColors = ClearColors
			SUITip.border:Hide()

			tooltip.SUITip = SUITip
			tooltip.SetBorderColor = SetBorderColor
			if (tooltip.SetBackdrop) then
				tooltip:SetBackdrop(nil)
			end
			tooltip:HookScript('OnShow', onShow)
			tooltip:HookScript('OnHide', onHide)
			_G.tremove(tooltips, i)
		end

		local style = {
			bgFile = 'Interface/Tooltips/UI-Tooltip-Background'
		}

		GameTooltip:SetBackdrop(style)
		GameTooltip:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
	end
end

function module:UpdateBG()
	for _, tooltip in pairs(tooltips) do
		if (tooltip.SUITip) then
			if not SUI.DB.Tooltips.c then
				if SUI.DB.Tooltips.ActiveStyle ~= 'none' then
					tooltip.SUITip:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
				else
					tooltip.SUITip:SetBackdropColor(0, 0, 0, 0)
					tooltip:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
				end
			end
		end
	end
end

function module:OnEnable()
	if SUI.DB.DisabledComponents.Tooltips then
		return
	end
	module:BuildOptions()

	--Create Anchor point
	for k, v in ipairs(RuleList) do
		local anchor = CreateFrame('Frame', nil)
		anchor:SetSize(150, 20)
		anchor:EnableMouse(enable)
		anchor.bg = anchor:CreateTexture(nil, 'OVERLAY')
		anchor.bg:SetAllPoints(anchor)
		anchor.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		anchor.bg:SetVertexColor(1, 1, 1, 0.8)
		anchor.lbl = anchor:CreateFontString(nil, 'OVERLAY')
		anchor.lbl:SetFont(SUI:GetFontFace(), 10)
		anchor.lbl:SetText('Anchor for Rule ' .. k)
		anchor.lbl:SetAllPoints(anchor)

		anchor:SetScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' then
					SUI.DB.Tooltips[v].Anchor.Moved = true
					module[v].anchor:SetMovable(true)
					module[v].anchor:StartMoving()
				end
			end
		)

		anchor:SetScript(
			'OnMouseUp',
			function(self, button)
				module[v].anchor:Hide()
				module[v].anchor:StopMovingOrSizing()
				local Anchors = {}
				Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = module[v].anchor:GetPoint()
				for k, val in pairs(Anchors) do
					SUI.DB.Tooltips[v].Anchor.AnchorPos[k] = val
				end
			end
		)

		anchor:SetScript(
			'OnShow',
			function(self)
				if SUI.DB.Tooltips[v].Anchor.Moved then
					local Anchors = {}
					for key, val in pairs(SUI.DB.Tooltips[v].Anchor.AnchorPos) do
						Anchors[key] = val
					end
					self:ClearAllPoints()
					self:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
				else
					self:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -20, 20)
				end
			end
		)

		anchor:SetScript(
			'OnEvent',
			function(self, event, ...)
				module[v].anchor:Hide()
			end
		)
		anchor:RegisterEvent('PLAYER_REGEN_DISABLED')

		module[v] = {anchor = anchor}
		module[v].anchor:Hide()
	end

	--Do Setup
	ApplyTooltipSkins()

	GameTooltip:HookScript('OnTooltipCleared', TipCleared)
	GameTooltip:HookScript('OnTooltipSetItem', TooltipSetItem)
	GameTooltip:HookScript('OnTooltipSetUnit', TooltipSetUnit)
	ShoppingTooltip1:HookScript('OnTooltipSetItem', TooltipSetItem)
	ShoppingTooltip2:HookScript('OnTooltipSetItem', TooltipSetItem)
	hooksecurefunc('GameTooltip_SetDefaultAnchor', setPoint)
	-- hooksecurefunc('GameTooltip_ShowCompareItem', ReStyle)
end

local OnMouseOpt = function(v)
	local style = SUI:GetModule('Style_' .. (SUI.DB.Artwork.Style or 'War'), true)
	if style and style.TooltipLoc and not SUI.DB.Buffs[ActiveRule()].OverrideLoc then
		SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v].args['OverrideLoc'].disabled = false
	else
		SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v].args['OverrideLoc'].disabled = true
	end

	SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v].args['MoveAnchor'].disabled =
		SUI.DB.Tooltips[v].Anchor.onMouse
	SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v].args['ResetAnchor'].disabled =
		SUI.DB.Tooltips[v].Anchor.onMouse
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['Tooltips'] = {
		type = 'group',
		name = L['Tooltips'],
		args = {
			Background = {
				name = L['Background'],
				type = 'select',
				order = 1,
				values = {
					['metal'] = 'metal',
					['smooth'] = 'smooth',
					['smoke'] = 'smoke',
					['none'] = L['None']
				},
				get = function(info)
					return SUI.DB.Tooltips.ActiveStyle
				end,
				set = function(info, val)
					SUI.DB.Tooltips.ActiveStyle = val
				end
			},
			OverrideLoc = {
				name = L['Override theme'],
				type = 'toggle',
				order = 2,
				desc = L['TooltipOverrideDesc'],
				get = function(info)
					return SUI.DB.Tooltips.Override[(SUI.DB.Artwork.Style or 'War')]
				end,
				set = function(info, val)
					SUI.DB.Tooltips.Override[(SUI.DB.Artwork.Style or 'War')] = val
				end
			},
			color = {
				name = L['Color'],
				type = 'color',
				hasAlpha = true,
				order = 10,
				width = 'full',
				get = function(info)
					return unpack(SUI.DB.Tooltips.Color)
				end,
				set = function(info, r, g, b, a)
					SUI.DB.Tooltips.Color = {r, g, b, a}
					module:UpdateBG()
				end
			},
			ColorOverlay = {
				name = L['Color Overlay'],
				type = 'toggle',
				order = 11,
				desc = L['Apply the color to the texture or put it over the texture'],
				get = function(info)
					return SUI.DB.Tooltips.ColorOverlay
				end,
				set = function(info, val)
					SUI.DB.Tooltips.ColorOverlay = val
					module:UpdateBG()
				end
			},
			SuppressNoMatch = {
				name = L['Suppress no rule match error'],
				type = 'toggle',
				order = 11,
				desc = L['Apply the color to the texture or put it over the texture'],
				get = function(info)
					return SUI.DB.Tooltips.SuppressNoMatch
				end,
				set = function(info, val)
					SUI.DB.Tooltips.SuppressNoMatch = val
				end
			}
		}
	}

	for k, v in ipairs(RuleList) do
		SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v] = {
			name = L['Display Location'] .. ' ' .. v,
			type = 'group',
			inline = true,
			order = k + 20.1,
			width = 'full',
			get = function(info)
				return SUI.DB.Tooltips[v][info[#info]]
			end,
			args = {
				Status = {
					name = L['Condition'],
					type = 'select',
					order = k + 20.2,
					values = {
						['Group'] = 'In a Group',
						['Raid'] = 'In a Raid Group',
						['Instance'] = 'In a instance',
						['All'] = 'All the time',
						['Disabled'] = 'Disabled'
					},
					set = function(info, val)
						SUI.DB.Tooltips[v].Status = val
					end
				},
				Combat = {
					name = L['Only if in combat'],
					type = 'toggle',
					order = k + 20.3,
					set = function(info, val)
						SUI.DB.Tooltips[v].Combat = val
					end
				},
				OnMouse = {
					name = L['Display on mouse?'],
					type = 'toggle',
					order = k + 20.4,
					desc = L['TooltipOverrideDesc'],
					get = function(info)
						OnMouseOpt(v)
						return SUI.DB.Tooltips[v].Anchor.onMouse
					end,
					set = function(info, val)
						SUI.DB.Tooltips[v].Anchor.onMouse = val
						OnMouseOpt(v)
					end
				},
				OverrideLoc = {
					name = L['Override theme'],
					type = 'toggle',
					order = k + 20.5,
					set = function(info, val)
						SUI.DB.Tooltips[v].OverrideLoc = val
					end
				},
				MoveAnchor = {
					name = L['Move anchor'],
					type = 'execute',
					order = k + 20.6,
					width = 'half',
					func = function(info, val)
						-- Force override sincce the user is moving the anchor
						SUI.DB.Tooltips[v].OverrideLoc = true
						--show the anchor
						module[v].anchor:Show()
					end
				},
				ResetAnchor = {
					name = L['Reset anchor'],
					type = 'execute',
					order = k + 20.7,
					width = 'half',
					func = function(info, val)
						SUI.DB.Tooltips[v].Anchor.Moved = false
					end
				}
			}
		}
	end
	if SUI.IsClassic then
		SUI.opt.args.ModSetting.args.Tooltips.args.VendorPrices = {
			name = L['Display vendor prices'],
			type = 'toggle',
			get = function(info)
				return SUI.DB.Tooltips.VendorPrices
			end,
			set = function(info, val)
				SUI.DB.Tooltips.VendorPrices = val
			end
		}
	end
end
