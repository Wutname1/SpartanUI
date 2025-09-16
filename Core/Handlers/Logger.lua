---@class SUI
local SUI = SUI
local logger = SUI:NewModule('Handler.Logger') ---@class SUI.LoggerInternal | SUI.Module
SUI.Handlers.Logger = logger
logger.description = 'SpartanUI Logging System'

----------------------------------------------------------------------------------------------------
-- Type Definitions for Logger System
----------------------------------------------------------------------------------------------------

---@alias LogLevel
---| "debug"    # Detailed debugging information
---| "info"     # General informational messages
---| "warning"  # Warning conditions
---| "error"    # Error conditions
---| "critical" # Critical system failures

---Logger function returned by RegisterAddon
---@alias SimpleLogger fun(message: string, level?: LogLevel): nil

---Logger table returned by RegisterAddonCategory
---@alias ComplexLoggers table<string, SimpleLogger>

---Internal Logger Handler (SUI.Handlers.Logger)
---@class SUI.LoggerInternal : SUI.Module
---@field description string

---External Logger API (SUI.Logger) - for third-party addons
---@class SUI.Logger
---@field RegisterAddon fun(addonName: string): SimpleLogger
---@field RegisterAddonCategory fun(addonName: string, subcategories: string[]): ComplexLoggers

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

local function FilterButton_SetUp(button, info)
	local normalText = button.Text
	local normalTexture = button.NormalTexture
	local line = button.Lines
	local btnWidth = 144
	local btnHeight = 20

	if info.type == 'category' then
		if info.isToken then
			button:SetNormalFontObject(GameFontNormalSmallBattleNetBlueLeft)
		else
			button:SetNormalFontObject(GameFontNormalSmall)
		end

		button.NormalTexture:SetAtlas('auctionhouse-nav-button', false)
		button.NormalTexture:SetSize(btnWidth + 6, btnHeight + 11)
		button.NormalTexture:ClearAllPoints()
		button.NormalTexture:SetPoint('TOPLEFT', -2, 0)
		button.SelectedTexture:SetAtlas('auctionhouse-nav-button-select', false)
		button.SelectedTexture:SetSize(btnWidth + 2, btnHeight)
		button.SelectedTexture:ClearAllPoints()
		button.SelectedTexture:SetPoint('LEFT')
		button.HighlightTexture:SetAtlas('auctionhouse-nav-button-highlight', false)
		button.HighlightTexture:SetSize(btnWidth + 2, btnHeight)
		button.HighlightTexture:ClearAllPoints()
		button.HighlightTexture:SetPoint('LEFT')
		button.HighlightTexture:SetBlendMode('BLEND')
		button:SetText(info.name)
		normalText:SetPoint('LEFT', button, 'LEFT', 8, 0)
		normalTexture:SetAlpha(1.0)
		line:Hide()
	elseif info.type == 'subCategory' then
		button:SetNormalFontObject(GameFontHighlightSmall)
		button.NormalTexture:SetAtlas('auctionhouse-nav-button-secondary', false)
		button.NormalTexture:SetSize(btnWidth + 3, btnHeight + 11)
		button.NormalTexture:ClearAllPoints()
		button.NormalTexture:SetPoint('TOPLEFT', 1, 0)
		button.SelectedTexture:SetAtlas('auctionhouse-nav-button-secondary-select', false)
		button.SelectedTexture:SetSize(btnWidth - 10, btnHeight)
		button.SelectedTexture:ClearAllPoints()
		button.SelectedTexture:SetPoint('TOPLEFT', 10, 0)
		button.HighlightTexture:SetAtlas('auctionhouse-nav-button-secondary-highlight', false)
		button.HighlightTexture:SetSize(btnWidth - 10, btnHeight)
		button.HighlightTexture:ClearAllPoints()
		button.HighlightTexture:SetPoint('TOPLEFT', 10, 0)
		button.HighlightTexture:SetBlendMode('BLEND')
		button:SetText(info.name or '')
		normalText:SetPoint('LEFT', button, 'LEFT', 18, 0)
		normalTexture:SetAlpha(1.0)
		line:Hide()
	elseif info.type == 'subSubCategory' then
		button:SetNormalFontObject(GameFontHighlightSmall)
		button.NormalTexture:ClearAllPoints()
		button.NormalTexture:SetPoint('TOPLEFT', 10, 0)
		button.SelectedTexture:SetAtlas('auctionhouse-ui-row-select', false)
		button.SelectedTexture:SetSize(btnWidth - 20, btnHeight - 3)
		button.SelectedTexture:ClearAllPoints()
		button.SelectedTexture:SetPoint('TOPRIGHT', 0, -2)
		button.HighlightTexture:SetAtlas('auctionhouse-ui-row-highlight', false)
		button.HighlightTexture:SetSize(btnWidth - 20, btnHeight - 3)
		button.HighlightTexture:ClearAllPoints()
		button.HighlightTexture:SetPoint('TOPRIGHT', 0, -2)
		button.HighlightTexture:SetBlendMode('ADD')
		button:SetText(info.name)
		normalText:SetPoint('LEFT', button, 'LEFT', 26, 0)
		normalTexture:SetAlpha(0.0)
		line:Show()
	end
	button.type = info.type

	if info.type == 'category' then
		button.categoryIndex = info.categoryIndex
	elseif info.type == 'subCategory' then
		button.subCategoryIndex = info.subCategoryIndex
	elseif info.type == 'subSubCategory' then
		button.subSubCategoryIndex = info.subSubCategoryIndex
	end

	button.SelectedTexture:SetShown(info.selected)
