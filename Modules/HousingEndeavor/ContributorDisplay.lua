---@class SUI
local SUI = SUI
local L = SUI.L

-- Only available in Retail
if not SUI.IsRetail then
	return
end

-- Get module reference (assigned at end of HousingEndeavor.lua, but file loads after)
---@class SUI.Module.HousingEndeavor
local module = SUI.HousingEndeavor or SUI:GetModule('HousingEndeavor')

-- Safety check - module must exist
if not module then
	-- This shouldn't happen if load order is correct
	print('|cffff0000SUI ContributorDisplay: Module not found!|r')
	return
end

-- Debug: Check if module loaded
if module.logger then
	module.logger.debug('ContributorDisplay.lua loading, module exists: true')
end

----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------

-- Rank color tiers (matching EnhancedEndeavors)
local RANK_COLORS = {
	[1] = { r = 1.0, g = 0.5, b = 0 }, -- Legendary (Orange)
	[2] = { r = 0.64, g = 0.21, b = 0.93 }, -- Epic (Purple)
	[3] = { r = 0, g = 0.44, b = 0.87 }, -- Rare (Blue)
	[4] = { r = 0.12, g = 1.0, b = 0 }, -- Uncommon (Green)
	[5] = { r = 0.12, g = 1.0, b = 0 }, -- Uncommon (Green)
}
local DEFAULT_COLOR = { r = 1, g = 1, b = 1 } -- Common (White)

---Get color for a rank position
---@param rank number
---@return table color {r, g, b}
local function GetRankColor(rank)
	return RANK_COLORS[rank] or DEFAULT_COLOR
end

----------------------------------------------------------------------------------------------------
-- Inline Contributor Panel
----------------------------------------------------------------------------------------------------

local contributorPanel = nil ---@type Frame|nil
local anchorFrame = nil ---@type Frame|nil
local contributorRows = {} ---@type table<number, {nameText: FontString, scoreText: FontString}>

---Create the contributor panel frame
---@return Frame
local function CreateContributorPanel()
	if module and module.logger then
		module.logger.debug('ContributorDisplay: CreateContributorPanel called')
	end

	local frame = CreateFrame('Frame', 'SUI_HousingEndeavor_ContributorPanel', UIParent, 'BackdropTemplate')
	frame:SetFrameStrata('HIGH')
	frame:SetFrameLevel(50)
	frame:SetClampedToScreen(true)
	frame:Hide()

	-- Backdrop styling (same as ProgressDisplay overlay)
	frame:SetBackdrop({
		bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
		edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

	-- Title: "Top Contributors"
	frame.title = frame:CreateFontString(nil, 'ARTWORK')
	frame.title:SetPoint('TOP', frame, 'TOP', 0, -8)
	frame.title:SetFontObject(GameFontNormal)
	frame.title:SetText(L['Top Contributors'])
	frame.title:SetJustifyH('CENTER')

	-- Create contributor rows (dynamically based on count setting)
	local previousRow = frame
	for i = 1, 2 do
		local row = {}

		-- Name text (white, GameFontNormal size)
		row.nameText = frame:CreateFontString(nil, 'ARTWORK')
		if i == 1 then
			row.nameText:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -26)
		else
			row.nameText:SetPoint('TOPLEFT', previousRow, 'BOTTOMLEFT', 0, -2)
		end

		row.nameText:SetFontObject(GameFontNormal)
		row.nameText:SetText('')
		row.nameText:SetJustifyH('LEFT')
		row.nameText:SetTextColor(1, 1, 1) -- White

		-- Score text (positioned to the right of name)
		row.scoreText = frame:CreateFontString(nil, 'ARTWORK')
		row.scoreText:SetPoint('LEFT', row.nameText, 'RIGHT', 4, 0)
		row.scoreText:SetFontObject(GameFontNormal)
		row.scoreText:SetText('')
		row.scoreText:SetJustifyH('LEFT')

		contributorRows[i] = row
		previousRow = row.nameText
	end

	-- "View More" button using AH-style atlas (like BugWindow)
	frame.viewMoreBtn = CreateFrame('Button', nil, frame)
	frame.viewMoreBtn:SetSize(100, 22)
	frame.viewMoreBtn:SetNormalAtlas('auctionhouse-nav-button')
	frame.viewMoreBtn:SetHighlightAtlas('auctionhouse-nav-button-highlight')
	frame.viewMoreBtn:SetPushedAtlas('auctionhouse-nav-button-select')

	-- Crop bottom for tab appearance
	local normalTexture = frame.viewMoreBtn:GetNormalTexture()
	if normalTexture then
		normalTexture:SetTexCoord(0, 1, 0, 0.7)
	end

	frame.viewMoreBtn.Text = frame.viewMoreBtn:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	frame.viewMoreBtn.Text:SetPoint('CENTER')
	frame.viewMoreBtn.Text:SetText(L['View More'] or 'View More')
	frame.viewMoreBtn.Text:SetTextColor(1, 1, 1, 1)

	frame.viewMoreBtn:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 5)
	frame.viewMoreBtn:SetScript('OnClick', function()
		if module.ShowContributorListWindow then
			module:ShowContributorListWindow()
		end
	end)

	return frame
