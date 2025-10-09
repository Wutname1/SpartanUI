---@class LibAT
local LibAT = LibAT
local logger = LibAT:NewModule('Handler.Logger') ---@class LibAT.LoggerInternal : AceAddon, AceEvent-3.0, AceConsole-3.0
LibAT.Logger = logger
logger.description = 'SpartanUI Logging System'

-- Use LibAT shared UI components
local UI = LibAT.UI

----------------------------------------------------------------------------------------------------
-- Type Definitions for Logger System
----------------------------------------------------------------------------------------------------

---@alias LogLevel
---| "debug"    # Detailed debugging information
---| "info"     # General informational messages
---| "warning"  # Warning conditions
---| "error"    # Error conditions
---| "critical" # Critical system failures

---Logger object returned by RegisterAddon
---@class LoggerObject
---@field log fun(message: string, level?: LogLevel): nil
---@field debug fun(message: string): nil
---@field info fun(message: string): nil
---@field warning fun(message: string): nil
---@field error fun(message: string): nil
---@field critical fun(message: string): nil
---@field RegisterCategory fun(self: LoggerObject, categoryName: string): LoggerObject
---@field Categories table<string, LoggerObject>

---Internal Logger Handler (LibAT.Handlers.Logger)
---@class LibAT.LoggerInternal : LibAT.Module
---@field description string

---External Logger API (LibAT.Logger) - for third-party addons
---@class LibAT.Logger
---@field RegisterAddon fun(addonName: string, categories?: string[]): LoggerObject

----------------------------------------------------------------------------------------------------
local LogWindow = nil ---@type table|Frame
local LogMessages = {}
local ScrollListing = {}
local ActiveModule = nil

-- Log levels with colors, priorities, and display names
local LOG_LEVELS = {
	['debug'] = {color = '|cff888888', priority = 1, display = 'Debug'},
	['info'] = {color = '|cff00ff00', priority = 2, display = 'Info'},
	['warning'] = {color = '|cffffff00', priority = 3, display = 'Warning'},
	['error'] = {color = '|cffff0000', priority = 4, display = 'Error'},
	['critical'] = {color = '|cffff00ff', priority = 5, display = 'Critical'}
}

-- Global and per-module log level settings
local GlobalLogLevel = 2 -- Default to 'info' and above
local ModuleLogLevels = {} -- Per-module overrides

-- Search and UI state
local CurrentSearchTerm = ''
local SearchAllModules = false
local AutoScrollEnabled = true

-- Registration system for external addons
local RegisteredAddons = {} -- Simple addons registered under "External Addons"
local AddonCategories = {} -- Complex addons with custom categories
local AddonLoggers = {} -- Cache of logger functions by addon name

-- Helper function to get log level by priority
local function GetLogLevelByPriority(priority)
	for level, data in pairs(LOG_LEVELS) do
		if data.priority == priority then
			return level, data
		end
	end
	return 'info', LOG_LEVELS['info'] -- Default fallback
end

-- Function to parse and categorize log sources using hierarchical system
-- Returns: category, subCategory, subSubCategory, sourceType
local function ParseLogSource(sourceName)
	-- Check if this is a registered simple addon (gets its own top-level category with Core subcategory)
	if RegisteredAddons[sourceName] then
		return sourceName, 'Core', nil, 'subCategory'
	end

	-- Check if this is part of a registered addon category hierarchy
	for addonName, categoryData in pairs(AddonCategories) do
		-- Check for three-level pattern: "AddonName.subCategory.subSubCategory"
		local subCategory, subSubCategory = sourceName:match('^' .. addonName .. '%.([^%.]+)%.(.+)')
		if subCategory and subSubCategory then
			return addonName, subCategory, subSubCategory, 'subSubCategory'
		end

		-- Check for two-level pattern: "AddonName.subCategory"
		local subCategoryOnly = sourceName:match('^' .. addonName .. '%.(.+)')
		if subCategoryOnly then
			return addonName, subCategoryOnly, nil, 'subCategory'
		end
	end

	-- Fall back to LibAT internal categorization with hierarchy support
	local internalCategories = {
		['Core'] = {'Core', 'Framework', 'Events', 'Options', 'Database', 'Profiles'},
		['UI Components'] = {'UnitFrames', 'Minimap', 'Artwork', 'ActionBars', 'ChatBox', 'Tooltips'},
		['Handlers'] = {'Handler', 'Logger', 'ChatCommands', 'Compatibility'},
		['Development'] = {'Debug', 'Test', 'Dev', 'Plugin'}
	}

	-- Check for internal three-level hierarchy: "System.Component.SubComponent"
	local parts = {}
	for part in sourceName:gmatch('[^%.]+') do
		table.insert(parts, part)
	end

	if #parts >= 3 then
		-- Check if first part matches any internal category keywords
		for category, keywords in pairs(internalCategories) do
			for _, keyword in ipairs(keywords) do
				if parts[1]:lower():find(keyword:lower()) or parts[2]:lower():find(keyword:lower()) then
					return category, parts[1] .. '.' .. parts[2], table.concat(parts, '.', 3), 'subSubCategory'
				end
			end
		end
	elseif #parts == 2 then
		-- Check for two-level internal hierarchy
		for category, keywords in pairs(internalCategories) do
			for _, keyword in ipairs(keywords) do
				if parts[1]:lower():find(keyword:lower()) then
					return category, parts[1], parts[2], 'subSubCategory'
				end
			end
		end
	end

	-- Single-level categorization fallback
	for category, keywords in pairs(internalCategories) do
		for _, keyword in ipairs(keywords) do
			if sourceName:lower():find(keyword:lower()) then
				return category, sourceName, nil, 'subCategory'
			end
		end
	end

	-- Default category for unmatched sources
	return 'Other Sources', sourceName, nil, 'subCategory'
end

