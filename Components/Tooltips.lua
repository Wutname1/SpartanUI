local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Component_Tooltips')
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
local whitebg = {bgFile = 'Interface\\AddOns\\SpartanUI\\media\\blank.tga', tile = false, edgeSize = 3}

function module:OnInitialize()
	if SUI.DB.Tooltips == nil then
		SUI.DB.Tooltips = {
			Styles = {
				metal = {
					bgFile = 'Interface\\AddOns\\SpartanUI\\media\\metal.tga',
					tile = false
				},
				smooth = {
					bgFile = 'Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga',
					tile = false
				},
				smoke = {
					bgFile = 'Interface\\AddOns\\SpartanUI\\media\\smoke.tga',
					tile = false
				},
				none = {
					bgFile = 'Interface\\AddOns\\SpartanUI\\media\\blank.tga',
					tile = false
				}
			},
			ActiveStyle = 'smoke',
			Override = {},
			ColorOverlay = true,
			Color = {0, 0, 0, 0.4},
			SuppressNoMatch = true
		}
	end

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
		if SUI.DB.Tooltips[v].Status ~= 'Disabled' then
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
		SUI:Print(L['You may customize the tooltip settings via'] + ' /SUI > Modules > Tooltips')
	end
	return 'Rule1'
end

-- local setPoint = function(self,point,parent,rpoint)
local setPoint = function(self, parent)
	if parent then
		if (SUI.DB.Tooltips[ActiveRule()].Anchor.onMouse) then
			self:SetOwner(parent, 'ANCHOR_CURSOR')
			return
		else
			self:SetOwner(parent, 'ANCHOR_NONE')
		end

		--See If the theme has an anchor and if we are allowed to use it
		if SUI.DB.Styles[SUI.DBMod.Artwork.Style].TooltipLoc and not SUI.DB.Tooltips[ActiveRule()].OverrideLoc then
			local style = SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style, true)
			if style then
				style:TooltipLoc(self, parent)
			end
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
					self:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
				end
			else
				self:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -20, 20)
			end
		end
	end
end

local onShow = function(self)
	self:SetBackdrop(whitebg)
	if
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip ~= nil and SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip.BG and
			not SUI.DB.Tooltip.Override[SUI.DBMod.Artwork.Style]
	 then
		self.SUIBorder:SetBackdrop(SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip.BG)
	else
		self.SUIBorder:SetBackdrop(SUI.DB.Tooltips.Styles[SUI.DB.Tooltips.ActiveStyle])
	end

	if (SUI.DB.Tooltips.ActiveStyle == 'none' or SUI.DB.Tooltips.ColorOverlay) or (not self.SUIBorder) then
		self:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
		self.SUIBorder:SetBackdropColor(1, 1, 1, 1)
	else
		self.SUIBorder:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
		self:SetBackdropColor(0, 0, 0, 0)
	end

	if (self.SUIBorder) and (not GameTooltipStatusBar:IsShown()) then
		self.SUIBorder:ClearAllPoints()
		self.SUIBorder:SetPoint('TOPLEFT', self, 'TOPLEFT', -1, 1)
		self.SUIBorder:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 1, -1)
	end
	--check if theme has a location
	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip ~= nil and SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip.Custom then
		SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):Tooltip()
	end
end

local onHide = function(self)
	onShow(self)
	self.SUIBorder:ClearColors()
end

local TipCleared = function(self)
	onShow(self)
	self.SUIBorder:ClearColors()
	self.itemCleared = nil
end

local Override_Color = function(self, r, g, b, a)
	local r2, b2, g2, a2 = unpack(SUI.DB.Tooltips.Color)
	if ((r ~= r2) and (g ~= g2) and (b ~= b2)) then
		if not SUI.DB.Tooltips.ColorOverlay then
			self.SUIBorder:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
		else
			self:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
		end
	end
end

local SetBorderColor = function(self, r, g, b, hasStatusBar)
	r, g, b = (r * 0.5), (g * 0.5), (b * 0.5)
	self[1]:SetTexture(r, g, b, 1)
	self[2]:SetTexture(r, g, b, 1)
	self[3]:SetTexture(r, g, b, 1)
	self[4]:SetTexture(r, g, b, 1)
end

