---@class SUI
local SUI = SUI
local logger = SUI:NewModule('Handler.Logger') ---@type SUI.Module
SUI.Handlers.Logger = logger
logger.description = 'SpartanUI Logging System'
----------------------------------------------------------------------------------------------------
local LogWindow = nil ---@type Frame
local LogMessages = {}
local ScrollListing = {}
local ActiveModule = nil

-- Log levels with colors, priorities, and display names
local LOG_LEVELS = {
	['debug'] = { color = '|cff888888', priority = 1, display = 'Debug' },
	['info'] = { color = '|cff00ff00', priority = 2, display = 'Info' },
	['warning'] = { color = '|cffffff00', priority = 3, display = 'Warning' },
	['error'] = { color = '|cffff0000', priority = 4, display = 'Error' },
	['critical'] = { color = '|cffff00ff', priority = 5, display = 'Critical' },
}

-- Global and per-module log level settings
local GlobalLogLevel = 2 -- Default to 'info' and above
local ModuleLogLevels = {} -- Per-module overrides

-- Search and UI state
local CurrentSearchTerm = ''
local SearchAllModules = false
local AutoScrollEnabled = true

-- Helper function to get log level by priority
local function GetLogLevelByPriority(priority)
	for level, data in pairs(LOG_LEVELS) do
		if data.priority == priority then return level, data end
	end
	return 'info', LOG_LEVELS['info'] -- Default fallback
end

