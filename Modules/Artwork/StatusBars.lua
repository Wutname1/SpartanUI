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
		HouseFavor = 6,
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
	[Enums.Bars.HouseFavor] = 'Housing',
}

---@class SUI.StatusBars.DB
local DBDefaults = {
	AllowRep = true,
	PriorityDirection = 'ltr',
	BarPriorities = {
		[Enums.Bars.Experience] = 0,
		[Enums.Bars.Reputation] = 1,
		[Enums.Bars.Honor] = 3,
		[Enums.Bars.Azerite] = 4,
		[Enums.Bars.Artifact] = 5,
		[Enums.Bars.HouseFavor] = 6,
	},
	bars = {
		['**'] = {
			ToolTip = 'hover',
			text = Enums.TextDisplayMode.OnMouseOver,
			alpha = 1,
			enabled = true,
			showTooltip = true,
		},
	},
}

---@class SUI.Style.Settings.StatusBars.Storage
---@field Left SUI.Style.Settings.StatusBars
---@field Right SUI.Style.Settings.StatusBars

---@class SUI.Style.Settings.StatusBars
---@field bgTexture? string
local StyleSettingsBase = {
	size = { 400, 15 },
	alpha = 1,
	MaxWidth = 0,
	texCords = { 0, 1, 0, 1 },
	tooltip = {
		texture = 'Interface\\Addons\\SpartanUI\\Images\\status-tooltip',
		textureCoords = { 0.103515625, 0.8984375, 0.1796875, 0.8203125 },
		size = { 300, 100 },
		textAreaSize = { 200, 60 },
		statusBarAnchor = 'TOP',
	},
	Position = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOM,-100,0',
}

local StyleSetting = {
	base = {
		Left = {
			Position = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOM,-100,0',
		},
		Right = {
			Position = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOM,100,0',
		},
	},
	skinsettings = {},
}
---Copy Base into left and right
for k, v in pairs(StyleSetting.base) do
	StyleSetting[k] = SUI:CopyData(v, StyleSettingsBase)
end

---@param ContainerKey string
---@return SUI.Style.Settings.StatusBars
local function GetStyleSettings(ContainerKey)
	if StyleSetting.skinsettings[SUI.DB.Artwork.Style] then
		return SUI:CopyData(StyleSetting.skinsettings[SUI.DB.Artwork.Style][ContainerKey], StyleSetting[ContainerKey])
	else
		return StyleSetting[ContainerKey]
	end
end

---@param style string
---@param settings SUI.Style.Settings.StatusBars.Storage
function module:RegisterStyle(style, settings)
	StyleSetting.skinsettings[style] = settings
end

function module:GetExperienceTooltipText()
	local currentXP = UnitXP('player')
	local maxXP = UnitXPMax('player')
	local restedXP = GetXPExhaustion() or 0
	local level = UnitLevel('player')
	local questLogXP = GetQuestLogRewardXP()

	GameTooltip:AddDoubleLine(L['Experience'], string.format('(Level %d)', level))
	GameTooltip:AddDoubleLine(L['Remaining:'], string.format('%s (%.2f%%)', BreakUpLargeNumbers(maxXP - currentXP), ((maxXP - currentXP) / maxXP) * 100), 1, 1, 1)

	if currentXP then
		GameTooltip:AddLine(' ')
		GameTooltip:AddDoubleLine(L['XP'], string.format('%s / %s (%.2f%%)', BreakUpLargeNumbers(currentXP), BreakUpLargeNumbers(maxXP), (currentXP / maxXP) * 100), 1, 1, 1)
	end
	if questLogXP > 0 then GameTooltip:AddDoubleLine(L['Quest Log XP:'], string.format('Quest Log XP: %s (%.2f%%)', BreakUpLargeNumbers(questLogXP), (questLogXP / maxXP) * 100), 1, 1, 1) end
	if restedXP > 0 then GameTooltip:AddDoubleLine(L['Rested:'], string.format('Rested: +%s (%.2f%%)', BreakUpLargeNumbers(restedXP), (restedXP / maxXP) * 100), 1, 1, 1) end
