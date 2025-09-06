---@class SUI
local SUI = SUI
local debugger = SUI:NewModule('Handler.Debugger') ---@type SUI.Module
SUI.Handlers.Debugger = debugger
debugger.description = 'SpartanUI Logging System'
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
		if data.priority == priority then
			return level, data
		end
	end
	return 'info', LOG_LEVELS['info'] -- Default fallback
end


local function CreateLogWindow()
	if LogWindow then return end

	-- Create main frame using PortraitFrameTemplate for proper skinning
	LogWindow = CreateFrame('Frame', 'SpartanUI_LogWindow', UIParent, 'PortraitFrameTemplate')
	LogWindow:SetSize(714, 487)
	LogWindow:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	LogWindow:SetFrameStrata('HIGH')
	LogWindow:Hide()
	
	-- Set the portrait (with safety checks)
	if LogWindow.portrait then
		if LogWindow.portrait.SetTexture then
			LogWindow.portrait:SetTexture('Interface\\AddOns\\SpartanUI\\images\\LogoSpartanUI')
		end
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
	LogWindow.LeftPanel = CreateFrame('Frame', nil, LogWindow.MainContent, 'InsetFrameTemplate')
	LogWindow.LeftPanel:SetPoint('TOPLEFT', LogWindow.MainContent, 'TOPLEFT', 8, -8)
	LogWindow.LeftPanel:SetPoint('BOTTOMLEFT', LogWindow.MainContent, 'BOTTOMLEFT', 8, 8)
	LogWindow.LeftPanel:SetWidth(160)
	
	-- Add a header for the module list
	LogWindow.ModuleHeader = LogWindow.LeftPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	LogWindow.ModuleHeader:SetText('Modules')
	LogWindow.ModuleHeader:SetPoint('TOP', LogWindow.LeftPanel, 'TOP', 0, -6)
	LogWindow.ModuleHeader:SetTextColor(1, 0.82, 0) -- Gold color like Blizzard headers

	-- Right panel for log text (main display area like AuctionFrame's item list)
	LogWindow.RightPanel = CreateFrame('Frame', nil, LogWindow.MainContent, 'InsetFrameTemplate')
	LogWindow.RightPanel:SetPoint('TOPLEFT', LogWindow.LeftPanel, 'TOPRIGHT', 8, 0)
	LogWindow.RightPanel:SetPoint('BOTTOMRIGHT', LogWindow.MainContent, 'BOTTOMRIGHT', -8, 8)

	-- Create scroll frame for module list in left panel (properly sized)
	LogWindow.ModuleScrollFrame = CreateFrame('ScrollFrame', nil, LogWindow.LeftPanel, 'UIPanelScrollFrameTemplate')
	LogWindow.ModuleScrollFrame:SetPoint('TOPLEFT', LogWindow.ModuleHeader, 'BOTTOMLEFT', -8, -5)
	LogWindow.ModuleScrollFrame:SetPoint('BOTTOMRIGHT', LogWindow.LeftPanel, 'BOTTOMRIGHT', -26, 8)
	
	LogWindow.ModuleList = CreateFrame('Frame', nil, LogWindow.ModuleScrollFrame)
	LogWindow.ModuleScrollFrame:SetScrollChild(LogWindow.ModuleList)
	LogWindow.ModuleList:SetSize(125, 1)

	-- Create log text display in right panel (styled like AuctionFrame's main area)
	LogWindow.TextPanel = CreateFrame('ScrollFrame', nil, LogWindow.RightPanel, 'UIPanelScrollFrameTemplate')
	LogWindow.TextPanel:SetPoint('TOPLEFT', LogWindow.RightPanel, 'TOPLEFT', 8, -8)
	LogWindow.TextPanel:SetPoint('BOTTOMRIGHT', LogWindow.RightPanel, 'BOTTOMRIGHT', -26, 8)
	
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
	LogWindow.Modules = {}
	LogWindow.moduleButtons = {}

	for moduleName, _ in pairs(debugger.DB.modules) do
		table.insert(ScrollListing, { text = moduleName, value = moduleName })
	end
	LogWindow.modules = debugger.DB.modules

	-- Create module buttons (styled like AuctionFrame category buttons)
	local buttonHeight = 20
	local buttonSpacing = 1
	for i, moduleData in ipairs(ScrollListing) do
		local button = CreateFrame('Button', nil, LogWindow.ModuleList, 'UIPanelButtonTemplate')
		button:SetSize(125, buttonHeight)
		button:SetPoint('TOPLEFT', LogWindow.ModuleList, 'TOPLEFT', 0, -(i-1) * (buttonHeight + buttonSpacing))
		button:SetText(moduleData.text)
		button:SetNormalFontObject('GameFontNormalSmall')
		button:SetHighlightFontObject('GameFontHighlightSmall')
		button:SetScript('OnClick', function(self)
			-- Update button states (highlight selected)
			for _, btn in pairs(LogWindow.moduleButtons) do
				btn:SetNormalFontObject('GameFontNormalSmall')
			end
			self:SetNormalFontObject('GameFontHighlightSmall')
			
			ActiveModule = self:GetText()
			UpdateLogDisplay()
		end)
		table.insert(LogWindow.moduleButtons, button)
	end

	-- Update module list height
	local totalHeight = #ScrollListing * (buttonHeight + buttonSpacing)
	LogWindow.ModuleList:SetHeight(math.max(totalHeight, LogWindow.ModuleScrollFrame:GetHeight()))

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
	local escapedTerm = searchTerm:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	
	-- Replace all occurrences (case-insensitive) with highlighted version
	local highlightedText = text:gsub('(' .. escapedTerm .. ')', function(match)
		return highlightColor .. match .. resetColor
	end)
	
	return highlightedText
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
			logText = 'Search Results: ' .. searchedCount .. ' matches across all modules\n' .. 
					  'Total entries: ' .. totalEntries .. ' | Filtered: ' .. filteredCount .. '\n\n' .. logText
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
	if AutoScrollEnabled and LogWindow.EditBox then
		LogWindow.EditBox:SetCursorPosition(string.len(logText))
	end
	
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
					if not CurrentSearchTerm or CurrentSearchTerm == '' or 
					   logEntry.message:lower():find(CurrentSearchTerm:lower(), 1, true) then
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
	-- Global log level dropdown
	UIDropDownMenu_Initialize(LogWindow.GlobalLevelDropdown, function(self, level)
		local info = UIDropDownMenu_CreateInfo()
		
		-- Add log levels
		for logLevel, data in pairs(LOG_LEVELS) do
			info.text = data.display
			info.value = data.priority
			info.func = function()
				GlobalLogLevel = data.priority
				debugger.DB.globalLogLevel = GlobalLogLevel
				UIDropDownMenu_SetText(LogWindow.GlobalLevelDropdown, data.display)
				UpdateLogDisplay() -- Refresh current view
			end
			info.checked = (GlobalLogLevel == data.priority)
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
			debugger.DB.moduleLogLevels[ActiveModule] = 0
			UIDropDownMenu_SetText(LogWindow.ModuleLevelDropdown, 'Global')
			UpdateLogDisplay()
		end
		info.checked = ((ModuleLogLevels[ActiveModule] or 0) == 0)
		UIDropDownMenu_AddButton(info)
		
		-- Add separator
		info = UIDropDownMenu_CreateInfo()
		info.text = ""
		info.disabled = true
		UIDropDownMenu_AddButton(info)
		
		-- Add log levels
		for logLevel, data in pairs(LOG_LEVELS) do
			info = UIDropDownMenu_CreateInfo()
			info.text = data.display
			info.value = data.priority
			info.func = function()
				ModuleLogLevels[ActiveModule] = data.priority
				debugger.DB.moduleLogLevels[ActiveModule] = data.priority
				UIDropDownMenu_SetText(LogWindow.ModuleLevelDropdown, data.display)
				UpdateLogDisplay()
			end
			info.checked = ((ModuleLogLevels[ActiveModule] or 0) == data.priority)
			UIDropDownMenu_AddButton(info)
		end
	end)
end

---Enhanced logging function with log levels
---@param debugText string The message to log
---@param module string The module name
---@param level? string Log level (debug, info, warning, error, critical) - defaults to 'info'
function SUI.Debug(debugText, module, level)
	level = level or 'info'
	
	-- Initialize module if it doesn't exist
	if not LogMessages[module] then
		LogMessages[module] = {}
		table.insert(ScrollListing, { text = module, value = module })
		
		-- Add new module button if log window exists
		if LogWindow and LogWindow.ModuleList then
			local buttonHeight = 20
			local buttonSpacing = 2
			local buttonIndex = #ScrollListing
			
			local button = CreateFrame('Button', nil, LogWindow.ModuleList, 'UIPanelButtonTemplate')
			button:SetSize(140, buttonHeight)
			button:SetPoint('TOPLEFT', LogWindow.ModuleList, 'TOPLEFT', 0, -(buttonIndex-1) * (buttonHeight + buttonSpacing))
			button:SetText(module)
			button:SetScript('OnClick', function(self)
				ActiveModule = self:GetText()
				UpdateLogDisplay()
			end)
			table.insert(LogWindow.moduleButtons, button)
			
			-- Update module list height
			local totalHeight = #ScrollListing * (buttonHeight + buttonSpacing)
			LogWindow.ModuleList:SetHeight(math.max(totalHeight, LogWindow.ModuleScrollFrame:GetHeight()))
		end
		
		debugger.DB.modules[module] = debugger.DB.enable
		if debugger.options then debugger.options.args[module] = {
			name = module,
			type = 'toggle',
			order = (#debugger.options.args + 1),
		} end
	end

	-- Check if we should log this message based on log levels
	local logLevel = LOG_LEVELS[level]
	if not logLevel then
		level = 'info'
		logLevel = LOG_LEVELS[level]
	end
	
	local moduleLogLevel = ModuleLogLevels[module] or 0
	local effectiveLogLevel = moduleLogLevel > 0 and moduleLogLevel or GlobalLogLevel
	
	-- Always capture warnings and errors if enabled
	local shouldCapture = false
	if debugger.DB.captureWarningsErrors and (level == 'warning' or level == 'error' or level == 'critical') then
		shouldCapture = true
	elseif debugger.DB.enable and debugger.DB.modules[module] then
		shouldCapture = true
	elseif logLevel.priority >= effectiveLogLevel then
		shouldCapture = true
	end
	
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
	local maxHistory = debugger.DB.maxLogHistory or 1000
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

local function AddOptions()
	---@type AceConfig.OptionsTable
	local options = {
		name = 'Debug',
		type = 'group',
		get = function(info)
			return debugger.DB.modules[info[#info]]
		end,
		set = function(info, val)
			debugger.DB.modules[info[#info]] = val
			if not val and debugger.DB.enable then debugger.DB.enable = false end
		end,
		args = {
			EnableAll = {
				name = 'Enable All',
				type = 'toggle',
				order = 0,
				get = function(info)
					return debugger.DB.enable
				end,
				set = function(info, val)
					debugger.DB.enable = val
					for k, _ in pairs(debugger.DB.modules) do
						debugger.DB.modules[k] = val
					end
				end,
			},
		},
	}

	for k, _ in pairs(debugger.DB.modules) do
		options.args[k] = {
			name = k,
			type = 'toggle',
			order = (#options.args + 1),
		}
	end
	debugger.options = options
	SUI.Options:AddOptions(options, 'Debug', 'Help')
end

function debugger:OnInitialize()
	local defaults = {
		enable = false,
		globalLogLevel = 2, -- Default to 'info' and above
		captureWarningsErrors = true, -- Always capture warnings and errors
		maxLogHistory = 1000, -- Maximum log entries per module
		modules = {
			['*'] = false,
			Core = false,
		},
		moduleLogLevels = {
			['*'] = 0, -- Use global level by default
		},
	}
	debugger.Database = SUI.SpartanUIDB:RegisterNamespace('Debugger', { profile = defaults })
	debugger.DB = debugger.Database.profile

	-- Initialize log structures
	for k, _ in pairs(debugger.DB.modules) do
		LogMessages[k] = {}
	end

	-- Load settings
	GlobalLogLevel = debugger.DB.globalLogLevel or 2
	ModuleLogLevels = debugger.DB.moduleLogLevels or {}

	if SUI:IsModuleEnabled('Chatbox') then debugger:RegisterEvent('ADDON_LOADED') end
end

function debugger:OnEnable()
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

function debugger:ADDON_LOADED(_, addon)
	if addon == 'Blizzard_DebugTools' then
		hooksecurefunc(TableInspectorMixin, 'RefreshAllData', RefreshData)
		hooksecurefunc(TableAttributeDisplay.dataProviders[2], 'RefreshData', RefreshData)
		debugger:UnregisterEvent('ADDON_LOADED')
	end
end