-- Function to create hierarchical log source tree (like AuctionFrame categories)
function CreateLogSourceCategories()
	if not LogWindow then
		return
	end

	-- Clear existing data
	LogWindow.Categories = {}
	ScrollListing = {}

	-- Organize log sources into hierarchical categories
	for sourceName, _ in pairs(logger.DB.modules) do
		local category, subCategory, subSubCategory, sourceType = ParseLogSource(sourceName)

		-- Initialize category if it doesn't exist
		if not LogWindow.Categories[category] then
			LogWindow.Categories[category] = {
				name = category,
				subCategories = {},
				expanded = AddonCategories[category] and AddonCategories[category].expanded or false,
				button = nil,
				-- Mark as addon category if it's in AddonCategories OR RegisteredAddons
				isAddonCategory = (AddonCategories[category] ~= nil) or (RegisteredAddons[category] ~= nil)
			}
		end

		if sourceType == 'subCategory' then
			-- This is a direct subCategory under the main category
			if not LogWindow.Categories[category].subCategories[subCategory] then
				LogWindow.Categories[category].subCategories[subCategory] = {
					name = subCategory,
					sourceName = sourceName,
					subSubCategories = {},
					expanded = false,
					button = nil,
					type = 'subCategory'
				}
			end
		elseif sourceType == 'subSubCategory' then
			-- This has a subSubCategory level
			if not LogWindow.Categories[category].subCategories[subCategory] then
				LogWindow.Categories[category].subCategories[subCategory] = {
					name = subCategory,
					subSubCategories = {},
					expanded = false,
					button = nil,
					type = 'subCategory'
				}
			end

			LogWindow.Categories[category].subCategories[subCategory].subSubCategories[subSubCategory] = {
				name = subSubCategory,
				sourceName = sourceName,
				button = nil,
				type = 'subSubCategory'
			}
		end

		table.insert(
			ScrollListing,
			{
				text = sourceName,
				value = sourceName,
				category = category,
				subCategory = subCategory,
				subSubCategory = subSubCategory,
				sourceType = sourceType
			}
		)
	end

	-- Sort categories and their contents
	local sortedCategories = {}
	for categoryName, categoryData in pairs(LogWindow.Categories) do
		table.insert(sortedCategories, categoryName)

		-- Sort subCategories
		local sortedSubCategories = {}
		for subCategoryName, _ in pairs(categoryData.subCategories) do
			table.insert(sortedSubCategories, subCategoryName)
		end
		table.sort(sortedSubCategories)
		categoryData.sortedSubCategories = sortedSubCategories

		-- Sort subSubCategories within each subCategory
		for _, subCategoryData in pairs(categoryData.subCategories) do
			local sortedSubSubCategories = {}
			for subSubCategoryName, _ in pairs(subCategoryData.subSubCategories) do
				table.insert(sortedSubSubCategories, subSubCategoryName)
			end
			table.sort(sortedSubSubCategories)
			subCategoryData.sortedSubSubCategories = sortedSubSubCategories
		end
	end
	table.sort(sortedCategories)

	-- Create the visual tree structure
	CreateCategoryTree(sortedCategories)
end