end

function module:GetReputationTooltipText()
	local data = C_Reputation.GetWatchedFactionData()
	if not data then return end

	GameTooltip:AddLine(data.name)
	GameTooltip:AddLine(' ')

	local friendshipInfo = C_GossipInfo.GetFriendshipReputation(data.factionID)
	local isMajorFaction = C_Reputation.IsMajorFaction(data.factionID)

	if friendshipInfo and friendshipInfo.friendshipFactionID > 0 then
		-- Friendship reputation
		GameTooltip:AddDoubleLine(STANDING .. ':', friendshipInfo.reaction, 1, 1, 1)
		if friendshipInfo.nextThreshold then
			local current = friendshipInfo.standing - (friendshipInfo.reactionThreshold or 0)
			local total = friendshipInfo.nextThreshold - (friendshipInfo.reactionThreshold or 0)
			GameTooltip:AddDoubleLine(REPUTATION .. ':', string.format('%d / %d (%d%%)', current, total, (current / total) * 100), 1, 1, 1)
		end
	elseif isMajorFaction then
		-- Major faction (Dragonflight renown system)
		local majorFactionData = C_MajorFactions.GetMajorFactionData(data.factionID)
		local renownLevel = majorFactionData.renownLevel
		local renownReputationEarned = majorFactionData.renownReputationEarned
		local renownLevelThreshold = majorFactionData.renownLevelThreshold

		GameTooltip:AddDoubleLine(RENOWN_LEVEL_LABEL, renownLevel, BLUE_FONT_COLOR.r, BLUE_FONT_COLOR.g, BLUE_FONT_COLOR.b)
		GameTooltip:AddDoubleLine(REPUTATION .. ':', string.format('%d / %d (%d%%)', renownReputationEarned, renownLevelThreshold, (renownReputationEarned / renownLevelThreshold) * 100), 1, 1, 1)
	else
		-- Standard reputation
		local standingText = _G['FACTION_STANDING_LABEL' .. data.reaction] or UNKNOWN
		GameTooltip:AddDoubleLine(STANDING .. ':', standingText, 1, 1, 1)

		if data.reaction < 8 then -- Not at max standing
			local current = data.currentStanding - data.currentReactionThreshold
			local total = data.nextReactionThreshold - data.currentReactionThreshold
			GameTooltip:AddDoubleLine(REPUTATION .. ':', string.format('%d / %d (%d%%)', current, total, (current / total) * 100), 1, 1, 1)
		end
	end

	-- Paragon reputation (if applicable)
	if C_Reputation.IsFactionParagon(data.factionID) then
		local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(data.factionID)
		local current = currentValue % threshold
		GameTooltip:AddDoubleLine(L['Paragon'] .. ':', string.format('%d / %d (%d%%)', current, threshold, (current / threshold) * 100), 1, 1, 1)
		if hasRewardPending then GameTooltip:AddLine(L['Reward Available'], 0, 1, 0) end
	end
end