-- Function to categorize modules like AuctionFrame categorizes items
local function CategorizeModule(moduleName)
	-- Define category rules (similar to AuctionFrame's item categorization)
	local categories = {
		['Core'] = { 'Core', 'Framework', 'Events', 'Options', 'Database', 'Profiles' },
		['UI Modules'] = { 'UnitFrames', 'Minimap', 'Artwork', 'ActionBars', 'ChatBox', 'Tooltips' },
		['External Addons'] = { 'LibsDataBar', 'LibsDisenchantAssist', 'Disenchant Assist', 'DataBar' },
		['Handlers'] = { 'Handler', 'Logger', 'ChatCommands', 'Compatibility' },
		['Development'] = { 'Debug', 'Test', 'Dev', 'Plugin' },
	}

	-- Check each category for module matches
	for category, keywords in pairs(categories) do
		for _, keyword in ipairs(keywords) do
			if moduleName:lower():find(keyword:lower()) then return category end
		end
	end

	-- Default category for unmatched modules
	return 'Other Modules'
end

-- Function to create hierarchical module tree (like AuctionFrame categories)
function CreateModuleCategories()
	if not LogWindow then return end

	-- Clear existing data
	LogWindow.Categories = {}
	ScrollListing = {}

	-- Organize modules into categories
	for moduleName, _ in pairs(logger.DB.modules) do
		local category = CategorizeModule(moduleName)

		if not LogWindow.Categories[category] then LogWindow.Categories[category] = {
			name = category,
			modules = {},
			expanded = false,
			button = nil,
		} end

		table.insert(LogWindow.Categories[category].modules, moduleName)
		table.insert(ScrollListing, { text = moduleName, value = moduleName, category = category })
	end

	-- Sort categories and modules within categories
	local sortedCategories = {}
	for categoryName, _ in pairs(LogWindow.Categories) do
		table.insert(sortedCategories, categoryName)
	end
	table.sort(sortedCategories)

	for _, categoryName in pairs(sortedCategories) do
		table.sort(LogWindow.Categories[categoryName].modules)
	end

	-- Create the visual tree structure
	CreateCategoryTree(sortedCategories)
end

-- Function to create the visual category tree (styled like AuctionFrame's category list)
function CreateCategoryTree(sortedCategories)
	if not LogWindow or not LogWindow.ModuleTree then return end

	-- Clear existing buttons
	for _, button in pairs(LogWindow.categoryButtons) do
		button:Hide()
		button:SetParent(nil)
	end
	for _, button in pairs(LogWindow.moduleButtons) do
		button:Hide()
		button:SetParent(nil)
	end
	LogWindow.categoryButtons = {}
	LogWindow.moduleButtons = {}

	local yOffset = 0
	local buttonHeight = 20
	local categoryHeight = 18
	local indentWidth = 15

	for _, categoryName in ipairs(sortedCategories) do
		local categoryData = LogWindow.Categories[categoryName]

		-- Create category button (styled like AuctionFrame's expandable categories)
		local categoryButton = CreateFrame('Button', nil, LogWindow.ModuleTree)
		categoryButton:SetSize(140, categoryHeight)
		categoryButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', 0, yOffset)

		-- Category background (darker, like AuctionFrame headers)
		categoryButton.bg = categoryButton:CreateTexture(nil, 'BACKGROUND')
		categoryButton.bg:SetAllPoints()
		categoryButton.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

		-- Expand/collapse indicator (+ or -)
		categoryButton.indicator = categoryButton:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
		categoryButton.indicator:SetPoint('LEFT', categoryButton, 'LEFT', 3, 0)
		categoryButton.indicator:SetText(categoryData.expanded and '-' or '+')
		categoryButton.indicator:SetTextColor(0.8, 0.8, 0.8)

		-- Category text
		categoryButton.text = categoryButton:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
		categoryButton.text:SetPoint('LEFT', categoryButton.indicator, 'RIGHT', 5, 0)
		categoryButton.text:SetText(categoryName .. ' (' .. #categoryData.modules .. ')')
		categoryButton.text:SetTextColor(1, 0.82, 0) -- Gold like AuctionFrame headers

		-- Category button functionality
		categoryButton:SetScript('OnClick', function(self)
			categoryData.expanded = not categoryData.expanded
			self.indicator:SetText(categoryData.expanded and '-' or '+')
			CreateCategoryTree(sortedCategories) -- Rebuild tree
		end)

		-- Hover effects like AuctionFrame
		categoryButton:SetScript('OnEnter', function(self)
			self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
		end)
		categoryButton:SetScript('OnLeave', function(self)
			self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
		end)

		categoryData.button = categoryButton
		table.insert(LogWindow.categoryButtons, categoryButton)
		yOffset = yOffset - (categoryHeight + 1)

		-- Create module buttons if category is expanded
		if categoryData.expanded then
			for _, moduleName in ipairs(categoryData.modules) do
				local moduleButton = CreateFrame('Button', nil, LogWindow.ModuleTree)
				moduleButton:SetSize(132, 21)
				moduleButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', indentWidth, yOffset)

				-- Create textures to match AuctionHouse nav button style
				-- Normal texture
				moduleButton.NormalTexture = moduleButton:CreateTexture(nil, 'BACKGROUND')
				moduleButton.NormalTexture:SetAtlas('auctionhouse-nav-button', false)
				moduleButton.NormalTexture:SetSize(136, 32)
				moduleButton.NormalTexture:SetPoint('TOPLEFT', moduleButton, 'TOPLEFT', -2, 0)

				-- Highlight texture
				moduleButton.HighlightTexture = moduleButton:CreateTexture(nil, 'BORDER')
				moduleButton.HighlightTexture:SetAtlas('auctionhouse-nav-button-highlight')
				moduleButton.HighlightTexture:SetPoint('CENTER', moduleButton, 'CENTER')
				moduleButton.HighlightTexture:Hide()

				-- Selected texture
				moduleButton.SelectedTexture = moduleButton:CreateTexture(nil, 'ARTWORK')
				moduleButton.SelectedTexture:SetAtlas('auctionhouse-nav-button-select')
				moduleButton.SelectedTexture:SetBlendMode('ADD')
				moduleButton.SelectedTexture:SetPoint('TOPLEFT', moduleButton.NormalTexture, 'TOPLEFT')
				moduleButton.SelectedTexture:SetPoint('BOTTOMRIGHT', moduleButton.NormalTexture, 'BOTTOMRIGHT')
				moduleButton.SelectedTexture:Hide()

				-- Button text
				moduleButton.Text = moduleButton:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
				moduleButton.Text:SetText(moduleName)
				moduleButton.Text:SetJustifyH('LEFT')
				moduleButton.Text:SetPoint('LEFT', moduleButton, 'LEFT', 4, 0)
				moduleButton.Text:SetPoint('RIGHT', moduleButton, 'RIGHT', -4, 0)
				moduleButton.Text:SetHeight(8)

				-- Hover effects
				moduleButton:SetScript('OnEnter', function(self)
					self.HighlightTexture:Show()
				end)
				moduleButton:SetScript('OnLeave', function(self)
					self.HighlightTexture:Hide()
				end)

				-- Module selection functionality
				moduleButton:SetScript('OnClick', function(self)
					-- Update button states (clear all selected states)
					for _, btn in pairs(LogWindow.moduleButtons) do
						btn.SelectedTexture:Hide()
						btn.Text:SetFontObject('GameFontNormalSmall')
					end
					-- Set this button as selected
					self.SelectedTexture:Show()
					self.Text:SetFontObject('GameFontHighlightSmall')

					ActiveModule = self.Text:GetText()
					UpdateLogDisplay()
				end)

				table.insert(LogWindow.moduleButtons, moduleButton)
				yOffset = yOffset - (buttonHeight + 1)
			end
		end
	end

	-- Update tree height
	local totalHeight = math.abs(yOffset) + 20
	LogWindow.ModuleTree:SetHeight(math.max(totalHeight, LogWindow.ModuleScrollFrame:GetHeight()))
end

-- Function to validate and clamp window dimensions to screen size
local function ValidateWindowDimensions(width, height)
	local screenWidth = GetScreenWidth()
	local screenHeight = GetScreenHeight()

	-- Ensure minimum dimensions
	width = math.max(width, 400)
	height = math.max(height, 300)

	-- Ensure maximum dimensions don't exceed screen size
	width = math.min(width, screenWidth - 50) -- Leave 50px margin
	height = math.min(height, screenHeight - 50) -- Leave 50px margin

	return width, height
end

-- Function to save window position and size
local function SaveWindowLayout()
	if not LogWindow or not logger.DB then return end

	local point, relativeTo, relativePoint, x, y = LogWindow:GetPoint()
	logger.DB.window.width = LogWindow:GetWidth()
	logger.DB.window.height = LogWindow:GetHeight()
	logger.DB.window.point = point or 'CENTER'
	logger.DB.window.relativeTo = 'UIParent' -- Always relative to UIParent for consistency
	logger.DB.window.relativePoint = relativePoint or 'CENTER'
	logger.DB.window.x = x or 0
	logger.DB.window.y = y or 0
end

-- Function to load and apply window position and size
local function LoadWindowLayout()
	if not LogWindow or not logger.DB or not logger.DB.window then return end

	local settings = logger.DB.window

	-- Validate dimensions against current screen size
	local width, height = ValidateWindowDimensions(settings.width, settings.height)

	-- Apply validated size
	LogWindow:SetSize(width, height)

	-- Validate position to ensure window stays on screen
	local screenWidth = GetScreenWidth()
	local screenHeight = GetScreenHeight()
	local x, y = settings.x, settings.y

	-- Clamp position to keep window on screen
	if settings.point == 'CENTER' then
		-- For center anchoring, ensure the window doesn't go off edges
		x = math.max(math.min(x, (screenWidth - width) / 2), -(screenWidth - width) / 2)
		y = math.max(math.min(y, (screenHeight - height) / 2), -(screenHeight - height) / 2)
	else
		-- For other anchor points, use basic clamping
		x = math.max(math.min(x, screenWidth - 100), -width + 100) -- Keep at least 100px visible
		y = math.max(math.min(y, screenHeight - 100), -height + 100)
	end

	-- Apply position
	LogWindow:ClearAllPoints()
	LogWindow:SetPoint(settings.point, UIParent, settings.relativePoint, x, y)

	-- Update database with clamped values
	logger.DB.window.width = width
	logger.DB.window.height = height
	logger.DB.window.x = x
	logger.DB.window.y = y
end

local function CreateLogWindow()
	if LogWindow then return end

	-- Create main frame using PortraitFrameTemplate for proper skinning (AH window size: 800x538)
	LogWindow = CreateFrame('Frame', 'SpartanUI_LogWindow', UIParent, 'PortraitFrameTemplate')
	LogWindow:SetSize(800, 538)
	LogWindow:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	LogWindow:SetFrameStrata('HIGH')
	LogWindow:Hide()

	-- Make the window movable
	LogWindow:SetMovable(true)
	LogWindow:EnableMouse(true)
	LogWindow:RegisterForDrag('LeftButton')
	LogWindow:SetScript('OnDragStart', LogWindow.StartMoving)
	LogWindow:SetScript('OnDragStop', function(self)
		self:StopMovingOrSizing()
		SaveWindowLayout() -- Save position when moved
	end)

	-- Make the window resizable
	LogWindow:SetResizable(true)
	-- Set dynamic resize bounds based on screen size
	local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
	LogWindow:SetResizeBounds(400, 300, screenWidth - 50, screenHeight - 50)

	-- Create resize grip (bottom-right corner)
	LogWindow.ResizeGrip = CreateFrame('Button', nil, LogWindow)
	LogWindow.ResizeGrip:SetSize(16, 16)
	LogWindow.ResizeGrip:SetPoint('BOTTOMRIGHT', LogWindow, 'BOTTOMRIGHT', -2, 2)
	LogWindow.ResizeGrip:SetNormalTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
	LogWindow.ResizeGrip:SetHighlightTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight')
	LogWindow.ResizeGrip:SetPushedTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down')
	LogWindow.ResizeGrip:EnableMouse(true)
	LogWindow.ResizeGrip:RegisterForDrag('LeftButton')
	LogWindow.ResizeGrip:SetScript('OnDragStart', function(self)
		LogWindow:StartSizing('BOTTOMRIGHT')
	end)
	LogWindow.ResizeGrip:SetScript('OnDragStop', function(self)
		LogWindow:StopMovingOrSizing()
		SaveWindowLayout() -- Save size when resized
	end)

	-- Set the portrait (with safety checks)
	if LogWindow.portrait then
		if LogWindow.portrait.SetTexture then LogWindow.portrait:SetTexture('Interface\\AddOns\\SpartanUI\\images\\LogoSpartanUI') end
	end

	-- Set title
	LogWindow:SetTitle('SpartanUI Logging')

	-- Create control frame below the title (like AuctionFrame's browse/bid/sell tabs area)
	LogWindow.ControlFrame = CreateFrame('Frame', nil, LogWindow)
	LogWindow.ControlFrame:SetPoint('TOPLEFT', LogWindow, 'TOPLEFT', 18, -65)
	LogWindow.ControlFrame:SetPoint('TOPRIGHT', LogWindow, 'TOPRIGHT', -18, -65)
	LogWindow.ControlFrame:SetHeight(55) -- Two rows of controls

	-- First row of controls (like AuctionFrame's search controls)
	-- Search box with proper styling
	LogWindow.SearchBox = CreateFrame('EditBox', 'SUI_LogSearchBox', LogWindow.ControlFrame, 'SearchBoxTemplate')
	LogWindow.SearchBox:SetSize(140, 22)
	LogWindow.SearchBox:SetPoint('TOPLEFT', LogWindow.ControlFrame, 'TOPLEFT', 0, -5)
	LogWindow.SearchBox:SetAutoFocus(false)
	LogWindow.SearchBox:SetScript('OnTextChanged', function(self)
		CurrentSearchTerm = self:GetText()
		UpdateLogDisplay()
	end)
	LogWindow.SearchBox:SetScript('OnEscapePressed', function(self)
		self:SetText('')
		self:ClearFocus()
		CurrentSearchTerm = ''
		UpdateLogDisplay()
	end)

	-- Search label
	LogWindow.SearchLabel = LogWindow.ControlFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	LogWindow.SearchLabel:SetText('Search:')
	LogWindow.SearchLabel:SetPoint('BOTTOMLEFT', LogWindow.SearchBox, 'TOPLEFT', 0, 3)

	-- Global Log Level dropdown (right side of first row)
	LogWindow.GlobalLevelLabel = LogWindow.ControlFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	LogWindow.GlobalLevelLabel:SetText('Global Level:')
	LogWindow.GlobalLevelLabel:SetPoint('TOPRIGHT', LogWindow.ControlFrame, 'TOPRIGHT', -90, -2)

	LogWindow.GlobalLevelDropdown = CreateFrame('Frame', 'SUI_GlobalLogLevelDropdown', LogWindow.ControlFrame, 'UIDropDownMenuTemplate')
	LogWindow.GlobalLevelDropdown:SetPoint('TOPRIGHT', LogWindow.ControlFrame, 'TOPRIGHT', -15, -5)
	UIDropDownMenu_SetWidth(LogWindow.GlobalLevelDropdown, 85)
	-- Set initial dropdown text based on current global level
	local _, globalLevelData = GetLogLevelByPriority(GlobalLogLevel)
	UIDropDownMenu_SetText(LogWindow.GlobalLevelDropdown, globalLevelData.display)

	-- Module Log Level dropdown (center of first row)
	LogWindow.ModuleLevelLabel = LogWindow.ControlFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	LogWindow.ModuleLevelLabel:SetText('Module Level:')
	LogWindow.ModuleLevelLabel:SetPoint('TOP', LogWindow.ControlFrame, 'TOP', -20, -2)

	LogWindow.ModuleLevelDropdown = CreateFrame('Frame', 'SUI_ModuleLogLevelDropdown', LogWindow.ControlFrame, 'UIDropDownMenuTemplate')
	LogWindow.ModuleLevelDropdown:SetPoint('TOP', LogWindow.ControlFrame, 'TOP', 55, -5)
	UIDropDownMenu_SetWidth(LogWindow.ModuleLevelDropdown, 85)
	UIDropDownMenu_SetText(LogWindow.ModuleLevelDropdown, 'Global')

	-- Second row of controls (checkboxes and buttons)
	-- Search all modules checkbox
	LogWindow.SearchAllModules = CreateFrame('CheckButton', 'SUI_SearchAllModules', LogWindow.ControlFrame, 'UICheckButtonTemplate')
	LogWindow.SearchAllModules:SetSize(18, 18)
	LogWindow.SearchAllModules:SetPoint('TOPLEFT', LogWindow.SearchBox, 'BOTTOMLEFT', 0, -10)
	LogWindow.SearchAllModules:SetScript('OnClick', function(self)
		SearchAllModules = self:GetChecked()
		UpdateLogDisplay()
	end)

	LogWindow.SearchAllModulesLabel = LogWindow.ControlFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	LogWindow.SearchAllModulesLabel:SetText('Search All Modules')
	LogWindow.SearchAllModulesLabel:SetPoint('LEFT', LogWindow.SearchAllModules, 'RIGHT', 2, 0)
	LogWindow.SearchAllModulesLabel:SetTextColor(1, 1, 1) -- White text

	-- Auto-scroll checkbox
	LogWindow.AutoScroll = CreateFrame('CheckButton', 'SUI_AutoScroll', LogWindow.ControlFrame, 'UICheckButtonTemplate')
	LogWindow.AutoScroll:SetSize(18, 18)
	LogWindow.AutoScroll:SetPoint('LEFT', LogWindow.SearchAllModulesLabel, 'RIGHT', 15, 0)
	LogWindow.AutoScroll:SetChecked(AutoScrollEnabled)
	LogWindow.AutoScroll:SetScript('OnClick', function(self)
		AutoScrollEnabled = self:GetChecked()
	end)

	LogWindow.AutoScrollLabel = LogWindow.ControlFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	LogWindow.AutoScrollLabel:SetText('Auto-scroll')
	LogWindow.AutoScrollLabel:SetPoint('LEFT', LogWindow.AutoScroll, 'RIGHT', 2, 0)
	LogWindow.AutoScrollLabel:SetTextColor(1, 1, 1) -- White text

	-- Action buttons (styled like AuctionFrame buttons)
	LogWindow.ClearButton = CreateFrame('Button', nil, LogWindow.ControlFrame, 'UIPanelButtonTemplate')
	LogWindow.ClearButton:SetSize(70, 22)
	LogWindow.ClearButton:SetPoint('TOPRIGHT', LogWindow.ControlFrame, 'BOTTOMRIGHT', -80, -5)
	LogWindow.ClearButton:SetText('Clear')
	LogWindow.ClearButton:SetScript('OnClick', function()
		ClearCurrentLogs()
	end)

	LogWindow.ExportButton = CreateFrame('Button', nil, LogWindow.ControlFrame, 'UIPanelButtonTemplate')
	LogWindow.ExportButton:SetSize(70, 22)
	LogWindow.ExportButton:SetPoint('RIGHT', LogWindow.ClearButton, 'LEFT', -5, 0)
	LogWindow.ExportButton:SetText('Export')
	LogWindow.ExportButton:SetScript('OnClick', function()
		ExportCurrentLogs()
	end)

	-- PortraitFrameTemplate already includes a close button, no need to create another

	-- Open Settings button (top right corner like AuctionFrame's "Browse" type buttons)
	LogWindow.OpenSettings = CreateFrame('Button', nil, LogWindow.ControlFrame, 'UIPanelButtonTemplate')
	LogWindow.OpenSettings:SetSize(90, 22)
	LogWindow.OpenSettings:SetPoint('BOTTOMRIGHT', LogWindow.ControlFrame, 'BOTTOMRIGHT', 0, 5)
	LogWindow.OpenSettings:SetText('Settings')
	LogWindow.OpenSettings:SetScript('OnClick', function()
		SUI.Options:ToggleOptions({ 'Help', 'Debug' })
	end)

	-- Create main content area like AuctionFrame (using Blizzard's standard inset style)
	LogWindow.MainContent = CreateFrame('Frame', nil, LogWindow)
	LogWindow.MainContent:SetPoint('TOPLEFT', LogWindow.ControlFrame, 'BOTTOMLEFT', -4, -10)
	LogWindow.MainContent:SetPoint('BOTTOMRIGHT', LogWindow, 'BOTTOMRIGHT', -20, 12)

	-- Left panel for module list (styled like AuctionFrame's category list)
	LogWindow.LeftPanel = CreateFrame('Frame', nil, LogWindow.MainContent)
	LogWindow.LeftPanel:SetPoint('TOPLEFT', LogWindow.MainContent, 'TOPLEFT', 4, 0)
	LogWindow.LeftPanel:SetPoint('BOTTOMLEFT', LogWindow.MainContent, 'BOTTOMLEFT', 4, 0)
	LogWindow.LeftPanel:SetWidth(168)

	-- Add AuctionHouse categories background
	LogWindow.LeftPanel.Background = LogWindow.LeftPanel:CreateTexture(nil, 'BACKGROUND')
	LogWindow.LeftPanel.Background:SetAtlas('auctionhouse-background-categories', true)
	LogWindow.LeftPanel.Background:SetPoint('TOPLEFT', LogWindow.LeftPanel, 'TOPLEFT', 3, -3)

	-- Add nine slice border for left panel
	LogWindow.LeftPanel.NineSlice = CreateFrame('Frame', nil, LogWindow.LeftPanel, 'NineSlicePanelTemplate')
	LogWindow.LeftPanel.NineSlice:SetAllPoints()

	-- Add a header for the module list (like AuctionFrame's "Browse" header)
	LogWindow.ModuleHeader = LogWindow.LeftPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
	LogWindow.ModuleHeader:SetText('Module Categories')
	LogWindow.ModuleHeader:SetPoint('TOP', LogWindow.LeftPanel, 'TOP', 0, -8)
	LogWindow.ModuleHeader:SetTextColor(1, 0.82, 0) -- Gold color like Blizzard headers

	-- Right panel for log text (main display area like AuctionFrame's item list)
	LogWindow.RightPanel = CreateFrame('Frame', nil, LogWindow.MainContent)
	LogWindow.RightPanel:SetPoint('TOPLEFT', LogWindow.LeftPanel, 'TOPRIGHT', 8, 0)
	LogWindow.RightPanel:SetPoint('BOTTOMRIGHT', LogWindow.MainContent, 'BOTTOMRIGHT', -4, 0)

	-- Add AuctionHouse index background
	LogWindow.RightPanel.Background = LogWindow.RightPanel:CreateTexture(nil, 'BACKGROUND')
	LogWindow.RightPanel.Background:SetAtlas('auctionhouse-background-index', true)
	LogWindow.RightPanel.Background:SetPoint('TOPLEFT', LogWindow.RightPanel, 'TOPLEFT', 3, -3)

	-- Add nine slice border for right panel
	LogWindow.RightPanel.NineSlice = CreateFrame('Frame', nil, LogWindow.RightPanel, 'NineSlicePanelTemplate')
	LogWindow.RightPanel.NineSlice:SetAllPoints()

	-- Create scroll frame for module tree in left panel (properly sized to match AH)
	LogWindow.ModuleScrollFrame = CreateFrame('ScrollFrame', nil, LogWindow.LeftPanel, 'UIPanelScrollFrameTemplate')
	LogWindow.ModuleScrollFrame:SetPoint('TOPLEFT', LogWindow.ModuleHeader, 'BOTTOMLEFT', -5, -6)
	LogWindow.ModuleScrollFrame:SetPoint('BOTTOMRIGHT', LogWindow.LeftPanel, 'BOTTOMRIGHT', -25, 2)

	LogWindow.ModuleTree = CreateFrame('Frame', nil, LogWindow.ModuleScrollFrame)
	LogWindow.ModuleScrollFrame:SetScrollChild(LogWindow.ModuleTree)
	LogWindow.ModuleTree:SetSize(140, 1)

	-- Create log text display in right panel (styled like AuctionFrame's main area)
	LogWindow.TextPanel = CreateFrame('ScrollFrame', nil, LogWindow.RightPanel, 'UIPanelScrollFrameTemplate')
	LogWindow.TextPanel:SetPoint('TOPLEFT', LogWindow.RightPanel, 'TOPLEFT', 6, -6)
	LogWindow.TextPanel:SetPoint('BOTTOMRIGHT', LogWindow.RightPanel, 'BOTTOMRIGHT', -25, 2)

	-- Create the text display area
	LogWindow.EditBox = CreateFrame('EditBox', nil, LogWindow.TextPanel)
	LogWindow.EditBox:SetMultiLine(true)
	LogWindow.EditBox:SetFontObject('GameFontHighlightSmall') -- Better font for log display
	LogWindow.EditBox:SetText('No logs active - select a module from the left or enable "Search All Modules"')
	LogWindow.EditBox:SetWidth(LogWindow.TextPanel:GetWidth() - 20)
	LogWindow.EditBox:SetScript('OnTextChanged', function(self)
		ScrollingEdit_OnTextChanged(self, self:GetParent())
	end)
	LogWindow.EditBox:SetScript('OnCursorChanged', function(self, x, y, w, h)
		ScrollingEdit_OnCursorChanged(self, x, y - 10, w, h)
	end)
	LogWindow.EditBox:SetAutoFocus(false)
	LogWindow.EditBox:EnableMouse(true) -- Allow selection for copying
	LogWindow.EditBox:SetTextColor(1, 1, 1) -- White text for better readability
	LogWindow.TextPanel:SetScrollChild(LogWindow.EditBox)

	-- Initialize data structures
	LogWindow.Categories = {}
	LogWindow.categoryButtons = {}
	LogWindow.moduleButtons = {}

	-- Build module categories (like AuctionFrame's item categories)
	CreateModuleCategories()

	-- Setup dropdown functionality
	SetupLogLevelDropdowns()

	-- Load saved window layout (position and size)
	LoadWindowLayout()

	-- Store references for compatibility
	LogWindow.NamespaceListings = LogWindow.ModuleScrollFrame
	LogWindow.OutputSelect = LogWindow.LeftPanel
end

-- Function to highlight search terms in text
local function HighlightSearchTerm(text, searchTerm)
	if not searchTerm or searchTerm == '' then return text end

	-- Case-insensitive search and replace with highlighting
	local highlightColor = '|cffff00ff' -- Bright magenta for search highlights
	local resetColor = '|r'

	-- Escape special characters in search term for pattern matching
	local escapedTerm = searchTerm:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')

	-- For case-insensitive highlighting, we need to find and replace manually
	-- since Lua patterns don't support case-insensitive flags
	local result = text
	local searchLower = escapedTerm:lower()
	local pos = 1

	while pos <= #result do
		-- Find the next occurrence (case-insensitive)
		local textLower = result:lower()
		local startPos, endPos = textLower:find(searchLower, pos, true)

		if not startPos then break end

		-- Extract the actual text with original case
		local actualMatch = result:sub(startPos, endPos)
		local highlightedMatch = highlightColor .. actualMatch .. resetColor

		-- Replace this occurrence
		result = result:sub(1, startPos - 1) .. highlightedMatch .. result:sub(endPos + 1)

		-- Move past this replacement
		pos = startPos + #highlightedMatch
	end

	return result
end

-- Function to check if a log entry matches the search criteria
local function MatchesSearchCriteria(logEntry, searchTerm, logLevel)
	-- Check log level first
	local entryLogLevel = LOG_LEVELS[logEntry.level]
	if not entryLogLevel or entryLogLevel.priority < logLevel then return false end

	-- Check search term
	if searchTerm and searchTerm ~= '' then return logEntry.message:lower():find(searchTerm:lower(), 1, true) ~= nil end

	return true
end

-- Function to update the log display based on current module and filter settings
function UpdateLogDisplay()
	if not LogWindow or not LogWindow.EditBox then return end

	local logText = ''
	local totalEntries = 0
	local filteredCount = 0
	local searchedCount = 0

	if SearchAllModules then
		-- Search across all modules
		logText = 'Search Results Across All Modules:\n\n'

		for moduleName, logs in pairs(LogMessages) do
			local moduleLogLevel = ModuleLogLevels[moduleName] or 0
			local effectiveLogLevel = moduleLogLevel > 0 and moduleLogLevel or GlobalLogLevel

			local moduleMatches = {}
			for _, logEntry in ipairs(logs) do
				totalEntries = totalEntries + 1
				if MatchesSearchCriteria(logEntry, CurrentSearchTerm, effectiveLogLevel) then
					table.insert(moduleMatches, logEntry)
					filteredCount = filteredCount + 1
				end
			end

			if #moduleMatches > 0 then
				logText = logText .. '=== ' .. moduleName .. ' (' .. #moduleMatches .. ' entries) ===\n'
				for _, logEntry in ipairs(moduleMatches) do
					local highlightedText = HighlightSearchTerm(logEntry.formattedMessage, CurrentSearchTerm)
					logText = logText .. highlightedText .. '\n'
					searchedCount = searchedCount + 1
				end
				logText = logText .. '\n'
			end
		end

		if searchedCount == 0 then
			logText = logText .. 'No logs match the current search and filter criteria.'
		else
			logText = 'Search Results: ' .. searchedCount .. ' matches across all modules\n' .. 'Total entries: ' .. totalEntries .. ' | Filtered: ' .. filteredCount .. '\n\n' .. logText
		end
	else
		-- Single module display
		if not ActiveModule then
			LogWindow.EditBox:SetText('No module selected - choose a module from the left or enable "Search All Modules"')
			return
		end

		local logs = LogMessages[ActiveModule] or {}
		totalEntries = #logs

		if totalEntries == 0 then
			LogWindow.EditBox:SetText('No logs for module: ' .. ActiveModule)
			return
		end

		-- Get current module log level for filtering
		local moduleLogLevel = ModuleLogLevels[ActiveModule] or 0
		local effectiveLogLevel = moduleLogLevel > 0 and moduleLogLevel or GlobalLogLevel

		local matchingEntries = {}
		for _, logEntry in ipairs(logs) do
			if MatchesSearchCriteria(logEntry, CurrentSearchTerm, effectiveLogLevel) then
				table.insert(matchingEntries, logEntry)
				filteredCount = filteredCount + 1
			end
		end

		-- Build the display text
		local searchInfo = ''
		if CurrentSearchTerm and CurrentSearchTerm ~= '' then searchInfo = ' | Search: "' .. CurrentSearchTerm .. '"' end

		logText = 'Logs for ' .. ActiveModule .. ' (' .. totalEntries .. ' total, ' .. filteredCount .. ' shown' .. searchInfo .. '):\n\n'

		if #matchingEntries > 0 then
			for _, logEntry in ipairs(matchingEntries) do
				local highlightedText = HighlightSearchTerm(logEntry.formattedMessage, CurrentSearchTerm)
				logText = logText .. highlightedText .. '\n'
			end
		else
			logText = logText .. 'No logs match current filter and search criteria.'
		end
	end

	LogWindow.EditBox:SetText(logText)

	-- Auto-scroll to bottom if enabled
	if AutoScrollEnabled and LogWindow.EditBox then LogWindow.EditBox:SetCursorPosition(string.len(logText)) end

	-- Update module level dropdown text
	if LogWindow.ModuleLevelDropdown and ActiveModule then
		local moduleLogLevel = ModuleLogLevels[ActiveModule] or 0
		local levelText = 'Global'
		if moduleLogLevel > 0 then
			for level, data in pairs(LOG_LEVELS) do
				if data.priority == moduleLogLevel then
					levelText = data.display
					break
				end
			end
		end
		UIDropDownMenu_SetText(LogWindow.ModuleLevelDropdown, levelText)
	end
end

-- Function to clear logs for the current module or all modules
function ClearCurrentLogs()
	if SearchAllModules then
		-- Clear all logs
		for moduleName in pairs(LogMessages) do
			LogMessages[moduleName] = {}
		end
		print('|cFF00FF00SpartanUI Logging:|r All logs cleared.')
	else
		-- Clear current module logs
		if ActiveModule and LogMessages[ActiveModule] then
			LogMessages[ActiveModule] = {}
			print('|cFF00FF00SpartanUI Logging:|r Logs cleared for module: ' .. ActiveModule)
		else
			print('|cFFFFFF00SpartanUI Logging:|r No active module selected.')
		end
	end

	UpdateLogDisplay()
end

-- Function to export current logs to a copyable format
function ExportCurrentLogs()
	if not LogWindow then return end

	-- Create export frame if it doesn't exist
	if not LogWindow.ExportFrame then
		LogWindow.ExportFrame = CreateFrame('Frame', 'SUI_LogExportFrame', UIParent, 'PortraitFrameTemplate')
		LogWindow.ExportFrame:SetSize(500, 400)
		LogWindow.ExportFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
		LogWindow.ExportFrame:SetFrameStrata('DIALOG')
		LogWindow.ExportFrame:Hide()

		-- Set the portrait (with safety checks)
		if LogWindow.ExportFrame.portrait then
			if LogWindow.ExportFrame.portrait.SetTexture then LogWindow.ExportFrame.portrait:SetTexture('Interface\\AddOns\\SpartanUI\\images\\LogoSpartanUI') end
		end

		-- Set title
		LogWindow.ExportFrame:SetTitle('Export Logs')

		-- Scroll frame for export text (properly styled)
		LogWindow.ExportFrame.ScrollFrame = CreateFrame('ScrollFrame', nil, LogWindow.ExportFrame, 'UIPanelScrollFrameTemplate')
		LogWindow.ExportFrame.ScrollFrame:SetPoint('TOPLEFT', LogWindow.ExportFrame.TitleBar, 'BOTTOMLEFT', 0, -10)
		LogWindow.ExportFrame.ScrollFrame:SetPoint('BOTTOMRIGHT', LogWindow.ExportFrame, 'BOTTOMRIGHT', -26, 40)

		LogWindow.ExportFrame.EditBox = CreateFrame('EditBox', nil, LogWindow.ExportFrame.ScrollFrame)
		LogWindow.ExportFrame.EditBox:SetMultiLine(true)
		LogWindow.ExportFrame.EditBox:SetFontObject('GameFontHighlightSmall')
		LogWindow.ExportFrame.EditBox:SetWidth(LogWindow.ExportFrame.ScrollFrame:GetWidth() - 20)
		LogWindow.ExportFrame.EditBox:SetAutoFocus(false)
		LogWindow.ExportFrame.EditBox:SetTextColor(1, 1, 1) -- White text
		LogWindow.ExportFrame.EditBox:SetScript('OnTextChanged', function(self)
			ScrollingEdit_OnTextChanged(self, self:GetParent())
		end)
		LogWindow.ExportFrame.EditBox:SetScript('OnCursorChanged', function(self, x, y, w, h)
			ScrollingEdit_OnCursorChanged(self, x, y - 10, w, h)
		end)
		LogWindow.ExportFrame.ScrollFrame:SetScrollChild(LogWindow.ExportFrame.EditBox)

		-- Instructions (styled like Blizzard help text)
		LogWindow.ExportFrame.Instructions = LogWindow.ExportFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
		LogWindow.ExportFrame.Instructions:SetText('Select all text (Ctrl+A) and copy (Ctrl+C) to export logs')
		LogWindow.ExportFrame.Instructions:SetPoint('BOTTOM', LogWindow.ExportFrame, 'BOTTOM', 0, 15)
		LogWindow.ExportFrame.Instructions:SetTextColor(1, 0.82, 0) -- Gold color like other instructions
	end

	-- Generate export text
	local exportText = '=== SpartanUI Log Export ===\n'
	exportText = exportText .. 'Generated: ' .. date('%Y-%m-%d %H:%M:%S') .. '\n'
	exportText = exportText .. 'Global Log Level: ' .. (GetLogLevelByPriority(GlobalLogLevel) or 'Unknown') .. '\n\n'

	if SearchAllModules then
		exportText = exportText .. '=== ALL MODULES ===\n\n'
		for moduleName, logs in pairs(LogMessages) do
			if #logs > 0 then
				exportText = exportText .. '--- Module: ' .. moduleName .. ' (' .. #logs .. ' entries) ---\n'

				local moduleLogLevel = ModuleLogLevels[moduleName] or 0
				local effectiveLogLevel = moduleLogLevel > 0 and moduleLogLevel or GlobalLogLevel

				for _, logEntry in ipairs(logs) do
					local entryLogLevel = LOG_LEVELS[logEntry.level]
					if entryLogLevel and entryLogLevel.priority >= effectiveLogLevel then
						-- Remove color codes for export
						local cleanMessage = logEntry.formattedMessage:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
						exportText = exportText .. cleanMessage .. '\n'
					end
				end
				exportText = exportText .. '\n'
			end
		end
	else
		if ActiveModule and LogMessages[ActiveModule] then
			exportText = exportText .. '=== Module: ' .. ActiveModule .. ' ===\n\n'

			local logs = LogMessages[ActiveModule]
			local moduleLogLevel = ModuleLogLevels[ActiveModule] or 0
			local effectiveLogLevel = moduleLogLevel > 0 and moduleLogLevel or GlobalLogLevel

			for _, logEntry in ipairs(logs) do
				local entryLogLevel = LOG_LEVELS[logEntry.level]
				if entryLogLevel and entryLogLevel.priority >= effectiveLogLevel then
					-- Apply search filtering if active
					if not CurrentSearchTerm or CurrentSearchTerm == '' or logEntry.message:lower():find(CurrentSearchTerm:lower(), 1, true) then
						-- Remove color codes for export
						local cleanMessage = logEntry.formattedMessage:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
						exportText = exportText .. cleanMessage .. '\n'
					end
				end
			end
		else
			exportText = exportText .. 'No active module selected.\n'
		end
	end

	exportText = exportText .. '\n=== End of Export ==='

	-- Set text and show frame
	LogWindow.ExportFrame.EditBox:SetText(exportText)
	LogWindow.ExportFrame:Show()

	-- Select all text for easy copying
	LogWindow.ExportFrame.EditBox:SetFocus()
	LogWindow.ExportFrame.EditBox:HighlightText()

	print('|cFF00FF00SpartanUI Logging:|r Logs exported. Use Ctrl+A and Ctrl+C to copy.')
end

-- Setup the log level dropdown functionality
function SetupLogLevelDropdowns()
	-- Create ordered list of log levels by priority
	local orderedLevels = {}
	for logLevel, data in pairs(LOG_LEVELS) do
		table.insert(orderedLevels, { level = logLevel, data = data })
	end
	table.sort(orderedLevels, function(a, b)
		return a.data.priority < b.data.priority
	end)

	-- Global log level dropdown
	UIDropDownMenu_Initialize(LogWindow.GlobalLevelDropdown, function(self, level)
		local info = UIDropDownMenu_CreateInfo()

		-- Add log levels in priority order
		for _, levelData in ipairs(orderedLevels) do
			info.text = levelData.data.display
			info.value = levelData.data.priority
			info.func = function()
				GlobalLogLevel = levelData.data.priority
				logger.DB.globalLogLevel = GlobalLogLevel
				UIDropDownMenu_SetText(LogWindow.GlobalLevelDropdown, levelData.data.display)
				UpdateLogDisplay() -- Refresh current view
			end
			info.checked = (GlobalLogLevel == levelData.data.priority)
			UIDropDownMenu_AddButton(info)
		end
	end)

	-- Module log level dropdown
	UIDropDownMenu_Initialize(LogWindow.ModuleLevelDropdown, function(self, level)
		if not ActiveModule then return end

		local info = UIDropDownMenu_CreateInfo()

		-- Add "Use Global" option
		info.text = 'Use Global'
		info.value = 0
		info.func = function()
			ModuleLogLevels[ActiveModule] = 0
			logger.DB.moduleLogLevels[ActiveModule] = 0
			UIDropDownMenu_SetText(LogWindow.ModuleLevelDropdown, 'Global')
			UpdateLogDisplay()
		end
		info.checked = ((ModuleLogLevels[ActiveModule] or 0) == 0)
		UIDropDownMenu_AddButton(info)

		-- Add separator
		info = UIDropDownMenu_CreateInfo()
		info.text = ''
		info.disabled = true
		UIDropDownMenu_AddButton(info)

		-- Add log levels in priority order
		for _, levelData in ipairs(orderedLevels) do
			info = UIDropDownMenu_CreateInfo()
			info.text = levelData.data.display
			info.value = levelData.data.priority
			info.func = function()
				ModuleLogLevels[ActiveModule] = levelData.data.priority
				logger.DB.moduleLogLevels[ActiveModule] = levelData.data.priority
				UIDropDownMenu_SetText(LogWindow.ModuleLevelDropdown, levelData.data.display)
				UpdateLogDisplay()
			end
			info.checked = ((ModuleLogLevels[ActiveModule] or 0) == levelData.data.priority)
			UIDropDownMenu_AddButton(info)
		end
	end)
end

---Enhanced logging function with log levels
---@param debugText string The message to log
---@param module string The module name
---@param level? string Log level (debug, info, warning, error, critical) - defaults to 'info'
function SUI.Log(debugText, module, level)
	level = level or 'info'

	-- Initialize module if it doesn't exist
	if not LogMessages[module] then
		LogMessages[module] = {}

		-- Add new module to category system if log window exists
		if LogWindow and LogWindow.Categories then
			-- Determine category and add module
			local category = CategorizeModule(module)

			if not LogWindow.Categories[category] then LogWindow.Categories[category] = {
				name = category,
				modules = {},
				expanded = false,
				button = nil,
			} end

			-- Add module to category if not already present
			local moduleExists = false
			for _, existingModule in ipairs(LogWindow.Categories[category].modules) do
				if existingModule == module then
					moduleExists = true
					break
				end
			end

			if not moduleExists then
				table.insert(LogWindow.Categories[category].modules, module)
				table.sort(LogWindow.Categories[category].modules)

				-- Rebuild the category tree to include new module
				local sortedCategories = {}
				for categoryName, _ in pairs(LogWindow.Categories) do
					table.insert(sortedCategories, categoryName)
				end
				table.sort(sortedCategories)
				CreateCategoryTree(sortedCategories)
			end
		end

		logger.DB.modules[module] = true -- Default to enabled for logging approach
		if logger.options then logger.options.args[module] = {
			name = module,
			type = 'toggle',
			order = (#logger.options.args + 1),
		} end
	end

	-- Validate log level
	local logLevel = LOG_LEVELS[level]
	if not logLevel then
		level = 'info'
		logLevel = LOG_LEVELS[level]
	end

	-- LOGGING APPROACH: Always capture all messages, filter during display
	-- This allows dynamic log level changes without losing historical data
	local shouldCapture = true

	-- Only skip if logging is completely disabled for this module specifically
	if logger.DB.modules[module] == false then shouldCapture = false end

	if not shouldCapture then return end

	-- Create log entry with timestamp and level
	local timestamp = date('%H:%M:%S')
	local coloredLevel = logLevel.color .. '[' .. logLevel.display:upper() .. ']|r'
	local formattedMessage = timestamp .. ' ' .. coloredLevel .. ' ' .. tostring(debugText)

	-- Store the log entry
	local logEntry = {
		timestamp = GetTime(),
		level = level,
		message = tostring(debugText),
		formattedMessage = formattedMessage,
	}

	table.insert(LogMessages[module], logEntry)

	-- Maintain maximum log history
	local maxHistory = logger.DB.maxLogHistory or 1000
	if #LogMessages[module] > maxHistory then table.remove(LogMessages[module], 1) end

	-- Initialize log window if needed
	if not LogWindow then CreateLogWindow() end

	-- Update display if this module is currently active
	if ActiveModule and ActiveModule == module then UpdateLogDisplay() end
end

-- Compatibility function to maintain existing SUI.Debug calls
---@param debugText string The message to log
---@param module string The module name
---@param level? string Log level (debug, info, warning, error, critical) - defaults to 'info'
function SUI.Debug(debugText, module, level)
	-- Redirect to the new logging function
	SUI.Log(debugText, module, level)
end

local function AddOptions()
	---@type AceConfig.OptionsTable
	local options = {
		name = 'Logging',
		type = 'group',
		get = function(info)
			return logger.DB.modules[info[#info]]
		end,
		set = function(info, val)
			logger.DB.modules[info[#info]] = val
		end,
		args = {
			Description = {
				name = 'SpartanUI uses a comprehensive logging system that captures all messages and filters by log level.\nModules can be individually disabled to stop collection entirely.',
				type = 'description',
				order = 0,
			},
			GlobalLogLevel = {
				name = 'Global Log Level',
				desc = 'Minimum log level to display globally. Individual modules can override this.',
				type = 'select',
				values = function()
					local values = {}
					-- Create ordered list to ensure proper display order
					local orderedLevels = {}
					for level, data in pairs(LOG_LEVELS) do
						table.insert(orderedLevels, { level = level, data = data })
					end
					table.sort(orderedLevels, function(a, b)
						return a.data.priority < b.data.priority
					end)

					for _, levelData in ipairs(orderedLevels) do
						values[levelData.data.priority] = levelData.data.display
					end
					return values
				end,
				sorting = function()
					-- Return sorted order for dropdown
					local sorted = {}
					local orderedLevels = {}
					for level, data in pairs(LOG_LEVELS) do
						table.insert(orderedLevels, { level = level, data = data })
					end
					table.sort(orderedLevels, function(a, b)
						return a.data.priority < b.data.priority
					end)

					for _, levelData in ipairs(orderedLevels) do
						table.insert(sorted, levelData.data.priority)
					end
					return sorted
				end,
				get = function(info)
					return logger.DB.globalLogLevel
				end,
				set = function(info, val)
					logger.DB.globalLogLevel = val
					GlobalLogLevel = val
					if LogWindow then UpdateLogDisplay() end
				end,
				order = 1,
			},
			CaptureWarningsErrors = {
				name = 'Always Capture Warnings/Errors',
				desc = 'Always capture warning, error, and critical messages regardless of log level settings.',
				type = 'toggle',
				get = function(info)
					return logger.DB.captureWarningsErrors
				end,
				set = function(info, val)
					logger.DB.captureWarningsErrors = val
				end,
				order = 2,
			},
			MaxLogHistory = {
				name = 'Maximum Log History',
				desc = 'Maximum number of log entries to keep per module.',
				type = 'range',
				min = 100,
				max = 5000,
				step = 100,
				get = function(info)
					return logger.DB.maxLogHistory
				end,
				set = function(info, val)
					logger.DB.maxLogHistory = val
				end,
				order = 3,
			},
			ModuleHeader = {
				name = 'Module Logging Control',
				type = 'header',
				order = 10,
			},
			EnableAll = {
				name = 'Enable All Modules',
				desc = 'Enable or disable logging for all modules at once.',
				type = 'toggle',
				order = 11,
				get = function(info)
					-- Check if all modules are enabled
					for _, enabled in pairs(logger.DB.modules) do
						if not enabled then return false end
					end
					return true
				end,
				set = function(info, val)
					for k, _ in pairs(logger.DB.modules) do
						logger.DB.modules[k] = val
					end
				end,
			},
		},
	}

	for k, _ in pairs(logger.DB.modules) do
		options.args[k] = {
			name = k,
			desc = 'Enable logging for the ' .. k .. ' module.',
			type = 'toggle',
			order = (#options.args + 1),
		}
	end
	logger.options = options
	SUI.Options:AddOptions(options, 'Logging', 'Help')
end

function logger:OnInitialize()
	local defaults = {
		globalLogLevel = 2, -- Default to 'info' and above
		captureWarningsErrors = true, -- Always capture warnings and errors
		maxLogHistory = 1000, -- Maximum log entries per module
		window = {
			width = 800,
			height = 538,
			point = 'CENTER',
			relativeTo = 'UIParent',
			relativePoint = 'CENTER',
			x = 0,
			y = 0,
		},
		modules = {
			['*'] = true, -- Default to enabled for logging approach
			Core = true,
		},
		moduleLogLevels = {
			['*'] = 0, -- Use global level by default
		},
	}
	logger.Database = SUI.SpartanUIDB:RegisterNamespace('Logger', { profile = defaults })
	logger.DB = logger.Database.profile

	-- Initialize log structures
	for k, _ in pairs(logger.DB.modules) do
		LogMessages[k] = {}
	end

	-- Load settings
	GlobalLogLevel = logger.DB.globalLogLevel or 2
	ModuleLogLevels = logger.DB.moduleLogLevels or {}

	if SUI:IsModuleEnabled('Chatbox') then logger:RegisterEvent('ADDON_LOADED') end
end

function logger:OnEnable()
	CreateLogWindow()

	local function ToggleLogWindow(comp)
		if not LogWindow then CreateLogWindow() end
		if LogWindow:IsVisible() then
			LogWindow:Hide()
		else
			LogWindow:Show()
		end
	end

	SUI:AddChatCommand('debug', ToggleLogWindow, 'Toggles the SpartanUI Logging window display')
	SUI:AddChatCommand('logs', ToggleLogWindow, 'Toggles the SpartanUI Logging window display')
	AddOptions()
end

local function RefreshData(self)
	local function OnMouseDown(line, button)
		local text = line.Text:GetText()
		if button == 'RightButton' then
			SUI.Chat:SetEditBoxMessage(text)
		elseif button == 'MiddleButton' then
			local rawData = line:GetParent():GetAttributeData().rawValue
			if rawData.IsObjectType and rawData:IsObjectType('Texture') then
				-- _G.TEX = rawData
				SUI:Print('_G.TEX set to: ', text)
			else
				-- _G.FRAME = rawData
				SUI:Print('_G.FRAME set to: ', text)
			end
		else
			TableAttributeDisplayValueButton_OnMouseDown(line)
		end
	end

	local scrollFrame = self.LinesScrollFrame or TableAttributeDisplay.LinesScrollFrame
	if not scrollFrame then return end
	for _, child in next, { scrollFrame.LinesContainer:GetChildren() } do
		if child.ValueButton and child.ValueButton:GetScript('OnMouseDown') ~= OnMouseDown then child.ValueButton:SetScript('OnMouseDown', OnMouseDown) end
	end
end

function logger:ADDON_LOADED(_, addon)
	if addon == 'Blizzard_DebugTools' then
		hooksecurefunc(TableInspectorMixin, 'RefreshAllData', RefreshData)
		hooksecurefunc(TableAttributeDisplay.dataProviders[2], 'RefreshData', RefreshData)
		logger:UnregisterEvent('ADDON_LOADED')
	end
end