local ClearColors = function(self)
	self[1]:SetTexture(0, 0, 0, 0)
	self[2]:SetTexture(0, 0, 0, 0)
	self[3]:SetTexture(0, 0, 0, 0)
	self[4]:SetTexture(0, 0, 0, 0)
end

local TooltipSetItem = function(self)
	local key = self:GetItem()
	if (key and (not self.itemCleared)) then
		local _, _, quality = GetItemInfo(key)
		if (quality) then
			local r, g, b = GetItemQualityColor(quality)
			self.SUIBorder:SetBorderColor(r, g, b)
		end
		self.itemCleared = true
	end
end

local TooltipSetUnit = function(self)
	if (not self) then
		return
	end
	-- tipbackground(self)
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
	local colors, qColor, totColor, lvlLine
	local line = 2
	local sex = {'', 'Male ', 'Female '}
	local creatureClassColors = {
		worldboss = format('|cffAF5050World Boss%s|r', BOSS),
		rareelite = format('|cffAF5050RARE-ELITE%s|r', ITEM_QUALITY3_DESC),
		elite = '|cffAF5050ELITE|r',
		rare = format('|cffAF5050RARE%s|r', ITEM_QUALITY3_DESC)
	}

	if UnitIsPlayer(unit) then
		local className, classToken = UnitClass(unit)
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
			GameTooltipTextLeft2:SetText(('|cff008000%s|r'):format(gName))
			line = line + 1
		end

		for i = line, self:NumLines() do
			local tip = _G['GameTooltipTextLeft' .. i]
			if tip:GetText() and tip:GetText():find(LEVEL) then
				lvlLine = tip
			end
		end

		if (lvlLine) then
			qColor = GetQuestDifficultyColor(unitLevel)
			local race, englishRace = UnitRace(unit)
			local _, factionGroup = UnitFactionGroup(unit)

			if (factionGroup and englishRace == 'Pandaren') then
				race = factionGroup .. ' ' .. race
			end

			if (GENDER_INFO) then
				if (gender) then
					race = race .. ' ' .. gender
				end
			end
			lvlLine:SetFormattedText(
				'|cff%02x%02x%02x%s|r %s |c%s%s|r',
				qColor.r * 255,
				qColor.g * 255,
				qColor.b * 255,
				unitLevel > 0 and unitLevel or '|TInterface\\TARGETINGFRAME\\UI-TargetingFrame-Skull.blp:16:16|t',
				race or '',
				colors.colorStr,
				className
			)
		end
	else
		for i = 2, self:NumLines() do
			local tip = _G['GameTooltipTextLeft' .. i]
			if tip:GetText() and tip:GetText():find(LEVEL) then
				lvlLine = tip
			end
		end

		if (lvlLine) then
			local creatureClassification = UnitClassification(unit)
			local creatureType = UnitCreatureType(unit)
			if not SUI.IsClassic and (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
				unitLevel = UnitBattlePetLevel(unit)
				local ab = C_PetJournal.GetPetTeamAverageLevel()
				if ab then
					qColor = GetRelativeDifficultyColor(ab, unitLevel)
				else
					qColor = GetQuestDifficultyColor(unitLevel)
				end
			else
				qColor = GetQuestDifficultyColor(unitLevel)
			end
			if creatureType == nil then
				creatureType = ''
			end

			lvlLine:SetFormattedText(
				'|cff%02x%02x%02x%s|r %s %s',
				qColor.r * 255,
				qColor.g * 255,
				qColor.b * 255,
				unitLevel > 0 and unitLevel or '??',
				creatureClassColors[creatureClassification] or '',
				creatureType
			)
		end
	end

	local unitTarget = unit .. 'target'
	if unit ~= 'player' and UnitExists(unitTarget) then
		if UnitIsPlayer(unitTarget) and (not SUI.IsClassic and not UnitHasVehicleUI(unitTarget)) then
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
	for i, tooltip in pairs(tooltips) do
		if (not tooltip) then
			return
		end

		if (not tooltip.SUIBorder) then
			local Offset = 0
			if (tooltip == GameTooltip) then
				Offset = (GameTooltipStatusBar:GetHeight() + 6) * -1
			end

			local tmp = CreateFrame('Frame', nil, tooltip)
			tmp:SetPoint('TOPLEFT', tooltip, 'TOPLEFT', -1, 1)
			tmp:SetPoint('BOTTOMRIGHT', tooltip, 'BOTTOMRIGHT', 1, Offset)
			tmp:SetFrameLevel(0)

			--TOP
			tmp[1] = tmp:CreateTexture(nil, 'OVERLAY')
			tmp[1]:SetPoint('BOTTOMLEFT', tmp, 'TOPLEFT', -3, 0)
			tmp[1]:SetPoint('BOTTOMRIGHT', tmp, 'TOPRIGHT', 3, 0)
			tmp[1]:SetHeight(3)
			tmp[1]:SetTexture(0, 0, 0)
			--BOTTOM
			tmp[2] = tmp:CreateTexture(nil, 'OVERLAY')
			tmp[2]:SetPoint('TOPLEFT', tmp, 'BOTTOMLEFT', -3, 0)
			tmp[2]:SetPoint('TOPRIGHT', tmp, 'BOTTOMRIGHT', 3, 0)
			tmp[2]:SetHeight(3)
			tmp[2]:SetTexture(0, 0, 0)
			--RIGHT
			tmp[3] = tmp:CreateTexture(nil, 'OVERLAY')
			tmp[3]:SetPoint('TOPLEFT', tmp, 'TOPRIGHT', 0, 3)
			tmp[3]:SetPoint('BOTTOMLEFT', tmp, 'BOTTOMRIGHT', 0, -3)
			tmp[3]:SetWidth(3)
			tmp[3]:SetTexture(0, 0, 0)
			--LEFT
			tmp[4] = tmp:CreateTexture(nil, 'OVERLAY')
			tmp[4]:SetPoint('TOPRIGHT', tmp, 'TOPLEFT', 0, 3)
			tmp[4]:SetPoint('BOTTOMRIGHT', tmp, 'BOTTOMLEFT', 0, -3)
			tmp[4]:SetWidth(3)
			tmp[4]:SetTexture(0, 0, 0)

			if
				(SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip ~= nil) and SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip.BG and
					not SUI.DB.Tooltip.Override[SUI.DBMod.Artwork.Style]
			 then
				tmp:SetBackdrop(SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip.BG)
			else
				tmp:SetBackdrop(SUI.DB.Tooltips.Styles[SUI.DB.Tooltips.ActiveStyle])
			end

			tmp.SetBorderColor = SetBorderColor
			tmp.ClearColors = ClearColors

			tooltip.SUIBorder = tmp
			tooltip:SetBackdrop(nil)

			hooksecurefunc(tooltip, 'SetBackdropColor', Override_Color)
			tooltip:HookScript('OnShow', onShow)
			tooltip:HookScript('OnHide', onHide)
			_G.tremove(tooltips, i)
		end
	end
end

function module:UpdateBG()
	for _, tooltip in pairs(tooltips) do
		if (tooltip.SUIBorder) then
			-- if SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip ~= nil and SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip.BG and not SUI.DB.Tooltip.Override[SUI.DBMod.Artwork.Style] then
			-- tooltip.SUIBorder:SetBackdrop(SUI.DB.Styles[SUI.DBMod.Artwork.Style].Tooltip.BG)
			-- else
			-- tooltip.SUIBorder:SetBackdrop(SUI.DB.Tooltips.Styles[SUI.DB.Tooltips.ActiveStyle])
			-- end
			if not SUI.DB.Tooltips.ColorOverlay then
				if SUI.DB.Tooltips.ActiveStyle ~= 'none' then
					tooltip.SUIBorder:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
				else
					tooltip.SUIBorder:SetBackdropColor(0, 0, 0, 0)
					tooltip:SetBackdropColor(unpack(SUI.DB.Tooltips.Color))
				end
			end
		end
	end
end

local function ReStyle()
	if (#tooltips > 0) then
		ApplyTooltipSkins()
	end
end

function module:OnEnable()
	module:BuildOptions()
	if not SUI.DB.EnabledComponents.Tooltips then
		module:HideOptions()
		return
	end
	--Create Anchor point
	for k, v in ipairs(RuleList) do
		local anchor = CreateFrame('Frame', nil)
		anchor:SetSize(150, 20)
		anchor:EnableMouse(enable)
		anchor.bg = anchor:CreateTexture(nil, 'OVERLAY')
		anchor.bg:SetAllPoints(anchor)
		anchor.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		anchor.bg:SetVertexColor(1, 1, 1, 0.8)
		anchor.lbl = anchor:CreateFontString(nil, 'OVERLAY', 'SUI_Font10')
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
	hooksecurefunc('GameTooltip_SetDefaultAnchor', setPoint)
	hooksecurefunc('GameTooltip_ShowCompareItem', ReStyle)

	-- GameTooltip:HookScript("SetPoint", setPoint)
	-- hooksecurefunc(GameTooltip,"SetPoint",setPoint);
end

local OnMouseOpt = function(v)
	if SUI.DB.Tooltips[v].Anchor.onMouse or not SUI.DB.Styles[SUI.DBMod.Artwork.Style].TooltipLoc then
		SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v].args['OverrideTheme'].disabled = true
	else
		SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v].args['OverrideTheme'].disabled = false
	end

	SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v].args['MoveAnchor'].disabled =
		SUI.DB.Tooltips[v].Anchor.onMouse
	SUI.opt.args['ModSetting'].args['Tooltips'].args['DisplayLocation' .. v].args['ResetAnchor'].disabled =
		SUI.DB.Tooltips[v].Anchor.onMouse
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['Tooltips'] = {
		type = 'group',
		name = 'Tooltips',
		args = {
			Background = {
				name = L['Background'],
				type = 'select',
				order = 1,
				values = {
					['metal'] = 'metal',
					['smooth'] = 'smooth',
					['smoke'] = 'smoke',
					['none'] = L['none']
				},
				get = function(info)
					return SUI.DB.Tooltips.ActiveStyle
				end,
				set = function(info, val)
					SUI.DB.Tooltips.ActiveStyle = val
				end
			},
			OverrideTheme = {
				name = L['OverrideTheme'],
				type = 'toggle',
				order = 2,
				desc = L['TooltipOverrideDesc'],
				get = function(info)
					return SUI.DB.Tooltips.Override[SUI.DBMod.Artwork.Style]
				end,
				set = function(info, val)
					SUI.DB.Tooltips.Override[SUI.DBMod.Artwork.Style] = val
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
				desc = L['ColorOverlayDesc'],
				get = function(info)
					return SUI.DB.Tooltips.ColorOverlay
				end,
				set = function(info, val)
					SUI.DB.Tooltips.ColorOverlay = val
					module:UpdateBG()
				end
			},
			SuppressNoMatch = {
				name = 'Suppress no rule match error',
				type = 'toggle',
				order = 11,
				desc = L['ColorOverlayDesc'],
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
			name = 'Display Location ' .. v,
			type = 'group',
			inline = true,
			order = k + 20.1,
			width = 'full',
			args = {
				Condition = {
					name = 'Condition',
					type = 'select',
					order = k + 20.2,
					values = {
						['Group'] = 'In a Group',
						['Raid'] = 'In a Raid Group',
						['Instance'] = 'In a instance',
						['All'] = 'All the time',
						['Disabled'] = 'Disabled'
					},
					get = function(info)
						return SUI.DB.Tooltips[v].Status
					end,
					set = function(info, val)
						SUI.DB.Tooltips[v].Status = val
					end
				},
				Combat = {
					name = 'only if in combat',
					type = 'toggle',
					order = k + 20.3,
					get = function(info)
						return SUI.DB.Tooltips[v].Combat
					end,
					set = function(info, val)
						SUI.DB.Tooltips[v].Combat = val
					end
				},
				OnMouse = {
					name = 'Display on mouse?',
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
				OverrideTheme = {
					name = L['OverrideTheme'],
					type = 'toggle',
					order = k + 20.5,
					get = function(info)
						return SUI.DB.Tooltips[v].OverrideLoc
					end,
					set = function(info, val)
						SUI.DB.Tooltips[v].OverrideLoc = val
					end
				},
				MoveAnchor = {
					name = 'Move anchor',
					type = 'execute',
					order = k + 20.6,
					width = 'half',
					func = function(info, val)
						module[v].anchor:Show()
					end
				},
				ResetAnchor = {
					name = 'Reset anchor',
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
end

function module:HideOptions()
	SUI.opt.args['ModSetting'].args['Tooltips'].disabled = true
end