end

---Update the contributor panel with current data
local function UpdateContributorPanel()
	if module and module.logger then
		module.logger.debug('ContributorDisplay: UpdateContributorPanel called')
	end

	if not contributorPanel then
		contributorPanel = CreateContributorPanel()
	end

	-- Check if enabled
	if not module or not module.DB or not module.DB.contributors or not module.DB.contributors.enabled then
		if module and module.logger then
			module.logger.debug('ContributorDisplay: Disabled or no DB')
		end
		contributorPanel:Hide()
		return
	end

	-- Check if anchor frame is valid and visible
	if not anchorFrame or not anchorFrame:IsVisible() then
		if module and module.logger then
			module.logger.debug('ContributorDisplay: No anchor frame or not visible')
		end
		contributorPanel:Hide()
		return
	end

	contributorPanel.title:SetText(L['Top Contributors'])

	local contributors = module:GetTopContributors()
	if not contributors or #contributors == 0 then
		if module and module.logger then
			module.logger.debug('ContributorDisplay: No contributor data, showing placeholders')
		end
		for i, row in ipairs(contributorRows) do
			if i == 1 then
				row.nameText:SetText('Activate Endeavor')
				row.nameText:SetTextColor(1, 1, 1)
				row.scoreText:SetText('')
				row.scoreText:SetTextColor(1, 1, 1)
			else
				row.nameText:SetText('To View')
				row.nameText:SetTextColor(1, 1, 1)
				row.scoreText:SetText('')
				row.scoreText:SetTextColor(1, 1, 1)
			end
		end
	else
		local count = module.DB.contributors.count or 2
		local showScore = module.DB.contributors.showScore ~= false
		local useRankColors = module.DB.contributors.useRankColors ~= false

		for i, row in ipairs(contributorRows) do
			if i <= count and contributors[i] then
				local contributor = contributors[i]
				local color = useRankColors and GetRankColor(i) or DEFAULT_COLOR

				row.nameText:SetText(contributor.name .. ':')
				row.nameText:SetTextColor(1, 1, 1) -- Name is white

				if showScore then
					-- Format score (multiply by 100 like EnhancedEndeavors)
					row.scoreText:SetText(BreakUpLargeNumbers(contributor.contribution))
					row.scoreText:SetTextColor(color.r, color.g, color.b)
					row.scoreText:Show()
				else
					row.scoreText:Hide()
				end

				row.nameText:Show()
			else
				row.nameText:Hide()
				row.scoreText:Hide()
			end
		end
	end

	-- Show/hide View More button
	local fullListEnabled = module.DB.contributors.fullListEnabled ~= false
	if fullListEnabled and contributors and #contributors > (module.DB.contributors.count or 2) then
		contributorPanel.viewMoreBtn:Show()
	else
		contributorPanel.viewMoreBtn:Hide()
	end

	-- Calculate frame size based on visible content
	local width = 110
	local height = 14 -- Title (smaller with GameFontNormal)

	local count = module.DB.contributors.count or 2
	for i = 1, count do
		local row = contributorRows[i]
		if row and row.nameText:IsShown() then
			local rowWidth = row.nameText:GetStringWidth() + (row.scoreText:IsShown() and row.scoreText:GetStringWidth() + 4 or 0) + 20
			width = math.max(width, rowWidth)
			height = height + 16 -- Smaller row height with GameFontNormal
		end
	end

	if contributorPanel.viewMoreBtn:IsShown() then
		height = height + 20
		width = math.max(width, 100)
	end

	contributorPanel:SetSize(width + 16, height + 20)

	-- Anchor to InitiativesFrame (top-right)
	contributorPanel:ClearAllPoints()
	contributorPanel:SetPoint('TOPRIGHT', anchorFrame, 'TOPRIGHT', -15, -8)
	contributorPanel:Show()

	-- Re-anchor the InitiativeTimer to our panel's left side to avoid overlap
	local initiativeSetFrame = HousingDashboardFrame
		and HousingDashboardFrame.HouseInfoContent
		and HousingDashboardFrame.HouseInfoContent.ContentFrame
		and HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame
		and HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame.InitiativeSetFrame
	if initiativeSetFrame and initiativeSetFrame.InitiativeTimer then
		initiativeSetFrame.InitiativeTimer:ClearAllPoints()
		initiativeSetFrame.InitiativeTimer:SetPoint('TOPRIGHT', contributorPanel, 'TOPLEFT', 32, 0)
	end

	if module and module.logger then
		module.logger.debug('ContributorDisplay: Panel shown')
	end