function module:GetHonorTooltipText()
	local honorLevel = UnitHonorLevel('player')
	local currentHonor = UnitHonor('player')
	local maxHonor = UnitHonorMax('player')

	if currentHonor == 0 and maxHonor == 0 then
		return -- If something odd happened and both values are 0 don't show anything
	end

	GameTooltip:AddLine(HONOR)
	GameTooltip:AddLine(' ')

	-- Current Honor Level
	GameTooltip:AddDoubleLine(
		HONOR_LEVEL_LABEL:format(honorLevel),
		string.format('%s / %s (%d%%)', BreakUpLargeNumbers(currentHonor), BreakUpLargeNumbers(maxHonor), ((currentHonor / maxHonor) * 100)),
		NORMAL_FONT_COLOR.r,
		NORMAL_FONT_COLOR.g,
		NORMAL_FONT_COLOR.b,
		1,
		1,
		1
	)

	-- Next Honor Level Reward
	local nextHonorLevelForReward = C_PvP.GetNextHonorLevelForReward(honorLevel)
	if nextHonorLevelForReward then
		local nextRewardInfo = C_PvP.GetHonorRewardInfo(nextHonorLevelForReward)
		if nextRewardInfo then
			GameTooltip:AddLine(' ')
			GameTooltip:AddDoubleLine(L['Next Honor Reward'], string.format(L['Level %d'], nextHonorLevelForReward), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, 1, 1)
			local rewardItemID = C_AchievementInfo.GetRewardItemID(nextRewardInfo.achievementRewardedID)
			if rewardItemID then GameTooltip:AddDoubleLine('|---', C_Item.GetItemNameByID(rewardItemID), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, 1, 1) end
		end
	end

	local brackets = {
		[1] = L['2v2'],
		[2] = L['3v3'],
		[3] = L['Solo Shuffle'],
		[4] = L['Rated Battleground'],
	}
	local hasRating = false
	local function AddPVPRatings()
		-- Arena Scores
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(L['PvP Ratings:'], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	end
	for i, bracketName in ipairs(brackets) do
		local rating, seasonBest = GetPersonalRatedInfo(i)
		if rating > 0 then
			if not hasRating then
				AddPVPRatings()
				hasRating = true
			end
			GameTooltip:AddDoubleLine(bracketName, string.format('%d (%d)', rating, seasonBest), 1, 1, 1, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		end
	end
end

function module:GetHouseFavorTooltipText(bar)
	-- Check if C_Housing API is available
	if not C_Housing then return end

	-- Get the tracked house GUID
	local trackedHouseGUID = C_Housing.GetTrackedHouseGuid()
	if not trackedHouseGUID then return end

	-- Try to get house level from the bar's stored data first
	local houseLevel, houseFavor, houseFavorNeeded

	if bar and bar.houseLevelFavor then
		-- Use data stored on the bar (similar to Blizzard's implementation)
		houseLevel = bar.houseLevelFavor.houseLevel or 1
		local currentFavor = bar.houseLevelFavor.houseFavor or 0
		local minBarFavor = C_Housing.GetHouseLevelFavorForLevel(houseLevel) or 0
		local maxBarFavor = C_Housing.GetHouseLevelFavorForLevel(houseLevel + 1) or 1
		houseFavor = currentFavor - minBarFavor
		houseFavorNeeded = maxBarFavor - minBarFavor
	else
		-- Fallback: try to get from bar values directly
		if bar and bar.StatusBar then
			local current = bar.StatusBar:GetValue()
			local min, max = bar.StatusBar:GetMinMaxValues()
			houseLevel = bar.level or 1
			houseFavor = current - min
			houseFavorNeeded = max - min
		else
			return
		end
	end

	if not houseLevel or not houseFavorNeeded then return end

	-- Use Blizzard's tooltip format
	if HOUSING_DASHBOARD_HOUSE_LEVEL then
		GameTooltip_AddNormalLine(GameTooltip, string.format(HOUSING_DASHBOARD_HOUSE_LEVEL, houseLevel))
	else
		GameTooltip_AddNormalLine(GameTooltip, string.format('House Level %d', houseLevel))
	end

	if HOUSING_DASHBOARD_NEIGHBORHOOD_FAVOR then
		GameTooltip_AddHighlightLine(GameTooltip, string.format(HOUSING_DASHBOARD_NEIGHBORHOOD_FAVOR, houseFavor, houseFavorNeeded))
	else
		GameTooltip_AddHighlightLine(GameTooltip, string.format('%d / %d', houseFavor, houseFavorNeeded))
	end

	if HOUSING_DASHBOARD_NEIGHBORHOOD_FAVOR_TOOLTIP then GameTooltip_AddHighlightLine(GameTooltip, HOUSING_DASHBOARD_NEIGHBORHOOD_FAVOR_TOOLTIP) end
end

function module:OnInitialize()
	module.Database = SUI.SpartanUIDB:RegisterNamespace('StatusBars', { profile = DBDefaults })
	DB = module.Database.profile

	-- Migrate old settings
	if SUI.DB.StatusBars then
		-- Check if old bar was set to honor
		for i = 1, 2 do
			if SUI.DB.StatusBars and SUI.DB.StatusBars[i] and SUI.DB.StatusBars[i].display == 'honor' then SetCVar('showHonorAsExperience', 1) end
		end
		-- Remove old settings
		SUI.DB.StatusBars = nil
	end
end

function module:OnEnable()
	module:factory()
	module:BuildOptions()
end

function module:factory()
	local barManager = self:CreateBarManager()
	self:CreateBarContainers(barManager)
	barManager:OnLoad()
end

function module:UpdateBars()
	local barManager = _G['SUI_StatusBar_Manager']
	if barManager then
		-- Update the shown bars
		barManager:UpdateBarsShown()

		-- Update text visibility for both containers
		self:UpdateBarTextVisibility('Left')
		self:UpdateBarTextVisibility('Right')

		-- Update container alphas and visibility
		for _, key in ipairs({ 'Left', 'Right' }) do
			local barContainer = module.bars[key]
			if barContainer then
				if DB.bars[key].enabled then
					-- Check if this container actually has a bar to show
					local hasActiveBar = false
					for _, bar in pairs(barContainer.bars) do
						if bar:IsShown() and bar.barIndex and bar.barIndex ~= Enums.Bars.None then
							hasActiveBar = true
							break
						end
					end

					if hasActiveBar then
						barContainer:SetAlpha(DB.bars[key].alpha or 1)
						barContainer:Show()
					else
						barContainer:Hide()
					end
				else
					barContainer:Hide()
				end
			end
		end

		-- Refresh the options display
		self:RefreshBarPriorityOptions()
	end
end

function module:UpdateBarTextVisibility(containerKey)
	local barContainer = module.bars[containerKey]
	if not barContainer then return end

	local textMode = DB.bars[containerKey].text

	for _, bar in pairs(barContainer.bars) do
		if textMode == Enums.TextDisplayMode.Always then
			bar.OverlayFrame.Text:Show()
		else -- OnMouseOver
			bar.OverlayFrame.Text:Hide()
		end

		-- Update the bar's UpdateTextVisibility function
		bar.UpdateTextVisibility = function(self)
			local blizzMode = self:ShouldBarTextBeDisplayed()
			self.OverlayFrame.Text:SetShown(textMode == Enums.TextDisplayMode.Always and blizzMode)
		end
	end
end

function module:RefreshBarPriorityOptions()
	local options = SUI.opt.args['Artwork'].args['StatusBars'].args.BarPriorities.args
	for barIndex, priority in pairs(DB.BarPriorities) do
		local optionKey = BarLabels[barIndex]
		if options[optionKey] then options[optionKey].order = priority end
	end
end

function module:CreateBarManager()
	local barManager = CreateFrame('Frame', 'SUI_StatusBar_Manager', SpartanUI)
	for k, v in pairs(StatusTrackingManagerMixin) do
		barManager[k] = v
	end

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

		-- Check if containers are enabled and hide disabled ones
		for i, barContainer in ipairs(self.barContainers) do
			local containerKey = i == 1 and 'Left' or 'Right'
			if DB and DB.bars and not DB.bars[containerKey].enabled then barContainer:SetShownBar(Enums.Bars.None) end
		end

		-- Determine what bars should be shown
		local newBarIndicesToShow = {}
		for _, barIndex in pairs(Enums.Bars) do
			if (barIndex == Enums.Bars.Reputation and DB.AllowRep and self:CanShowBar(barIndex)) or (barIndex ~= Enums.Bars.Reputation and self:CanShowBar(barIndex)) then
				table.insert(newBarIndicesToShow, barIndex)
			end
		end

		-- Sort based on priority
		table.sort(newBarIndicesToShow, function(left, right)
			return self:GetBarPriority(left) < self:GetBarPriority(right)
		end)

		-- Filter out containers that are disabled
		local enabledContainers = {}
		for i, barContainer in ipairs(self.barContainers) do
			local containerKey = i == 1 and 'Left' or 'Right'
			if containerKey ~= nil and DB.bars[containerKey] ~= nil and DB.bars[containerKey].enabled then table.insert(enabledContainers, { container = barContainer, index = i }) end
		end

		-- We can only show as many bars as we have enabled containers for
		while #newBarIndicesToShow > #enabledContainers do
			table.remove(newBarIndicesToShow)
		end

		-- Assign the bar indices to the enabled bar containers
		for i = 1, #self.barContainers do
			local barContainer = self.barContainers[i]
			local containerKey = i == 1 and 'Left' or 'Right'
			local newBarIndex = Enums.Bars.None

			-- Only assign bars to enabled containers
			if DB.bars[containerKey].enabled then
				local enabledIndex = 0
				for j = 1, i do
					local checkKey = j == 1 and 'Left' or 'Right'
					if DB.bars[checkKey].enabled then enabledIndex = enabledIndex + 1 end
				end

				if #newBarIndicesToShow == 1 then
					-- Special case for single bar - show on first enabled container
					if enabledIndex == 1 then newBarIndex = newBarIndicesToShow[1] end
				else
					if DB.PriorityDirection == 'ltr' then
						newBarIndex = newBarIndicesToShow[enabledIndex] or Enums.Bars.None
					else
						newBarIndex = newBarIndicesToShow[#newBarIndicesToShow - enabledIndex + 1] or Enums.Bars.None
					end
				end
			end

			barContainer:SetShownBar(newBarIndex)
		end

		self.shownBarIndices = newBarIndicesToShow
	end

	barManager:SetScript('OnLoad', barManager.OnLoad)
	barManager:SetScript('OnEvent', barManager.OnEvent)

	barManager.GetBarPriority = function(self, barIndex)
		if not DB.BarPriorities then return 0 end -- Sometimes we get called before Initilize has been called. This is a safe guard.

		return DB.BarPriorities[barIndex] or 0
	end

	return barManager
end

function module:CreateBarContainers(barManager)
	for i, key in ipairs({ 'Left', 'Right' }) do
		local barContainer = self:CreateBarContainer(barManager, key, i)
		self:SetupBarContainerBehavior(barContainer, i)
		module.bars[key] = barContainer
	end
end

function module:CreateBarContainer(barManager, key, index)
	local barStyle = GetStyleSettings(key)
	local barContainer = CreateFrame('Frame', 'SUI_StatusBar_' .. key, barManager, 'StatusTrackingBarContainerTemplate')
	barContainer.barStyle = barStyle

	barContainer:SetSize(unpack(barStyle.size))
	barContainer:SetFrameStrata('LOW')
	barContainer:SetFrameLevel(20)

	-- Hide with SpartanUI
	SpartanUI:HookScript('OnHide', function()
		barContainer:Hide()
	end)
	SpartanUI:HookScript('OnShow', function()
		barContainer:Show()
	end)

	self:SetupBarContainerVisuals(barContainer, barStyle)
	self:SetupBarContainerPosition(barContainer, barStyle, index)
	self:SetupBarContainerMouseEvents(barContainer, index)

	-- Create MoveIt mover for this statusbar
	if SUI.MoveIt then
		-- Set dirtyWidth/dirtyHeight to match the visual statusbar size (with padding)
		barContainer.dirtyWidth = barStyle.size[1] - 30
		barContainer.dirtyHeight = barStyle.size[2] - 5
		SUI.MoveIt:CreateMover(barContainer, 'StatusBar_' .. key, key .. ' Status Bar', nil, 'StatusBars')
	end

	return barContainer
end

function module:SetupBarContainerVisuals(barContainer, barStyle)
	-- barContainer.BarFrameTexture:Hide()
	-- Create background
	barContainer.bg = barContainer:CreateTexture(nil, 'BACKGROUND')
	barContainer.bg:SetTexture(barStyle.bgTexture or '')
	barContainer.bg:SetAllPoints(barContainer)
	barContainer.bg:SetTexCoord(unpack(barStyle.texCords))
	if barStyle.bgTexture then
		barContainer.bg:Show()
	else
		barContainer.bg:Hide()
	end

	-- Create overlay
	barContainer.overlay = barContainer:CreateTexture(nil, 'OVERLAY')
	barContainer.overlay:SetTexture(barStyle.bgTexture or '')
	barContainer.overlay:SetAllPoints(barContainer.bg)
	barContainer.overlay:SetTexCoord(unpack(barStyle.texCords))
	if barStyle.bgTexture then
		barContainer.overlay:Show()
	else
		barContainer.overlay:Hide()
	end

	barContainer.settings = barStyle
end

function module:SetupBarContainerPosition(barContainer, barStyle, index)
	local point, anchor, secondaryPoint, x, y = strsplit(',', barStyle.Position)
	barContainer:ClearAllPoints()
	barContainer:SetPoint(point, anchor, secondaryPoint, x, y)
	local containerKey = index == 1 and 'Left' or 'Right'

	-- Set initial visibility and alpha based on enabled state
	-- Note: We start hidden and let UpdateBars() show containers that have content
	if DB.bars[containerKey].enabled then barContainer:SetAlpha(DB.bars[containerKey].alpha or 1) end
	barContainer:Hide() -- Start hidden, UpdateBars will show if there's content
end

function module:HandleBarOnEnter(bar, containerKey)
	-- Update HouseFavor text if needed
	if bar.barIndex == Enums.Bars.HouseFavor then
		-- Get current bar values
		local current = bar.StatusBar:GetValue()
		local min, max = bar.StatusBar:GetMinMaxValues()
		if max > min then
			local currentProgress = current - min
			local totalLevelXP = max - min
			local houseLevel = bar.level or (bar.houseLevelFavor and bar.houseLevelFavor.houseLevel) or 1
			-- Format: Level # X/Y
			bar.OverlayFrame.Text:SetFormattedText('Level %d %d/%d', houseLevel, currentProgress, totalLevelXP)
		end
	end

	-- Show text if configured for mouseover
	if DB.bars[containerKey].text == Enums.TextDisplayMode.OnMouseOver then bar.OverlayFrame.Text:Show() end

	-- Show custom tooltip using the bar's data (if enabled)
	if DB.bars[containerKey].showTooltip then
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(bar, 'ANCHOR_CURSOR')
		if bar.barIndex == Enums.Bars.Experience then
			module:GetExperienceTooltipText()
		elseif bar.barIndex == Enums.Bars.Reputation then
			module:GetReputationTooltipText()
		elseif bar.barIndex == Enums.Bars.Honor then
			module:GetHonorTooltipText()
		elseif bar.barIndex == Enums.Bars.HouseFavor then
			module:GetHouseFavorTooltipText(bar)
		end
		GameTooltip:Show()
	end
end

function module:HandleBarOnLeave(bar, containerKey)
	-- Hide text if configured for mouseover
	if DB.bars[containerKey].text == Enums.TextDisplayMode.OnMouseOver then bar.OverlayFrame.Text:Hide() end
	-- Hide tooltip (if it was enabled)
	if DB.bars[containerKey].showTooltip then GameTooltip:Hide() end
end

function module:SetupBarContainerMouseEvents(barContainer, index)
	-- Add mouse events to the container itself to handle cases where mover blocks individual bar events
	barContainer:EnableMouse(true)
	local containerKey = index == 1 and 'Left' or 'Right'

	barContainer:SetScript('OnEnter', function(self)
		-- Find the active bar in this container and trigger its tooltip
		for _, bar in pairs(self.bars) do
			if bar:IsShown() and bar.barIndex and bar.barIndex ~= Enums.Bars.None then
				module:HandleBarOnEnter(bar, containerKey)
				break -- Only handle the first active bar
			end
		end
	end)

	barContainer:SetScript('OnLeave', function(self)
		-- Hide text and tooltip for all bars in this container
		for _, bar in pairs(self.bars) do
			if bar:IsShown() and bar.barIndex and bar.barIndex ~= Enums.Bars.None then module:HandleBarOnLeave(bar, containerKey) end
		end
	end)
end

function module:SetupBarContainerBehavior(barContainer, index)
	local width, height = unpack(barContainer.settings.size)
	for _, bar in pairs(barContainer.bars) do
		self:SetupBar(bar, barContainer, width, height, index)
	end

	SpartanUI:HookScript('OnHide', function()
		barContainer:Hide()
	end)
	SpartanUI:HookScript('OnShow', function()
		barContainer:Show()
	end)
end

function module:SetupBar(bar, barContainer, width, height, index)
	bar:SetSize(width - 30, height - 5)
	bar.StatusBar:SetSize(width - 30, height - 5)
	bar:ClearAllPoints()
	bar:SetPoint('BOTTOM', barContainer, 'BOTTOM', 0, 0)
	bar:SetUsingParentLevel(false)
	bar:SetFrameLevel(barContainer:GetFrameLevel() - 5)

	-- Ensure mouse events work
	bar:EnableMouse(true)

	self:SetupBarText(bar, barContainer.settings, index)

	bar:HookScript('OnEnter', function(self)
		local containerKey = index == 1 and 'Left' or 'Right'
		module:HandleBarOnEnter(self, containerKey)
	end)

	bar:HookScript('OnLeave', function(self)
		local containerKey = index == 1 and 'Left' or 'Right'
		module:HandleBarOnLeave(self, containerKey)
	end)
end

function module:SetActiveStyle(style)
	-- Update the style for each container (Left and Right)
	for _, key in ipairs({ 'Left', 'Right' }) do
		local barContainer = module.bars[key]
		if barContainer then
			local newStyle = GetStyleSettings(key)

			-- Update size
			barContainer:SetSize(unpack(newStyle.size))

			-- Update background
			if newStyle.bgTexture then
				barContainer.bg:SetTexture(newStyle.bgTexture)
				barContainer.bg:Show()
				if newStyle.texCords then
					barContainer.bg:SetTexCoord(unpack(newStyle.texCords))
				else
					barContainer.bg:SetTexCoord(0, 1, 0, 1)
				end
			else
				barContainer.bg:SetTexture('')
				barContainer.bg:Hide()
			end

			-- Update overlay
			if newStyle.bgTexture then
				barContainer.overlay:SetTexture(newStyle.bgTexture)
				barContainer.overlay:Show()
				if newStyle.texCords then
					barContainer.overlay:SetTexCoord(unpack(newStyle.texCords))
				else
					barContainer.overlay:SetTexCoord(0, 1, 0, 1)
				end
			else
				barContainer.overlay:SetTexture('')
				barContainer.overlay:Hide()
			end

			-- Update position
			local point, anchor, secondaryPoint, x, y = strsplit(',', newStyle.Position)
			barContainer:ClearAllPoints()
			barContainer:SetPoint(point, anchor, secondaryPoint, x, y)

			-- Update individual bars
			for _, bar in pairs(barContainer.bars) do
				bar:SetSize(newStyle.size[1] - 30, newStyle.size[2] - 5)
				bar.StatusBar:SetSize(newStyle.size[1] - 30, newStyle.size[2] - 5)

				-- Update text if needed
				self:SetupBarText(bar, newStyle, key == 'Left' and 1 or 2)
			end

			-- Store the new style settings
			barContainer.settings = newStyle
		end
	end

	-- Refresh the bars
	self:UpdateBars()
end

function module:SetupBarText(bar, StyleSetting, index)
	local containerKey = index == 1 and 'Left' or 'Right'
	local textMode = DB.bars[containerKey].text
	SUI.Font:Format(bar.OverlayFrame.Text, StyleSetting.Font or 10, 'StatusBars')
	bar.OverlayFrame.Text:SetShown(textMode == Enums.TextDisplayMode.Always)

	-- Update the bar's UpdateTextVisibility function
	bar.UpdateTextVisibility = function(self)
		local blizzMode = self:ShouldBarTextBeDisplayed()
		self.OverlayFrame.Text:SetShown(textMode == Enums.TextDisplayMode.Always and blizzMode)
	end
end

function module:BuildOptions()
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
					self:UpdateBars()
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
					self:UpdateBars()
				end,
			},
			BarPriorities = self:CreateBarPrioritiesOptions(),
			Font = self:CreateFontOptions(),
			Left = self:CreateContainerOptions('Left', 110),
			Right = self:CreateContainerOptions('Right', 120),
		},
	}
end

function module:CreateContainerOptions(containerKey, order)
	return {
		name = containerKey .. ' Status Bar',
		type = 'group',
		inline = true,
		order = order,
		args = {
			enabled = {
				name = 'Enable ' .. containerKey .. ' Bar',
				type = 'toggle',
				order = 0,
				get = function()
					return DB.bars[containerKey].enabled
				end,
				set = function(_, value)
					DB.bars[containerKey].enabled = value
					self:UpdateBars()
				end,
			},
			text = {
				name = 'Text Display',
				type = 'select',
				order = 1,
				disabled = function()
					return not DB.bars[containerKey].enabled
				end,
				values = {
					[Enums.TextDisplayMode.OnMouseOver] = 'On Mouse Over',
					[Enums.TextDisplayMode.Always] = 'Always',
					[Enums.TextDisplayMode.Never] = 'Never',
				},
				get = function()
					return DB.bars[containerKey].text
				end,
				set = function(_, value)
					DB.bars[containerKey].text = value
					self:UpdateBars()
				end,
			},
			alpha = {
				name = 'Alpha',
				type = 'range',
				order = 2,
				min = 0,
				max = 1,
				step = 0.01,
				disabled = function()
					return not DB.bars[containerKey].enabled
				end,
				get = function()
					return DB.bars[containerKey].alpha
				end,
				set = function(_, value)
					DB.bars[containerKey].alpha = value
					self:UpdateBars()
				end,
			},
			showTooltip = {
				name = 'Show Tooltip on Mouseover',
				type = 'toggle',
				order = 3,
				disabled = function()
					return not DB.bars[containerKey].enabled
				end,
				get = function()
					return DB.bars[containerKey].showTooltip
				end,
				set = function(_, value)
					DB.bars[containerKey].showTooltip = value
				end,
			},
		},
	}
end

function module:CreateFontOptions()
	return {
		name = 'Font Settings',
		type = 'group',
		order = 100,
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
	}
end

function module:CreateBarPrioritiesOptions()
	local options = {
		name = 'Bar Priorities',
		type = 'group',
		order = 50,
		inline = true,
		args = {},
	}

	local function isBarAtTop(barIndex)
		return DB.BarPriorities[barIndex] == 0
	end

	local function isBarAtBottom(barIndex)
		local highest = 0
		for _, priority in pairs(DB.BarPriorities) do
			if priority > highest then highest = priority end
		end
		return DB.BarPriorities[barIndex] == highest
	end

	local function moveBar(barIndex, direction)
		local currentPriority = DB.BarPriorities[barIndex]
		local newPriority = currentPriority + (direction == 'up' and -1 or 1)

		for otherBarIndex, priority in pairs(DB.BarPriorities) do
			if priority == newPriority then
				DB.BarPriorities[otherBarIndex] = currentPriority
				DB.BarPriorities[barIndex] = newPriority
				break
			end
		end

		self:UpdateBars()
	end

	for i, v in pairs(DB.BarPriorities) do
		options.args[BarLabels[i]] = {
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
					disabled = function()
						return isBarAtTop(i)
					end,
					func = function()
						moveBar(i, 'up')
					end,
				},
				down = {
					type = 'execute',
					name = 'Down',
					width = 'half',
					order = 3,
					disabled = function()
						return isBarAtBottom(i)
					end,
					func = function()
						moveBar(i, 'down')
					end,
				},
			},
		}
	end

	return options
end
