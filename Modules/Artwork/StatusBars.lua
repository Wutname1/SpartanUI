local SUI, L = SUI, SUI.L
---@class SUI.Module.Artwork.StatusBars : SUI.Module
local module = SUI:NewModule('Artwork.StatusBars')
module.bars = {}
local DB ---@type SUI.StatusBars.DB

local Enums = {
	Bars = {
		None = -1,
		Reputation = 1,
		Honor = 2,
		Artifact = 3,
		Experience = 4,
		Azerite = 5,
	},
	TextDisplayMode = {
		OnMouseOver = 0,
		Always = 1,
		Never = 2,
	},
}

local BarLabels = {
	[Enums.Bars.Azerite] = 'Azerite',
	[Enums.Bars.Reputation] = 'Reputation',
	[Enums.Bars.Honor] = 'Honor',
	[Enums.Bars.Artifact] = 'Artifact',
	[Enums.Bars.Experience] = 'Experience',
}

---@class SUI.StatusBars.DB
local DBDefaults = {
	AllowRep = true,
	PriorityDirection = 'ltr',
	BarPriorities = {
		[Enums.Bars.Azerite] = 0,
		[Enums.Bars.Reputation] = 1,
		[Enums.Bars.Honor] = 2,
		[Enums.Bars.Artifact] = 3,
		[Enums.Bars.Experience] = 4,
	},
	bars = {
		['**'] = {
			ToolTip = 'hover',
			text = Enums.TextDisplayMode.OnMouseOver,
			alpha = 1,
		},
	},
}

function module:OnInitialize()
	module.Database = SUI.SpartanUIDB:RegisterNamespace('StatusBars', { profile = DBDefaults })
	DB = module.Database.profile
end

function module:OnEnable()
	module:factory()
	module:BuildOptions()
end

local GetFactionDetails = function(name)
	if not name then return end
	local description = ' '
	for i = 1, C_Reputation.GetNumFactions() do
		local factionData = C_Reputation.GetFactionDataByIndex(i)
		if name == factionData.name then description = factionData.description end
	end
	return description
end

local showXPTooltip = function(self)
	local xptip1 = string.gsub(EXHAUST_TOOLTIP1, '\n', ' ') -- %s %d%% of normal experience gained from monsters.
	local XP_LEVEL_TEMPLATE = '( %s / %s ) %d%% ' .. COMBAT_XP_GAIN -- use Global Strings and regex to make the level string work in any locale
	local xprest = TUTORIAL_TITLE26 .. ' (%d%%) -' -- Rested (%d%%) -
	local a = format('Level %s ', UnitLevel('player'))
	local b = format(XP_LEVEL_TEMPLATE, SUI.Font:comma_value(UnitXP('player')), SUI.Font:comma_value(UnitXPMax('player')), (UnitXP('player') / UnitXPMax('player') * 100))
	self.tooltip.TextFrame.HeaderText:SetText(a .. b) -- Level 99 (9999 / 9999) 100% Experience
	local rested, text = GetXPExhaustion() or 0, ''
	if rested > 0 then
		text = format(xptip1, format(xprest, (rested / UnitXPMax('player')) * 100), 200)
		self.tooltip.TextFrame.MainText:SetText(text) -- Rested (15%) - 200% of normal experience gained from monsters.
	else
		self.tooltip.TextFrame.MainText:SetText(format(xptip1, EXHAUST_TOOLTIP2, 100)) -- You should rest at an Inn. 100% of normal experience gained from monsters.
	end
	self.tooltip:Show()
end