end

---Hide the contributor panel
local function HideContributorPanel()
	if contributorPanel then
		contributorPanel:Hide()
	end
end

----------------------------------------------------------------------------------------------------
-- Full Contributor List Window
----------------------------------------------------------------------------------------------------

local contributorListWindow = nil ---@type Frame|nil
local listRows = {} ---@type table<number, Frame>

---Create a row for the contributor list
---@param parent Frame
---@param index number
---@return Frame row
local function CreateListRow(parent, index)
	local row = CreateFrame('Frame', nil, parent)
	row:SetHeight(22)

	-- Rank number (2-3 digits max)
	row.rank = row:CreateFontString(nil, 'ARTWORK')
	row.rank:SetPoint('LEFT', row, 'LEFT', 4, 0)
	row.rank:SetWidth(18)
	row.rank:SetFontObject(GameFontHighlight)
	row.rank:SetJustifyH('RIGHT')

	-- Name (flexible)
	row.name = row:CreateFontString(nil, 'ARTWORK')
	row.name:SetPoint('LEFT', row.rank, 'RIGHT', 4, 0)
	row.name:SetPoint('RIGHT', row, 'RIGHT', -55, 0) -- Leave room for score
	row.name:SetFontObject(GameFontHighlight)
	row.name:SetJustifyH('LEFT')

	-- Score (right-aligned, 6-7 digits)
	row.score = row:CreateFontString(nil, 'ARTWORK')
	row.score:SetPoint('RIGHT', row, 'RIGHT', -4, 0)
	row.score:SetWidth(50)
	row.score:SetFontObject(GameFontHighlight)
	row.score:SetJustifyH('RIGHT')

	return row
end

