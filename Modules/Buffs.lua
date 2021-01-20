local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Component_Buffs')
----------------------------------------------------------------------------------------------------
local RuleList = {'Rule1', 'Rule2', 'Rule3'}
local BuffWatcher = CreateFrame('Frame')

function module:OnInitialize()
	if SUI.DB.Buffs == nil then
		SUI.DB.Buffs = {Override = {}}
	end

	if SUI.DB.Buffs.Rule1 == nil then
		for _, v in ipairs(RuleList) do
			SUI.DB.Buffs[v] = {
				Status = 'Disabled',
				Combat = false,
				OverrideLoc = false,
				offset = 0,
				Anchor = {Moved = false, AnchorPos = {}}
			}
		end
	end
end

local function ActiveRule()
	for _, v in ipairs(RuleList) do
		if SUI.DB.Buffs[v].Status ~= 'Disabled' then
			local CombatRule = false
			if InCombatLockdown() and SUI.DB.Buffs[v].Combat then
				CombatRule = true
			elseif not InCombatLockdown() and not SUI.DB.Buffs[v].Combat then
				CombatRule = true
			end

			if SUI.DB.Buffs[v].Status == 'Group' and (IsInGroup() and not IsInRaid()) and CombatRule then
				return v
			elseif SUI.DB.Buffs[v].Status == 'Raid' and IsInRaid() and CombatRule then
				return v
			elseif SUI.DB.Buffs[v].Status == 'Instance' and IsInInstance() then
				return v
			elseif SUI.DB.Buffs[v].Status == 'All' and CombatRule then
				return v
			end
		end
	end

	--Failback of Rule1
	return 'Rule1'
end

local BuffPosUpdate = function()
	BuffFrame:ClearAllPoints()
	BuffFrame:SetParent(UIParent)
	BuffFrame:SetFrameStrata('MEDIUM')
	local setdefault = false

	--See If the theme has an anchor and if we are allowed to use it
	local style = SUI:GetModule('Style_' .. (SUI.DB.Artwork.Style or 'War'), true)
	if style and style.BuffLoc and not SUI.DB.Buffs[ActiveRule()].OverrideLoc then
		style:BuffLoc(nil, nil)
	else
		if SUI.DB.Buffs[ActiveRule()].Anchor.Moved then
			local Anchors = {}
			for key, val in pairs(SUI.DB.Buffs[ActiveRule()].Anchor.AnchorPos) do
				Anchors[key] = val
			end

			if Anchors.point == nil then
				--Error Catch
				setdefault = true
				SUI.DB.Buffs[ActiveRule()].Anchor.Moved = false
			else
				--Set the Buff location
				BuffFrame:SetPoint(Anchors.point, UIParent, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
			end
		else
			setdefault = true
		end
	end

	if setdefault then
		BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
	end
end

function module:OnEnable()
	if SUI.DB.DisabledComponents.Buffs then
		return
	end
	module:BuildOptions()

	BuffWatcher:SetScript('OnEvent', BuffPosUpdate)
	BuffWatcher:RegisterEvent('ZONE_CHANGED')
	BuffWatcher:RegisterEvent('ZONE_CHANGED_INDOORS')
	BuffWatcher:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	BuffWatcher:RegisterEvent('PLAYER_ENTERING_WORLD')
	BuffWatcher:RegisterEvent('PLAYER_REGEN_DISABLED')
	BuffWatcher:RegisterEvent('PLAYER_REGEN_ENABLED')
	BuffWatcher:RegisterEvent('UNIT_AURA')
	BuffWatcher:RegisterEvent('COMBAT_LOG_EVENT')
	BuffWatcher:RegisterEvent('GROUP_JOINED')
	BuffWatcher:RegisterEvent('GROUP_ROSTER_UPDATE')
	BuffWatcher:RegisterEvent('RAID_INSTANCE_WELCOME')
	BuffWatcher:RegisterEvent('ENCOUNTER_START')
	BuffWatcher:RegisterEvent('ENCOUNTER_END')

	--The Frame is not ready to be moved yet, wait a second first.
	C_Timer.After(1, BuffPosUpdate)

	for k, v in ipairs(RuleList) do
		local anchor = CreateFrame('Frame', nil)
		anchor:SetSize(150, 25)
		anchor:EnableMouse(enable)
		anchor.bg = anchor:CreateTexture(nil, 'OVERLAY')
		anchor.bg:SetAllPoints(anchor)
		anchor.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		anchor.bg:SetAlpha(0.9)
		anchor.lbl = anchor:CreateFontString(nil, 'OVERLAY')
		anchor.lbl:SetFont(SUI:GetFontFace(), 10)
		anchor.lbl:SetText('Anchor for Rule ' .. k)
		anchor.lbl:SetAllPoints(anchor)

		anchor:SetScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' then
					SUI.DB.Buffs[v].Anchor.Moved = true
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
					SUI.DB.Buffs[v].Anchor.AnchorPos[k] = val
				end
				BuffPosUpdate()
			end
		)

		anchor:SetScript(
			'OnShow',
			function(self)
				if SUI.DB.Buffs[v].Anchor.Moved then
					local Anchors = {}
					for key, val in pairs(SUI.DB.Buffs[v].Anchor.AnchorPos) do
						Anchors[key] = val
					end
					self:ClearAllPoints()
					self:SetPoint(Anchors.point, UIParent, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
				else
					self:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -140, -10)
				end
			end
		)

		anchor:SetScript(
			'OnEvent',
			function(self, event, ...)
				self:Hide()
				BuffPosUpdate()
			end
		)
		anchor:RegisterEvent('PLAYER_REGEN_DISABLED')

		module[v] = {anchor = anchor}
		module[v].anchor:Hide()
	end
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['Buffs'] = {
		type = 'group',
		name = L['Buffs'],
		args = {}
	}

	for k, v in ipairs(RuleList) do
		SUI.opt.args['ModSetting'].args['Buffs'].args['DisplayLocation' .. v] = {
			name = L['Display Location'] .. ' ' .. v,
			type = 'group',
			inline = true,
			order = k + 20.1,
			width = 'full',
			args = {
				Condition = {
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
					get = function(info)
						return SUI.DB.Buffs[v].Status
					end,
					set = function(info, val)
						SUI.DB.Buffs[v].Status = val
						BuffPosUpdate()
					end
				},
				Combat = {
					name = L['Only in combat'],
					type = 'toggle',
					order = k + 20.3,
					get = function(info)
						return SUI.DB.Buffs[v].Combat
					end,
					set = function(info, val)
						SUI.DB.Buffs[v].Combat = val
						BuffPosUpdate()
					end
				},
				OverrideTheme = {
					name = L['Override theme'],
					type = 'toggle',
					order = k + 20.5,
					get = function(info)
						return SUI.DB.Buffs[v].OverrideLoc
					end,
					set = function(info, val)
						SUI.DB.Buffs[v].OverrideLoc = val
						BuffPosUpdate()
					end
				},
				MoveAnchor = {
					name = L['Move anchor'],
					type = 'execute',
					order = k + 20.6,
					width = 'half',
					func = function(info, val)
						module[v].anchor:Show()
					end
				},
				ResetAnchor = {
					name = L['Reset anchor'],
					type = 'execute',
					order = k + 20.7,
					width = 'half',
					func = function(info, val)
						SUI.DB.Buffs[v].Anchor.Moved = false
						BuffPosUpdate()
					end
				}
			}
		}
	end
end