local showRepTooltip = function(self)
	local watchedFactionData = C_Reputation.GetWatchedFactionData()
	if not watchedFactionData or watchedFactionData.factionID == 0 then return end
	local factionID = watchedFactionData.factionID

	local factionStandingtext
	local factionData = C_Reputation.GetFactionDataByID(factionID)
	local reputationInfo = C_GossipInfo.GetFriendshipReputation(factionID)
	if reputationInfo and reputationInfo.friendshipFactionID > 0 then
		factionStandingtext = reputationInfo.reaction
	elseif C_Reputation.IsMajorFaction(factionID) then
		factionStandingtext = MAJOR_FACTION_MAX_RENOWN_REACHED
	else
		local gender = UnitSex('player')
		factionStandingtext = GetText('FACTION_STANDING_LABEL' .. factionData.reaction, gender)
	end
	local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID)

	local low = watchedFactionData.currentReactionThreshold or 0
	local high = threshold or watchedFactionData.nextReactionThreshold or 1
	local current = currentValue or watchedFactionData.currentStanding or 1
	local repLevelLow = (current - low) or 0
	local repLevelHigh = (high - low) or 1
	local percentage

	if watchedFactionData.name then
		local text = GetFactionDetails(watchedFactionData.name)
		if repLevelHigh == 0 then
			percentage = 100
		else
			percentage = (repLevelLow / repLevelHigh) * 100
		end
		self.tooltip.TextFrame.HeaderText:SetText(
			format('%s ( %s / %s ) %d%% %s', watchedFactionData.name, SUI.Font:comma_value(repLevelLow), SUI.Font:comma_value(repLevelHigh), percentage, factionStandingtext)
		)
		self.tooltip.TextFrame.MainText:SetText('|cffffd200' .. text .. '|r')
		self.tooltip:Show()
	else
		self.tooltip.TextFrame.HeaderText:SetText(REPUTATION)
		self.tooltip.TextFrame.MainText:SetText(REPUTATION_STANDING_DESCRIPTION)
	end
end

local showHonorTooltip = function(self)
	local honorLevel = UnitHonorLevel('player')
	local currentHonor = UnitHonor('player')
	local maxHonor = UnitHonorMax('player')

	if currentHonor == 0 and maxHonor == 0 then
		return -- If something odd happened and both values are 0 don't show anything
	end

	self.tooltip.TextFrame.HeaderText:SetFormattedText(HONOR_LEVEL_LABEL, honorLevel)
	self.tooltip.TextFrame.MainText:SetFormattedText('( %s / %s ) %d%%', SUI.Font:comma_value(currentHonor), SUI.Font:comma_value(maxHonor), ((currentHonor / maxHonor) * 100))

	self.tooltip:Show()
end