---Create the contributor list window (styled like SUI Chat Copy window)
---@return Frame
local function CreateContributorListWindow()
	if module and module.logger then
		module.logger.debug('ContributorDisplay: CreateContributorListWindow called')
	end

	-- Create window using ButtonFrameTemplate (like Chat Copy)
	local window = CreateFrame('Frame', 'SUI_ContributorListWindow', UIParent, 'ButtonFrameTemplate')
	ButtonFrameTemplate_HidePortrait(window)
	ButtonFrameTemplate_HideButtonBar(window)
	window.Inset:Hide()
	window:SetSize(320, 350)
	window:SetFrameStrata('MEDIUM')
	window:Hide()

	-- Make the window movable
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag('LeftButton')
	window:SetScript('OnDragStart', window.StartMoving)
	window:SetScript('OnDragStop', window.StopMovingOrSizing)

	-- Set title
	window:SetTitle('|cffffffffSpartan|cffe21f1fUI|r ' .. L['Top Contributors'])

	-- Create main content area
	window.MainContent = CreateFrame('Frame', nil, window)
	window.MainContent:SetPoint('TOPLEFT', window, 'TOPLEFT', 18, -30)
	window.MainContent:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -25, 12)

	-- Create scroll frame with MinimalScrollBar
	window.scrollFrame = CreateFrame('ScrollFrame', nil, window.MainContent)
	window.scrollFrame:SetPoint('TOPLEFT', window.MainContent, 'TOPLEFT', 6, -26)
	window.scrollFrame:SetPoint('BOTTOMRIGHT', window.MainContent, 'BOTTOMRIGHT', 0, 2)

	-- Background texture (AuctionHouse style)
	window.scrollFrame.Background = window.scrollFrame:CreateTexture(nil, 'BACKGROUND')
	window.scrollFrame.Background:SetAtlas('auctionhouse-background-index', true)
	window.scrollFrame.Background:SetPoint('TOPLEFT', window.scrollFrame, 'TOPLEFT', -6, 6)
	window.scrollFrame.Background:SetPoint('BOTTOMRIGHT', window.scrollFrame, 'BOTTOMRIGHT', 0, -6)

	-- Create minimal scrollbar
	window.scrollFrame.ScrollBar = CreateFrame('EventFrame', nil, window.scrollFrame, 'MinimalScrollBar')
	window.scrollFrame.ScrollBar:SetPoint('TOPLEFT', window.scrollFrame, 'TOPRIGHT', 6, 0)
	window.scrollFrame.ScrollBar:SetPoint('BOTTOMLEFT', window.scrollFrame, 'BOTTOMRIGHT', 6, 0)
	ScrollUtil.InitScrollFrameWithScrollBar(window.scrollFrame, window.scrollFrame.ScrollBar)

	-- Content frame for rows (use fixed width based on window size minus margins)
	window.content = CreateFrame('Frame', nil, window.scrollFrame)
	window.content:SetWidth(250) -- Window is 320, minus margins and scrollbar
	window.content:SetHeight(1)
	window.scrollFrame:SetScrollChild(window.content)

	-- Header row (above scroll frame)
	window.header = CreateFrame('Frame', nil, window.MainContent)
	window.header:SetPoint('TOPLEFT', window.MainContent, 'TOPLEFT', 6, 0)
	window.header:SetPoint('TOPRIGHT', window.MainContent, 'TOPRIGHT', -20, 0)
	window.header:SetHeight(22)

	window.header.rankLabel = window.header:CreateFontString(nil, 'ARTWORK')
	window.header.rankLabel:SetPoint('LEFT', window.header, 'LEFT', 4, 0)
	window.header.rankLabel:SetWidth(18)
	window.header.rankLabel:SetFontObject(GameFontNormalSmall)
	window.header.rankLabel:SetText('#')
	window.header.rankLabel:SetJustifyH('RIGHT')

	window.header.nameLabel = window.header:CreateFontString(nil, 'ARTWORK')
	window.header.nameLabel:SetPoint('LEFT', window.header.rankLabel, 'RIGHT', 4, 0)
	window.header.nameLabel:SetFontObject(GameFontNormalSmall)
	window.header.nameLabel:SetText(L['Name'] or 'Name')
	window.header.nameLabel:SetJustifyH('LEFT')

	window.header.scoreLabel = window.header:CreateFontString(nil, 'ARTWORK')
	window.header.scoreLabel:SetPoint('RIGHT', window.header, 'RIGHT', -4, 0)
	window.header.scoreLabel:SetWidth(50)
	window.header.scoreLabel:SetFontObject(GameFontNormalSmall)
	window.header.scoreLabel:SetText(L['Contribution'] or 'Contribution')
	window.header.scoreLabel:SetJustifyH('RIGHT')

	return window