end

-- Function to parse and categorize log sources using hierarchical system
-- Returns: category, subCategory, subSubCategory, sourceType
local function ParseLogSource(sourceName)
	-- Check if this is a registered simple addon (category level only)
	if RegisteredAddons[sourceName] then
		return 'External Addons', sourceName, nil, 'subCategory'
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

	-- Fall back to SUI internal categorization with hierarchy support
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
				isAddonCategory = AddonCategories[category] ~= nil
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

-- Function to create a button with the proper AuctionHouse template structure
local function CreateLoggerFilterButton(parent, name)
	local button = CreateFrame('Button', name, parent, 'TruncatedTooltipScriptTemplate')
	button:SetSize(150, 21)

	-- Create all texture layers as defined in the XML template
	-- BACKGROUND layer
	button.Lines = button:CreateTexture(nil, 'BACKGROUND')
	button.Lines:SetAtlas('auctionhouse-nav-button-tertiary-filterline', true)
	button.Lines:SetPoint('LEFT', button, 'LEFT', 18, 3)

	button.NormalTexture = button:CreateTexture(nil, 'BACKGROUND')

	-- BORDER layer
	button.HighlightTexture = button:CreateTexture(nil, 'BORDER')
	button.HighlightTexture:Hide()

	-- ARTWORK layer
	button.SelectedTexture = button:CreateTexture(nil, 'ARTWORK')
	button.SelectedTexture:Hide()

	-- Button text with shadow
	button.Text = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	button.Text:SetSize(0, 8)
	button.Text:SetPoint('LEFT', button, 'LEFT', 4, 0)
	button.Text:SetPoint('RIGHT', button, 'RIGHT', -4, 0)
	button.Text:SetJustifyH('LEFT')
	-- Add text shadow
	button.Text:SetShadowOffset(1, -1)
	button.Text:SetShadowColor(0, 0, 0)

	-- Set font objects
	button:SetNormalFontObject(GameFontNormalSmall)
	button:SetHighlightFontObject(GameFontHighlightSmall)

	return button
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

		-- Create category button using the proper template
		local categoryButton = CreateLoggerFilterButton(LogWindow.ModuleTree, 'SUI_CategoryButton_' .. categoryName)
		categoryButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', 3, yOffset)

		-- Set up category button using Blizzard's helper function
		local categoryInfo = {
			type = 'category',
			name = categoryName .. ' (' .. subCategoryCount .. ')',
			categoryIndex = categoryName,
			isToken = categoryData.isAddonCategory, -- Use isToken for external addons (matches Blizzard's pattern)
			selected = false
		}
		FilterButton_SetUp(categoryButton, categoryInfo)

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

		-- Create subCategory and subSubCategory buttons if category is expanded
		if categoryData.expanded then
			for _, subCategoryName in ipairs(categoryData.sortedSubCategories) do
				local subCategoryData = categoryData.subCategories[subCategoryName]

				-- Create subCategory button using the proper template
				local subCategoryButton = CreateLoggerFilterButton(LogWindow.ModuleTree, nil)
				subCategoryButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', 3, yOffset)

				-- Set up subCategory button using Blizzard's helper function
				local subCategoryInfo = {
					type = 'subCategory',
					name = subCategoryName,
					subCategoryIndex = subCategoryName,
					selected = (ActiveModule == (subCategoryData.sourceName or subCategoryName))
				}
				FilterButton_SetUp(subCategoryButton, subCategoryInfo)

				-- If this subCategory has subSubCategories, add expand/collapse indicator
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
						local subSubCategoryButton = CreateLoggerFilterButton(LogWindow.ModuleTree, nil)
						subSubCategoryButton:SetPoint('TOPLEFT', LogWindow.ModuleTree, 'TOPLEFT', 3, yOffset)

						-- Set up subSubCategory button using Blizzard's helper function
						local subSubCategoryInfo = {
							type = 'subSubCategory',
							name = subSubCategoryName,
							subSubCategoryIndex = subSubCategoryName,
							selected = (ActiveModule == subSubCategoryData.sourceName)
						}
						FilterButton_SetUp(subSubCategoryButton, subSubCategoryInfo)

						-- Standard hover effects
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

	-- Create main frame using ButtonFrameTemplate for proper skinning (AH window size: 800x538)
	LogWindow = CreateFrame('Frame', 'SpartanUI_LogWindow', UIParent, 'ButtonFrameTemplate')
	ButtonFrameTemplate_HidePortrait(LogWindow)
	LogWindow:SetSize(800, 538)
	LogWindow:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	LogWindow:SetFrameStrata('HIGH')
	LogWindow:Hide()

	-- Make the window movable
	LogWindow:SetMovable(true)
	LogWindow:EnableMouse(true)
	LogWindow:RegisterForDrag('LeftButton')
	LogWindow:SetScript('OnDragStart', LogWindow.StartMoving)
	LogWindow:SetScript(
		'OnDragStop',
		function(self)
			self:StopMovingOrSizing()
		end
	)

	-- Set the portrait (with safety checks)
	if LogWindow.portrait then
		if LogWindow.portrait.SetTexture then
			LogWindow.portrait:SetTexture('Interface\\AddOns\\SpartanUI\\images\\LogoSpartanUI')
		end
	end

	-- Set title
	LogWindow:SetTitle('|cffffffffSpartan|cffe21f1fUI|r Logging')

	-- Create control frame positioned like AuctionHouse SearchBar (y=-29)
	LogWindow.ControlFrame = CreateFrame('Frame', nil, LogWindow)
	LogWindow.ControlFrame:SetPoint('TOPLEFT', LogWindow, 'TOPLEFT', 2, -33)
	LogWindow.ControlFrame:SetPoint('TOPRIGHT', LogWindow, 'TOPRIGHT', -2, -33)
	LogWindow.ControlFrame:SetHeight(28) -- Reduced height to match AH

	LogWindow.HeaderAnchor = CreateFrame('Frame', nil, LogWindow)
	LogWindow.HeaderAnchor:SetPoint('TOPLEFT', LogWindow.ControlFrame, 'TOPLEFT', 53, 0)
	LogWindow.HeaderAnchor:SetPoint('TOPRIGHT', LogWindow.ControlFrame, 'TOPRIGHT', -16, 0)
	LogWindow.HeaderAnchor:SetHeight(28) -- Reduced height to match AH

	-- All controls on same horizontal line, left to right: checkbox, search, logging level, gear
	-- Search all modules checkbox (leftmost)
	LogWindow.SearchAllModules = CreateFrame('CheckButton', 'SUI_SearchAllModules', LogWindow.HeaderAnchor, 'UICheckButtonTemplate')
	LogWindow.SearchAllModules:SetSize(18, 18)
	LogWindow.SearchAllModules:SetPoint('LEFT', LogWindow.HeaderAnchor, 'LEFT', 0, 0)
	LogWindow.SearchAllModules:SetScript(
		'OnClick',
		function(self)
			SearchAllModules = self:GetChecked()
			UpdateLogDisplay()
		end
	)

	LogWindow.SearchAllModulesLabel = LogWindow.HeaderAnchor:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	LogWindow.SearchAllModulesLabel:SetText('Search All Modules')
	LogWindow.SearchAllModulesLabel:SetPoint('LEFT', LogWindow.SearchAllModules, 'RIGHT', 2, 0)
	LogWindow.SearchAllModulesLabel:SetTextColor(1, 1, 1) -- White text

	-- Search box positioned after checkbox
	LogWindow.SearchBox = CreateFrame('EditBox', 'SUI_LogSearchBox', LogWindow.HeaderAnchor, 'SearchBoxTemplate')
	LogWindow.SearchBox:SetSize(241, 22)
	LogWindow.SearchBox:SetPoint('LEFT', LogWindow.SearchAllModulesLabel, 'RIGHT', 10, 0)
	LogWindow.SearchBox:SetAutoFocus(false)
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

	-- Settings button (workshop icon, positioned after logging level dropdown)
	LogWindow.OpenSettings = CreateFrame('Button', nil, LogWindow.HeaderAnchor)
	LogWindow.OpenSettings:SetSize(24, 24)
	LogWindow.OpenSettings:SetPoint('RIGHT', LogWindow.HeaderAnchor, 'RIGHT', 0, 0)

	-- Set up texture states
	LogWindow.OpenSettings:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\empty') -- Placeholder, will use atlas
	LogWindow.OpenSettings:SetHighlightTexture('Interface\\AddOns\\SpartanUI\\images\\empty') -- Placeholder, will use atlas
	LogWindow.OpenSettings:SetPushedTexture('Interface\\AddOns\\SpartanUI\\images\\empty') -- Placeholder, will use atlas

	-- Create texture layers using atlas
	LogWindow.OpenSettings.NormalTexture = LogWindow.OpenSettings:CreateTexture(nil, 'ARTWORK')
	LogWindow.OpenSettings.NormalTexture:SetAtlas('Warfronts-BaseMapIcons-Empty-Workshop')
	LogWindow.OpenSettings.NormalTexture:SetAllPoints()

	LogWindow.OpenSettings.HighlightTexture = LogWindow.OpenSettings:CreateTexture(nil, 'HIGHLIGHT')
	LogWindow.OpenSettings.HighlightTexture:SetAtlas('Warfronts-BaseMapIcons-Alliance-Workshop')
	LogWindow.OpenSettings.HighlightTexture:SetAllPoints()
	LogWindow.OpenSettings.HighlightTexture:SetAlpha(0)

	LogWindow.OpenSettings.PushedTexture = LogWindow.OpenSettings:CreateTexture(nil, 'ARTWORK')
	LogWindow.OpenSettings.PushedTexture:SetAtlas('Warfronts-BaseMapIcons-Horde-Workshop')
	LogWindow.OpenSettings.PushedTexture:SetAllPoints()
	LogWindow.OpenSettings.PushedTexture:SetAlpha(0)

	-- Set up hover and click effects
	LogWindow.OpenSettings:SetScript(
		'OnEnter',
		function(self)
			self.HighlightTexture:SetAlpha(1)
		end
	)
	LogWindow.OpenSettings:SetScript(
		'OnLeave',
		function(self)
			self.HighlightTexture:SetAlpha(0)
		end
	)
	LogWindow.OpenSettings:SetScript(
		'OnMouseDown',
		function(self)
			self.PushedTexture:SetAlpha(1)
			self.NormalTexture:SetAlpha(0)
		end
	)
	LogWindow.OpenSettings:SetScript(
		'OnMouseUp',
		function(self)
			self.PushedTexture:SetAlpha(0)
			self.NormalTexture:SetAlpha(1)
		end
	)
	LogWindow.OpenSettings:SetScript(
		'OnClick',
		function()
			SUI.Options:ToggleOptions({'Help', 'Logging'})
		end
	)

	-- Logging Level dropdown positioned after search box
	LogWindow.LoggingLevelButton = CreateFrame('DropdownButton', 'SUI_LoggingLevelButton', LogWindow.HeaderAnchor, 'WowStyle1FilterDropdownTemplate')
	LogWindow.LoggingLevelButton:SetPoint('RIGHT', LogWindow.OpenSettings, 'LEFT', -10, 0)
	LogWindow.LoggingLevelButton:SetSize(120, 22)
	LogWindow.LoggingLevelButton:SetText('Logging Level')
	-- Set initial dropdown text based on current global level
	local _, globalLevelData = GetLogLevelByPriority(GlobalLogLevel)
	if globalLevelData then
		LogWindow.LoggingLevelButton:SetText('Logging Level')
	end

	-- Create main content area positioned like AuctionHouse panels (-4px from SearchBar bottom)
	LogWindow.MainContent = CreateFrame('Frame', nil, LogWindow)
	LogWindow.MainContent:SetPoint('TOPLEFT', LogWindow.ControlFrame, 'BOTTOMLEFT', 0, -4)
	LogWindow.MainContent:SetPoint('BOTTOMRIGHT', LogWindow, 'BOTTOMRIGHT', -20, 12)

	-- Left panel for module list (styled like AuctionFrame's category list)
	LogWindow.LeftPanel = CreateFrame('Frame', 'SUI_LeftPanel', LogWindow.MainContent)
	LogWindow.LeftPanel:SetPoint('TOPLEFT', LogWindow.MainContent, 'TOPLEFT', 10, 0)
	LogWindow.LeftPanel:SetPoint('BOTTOMLEFT', LogWindow.MainContent, 'BOTTOMLEFT', 10, 20)
	LogWindow.LeftPanel:SetWidth(155)
	LogWindow.LeftPanel.layoutType = 'InsetFrameTemplate'

	-- Add AuctionHouse categories background
	LogWindow.LeftPanel.Background = LogWindow.LeftPanel:CreateTexture(nil, 'BACKGROUND')
	LogWindow.LeftPanel.Background:SetAtlas('auctionhouse-background-summarylist', true)
	LogWindow.LeftPanel.Background:SetAllPoints(LogWindow.LeftPanel)

	-- Add nine slice border for left panel
	LogWindow.LeftPanel.NineSlice = CreateFrame('Frame', 'SUI_LeftPanelNineSlice', LogWindow.LeftPanel, 'NineSlicePanelTemplate')
	LogWindow.LeftPanel.NineSlice:SetAllPoints()

	-- Create scroll frame for module tree in left panel with MinimalScrollBar
	LogWindow.ModuleScrollFrame = CreateFrame('ScrollFrame', 'SUI_ModuleScrollFrame', LogWindow.LeftPanel)
	LogWindow.ModuleScrollFrame:SetPoint('TOPLEFT', LogWindow.LeftPanel, 'TOPLEFT', 2, -7)
	LogWindow.ModuleScrollFrame:SetPoint('BOTTOMRIGHT', LogWindow.LeftPanel, 'BOTTOMRIGHT', 0, 2)

	-- Create minimal scrollbar for left panel
	LogWindow.ModuleScrollFrame.ScrollBar = CreateFrame('EventFrame', nil, LogWindow.ModuleScrollFrame, 'MinimalScrollBar')
	LogWindow.ModuleScrollFrame.ScrollBar:SetPoint('TOPLEFT', LogWindow.ModuleScrollFrame, 'TOPRIGHT', 2, 0)
	LogWindow.ModuleScrollFrame.ScrollBar:SetPoint('BOTTOMLEFT', LogWindow.ModuleScrollFrame, 'BOTTOMRIGHT', 2, 0)
	ScrollUtil.InitScrollFrameWithScrollBar(LogWindow.ModuleScrollFrame, LogWindow.ModuleScrollFrame.ScrollBar)

	LogWindow.ModuleTree = CreateFrame('Frame', 'SUI_ModuleTree', LogWindow.ModuleScrollFrame)
	LogWindow.ModuleScrollFrame:SetScrollChild(LogWindow.ModuleTree)
	LogWindow.ModuleTree:SetSize(160, 1)

	-- Right panel for log text (main display area like AuctionFrame's item list)
	LogWindow.RightPanel = CreateFrame('Frame', 'SUI_RightPanel', LogWindow.MainContent)
	LogWindow.RightPanel:SetPoint('TOPLEFT', LogWindow.LeftPanel, 'TOPRIGHT', 20, 0)
	LogWindow.RightPanel:SetPoint('BOTTOMRIGHT', LogWindow.MainContent, 'BOTTOMRIGHT', -10, 20)
	LogWindow.RightPanel.layoutType = 'InsetFrameTemplate'

	-- Add AuctionHouse index background
	LogWindow.RightPanel.Background = LogWindow.RightPanel:CreateTexture(nil, 'BACKGROUND')
	LogWindow.RightPanel.Background:SetAtlas('auctionhouse-background-index', true)
	LogWindow.RightPanel.Background:SetAllPoints(LogWindow.RightPanel)
	-- LogWindow.RightPanel.Background:SetPoint('TOPLEFT', LogWindow.RightPanel, 'TOPLEFT', 3, -3)

	-- Add nine slice border for right panel
	LogWindow.RightPanel.NineSlice = CreateFrame('Frame', nil, LogWindow.RightPanel, 'NineSlicePanelTemplate')
	LogWindow.RightPanel.NineSlice:SetAllPoints()

	-- Action buttons positioned in bottom right like AH Cancel Auction button
	LogWindow.ClearButton = CreateFrame('Button', nil, LogWindow, 'UIPanelButtonTemplate')
	LogWindow.ClearButton:SetSize(70, 22)
	LogWindow.ClearButton:SetPoint('BOTTOMRIGHT', LogWindow, 'BOTTOMRIGHT', -3, 4)
	LogWindow.ClearButton:SetText('Clear')
	LogWindow.ClearButton:SetScript(
		'OnClick',
		function()
			ClearCurrentLogs()
		end
	)

	LogWindow.ExportButton = CreateFrame('Button', nil, LogWindow, 'UIPanelButtonTemplate')
	LogWindow.ExportButton:SetSize(70, 22)
	LogWindow.ExportButton:SetPoint('RIGHT', LogWindow.ClearButton, 'LEFT', -5, 0)
	LogWindow.ExportButton:SetText('Export')
	LogWindow.ExportButton:SetScript(
		'OnClick',
		function()
			ExportCurrentLogs()
		end
	)

	-- Reload UI button positioned in bottom left
	LogWindow.ReloadButton = CreateFrame('Button', nil, LogWindow, 'UIPanelButtonTemplate')
	LogWindow.ReloadButton:SetSize(80, 22)
	LogWindow.ReloadButton:SetPoint('BOTTOMLEFT', LogWindow, 'BOTTOMLEFT', 3, 4)
	LogWindow.ReloadButton:SetText('Reload UI')
	LogWindow.ReloadButton:SetScript(
		'OnClick',
		function()
			ReloadUI()
		end
	)

	-- Create log text display in right panel with MinimalScrollBar
	LogWindow.TextPanel = CreateFrame('ScrollFrame', nil, LogWindow.RightPanel)
	LogWindow.TextPanel:SetPoint('TOPLEFT', LogWindow.RightPanel, 'TOPLEFT', 6, -6)
	LogWindow.TextPanel:SetPoint('BOTTOMRIGHT', LogWindow.RightPanel, 'BOTTOMRIGHT', 0, 2)

	-- Create minimal scrollbar for right panel
	LogWindow.TextPanel.ScrollBar = CreateFrame('EventFrame', nil, LogWindow.TextPanel, 'MinimalScrollBar')
	LogWindow.TextPanel.ScrollBar:SetPoint('TOPLEFT', LogWindow.TextPanel, 'TOPRIGHT', 0, 0)
	LogWindow.TextPanel.ScrollBar:SetPoint('BOTTOMLEFT', LogWindow.TextPanel, 'BOTTOMRIGHT', 0, 0)
	ScrollUtil.InitScrollFrameWithScrollBar(LogWindow.TextPanel, LogWindow.TextPanel.ScrollBar)

	-- Create the text display area
	LogWindow.EditBox = CreateFrame('EditBox', nil, LogWindow.TextPanel)
	LogWindow.EditBox:SetMultiLine(true)
	LogWindow.EditBox:SetFontObject('GameFontHighlight') -- Increased font size by 2 from GameFontHighlightSmall
	LogWindow.EditBox:SetText('No logs active - select a module from the left or enable "Search All Modules"')
	LogWindow.EditBox:SetWidth(LogWindow.TextPanel:GetWidth() - 20)
	LogWindow.EditBox:SetScript(
		'OnTextChanged',
		function(self)
			ScrollingEdit_OnTextChanged(self, self:GetParent())
		end
	)
	LogWindow.EditBox:SetScript(
		'OnCursorChanged',
		function(self, x, y, w, h)
			ScrollingEdit_OnCursorChanged(self, x, y - 10, w, h)
		end
	)
	LogWindow.EditBox:SetAutoFocus(false)
	LogWindow.EditBox:EnableMouse(true) -- Allow selection for copying
	LogWindow.EditBox:SetTextColor(1, 1, 1) -- White text for better readability
	LogWindow.TextPanel:SetScrollChild(LogWindow.EditBox)

	-- Auto-scroll checkbox centered under right panel
	LogWindow.AutoScroll = CreateFrame('CheckButton', 'SUI_AutoScroll', LogWindow, 'UICheckButtonTemplate')
	LogWindow.AutoScroll:SetSize(18, 18)
	LogWindow.AutoScroll:SetPoint('CENTER', LogWindow.RightPanel, 'BOTTOM', 0, -15)
	LogWindow.AutoScroll:SetChecked(AutoScrollEnabled)

	LogWindow.AutoScrollLabel = LogWindow:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	LogWindow.AutoScrollLabel:SetText('Auto-scroll')
	LogWindow.AutoScrollLabel:SetPoint('LEFT', LogWindow.AutoScroll, 'RIGHT', 2, 0)
	LogWindow.AutoScrollLabel:SetTextColor(1, 1, 1) -- White text

	-- Initialize data structures
	LogWindow.Categories = {}
	LogWindow.categoryButtons = {}
	LogWindow.moduleButtons = {}

	-- Build log source categories (like AuctionFrame's item categories)
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
		LogWindow.ExportFrame = CreateFrame('Frame', 'SUI_LogExportFrame', UIParent, 'ButtonFrameTemplate')
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
-- External API - SUI.Logger (for third-party addons)
----------------------------------------------------------------------------------------------------

-- Initialize the external Logger API
SUI.Logger = {} ---@class SUI.Logger

---Register a simple addon for logging under "External Addons" category
---@param addonName string Name of the addon to register
---@return SimpleLogger logger Logger function that takes (message, level?)
function SUI.Logger.RegisterAddon(addonName)
	-- Protect against incorrect colon syntax: SUI.Logger:RegisterAddon()
	if type(addonName) == 'table' and addonName == SUI.Logger then
		error('RegisterAddon: Called with colon syntax (:) - use dot syntax (.) instead: SUI.Logger.RegisterAddon(addonName)')
	end

	if not addonName or addonName == '' or type(addonName) ~= 'string' then
		error('RegisterAddon: addonName must be a non-empty string')
	end

	-- Store registration
	RegisteredAddons[addonName] = true

	-- Create and cache logger function
	local loggerFunc = function(message, level)
		SUI.Log(message, addonName, level)
	end

	AddonLoggers[addonName] = loggerFunc

	-- Initialize in database if logger is ready
	if logger.DB then
		logger.DB.modules[addonName] = true
	end

	return loggerFunc
end

---Register an addon with its own expandable category and subcategories
---@param addonName string Name of the addon (will be the category name)
---@param subcategories string[] Array of subcategory names
---@return ComplexLoggers loggers Table of logger functions keyed by subcategory name
function SUI.Logger.RegisterAddonCategory(addonName, subcategories)
	-- Protect against incorrect colon syntax: SUI.Logger:RegisterAddonCategory()
	if type(addonName) == 'table' and addonName == SUI.Logger then
		error('RegisterAddonCategory: Called with colon syntax (:) - use dot syntax (.) instead: SUI.Logger.RegisterAddonCategory(addonName, subcategories)')
	end

	if not addonName or addonName == '' or type(addonName) ~= 'string' then
		error('RegisterAddonCategory: addonName must be a non-empty string')
	end
	if not subcategories or type(subcategories) ~= 'table' or #subcategories == 0 then
		error('RegisterAddonCategory: subcategories must be a non-empty array')
	end

	-- Validate all subcategory names are strings
	for i, subcat in ipairs(subcategories) do
		if type(subcat) ~= 'string' or subcat == '' then
			error('RegisterAddonCategory: subcategory at index ' .. i .. ' must be a non-empty string, got: ' .. type(subcat))
		end
		-- Check for invalid characters that could cause parsing issues
		if subcat:find('%.') then
			error('RegisterAddonCategory: subcategory "' .. subcat .. '" cannot contain dots (.) as they are used for hierarchy parsing')
		end
	end

	-- Validate addonName doesn't contain problematic characters
	if addonName:find('%.') then
		error('RegisterAddonCategory: addonName "' .. addonName .. '" cannot contain dots (.) as they are used for hierarchy parsing')
	end

	-- Store category registration
	AddonCategories[addonName] = {
		subcategories = subcategories,
		expanded = false
	}

	-- Create logger functions for each subcategory
	local loggers = {}
	for _, subcat in ipairs(subcategories) do
		local moduleName = addonName .. '.' .. subcat
		loggers[subcat] = function(message, level)
			SUI.Log(message, moduleName, level)
		end

		-- Initialize in database if logger is ready
		if logger.DB then
			logger.DB.modules[moduleName] = true
		end
	end

	-- Cache the logger table
	AddonLoggers[addonName] = loggers

	return loggers
end

---Enhanced logging function with log levels
---@param debugText string The message to log
---@param module string The module name
---@param level? LogLevel Log level - defaults to 'info'
function SUI.Log(debugText, module, level)
	level = level or 'info'

	-- Validate module name to prevent invalid entries
	if type(module) ~= 'string' or module == '' then
		-- Log to a fallback module name and issue a warning
		module = 'InvalidModule'
		debugText = 'Invalid module name provided to SUI.Log: ' .. tostring(debugText)
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
	if SUI.releaseType ~= 'DEV Build' then
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

-- Compatibility function to maintain existing SUI.Debug calls
---@param debugText string The message to log
---@param module string The module name
---@param level? LogLevel Log level - defaults to 'info'
function SUI.Debug(debugText, module, level)
	-- Redirect to the new logging function
	SUI.Log(debugText, module, level)
end

----------------------------------------------------------------------------------------------------
-- Internal SpartanUI Module Logging API
----------------------------------------------------------------------------------------------------

---Enhanced logging function for SpartanUI modules that leverages module objects
---Automatically uses module DisplayName, falls back to module name, and supports hierarchical categorization
---@param moduleObj SUI.Module The SpartanUI module object
---@param message string The message to log
---@param component? string Optional component/subcomponent for hierarchical logging (e.g., "Database.Connection")
---@param level? LogLevel Log level - defaults to 'info'
function SUI.ModuleLog(moduleObj, message, component, level)
	if not moduleObj then
		SUI.Log(message, 'Unknown', level)
		return
	end

	-- Get the best display name for the module
	local moduleName = moduleObj.DisplayName or moduleObj:GetName()

	-- Create hierarchical source name if component is provided
	local logSource = moduleName
	if component and component ~= '' then
		logSource = moduleName .. '.' .. component
	end

	SUI.Log(message, logSource, level)
end

---Create a logger function for a specific SpartanUI module
---Returns a logger function that automatically uses the module's information
---@param moduleObj SUI.Module The SpartanUI module object
---@param defaultComponent? string Optional default component name for all logs from this logger
---@return fun(message: string, component?: string, level?: LogLevel) logger Logger function
function SUI.CreateModuleLogger(moduleObj, defaultComponent)
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

		SUI.ModuleLog(moduleObj, message, component, level)
	end
end

---Enhanced module registration system that provides easy logging setup
---Call this in your module's OnInitialize to get a pre-configured logger
---@param moduleObj SUI.Module The SpartanUI module object
---@param components? string[] Optional list of components for structured logging
---@return SimpleLogger|ComplexLoggers logger Either a simple logger function or a table of component loggers
function SUI.SetupModuleLogging(moduleObj, components)
	if not moduleObj then
		error('SetupModuleLogging: moduleObj is required')
	end

	if not components or #components == 0 then
		-- Simple logger - just logs to the module name
		return SUI.CreateModuleLogger(moduleObj)
	else
		-- Complex logger - create component-specific loggers
		local loggers = {}
		for _, component in ipairs(components) do
			loggers[component] = SUI.CreateModuleLogger(moduleObj, component)
		end

		-- Also add a general logger without component prefix
		loggers.general = SUI.CreateModuleLogger(moduleObj)

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
		SUI.Log('Purging ' .. #invalidEntries .. ' invalid entries from logger modules database', 'Logger', 'warning')
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
		SUI.Log('Purging ' .. #invalidEntries .. ' invalid entries from logger moduleLogLevels database', 'Logger', 'warning')
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
					SUI:Print('All module log levels reset to global setting.')
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
			y = 0
		},
		modules = {
			['*'] = true, -- Default to enabled for logging approach
			Core = true
		},
		moduleLogLevels = {
			['*'] = 0 -- Use global level by default
		}
	}
	logger.Database = SUI.SpartanUIDB:RegisterNamespace('Logger', {profile = defaults})
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

	if SUI:IsModuleEnabled('Chatbox') then
		logger:RegisterEvent('ADDON_LOADED')
	end
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

	SUI:AddChatCommand('logs', ToggleLogWindow, 'Toggles the SpartanUI Logging window display')

	-- Register direct WoW slash commands
	SLASH_SUILOGS1 = '/logs'
	SlashCmdList['SUILOGS'] = ToggleLogWindow

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
	if not scrollFrame then
		return
	end
	for _, child in next, {scrollFrame.LinesContainer:GetChildren()} do
		if child.ValueButton and child.ValueButton:GetScript('OnMouseDown') ~= OnMouseDown then
			child.ValueButton:SetScript('OnMouseDown', OnMouseDown)
		end
	end
end

function logger:ADDON_LOADED(_, addon)
	if addon == 'Blizzard_DebugTools' then
		hooksecurefunc(TableInspectorMixin, 'RefreshAllData', RefreshData)
		hooksecurefunc(TableAttributeDisplay.dataProviders[2], 'RefreshData', RefreshData)
		logger:UnregisterEvent('ADDON_LOADED')
	end
end