-- Function to create the visual category tree (styled like AuctionFrame's category list)
function CreateCategoryTree(sortedCategories)
	if not LogWindow or not LogWindow.ModuleTree then
		return
	end

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
	local buttonHeight = 21 -- Standard AuctionHouse button height

	for _, categoryName in ipairs(sortedCategories) do
		local categoryData = LogWindow.Categories[categoryName]
		local subCategoryCount = 0

		-- Count total items in this category (subCategories + subSubCategories)
		if categoryData.subCategories then
			for _, subCategoryData in pairs(categoryData.subCategories) do
				subCategoryCount = subCategoryCount + 1
				if subCategoryData.subSubCategories then
					for _, _ in pairs(subCategoryData.subSubCategories) do
						subCategoryCount = subCategoryCount + 1
					end
				end
			end
		end

		-- Check if this category only has a single "Core" subcategory (make it directly selectable)
		local isCoreOnly = (subCategoryCount == 1 and categoryData.sortedSubCategories and #categoryData.sortedSubCategories == 1 and categoryData.sortedSubCategories[1] == 'Core')

		if isCoreOnly then
			-- Create a directly selectable button (top-level category style, but selectable)
			local coreSubCategory = categoryData.subCategories['Core']
			local categoryButton = UI.CreateFilterButton(LogWindow.ModuleTree, nil)
			categoryButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', 3, yOffset)

			local categoryInfo = {
				type = 'category',
				name = categoryName,
				categoryIndex = categoryName,
				isToken = categoryData.isAddonCategory,
				selected = (ActiveModule == coreSubCategory.sourceName)
			}
			UI.SetupFilterButton(categoryButton, categoryInfo)

			-- No expand/collapse indicator for core-only categories

			-- Make it selectable
			categoryButton:SetScript(
				'OnClick',
				function(self)
					-- Update button states (clear all selected states)
					for _, btn in pairs(LogWindow.moduleButtons) do
						btn.SelectedTexture:Hide()
						btn:SetNormalFontObject(GameFontHighlightSmall)
					end
					-- Set this button as selected
					self.SelectedTexture:Show()
					self:SetNormalFontObject(GameFontNormalSmall)

					ActiveModule = coreSubCategory.sourceName
					UpdateLogDisplay()
				end
			)

			-- Standard hover effects
			categoryButton:SetScript(
				'OnEnter',
				function(self)
					self.HighlightTexture:Show()
				end
			)
			categoryButton:SetScript(
				'OnLeave',
				function(self)
					self.HighlightTexture:Hide()
				end
			)

			table.insert(LogWindow.moduleButtons, categoryButton)
			yOffset = yOffset - (buttonHeight + 1)
		else
			-- Create expandable category button (has multiple subcategories)
			local categoryButton = UI.CreateFilterButton(LogWindow.ModuleTree, 'LibAT_CategoryButton_' .. categoryName)
			categoryButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', 3, yOffset)

			-- Set up category button using Blizzard's helper function
			local categoryInfo = {
				type = 'category',
				name = categoryName .. ' (' .. subCategoryCount .. ')',
				categoryIndex = categoryName,
				isToken = categoryData.isAddonCategory, -- Use isToken for external addons (matches Blizzard's pattern)
				selected = false
			}
			UI.SetupFilterButton(categoryButton, categoryInfo)

			-- Add expand/collapse indicator
			categoryButton.indicator = categoryButton:CreateTexture(nil, 'OVERLAY')
			categoryButton.indicator:SetSize(15, 15)
			categoryButton.indicator:SetPoint('LEFT', categoryButton, 'LEFT', 2, 0)
			if categoryData.expanded then
				categoryButton.indicator:SetAtlas('uitools-icon-minimize')
			else
				categoryButton.indicator:SetAtlas('uitools-icon-plus')
			end

			-- Override text color for gold category headers
			categoryButton.Text:SetTextColor(1, 0.82, 0)

			-- Category button functionality
			categoryButton:SetScript(
				'OnClick',
				function(self)
					categoryData.expanded = not categoryData.expanded

					-- Persist expansion state for registered addon categories
					if categoryData.isAddonCategory and AddonCategories[categoryName] then
						AddonCategories[categoryName].expanded = categoryData.expanded
					end

					if categoryData.expanded then
						self.indicator:SetAtlas('uitools-icon-minimize')
					else
						self.indicator:SetAtlas('uitools-icon-plus')
					end
					CreateCategoryTree(sortedCategories) -- Rebuild tree
				end
			)

			-- Standard hover effects
			categoryButton:SetScript(
				'OnEnter',
				function(self)
					self.HighlightTexture:Show()
				end
			)
			categoryButton:SetScript(
				'OnLeave',
				function(self)
					self.HighlightTexture:Hide()
				end
			)

			categoryData.button = categoryButton
			table.insert(LogWindow.categoryButtons, categoryButton)
			yOffset = yOffset - (buttonHeight + 1)
		end

		-- Create subCategory and subSubCategory buttons if category is expanded (skip for core-only categories)
		if categoryData.expanded and not isCoreOnly then
			for _, subCategoryName in ipairs(categoryData.sortedSubCategories) do
				local subCategoryData = categoryData.subCategories[subCategoryName]

				-- Create subCategory button using the proper template
				local subCategoryButton = UI.CreateFilterButton(LogWindow.ModuleTree, nil)
				subCategoryButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', 3, yOffset)

				-- Set up subCategory button using Blizzard's helper function
				local subCategoryInfo = {
					type = 'subCategory',
					name = subCategoryName,
					subCategoryIndex = subCategoryName,
					selected = (ActiveModule == (subCategoryData.sourceName or subCategoryName))
				}
				UI.SetupFilterButton(subCategoryButton, subCategoryInfo) -- If this subCategory has subSubCategories, add expand/collapse indicator
				if subCategoryData.subSubCategories and next(subCategoryData.subSubCategories) then
					subCategoryButton.indicator = subCategoryButton:CreateTexture(nil, 'OVERLAY')
					subCategoryButton.indicator:SetSize(12, 12)
					subCategoryButton.indicator:SetPoint('LEFT', subCategoryButton, 'LEFT', 2, 0)
					if subCategoryData.expanded then
						subCategoryButton.indicator:SetAtlas('uitools-icon-minimize')
					else
						subCategoryButton.indicator:SetAtlas('uitools-icon-plus')
					end
				end

				-- Standard hover effects
				subCategoryButton:SetScript(
					'OnEnter',
					function(self)
						self.HighlightTexture:Show()
					end
				)
				subCategoryButton:SetScript(
					'OnLeave',
					function(self)
						self.HighlightTexture:Hide()
					end
				)

				-- SubCategory functionality
				subCategoryButton:SetScript(
					'OnClick',
					function(self)
						-- If this has subSubCategories, toggle expansion
						if subCategoryData.subSubCategories and next(subCategoryData.subSubCategories) then
							subCategoryData.expanded = not subCategoryData.expanded
							if self.indicator then
								if subCategoryData.expanded then
									self.indicator:SetAtlas('uitools-icon-minimize')
								else
									self.indicator:SetAtlas('uitools-icon-plus')
								end
							end
							CreateCategoryTree(sortedCategories) -- Rebuild tree
						else
							-- This is a selectable log source
							-- Update button states (clear all selected states)
							for _, btn in pairs(LogWindow.moduleButtons) do
								btn.SelectedTexture:Hide()
								btn:SetNormalFontObject(GameFontHighlightSmall)
							end
							-- Set this button as selected
							self.SelectedTexture:Show()
							self:SetNormalFontObject(GameFontNormalSmall)

							ActiveModule = subCategoryData.sourceName or subCategoryName
							UpdateLogDisplay()
						end
					end
				)

				table.insert(LogWindow.moduleButtons, subCategoryButton)
				yOffset = yOffset - (buttonHeight + 1)

				-- Create subSubCategory buttons if subCategory is expanded
				if subCategoryData.expanded and subCategoryData.sortedSubSubCategories then
					for _, subSubCategoryName in ipairs(subCategoryData.sortedSubSubCategories) do
						local subSubCategoryData = subCategoryData.subSubCategories[subSubCategoryName]

						-- Create subSubCategory button using the proper template
						local subSubCategoryButton = UI.CreateFilterButton(LogWindow.ModuleTree, nil)
						subSubCategoryButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', 3, yOffset)

						-- Set up subSubCategory button using Blizzard's helper function
						local subSubCategoryInfo = {
							type = 'subSubCategory',
							name = subSubCategoryName,
							subSubCategoryIndex = subSubCategoryName,
							selected = (ActiveModule == subSubCategoryData.sourceName)
						}
						UI.SetupFilterButton(subSubCategoryButton, subSubCategoryInfo) -- Standard hover effects
						subSubCategoryButton:SetScript(
							'OnEnter',
							function(self)
								self.HighlightTexture:Show()
							end
						)
						subSubCategoryButton:SetScript(
							'OnLeave',
							function(self)
								self.HighlightTexture:Hide()
							end
						)

						-- SubSubCategory selection functionality
						subSubCategoryButton:SetScript(
							'OnClick',
							function(self)
								-- Update button states (clear all selected states)
								for _, btn in pairs(LogWindow.moduleButtons) do
									btn.SelectedTexture:Hide()
									btn:SetNormalFontObject(GameFontHighlightSmall)
								end
								-- Set this button as selected
								self.SelectedTexture:Show()
								self:SetNormalFontObject(GameFontNormalSmall)

								ActiveModule = subSubCategoryData.sourceName
								UpdateLogDisplay()
							end
						)

						table.insert(LogWindow.moduleButtons, subSubCategoryButton)
						yOffset = yOffset - (buttonHeight + 1)
					end
				end
			end
		end
	end

	-- Update tree height
	local totalHeight = math.abs(yOffset) + 20
	LogWindow.ModuleTree:SetHeight(math.max(totalHeight, LogWindow.ModuleScrollFrame:GetHeight()))
end

local function CreateLogWindow()
	if LogWindow then
		return
	end

	-- Create base window using LibAT.UI
	LogWindow =
		UI.CreateWindow(
		{
			name = 'LibAT_LogWindow',
			title = '|cffffffffSpartan|cffe21f1fUI|r Logging',
			width = 800,
			height = 538,
			portrait = 'Interface\\AddOns\\SpartanUI\\images\\LogoSpartanUI'
		}
	)

	-- Create control frame (top bar for search/filters)
	LogWindow.ControlFrame = UI.CreateControlFrame(LogWindow)

	-- Create header anchor (slightly offset for controls)
	LogWindow.HeaderAnchor = CreateFrame('Frame', nil, LogWindow)
	LogWindow.HeaderAnchor:SetPoint('TOPLEFT', LogWindow.ControlFrame, 'TOPLEFT', 53, 0)
	LogWindow.HeaderAnchor:SetPoint('TOPRIGHT', LogWindow.ControlFrame, 'TOPRIGHT', -16, 0)
	LogWindow.HeaderAnchor:SetHeight(28)

	-- Search all modules checkbox (leftmost)
	LogWindow.SearchAllModules = UI.CreateCheckbox(LogWindow.HeaderAnchor, 'Search All Modules')
	LogWindow.SearchAllModules:SetPoint('LEFT', LogWindow.HeaderAnchor, 'LEFT', 0, 0)
	LogWindow.SearchAllModules:SetScript(
		'OnClick',
		function(self)
			SearchAllModules = self:GetChecked()
			UpdateLogDisplay()
		end
	)
	LogWindow.SearchAllModulesLabel = LogWindow.SearchAllModules.Label

	-- Search box positioned after checkbox
	LogWindow.SearchBox = UI.CreateSearchBox(LogWindow.HeaderAnchor, 241)
	LogWindow.SearchBox:SetPoint('LEFT', LogWindow.SearchAllModulesLabel, 'RIGHT', 10, 0)
	LogWindow.SearchBox:SetScript(
		'OnTextChanged',
		function(self)
			CurrentSearchTerm = self:GetText()
			UpdateLogDisplay()
		end
	)
	LogWindow.SearchBox:SetScript(
		'OnEscapePressed',
		function(self)
			self:SetText('')
			self:ClearFocus()
			CurrentSearchTerm = ''
			UpdateLogDisplay()
		end
	)

	-- Settings button (workshop icon, positioned at right)
	LogWindow.OpenSettings = UI.CreateIconButton(LogWindow.HeaderAnchor, 'Warfronts-BaseMapIcons-Empty-Workshop', 'Warfronts-BaseMapIcons-Alliance-Workshop', 'Warfronts-BaseMapIcons-Horde-Workshop')
	LogWindow.OpenSettings:SetPoint('RIGHT', LogWindow.HeaderAnchor, 'RIGHT', 0, 0)
	LogWindow.OpenSettings:SetScript(
		'OnClick',
		function()
			LibAT.Options:ToggleOptions({'Help', 'Logging'})
		end
	)

	-- Logging Level dropdown positioned before settings button
	LogWindow.LoggingLevelButton = UI.CreateDropdown(LogWindow.HeaderAnchor, 'Logging Level', 120, 22)
	LogWindow.LoggingLevelButton:SetPoint('RIGHT', LogWindow.OpenSettings, 'LEFT', -10, 0)

	-- Set initial dropdown text based on current global level
	local _, globalLevelData = GetLogLevelByPriority(GlobalLogLevel)
	if globalLevelData then
		LogWindow.LoggingLevelButton:SetText('Logging Level')
	end

	-- Create main content area
	LogWindow.MainContent = UI.CreateContentFrame(LogWindow, LogWindow.ControlFrame)

	-- Create left panel for module navigation
	LogWindow.LeftPanel = UI.CreateLeftPanel(LogWindow.MainContent)

	-- Create scroll frame for module tree (will be populated by CreateLogSourceCategories)
	LogWindow.ModuleScrollFrame = CreateFrame('ScrollFrame', 'LibAT_ModuleScrollFrame', LogWindow.LeftPanel)
	LogWindow.ModuleScrollFrame:SetPoint('TOPLEFT', LogWindow.LeftPanel, 'TOPLEFT', 2, -7)
	LogWindow.ModuleScrollFrame:SetPoint('BOTTOMRIGHT', LogWindow.LeftPanel, 'BOTTOMRIGHT', 0, 2)

	-- Create minimal scrollbar for left panel
	LogWindow.ModuleScrollFrame.ScrollBar = CreateFrame('EventFrame', nil, LogWindow.ModuleScrollFrame, 'MinimalScrollBar')
	LogWindow.ModuleScrollFrame.ScrollBar:SetPoint('TOPLEFT', LogWindow.ModuleScrollFrame, 'TOPRIGHT', 2, 0)
	LogWindow.ModuleScrollFrame.ScrollBar:SetPoint('BOTTOMLEFT', LogWindow.ModuleScrollFrame, 'BOTTOMRIGHT', 2, 0)
	ScrollUtil.InitScrollFrameWithScrollBar(LogWindow.ModuleScrollFrame, LogWindow.ModuleScrollFrame.ScrollBar)

	LogWindow.ModuleTree = CreateFrame('Frame', 'LibAT_ModuleTree', LogWindow.ModuleScrollFrame)
	LogWindow.ModuleScrollFrame:SetScrollChild(LogWindow.ModuleTree)
	LogWindow.ModuleTree:SetSize(160, 1)

	-- Create right panel for log display
	LogWindow.RightPanel = UI.CreateRightPanel(LogWindow.MainContent, LogWindow.LeftPanel)

	-- Create scrollable text display for logs
	LogWindow.TextPanel, LogWindow.EditBox = UI.CreateScrollableTextDisplay(LogWindow.RightPanel)
	LogWindow.TextPanel:SetPoint('TOPLEFT', LogWindow.RightPanel, 'TOPLEFT', 6, -6)
	LogWindow.TextPanel:SetPoint('BOTTOMRIGHT', LogWindow.RightPanel, 'BOTTOMRIGHT', 0, 2)
	LogWindow.EditBox:SetWidth(LogWindow.TextPanel:GetWidth() - 20)
	LogWindow.EditBox:SetText('No logs active - select a module from the left or enable "Search All Modules"')

	-- Create action buttons at bottom
	local actionButtons =
		UI.CreateActionButtons(
		LogWindow,
		{
			{
				text = 'Clear',
				width = 70,
				onClick = function()
					ClearCurrentLogs()
				end
			},
			{
				text = 'Export',
				width = 70,
				onClick = function()
					ExportCurrentLogs()
				end
			}
		}
	)
	LogWindow.ClearButton = actionButtons[1]
	LogWindow.ExportButton = actionButtons[2]

	-- Reload UI button positioned in bottom left
	LogWindow.ReloadButton = UI.CreateButton(LogWindow, 80, 22, 'Reload UI')
	LogWindow.ReloadButton:SetPoint('BOTTOMLEFT', LogWindow, 'BOTTOMLEFT', 3, 4)
	LogWindow.ReloadButton:SetScript(
		'OnClick',
		function()
			LibAT:SafeReloadUI()
		end
	)

	-- Auto-scroll checkbox centered under right panel
	LogWindow.AutoScroll = UI.CreateCheckbox(LogWindow, 'Auto-scroll')
	LogWindow.AutoScroll:SetPoint('CENTER', LogWindow.RightPanel, 'BOTTOM', 0, -15)
	LogWindow.AutoScroll:SetChecked(AutoScrollEnabled)
	LogWindow.AutoScrollLabel = LogWindow.AutoScroll.Label

	-- Initialize data structures
	LogWindow.Categories = {}
	LogWindow.categoryButtons = {}
	LogWindow.moduleButtons = {}

	-- Build log source categories
	CreateLogSourceCategories()

	-- Setup dropdown functionality
	SetupLogLevelDropdowns()

	-- Store references for compatibility
	LogWindow.NamespaceListings = LogWindow.ModuleScrollFrame
	LogWindow.OutputSelect = LogWindow.LeftPanel
end

-- Function to highlight search terms in text
local function HighlightSearchTerm(text, searchTerm)
	if not searchTerm or searchTerm == '' then
		return text
	end

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

		if not startPos then
			break
		end

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
	if not entryLogLevel or entryLogLevel.priority < logLevel then
		return false
	end

	-- Check search term
	if searchTerm and searchTerm ~= '' then
		return logEntry.message:lower():find(searchTerm:lower(), 1, true) ~= nil
	end

	return true
end

-- Function to update the log display based on current module and filter settings
function UpdateLogDisplay()
	if not LogWindow or not LogWindow.EditBox then
		return
	end

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
		if CurrentSearchTerm and CurrentSearchTerm ~= '' then
			searchInfo = ' | Search: "' .. CurrentSearchTerm .. '"'
		end

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
	if LogWindow.AutoScroll and LogWindow.AutoScroll:GetChecked() and LogWindow.EditBox then
		LogWindow.EditBox:SetCursorPosition(string.len(logText))
	end

	-- Update logging level button text with color
	if LogWindow.LoggingLevelButton then
		local _, globalLevelData = GetLogLevelByPriority(GlobalLogLevel)
		if globalLevelData then
			local coloredButtonText = 'Log Level: ' .. globalLevelData.color .. globalLevelData.display .. '|r'
			LogWindow.LoggingLevelButton:SetText(coloredButtonText)
		end
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
	if not LogWindow then
		return
	end

	-- Create export frame if it doesn't exist
	if not LogWindow.ExportFrame then
		LogWindow.ExportFrame = CreateFrame('Frame', 'LibAT_LogExportFrame', UIParent, 'ButtonFrameTemplate')
		LogWindow.ExportFrame:SetSize(500, 400)
		LogWindow.ExportFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
		LogWindow.ExportFrame:SetFrameStrata('DIALOG')
		LogWindow.ExportFrame:Hide()

		-- Set the portrait (with safety checks)
		if LogWindow.ExportFrame.portrait then
			if LogWindow.ExportFrame.portrait.SetTexture then
				LogWindow.ExportFrame.portrait:SetTexture('Interface\\AddOns\\SpartanUI\\images\\LogoSpartanUI')
			end
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
		LogWindow.ExportFrame.EditBox:SetScript(
			'OnTextChanged',
			function(self)
				ScrollingEdit_OnTextChanged(self, self:GetParent())
			end
		)
		LogWindow.ExportFrame.EditBox:SetScript(
			'OnCursorChanged',
			function(self, x, y, w, h)
				ScrollingEdit_OnCursorChanged(self, x, y - 10, w, h)
			end
		)
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
		table.insert(orderedLevels, {level = logLevel, data = data})
	end
	table.sort(
		orderedLevels,
		function(a, b)
			return a.data.priority < b.data.priority
		end
	)

	-- Setup logging level filter button (AH style)
	LogWindow.LoggingLevelButton:SetupMenu(
		function(dropdown, rootDescription)
			-- Add log levels in priority order with colored text
			for _, levelData in ipairs(orderedLevels) do
				-- Create colored display text
				local coloredText = levelData.data.color .. levelData.data.display .. '|r'
				local button =
					rootDescription:CreateButton(
					coloredText,
					function()
						GlobalLogLevel = levelData.data.priority
						logger.DB.globalLogLevel = GlobalLogLevel
						-- Update button text with colored level name
						local coloredButtonText = 'Level: ' .. levelData.data.color .. levelData.data.display .. '|r'
						LogWindow.LoggingLevelButton:SetText(coloredButtonText)
						UpdateLogDisplay() -- Refresh current view
					end
				)
				-- Add tooltip
				button:SetTooltip(
					function(tooltip, elementDescription)
						GameTooltip_SetTitle(tooltip, levelData.data.display .. ' Level')
						GameTooltip_AddNormalLine(tooltip, 'Shows ' .. levelData.data.display:lower() .. ' messages and higher priority')
					end
				)
				-- Check current selection
				if GlobalLogLevel == levelData.data.priority then
					button:SetRadio(true)
				end
			end
		end
	)
end

----------------------------------------------------------------------------------------------------
-- External API - LibAT.Logger (for third-party addons)
----------------------------------------------------------------------------------------------------

-- Initialize the external Logger API
LibAT.Logger = {} ---@class LibAT.Logger

---Helper function to create a logger object for a module
---@param addonName string The addon name
---@param moduleName string The full module name (addonName or addonName.category)
---@return LoggerObject
local function CreateLoggerObject(addonName, moduleName)
	---@type LoggerObject
	local loggerObj = {
		Categories = {}
	}

	-- Generic log function
	loggerObj.log = function(message, level)
		LibAT.Log(message, moduleName, level)
	end

	-- Shorthand methods for each log level
	loggerObj.debug = function(message)
		LibAT.Log(message, moduleName, 'debug')
	end

	loggerObj.info = function(message)
		LibAT.Log(message, moduleName, 'info')
	end

	loggerObj.warning = function(message)
		LibAT.Log(message, moduleName, 'warning')
	end

	loggerObj.error = function(message)
		LibAT.Log(message, moduleName, 'error')
	end

	loggerObj.critical = function(message)
		LibAT.Log(message, moduleName, 'critical')
	end

	-- RegisterCategory method for dynamic category creation
	loggerObj.RegisterCategory = function(self, categoryName)
		if not categoryName or categoryName == '' or type(categoryName) ~= 'string' then
			error('RegisterCategory: categoryName must be a non-empty string')
		end

		-- Check for invalid characters
		if categoryName:find('%.') then
			error('RegisterCategory: categoryName "' .. categoryName .. '" cannot contain dots (.)')
		end

		-- If category already exists, return it
		if self.Categories[categoryName] then
			return self.Categories[categoryName]
		end

		-- Create the full module name
		local fullModuleName = addonName .. '.' .. categoryName

		-- Create new logger object for this category
		local categoryLogger = CreateLoggerObject(addonName, fullModuleName)

		-- Store in Categories table
		self.Categories[categoryName] = categoryLogger

		-- Initialize in database if logger is ready
		if logger.DB then
			logger.DB.modules[fullModuleName] = true
		end

		-- Update category registration
		if not AddonCategories[addonName] then
			AddonCategories[addonName] = {
				subcategories = {},
				expanded = false
			}
		end
		table.insert(AddonCategories[addonName].subcategories, categoryName)

		-- Rebuild UI if window exists
		if LogWindow and LogWindow.Categories then
			CreateLogSourceCategories()
		end

		return categoryLogger
	end

	return loggerObj
end

---Register an addon for logging with optional pre-defined categories
---@param addonName string Name of the addon to register
---@param categories? string[] Optional array of pre-defined category names
---@return LoggerObject logger Logger object with methods and category support
function LibAT.Logger.RegisterAddon(addonName, categories)
	-- Protect against incorrect colon syntax: LibAT.Logger:RegisterAddon()
	if type(addonName) == 'table' and addonName == LibAT.Logger then
		error('RegisterAddon: Called with colon syntax (:) - use dot syntax (.) instead: LibAT.Logger.RegisterAddon(addonName)')
	end

	if not addonName or addonName == '' or type(addonName) ~= 'string' then
		error('RegisterAddon: addonName must be a non-empty string')
	end

	-- Validate addonName doesn't contain problematic characters
	if addonName:find('%.') then
		error('RegisterAddon: addonName "' .. addonName .. '" cannot contain dots (.)')
	end

	-- Create the main logger object
	local loggerObj = CreateLoggerObject(addonName, addonName)

	-- If categories are provided, pre-register them
	if categories and type(categories) == 'table' then
		if #categories == 0 then
			error('RegisterAddon: categories array must not be empty if provided')
		end

		-- Validate and create all categories
		for i, categoryName in ipairs(categories) do
			if type(categoryName) ~= 'string' or categoryName == '' then
				error('RegisterAddon: category at index ' .. i .. ' must be a non-empty string')
			end
			if categoryName:find('%.') then
				error('RegisterAddon: category "' .. categoryName .. '" cannot contain dots (.)')
			end
		end

		-- Store category registration
		AddonCategories[addonName] = {
			subcategories = categories,
			expanded = false
		}

		-- Create logger objects for each pre-defined category
		for _, categoryName in ipairs(categories) do
			local fullModuleName = addonName .. '.' .. categoryName
			loggerObj.Categories[categoryName] = CreateLoggerObject(addonName, fullModuleName)

			-- Initialize in database if logger is ready
			if logger.DB then
				logger.DB.modules[fullModuleName] = true
			end
		end
	else
		-- Simple registration - store as a registered addon
		RegisteredAddons[addonName] = true
	end

	-- Cache the logger object
	AddonLoggers[addonName] = loggerObj

	-- Initialize main addon in database if logger is ready
	if logger.DB then
		logger.DB.modules[addonName] = true
	end

	-- Rebuild UI if window exists
	if LogWindow and LogWindow.Categories then
		CreateLogSourceCategories()
	end

	return loggerObj
end

---Enhanced logging function with log levels
---@param debugText string The message to log
---@param module string The module name
---@param level? LogLevel Log level - defaults to 'info'
function LibAT.Log(debugText, module, level)
	level = level or 'info'

	-- Validate module name to prevent invalid entries
	if type(module) ~= 'string' or module == '' then
		-- Log to a fallback module name and issue a warning
		module = 'InvalidModule'
		debugText = 'Invalid module name provided to LibAT.Log: ' .. tostring(debugText)
		level = 'warning'
	end

	-- Initialize module if it doesn't exist
	if not LogMessages[module] then
		LogMessages[module] = {}

		-- Add new module to category system if log window exists
		if LogWindow and LogWindow.Categories then
			-- Rebuild the category tree to include new module
			CreateLogSourceCategories()
		end

		logger.DB.modules[module] = true -- Default to enabled for logging approach
		if logger.options then
			logger.options.args[module] = {
				name = module,
				desc = 'Set the minimum log level for the ' .. module .. ' module. Use "Global" to inherit the global log level setting.',
				type = 'select',
				values = function()
					local values = {[0] = 'Global (inherit)'}
					-- Create ordered list to ensure proper display order
					local orderedLevels = {}
					for level, data in pairs(LOG_LEVELS) do
						table.insert(orderedLevels, {level = level, data = data})
					end
					table.sort(
						orderedLevels,
						function(a, b)
							return a.data.priority < b.data.priority
						end
					)

					for _, levelData in ipairs(orderedLevels) do
						values[levelData.data.priority] = levelData.data.display
					end
					return values
				end,
				sorting = function()
					-- Return sorted order for dropdown
					local sorted = {0} -- Global first
					local orderedLevels = {}
					for level, data in pairs(LOG_LEVELS) do
						table.insert(orderedLevels, {level = level, data = data})
					end
					table.sort(
						orderedLevels,
						function(a, b)
							return a.data.priority < b.data.priority
						end
					)

					for _, levelData in ipairs(orderedLevels) do
						table.insert(sorted, levelData.data.priority)
					end
					return sorted
				end,
				get = function(info)
					return logger.DB.moduleLogLevels[info[#info]] or 0
				end,
				set = function(info, val)
					logger.DB.moduleLogLevels[info[#info]] = val
					ModuleLogLevels[info[#info]] = val
					if LogWindow then
						UpdateLogDisplay()
					end
				end,
				order = (#logger.options.args + 1)
			}
		end
	end

	-- Validate log level
	local logLevel = LOG_LEVELS[level]
	if not logLevel then
		level = 'info'
		logLevel = LOG_LEVELS[level]
	end

	-- PERFORMANCE OPTIMIZATION: In release builds, skip logs below current threshold
	-- Dev builds capture everything for dynamic filtering, release builds filter early for performance
	if LibAT.releaseType ~= 'DEV Build' then
		-- Get effective log level for this module
		local moduleLogLevel = ModuleLogLevels[module] or 0
		local effectiveLogLevel = moduleLogLevel > 0 and moduleLogLevel or GlobalLogLevel

		-- Skip capturing if log level is below threshold (unless it's warning/error/critical)
		if logLevel.priority < effectiveLogLevel and logLevel.priority < 3 then
			return -- Early exit, don't capture low-priority logs in release builds
		end
	end

	-- LOGGING APPROACH:
	-- DEV builds: Always capture all messages, filter during display (allows dynamic level changes)
	-- RELEASE builds: Filter at capture time for performance, still capture warnings/errors

	-- Create log entry with timestamp and level
	local timestamp = date('%H:%M:%S')
	local coloredLevel = logLevel.color .. '[' .. logLevel.display:upper() .. ']|r'
	local formattedMessage = timestamp .. ' ' .. coloredLevel .. ' ' .. tostring(debugText)

	-- Store the log entry
	local logEntry = {
		timestamp = GetTime(),
		level = level,
		message = tostring(debugText),
		formattedMessage = formattedMessage
	}

	table.insert(LogMessages[module], logEntry)

	-- Maintain maximum log history
	local maxHistory = logger.DB.maxLogHistory or 1000
	if #LogMessages[module] > maxHistory then
		table.remove(LogMessages[module], 1)
	end

	-- Initialize log window if needed
	if not LogWindow then
		CreateLogWindow()
	end

	-- Update display if this module is currently active
	if ActiveModule and ActiveModule == module then
		UpdateLogDisplay()
	end
end

---@param debugText string The message to log
---@param module string The module name
function LibAT.Debug(debugText, module)
	-- Redirect to the new logging function
	LibAT.Log(debugText, module, 'debug')
end

----------------------------------------------------------------------------------------------------
-- Internal SpartanUI Module Logging API
----------------------------------------------------------------------------------------------------

---Enhanced logging function for SpartanUI modules that leverages module objects
---Automatically uses module DisplayName, falls back to module name, and supports hierarchical categorization
---@param moduleObj LibAT.Module The SpartanUI module object
---@param message string The message to log
---@param component? string Optional component/subcomponent for hierarchical logging (e.g., "Database.Connection")
---@param level? LogLevel Log level - defaults to 'info'
function LibAT.ModuleLog(moduleObj, message, component, level)
	if not moduleObj then
		LibAT.Log(message, 'Unknown', level)
		return
	end

	-- Get the best display name for the module
	local moduleName = moduleObj.DisplayName or moduleObj:GetName()

	-- Create hierarchical source name if component is provided
	local logSource = moduleName
	if component and component ~= '' then
		logSource = moduleName .. '.' .. component
	end

	LibAT.Log(message, logSource, level)
end

---Create a logger function for a specific SpartanUI module
---Returns a logger function that automatically uses the module's information
---@param moduleObj LibAT.Module The SpartanUI module object
---@param defaultComponent? string Optional default component name for all logs from this logger
---@return fun(message: string, component?: string, level?: LogLevel) logger Logger function
function LibAT.CreateModuleLogger(moduleObj, defaultComponent)
	return function(message, component, level)
		-- If component is actually the level (for backwards compatibility)
		if type(component) == 'string' and LOG_LEVELS[component] and not level then
			level = component
			component = defaultComponent
		elseif not component then
			component = defaultComponent
		elseif defaultComponent then
			-- Combine default and provided component
			component = defaultComponent .. '.' .. component
		end

		LibAT.ModuleLog(moduleObj, message, component, level)
	end
end

---Enhanced module registration system that provides easy logging setup
---Call this in your module's OnInitialize to get a pre-configured logger
---@param moduleObj LibAT.Module The SpartanUI module object
---@param components? string[] Optional list of components for structured logging
---@return SimpleLogger|ComplexLoggers logger Either a simple logger function or a table of component loggers
function LibAT.SetupModuleLogging(moduleObj, components)
	if not moduleObj then
		error('SetupModuleLogging: moduleObj is required')
	end

	if not components or #components == 0 then
		-- Simple logger - just logs to the module name
		return LibAT.CreateModuleLogger(moduleObj)
	else
		-- Complex logger - create component-specific loggers
		local loggers = {}
		for _, component in ipairs(components) do
			loggers[component] = LibAT.CreateModuleLogger(moduleObj, component)
		end

		-- Also add a general logger without component prefix
		loggers.general = LibAT.CreateModuleLogger(moduleObj)

		return loggers
	end
end

-- Validate and purge invalid entries from the modules database
local function ValidateAndPurgeModulesDB()
	local invalidEntries = {}

	-- Check for invalid entries in modules DB
	for k, v in pairs(logger.DB.modules) do
		if type(k) ~= 'string' then
			-- Key is not a string, mark for removal
			table.insert(invalidEntries, k)
		elseif type(v) ~= 'boolean' then
			-- Value is not a boolean, mark for removal
			table.insert(invalidEntries, k)
		end
	end

	-- Remove invalid entries
	if #invalidEntries > 0 then
		LibAT.Log('Purging ' .. #invalidEntries .. ' invalid entries from logger modules database', 'Logger', 'warning')
		for _, key in ipairs(invalidEntries) do
			logger.DB.modules[key] = nil
			if LogMessages[key] then
				LogMessages[key] = nil
			end
			if ModuleLogLevels[key] then
				ModuleLogLevels[key] = nil
			end
			if logger.DB.moduleLogLevels[key] then
				logger.DB.moduleLogLevels[key] = nil
			end
		end
	end

	-- Also validate moduleLogLevels
	invalidEntries = {}
	for k, v in pairs(logger.DB.moduleLogLevels) do
		if type(k) ~= 'string' or type(v) ~= 'number' then
			table.insert(invalidEntries, k)
		end
	end

	if #invalidEntries > 0 then
		LibAT.Log('Purging ' .. #invalidEntries .. ' invalid entries from logger moduleLogLevels database', 'Logger', 'warning')
		for _, key in ipairs(invalidEntries) do
			logger.DB.moduleLogLevels[key] = nil
			if ModuleLogLevels[key] then
				ModuleLogLevels[key] = nil
			end
		end
	end
end

local function AddOptions()
	-- Validate and purge invalid DB entries before building options
	ValidateAndPurgeModulesDB()

	---@type AceConfig.OptionsTable
	local options = {
		name = 'Logging',
		type = 'group',
		args = {
			Description = {
				name = 'SpartanUI uses a comprehensive logging system that captures all messages and filters by log level.\nAll modules are always enabled - use log level settings to control what messages are displayed.',
				type = 'description',
				order = 0
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
						table.insert(orderedLevels, {level = level, data = data})
					end
					table.sort(
						orderedLevels,
						function(a, b)
							return a.data.priority < b.data.priority
						end
					)

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
						table.insert(orderedLevels, {level = level, data = data})
					end
					table.sort(
						orderedLevels,
						function(a, b)
							return a.data.priority < b.data.priority
						end
					)

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
					if LogWindow then
						UpdateLogDisplay()
					end
				end,
				order = 1
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
				order = 2
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
				order = 3
			},
			ModuleHeader = {
				name = 'Module Logging Control',
				type = 'header',
				order = 10
			},
			ResetAllToGlobal = {
				name = 'Reset All Modules to Global',
				desc = 'Reset all modules to use the global log level setting (remove individual overrides).',
				type = 'execute',
				order = 11,
				func = function()
					for k, _ in pairs(logger.DB.modules) do
						logger.DB.moduleLogLevels[k] = 0
						ModuleLogLevels[k] = 0
					end
					if LogWindow then
						UpdateLogDisplay()
					end
					LibAT:Print('All module log levels reset to global setting.')
				end
			}
		}
	}

	for k, _ in pairs(logger.DB.modules) do
		if type(k) == 'string' then
			options.args[k] = {
				name = k,
				desc = 'Set the minimum log level for the ' .. k .. ' module. Use "Global" to inherit the global log level setting.',
				type = 'select',
				values = function()
					local values = {[0] = 'Global (inherit)'}
					-- Create ordered list to ensure proper display order
					local orderedLevels = {}
					for level, data in pairs(LOG_LEVELS) do
						table.insert(orderedLevels, {level = level, data = data})
					end
					table.sort(
						orderedLevels,
						function(a, b)
							return a.data.priority < b.data.priority
						end
					)

					for _, levelData in ipairs(orderedLevels) do
						values[levelData.data.priority] = levelData.data.display
					end
					return values
				end,
				sorting = function()
					-- Return sorted order for dropdown
					local sorted = {0} -- Global first
					local orderedLevels = {}
					for level, data in pairs(LOG_LEVELS) do
						table.insert(orderedLevels, {level = level, data = data})
					end
					table.sort(
						orderedLevels,
						function(a, b)
							return a.data.priority < b.data.priority
						end
					)

					for _, levelData in ipairs(orderedLevels) do
						table.insert(sorted, levelData.data.priority)
					end
					return sorted
				end,
				get = function(info)
					return logger.DB.moduleLogLevels[info[#info]] or 0
				end,
				set = function(info, val)
					logger.DB.moduleLogLevels[info[#info]] = val
					ModuleLogLevels[info[#info]] = val
					if LogWindow then
						UpdateLogDisplay()
					end
				end,
				order = (#options.args + 1)
			}
		end
	end
	logger.options = options
	LibAT.Options:AddOptions(options, 'Logging', 'Help')
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
			y = 0
		},
		modules = {
			['*'] = true -- Default to enabled for logging approach
		},
		moduleLogLevels = {
			['*'] = 0 -- Use global level by default
		}
	}
	logger.Database = LibAT.Database:RegisterNamespace('Logger', {profile = defaults})
	logger.DB = logger.Database.profile

	-- Validate and purge any invalid entries from the database
	ValidateAndPurgeModulesDB()

	-- Initialize log structures
	for k, _ in pairs(logger.DB.modules) do
		if type(k) == 'string' then -- Extra safety check after validation
			LogMessages[k] = {}
		end
	end

	-- Load settings
	GlobalLogLevel = logger.DB.globalLogLevel or 2
	ModuleLogLevels = logger.DB.moduleLogLevels or {}

	-- logger:RegisterEvent('ADDON_LOADED')
end

function logger:OnEnable()
	CreateLogWindow()

	local function ToggleLogWindow(comp)
		if not LogWindow then
			CreateLogWindow()
		end
		if LogWindow:IsVisible() then
			LogWindow:Hide()
		else
			LogWindow:Show()
		end
	end

	-- Expose as public method for LibAT to use
	logger.ToggleWindow = ToggleLogWindow

	-- Register direct WoW slash commands
	SLASH_LibATLOGS1 = '/logs'
	SlashCmdList['LibATLOGS'] = ToggleLogWindow

	AddOptions()
end

-- local function RefreshData(self)
-- 	local function OnMouseDown(line, button)
-- 		local text = line.Text:GetText()
-- 		if button == 'RightButton' then
-- 			LibAT.Chat:SetEditBoxMessage(text)
-- 		elseif button == 'MiddleButton' then
-- 			local rawData = line:GetParent():GetAttributeData().rawValue
-- 			if rawData.IsObjectType and rawData:IsObjectType('Texture') then
-- 				-- _G.TEX = rawData
-- 				LibAT:Print('_G.TEX set to: ', text)
-- 			else
-- 				-- _G.FRAME = rawData
-- 				LibAT:Print('_G.FRAME set to: ', text)
-- 			end
-- 		else
-- 			TableAttributeDisplayValueButton_OnMouseDown(line)
-- 		end
-- 	end

-- 	local scrollFrame = self.LinesScrollFrame or TableAttributeDisplay.LinesScrollFrame
-- 	if not scrollFrame then
-- 		return
-- 	end
-- 	for _, child in next, {scrollFrame.LinesContainer:GetChildren()} do
-- 		if child.ValueButton and child.ValueButton:GetScript('OnMouseDown') ~= OnMouseDown then
-- 			child.ValueButton:SetScript('OnMouseDown', OnMouseDown)
-- 		end
-- 	end
-- end

-- function logger:ADDON_LOADED(_, addon)
-- 	if addon == 'Blizzard_DebugTools' then
-- 		hooksecurefunc(TableInspectorMixin, 'RefreshAllData', RefreshData)
-- 		hooksecurefunc(TableAttributeDisplay.dataProviders[2], 'RefreshData', RefreshData)
-- 		logger:UnregisterEvent('ADDON_LOADED')
-- 	end
-- end