end

---Update the contributor list window content
local function UpdateContributorListWindow()
	if not contributorListWindow then
		return
	end

	local contributors = module:GetTopContributors()
	local content = contributorListWindow.content
	local useRankColors = module.DB and module.DB.contributors and module.DB.contributors.useRankColors ~= false

	-- Clear existing rows
	for _, row in ipairs(listRows) do
		row:Hide()
	end

	if not contributors or #contributors == 0 then
		return
	end

	-- Create/update rows
	local yOffset = 0
	for i, contributor in ipairs(contributors) do
		local row = listRows[i]
		if not row then
			row = CreateListRow(content, i)
			listRows[i] = row
		end

		row:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -yOffset)
		row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', 0, -yOffset)

		local color = useRankColors and GetRankColor(i) or DEFAULT_COLOR

		row.rank:SetText(tostring(i))
		row.rank:SetTextColor(color.r, color.g, color.b)

		row.name:SetText(contributor.name)
		row.name:SetTextColor(1, 1, 1)

		row.score:SetText(BreakUpLargeNumbers(contributor.contribution))
		row.score:SetTextColor(color.r, color.g, color.b)

		row:Show()
		yOffset = yOffset + 22
	end

	-- Update content height for scrolling
	content:SetHeight(math.max(1, yOffset))
end

---Show the contributor list window
function module:ShowContributorListWindow()
	if not contributorListWindow then
		contributorListWindow = CreateContributorListWindow()
	end

	-- Update window title with zone name (e.g., "46 Stormy Shores Top Contributors")
	local info = self:GetInitiativeInfo()
	if info and info.title then
		contributorListWindow:SetTitle(info.title .. ' ' .. L['Top Contributors'])
	else
		contributorListWindow:SetTitle(L['Top Contributors'])
	end

	UpdateContributorListWindow()

	-- Position next to HousingDashboardFrame
	contributorListWindow:ClearAllPoints()
	if HousingDashboardFrame and HousingDashboardFrame:IsVisible() then
		contributorListWindow:SetPoint('TOPLEFT', HousingDashboardFrame, 'TOPRIGHT', 50, 0)
	else
		contributorListWindow:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	end

	contributorListWindow:Show()
end

----------------------------------------------------------------------------------------------------
-- Frame Hooking (similar to ProgressDisplay)
----------------------------------------------------------------------------------------------------

local hooked = false

---Find the InitiativesFrame to anchor to
---@return Frame|nil
local function FindInitiativesFrame()
	if module and module.logger then
		module.logger.debug('ContributorDisplay: FindInitiativesFrame called')
	end

	-- Try the specific path
	local initiativesFrame = HousingDashboardFrame
		and HousingDashboardFrame.HouseInfoContent
		and HousingDashboardFrame.HouseInfoContent.ContentFrame
		and HousingDashboardFrame.HouseInfoContent.ContentFrame.InitiativesFrame

	if initiativesFrame and not initiativesFrame:IsForbidden() then
		if module and module.logger then
			module.logger.debug('ContributorDisplay: Found InitiativesFrame directly')
		end
		return initiativesFrame
	end

	-- Fallback to HousingDashboardFrame
	if HousingDashboardFrame and not HousingDashboardFrame:IsForbidden() then
		if module and module.logger then
			module.logger.debug('ContributorDisplay: Using HousingDashboardFrame as fallback')
		end
		return HousingDashboardFrame
	end

	if module and module.logger then
		module.logger.debug('ContributorDisplay: No InitiativesFrame found')
	end
	return nil
end