function module:factory()
	local barManager = CreateFrame('Frame', 'SUI_StatusBar_Manager', SpartanUI)
	-- barManager.barContainers = {}
	--Setup Actions
	for k, v in pairs(StatusTrackingManagerMixin) do
		barManager[k] = v
	end

	barManager:SetScript('OnLoad', barManager.OnLoad)
	barManager:SetScript('OnEvent', barManager.OnEvent)

	--Override UpdateBarsShown
	barManager.UpdateBarsShown = function(self)
		local function onFinishedAnimating(barContainer)
			barContainer:UnsubscribeFromOnFinishedAnimating(self)
			self:UpdateBarsShown()
		end

		-- If any bar is animating then wait for that animation to end before updating shown bars
		for i, barContainer in ipairs(self.barContainers) do
			if barContainer:IsAnimating() then
				barContainer:SubscribeToOnFinishedAnimating(self, onFinishedAnimating)
				return
			end
		end

		-- Determine what bars should be shown
		local newBarIndicesToShow = {}

		for _, barIndex in pairs(Enums.Bars) do
			if barIndex == Enums.Bars.Reputation and DB.AllowRep and self:CanShowBar(barIndex) then
				table.insert(newBarIndicesToShow, barIndex)
			elseif self:CanShowBar(barIndex) then
				table.insert(newBarIndicesToShow, barIndex)
			end
		end
		table.sort(newBarIndicesToShow, function(left, right)
			return self:GetBarPriority(left) > self:GetBarPriority(right)
		end)

		-- We can only show as many bars as we have containers for
		while #newBarIndicesToShow > #self.barContainers do
			table.remove(newBarIndicesToShow, #newBarIndicesToShow)
		end

		-- Assign the bar indices to the bar containers
		for i = 1, #self.barContainers do
			local barContainer = self.barContainers[i]
			local newBarIndex = newBarIndicesToShow[i] or Enums.Bars.None
			local oldBarIndex = self.shownBarIndices[i]

			if newBarIndex ~= oldBarIndex then
				-- If the bar being shown in this container is already being shown in another container then
				-- make both containers fade out fully before actually assigning the new bars.
				-- This will lead to the bars fading in together rather than staggering.
				if (newBarIndex ~= Enums.Bars.None and tContains(self.shownBarIndices, newBarIndex)) or (oldBarIndex ~= Enums.Bars.None and tContains(newBarIndicesToShow, oldBarIndex)) then
					newBarIndex = Enums.Bars.None
					barContainer:SubscribeToOnFinishedAnimating(self, onFinishedAnimating)
				end
			end

			barContainer:SetShownBar(newBarIndex)
		end

		self.shownBarIndices = newBarIndicesToShow
	end
	--Override GetBarPriority
	barManager.GetBarPriority = function(self, barIndex)
		return DB.BarPriorities[barIndex] or -1
	end

	for i, key in ipairs({ 'Left', 'Right' }) do
		local StyleSetting = SUI.DB.Styles[SUI.DB.Artwork.Style].StatusBars[key]

		--Status Bar
		local barContainer = CreateFrame('Frame', 'SUI_StatusBar_' .. key, barManager, 'StatusTrackingBarContainerTemplate')

		local width, height = unpack(StyleSetting.size)

		barContainer.BarFrameTexture:Hide()

		barContainer:SetSize(unpack(StyleSetting.size))
		barContainer:SetFrameStrata('LOW')
        barContainer:SetFrameLevel(20)
		
		--loop over the bars and set the sizes
		for _, bar in pairs(barContainer.bars) do
			bar:SetSize(width - 30, height - 5)
			bar.StatusBar:SetSize(width - 30, height - 5)
			bar:ClearAllPoints()
			bar:SetPoint('BOTTOM', barContainer, 'BOTTOM', 0, 0)
			bar:SetUsingParentLevel(false)
			bar:SetFrameLevel(barContainer:GetFrameLevel() - 5)

			-- Text
			SUI.Font:Format(bar.OverlayFrame.Text, StyleSetting.Font or 10, 'StatusBars')
			if DB.bars[i].text == Enums.TextDisplayMode.Always then
				bar.OverlayFrame.Text:Show()
			else
				bar.OverlayFrame.Text:Hide()
			end

			bar.UpdateTextVisibility = function(self)
				-- self:SetFrameLevel(barContainer:GetFrameLevel() - 5)
				local blizzMode = self:ShouldBarTextBeDisplayed()
				self.OverlayFrame.Text:SetShown(DB.bars[i].text == Enums.TextDisplayMode.Always and blizzMode)
			end

			--Setup OnMouseOver
			bar:HookScript('OnEnter', function()
				if DB.bars[i].text == Enums.TextDisplayMode.OnMouseOver then bar.OverlayFrame.Text:Show() end
			end)
			bar:HookScript('OnLeave', function()
				if DB.bars[i].text == Enums.TextDisplayMode.OnMouseOver then bar.OverlayFrame.Text:Hide() end
			end)
		end

		--Theme image overlay
		barContainer.bg = barContainer:CreateTexture(nil, 'BACKGROUND')
		barContainer.bg:SetTexture(StyleSetting.bgImg or '')
		barContainer.bg:SetAllPoints(barContainer)
		barContainer.bg:SetTexCoord(unpack(StyleSetting.texCords))

		barContainer.overlay = barContainer:CreateTexture(nil, 'OVERLAY')
		barContainer.overlay:SetTexture(StyleSetting.bgImg)
		barContainer.overlay:SetAllPoints(barContainer.bg)
		barContainer.overlay:SetTexCoord(unpack(StyleSetting.texCords))

		barContainer.settings = StyleSetting
		barContainer.i = i

		module.bars[key] = barContainer

		--Position
		local point, anchor, secondaryPoint, x, y = strsplit(',', StyleSetting.Position)
		barContainer:ClearAllPoints()
		barContainer:SetPoint(point, anchor, secondaryPoint, x, y)
		barContainer:SetAlpha(DB.bars[i].alpha or 1)

		-- Hide with SpartanUI
		SpartanUI:HookScript('OnHide', function()
			barContainer:Hide()
		end)
		SpartanUI:HookScript('OnShow', function()
			barContainer:Show()
		end)
	end

	barManager:OnLoad()
end

function module:BuildOptions()
	-- Build Holder
	SUI.opt.args['Artwork'].args['StatusBars'] = {
		name = L['Status bars'],
		type = 'group',
		args = {
			IsWatchingHonorAsXP = {
				name = 'Enable Honor bar',
				type = 'toggle',
				order = 2,
				get = function()
					return GetCVarBool('showHonorAsExperience')
				end,
				set = function(_, value)
					SetCVar('showHonorAsExperience', value)
				end,
			},
			EnableReputation = {
				name = 'Enable Reputation',
				type = 'toggle',
				order = 3,
				get = function()
					return DB.AllowRep
				end,
				set = function(_, value)
					DB.AllowRep = value
				end,
			},
			PriorityDirection = {
				name = 'Priority Direction',
				type = 'select',
				order = 4,
				values = {
					['ltr'] = 'Left to Right',
					['rtl'] = 'Right to Left',
				},
				get = function()
					return DB.PriorityDirection
				end,
				set = function(_, value)
					DB.PriorityDirection = value
				end,
			},
			Font = {
				name = 'Font Settings',
				type = 'group',
				order = 90,
				inline = true,
				get = function(info)
					return SUI.Font.DB.Modules.StatusBars[info[#info]]
				end,
				set = function(info, val)
					SUI.Font.DB.Modules.StatusBars[info[#info]] = val
					SUI.Font:Refresh('StatusBars')
				end,
				args = {
					Face = {
						type = 'select',
						name = L['Font face'],
						order = 1,
						dialogControl = 'LSM30_Font',
						values = SUI.Lib.LSM:HashTable('font'),
					},
					Type = {
						name = L['Font style'],
						type = 'select',
						order = 2,
						values = {
							['normal'] = L['Normal'],
							['monochrome'] = L['Monochrome'],
							['outline'] = L['Outline'],
							['thickoutline'] = L['Thick outline'],
						},
					},
					Size = {
						name = L['Adjust font size'],
						type = 'range',
						order = 3,
						width = 'double',
						min = -15,
						max = 15,
						step = 1,
					},
				},
			},
			BarPriorities = {
				name = 'Bar Priorities',
				type = 'group',
				order = 100,
				inline = true,
				args = {},
			},
		},
	}

	-- Build Bar Priorities
	for i, v in pairs(DB.BarPriorities) do
		SUI.opt.args['Artwork'].args['StatusBars'].args.BarPriorities.args[BarLabels[i]] = {
			name = '',
			type = 'group',
			order = v,
			args = {
				label = {
					type = 'description',
					width = 'double',
					fontSize = 'medium',
					order = 1,
					name = BarLabels[i],
				},
				up = {
					type = 'execute',
					name = 'Up',
					width = 'half',
					order = 2,
					disabled = function(info)
						--If wea re at the top, disable the button
						return DB.BarPriorities[Enums.Bars[info[#info - 1]]] == 0
					end,
					func = function(info)
						local myName = info[#info - 1]
						local currentPriority = DB.BarPriorities[Enums.Bars[myName]]

						--Find the next highest priority
						local newspot = currentPriority - 1
						for k, j in pairs(DB.BarPriorities) do
							if j == newspot then
								DB.BarPriorities[k] = currentPriority
								DB.BarPriorities[Enums.Bars[myName]] = j
								--Swap the order on the options
								SUI.opt.args['Artwork'].args['StatusBars'].args.BarPriorities.args[myName].order = newspot
								SUI.opt.args['Artwork'].args['StatusBars'].args.BarPriorities.args[BarLabels[k]].order = currentPriority
							end
						end
					end,
				},
				down = {
					type = 'execute',
					name = 'Down',
					width = 'half',
					order = 3,
					disabled = function(info)
						--If we are at the bottom, disable the button
						return DB.BarPriorities[Enums.Bars[info[#info - 1]]] == #DB.BarPriorities - 1
					end,
					func = function(info)
						local myName = info[#info - 1]
						local currentPriority = DB.BarPriorities[Enums.Bars[myName]]

						--Find the next lowest priority
						local newspot = currentPriority + 1
						for k, j in pairs(DB.BarPriorities) do
							if j == newspot then
								DB.BarPriorities[k] = currentPriority
								DB.BarPriorities[Enums.Bars[myName]] = j
								--Swap the order on the options
								SUI.opt.args['Artwork'].args['StatusBars'].args.BarPriorities.args[myName].order = newspot
								SUI.opt.args['Artwork'].args['StatusBars'].args.BarPriorities.args[BarLabels[k]].order = currentPriority
							end
						end
					end,
				},
			},
		}
	end
end