---Hook the frame to show panel when visible
local function HookFrame()
	if hooked then
		return true
	end

	if module and module.logger then
		module.logger.debug('ContributorDisplay: HookFrame called')
	end

	local frame = FindInitiativesFrame()
	if not frame then
		if module and module.logger then
			module.logger.debug('ContributorDisplay: No frame to hook')
		end
		return false
	end

	anchorFrame = frame

	if module and module.logger then
		module.logger.debug('ContributorDisplay: Hooking frame OnShow/OnHide')
	end

	-- Hook OnShow/OnHide
	frame:HookScript('OnShow', function()
		if module and module.logger then
			module.logger.debug('ContributorDisplay: OnShow triggered')
		end
		-- Request fresh activity log data
		module:RequestActivityLog()
		C_Timer.After(0.5, UpdateContributorPanel)
	end)

	frame:HookScript('OnHide', function()
		if module and module.logger then
			module.logger.debug('ContributorDisplay: OnHide triggered')
		end
		HideContributorPanel()
		-- Also hide the full contributor list window
		if contributorListWindow and contributorListWindow:IsVisible() then
			contributorListWindow:Hide()
		end
	end)

	hooked = true

	-- If already visible, show now
	if frame:IsVisible() then
		if module and module.logger then
			module.logger.debug('ContributorDisplay: Frame already visible, updating panel')
		end
		module:RequestActivityLog()
		C_Timer.After(0.5, UpdateContributorPanel)
	end

	if module and module.logger then
		module.logger.info('ContributorDisplay: Successfully hooked frame')
	end

	return true
end

----------------------------------------------------------------------------------------------------
-- Module Integration
----------------------------------------------------------------------------------------------------

---Initialize the contributor display system
function module:InitContributorDisplay()
	if self.logger then
		self.logger.debug('ContributorDisplay: InitContributorDisplay called')
	end

	-- Hook HousingDashboardFrame if it exists
	if HousingDashboardFrame then
		if self.logger then
			self.logger.debug('ContributorDisplay: HousingDashboardFrame exists at init')
		end
		HousingDashboardFrame:HookScript('OnShow', function()
			if self.logger then
				self.logger.debug('ContributorDisplay: HousingDashboardFrame OnShow fired')
			end
			C_Timer.After(0.1, HookFrame)
		end)
	end

	-- Note: NEIGHBORHOOD_INITIATIVE_UPDATED is handled by main HousingEndeavor.lua
	-- which clears caches, requests fresh data, and sends SUI_HOUSING_ENDEAVOR_UPDATED message

	-- Watch for housing addons to load
	local watchFrame = CreateFrame('Frame')
	watchFrame:RegisterEvent('ADDON_LOADED')
	watchFrame:SetScript('OnEvent', function(_, event, addonName)
		if addonName == 'Blizzard_HousingDashboard' then
			if self.logger then
				self.logger.debug('ContributorDisplay: Blizzard_HousingDashboard loaded')
			end
			C_Timer.After(0.1, function()
				if HousingDashboardFrame and not hooked then
					HookFrame()
					-- If already visible, update now
					if anchorFrame and anchorFrame:IsVisible() then
						UpdateContributorPanel()
					end
				end
			end)
		end
	end)

	-- Try to hook immediately
	if not HookFrame() then
		if self.logger then
			self.logger.debug('ContributorDisplay: Initial hook failed, setting up retries')
		end

		-- Also retry a few times with delays as fallback
		C_Timer.After(3, HookFrame)
		C_Timer.After(10, HookFrame)
	end

	-- Note: Message handlers are registered centrally in HousingEndeavor.lua OnEnable
	-- to avoid multiple handlers overwriting each other

	if self.logger then
		self.logger.info('ContributorDisplay: Initialization complete')
	end
end

---Public update function called by centralized message handler
function module:UpdateContributorDisplay()
	if self.logger then
		self.logger.debug('ContributorDisplay: UpdateContributorDisplay called, anchorFrame=' .. tostring(anchorFrame ~= nil) .. ', visible=' .. tostring(anchorFrame and anchorFrame:IsVisible()))
	end
	if anchorFrame and anchorFrame:IsVisible() then
		C_Timer.After(0.5, UpdateContributorPanel)
	end
	if contributorListWindow and contributorListWindow:IsVisible() then
		C_Timer.After(0.5, UpdateContributorListWindow)
	end
end
