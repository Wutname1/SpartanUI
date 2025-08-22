---@diagnostic disable: duplicate-set-field
--[===[ File: Configuration/PluginManager.lua
LibsDataBar Advanced Plugin Management Interface
Enhanced plugin management with performance monitoring and organization
--]===]

-- Get the LibsDataBar addon
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- AceGUI for interface elements
local AceGUI = LibStub('AceGUI-3.0', true)
if not AceGUI then
	LibsDataBar:DebugLog('error', 'PluginManager requires AceGUI-3.0', 'plugins')
	return
end

---@class PluginManager
---@field managementFrame AceGUIFrame|nil Plugin management frame
---@field pluginList table<string, PluginInfo> Enhanced plugin information
---@field filterSettings table Current filter settings
---@field sortSettings table Current sort settings
---@field refreshTimer table|nil Auto-refresh timer
local PluginManager = {}

---@class PluginInfo
---@field plugin table Plugin object
---@field performance PerformanceData Performance metrics
---@field status PluginStatus Status information
---@field lastUpdate number Last update timestamp

---@class PerformanceData
---@field updateTime number Average update time (ms)
---@field memoryUsage number Memory usage (KB)
---@field errorCount number Number of errors
---@field callCount number Number of update calls
---@field efficiency number Efficiency rating (0-100)

---@class PluginStatus
---@field enabled boolean Whether plugin is enabled
---@field loaded boolean Whether plugin is loaded
---@field bars table<string, boolean> Bars the plugin is added to
---@field lastError string|nil Last error message
---@field validationScore number|nil Validation score

-- Enhanced Plugin Manager for LibsDataBar
LibsDataBar.pluginManager = LibsDataBar.pluginManager
	or setmetatable({
		managementFrame = nil,
		pluginList = {},
		filterSettings = {
			showEnabled = true,
			showDisabled = true,
			showNative = true,
			showLDB = true,
			category = 'all',
			searchText = '',
		},
		sortSettings = {
			field = 'name',
			ascending = true,
		},
		refreshTimer = nil,
	}, { __index = PluginManager })

-- Plugin categories for organization
local PLUGIN_CATEGORIES = {
	['Information'] = 'Information & Display',
	['System'] = 'System Monitoring',
	['Character'] = 'Character Data',
	['Social'] = 'Social Features',
	['Game'] = 'Game Information',
	['Utility'] = 'Utility & Tools',
	['Custom'] = 'Custom Plugins',
	['LDB'] = 'LibDataBroker Plugins',
}

---Initialize the plugin manager
function PluginManager:Initialize()
	-- Scan and catalog all plugins
	self:ScanPlugins()

	-- Start performance monitoring
	self:StartPerformanceMonitoring()

	LibsDataBar:DebugLog('info', 'Advanced plugin manager initialized', 'plugins')
end

---Scan and catalog all available plugins
function PluginManager:ScanPlugins()
	self.pluginList = {}

	-- Scan native LibsDataBar plugins
	for pluginId, plugin in pairs(LibsDataBar.plugins or {}) do
		self:AddPluginToList(pluginId, plugin, 'native')
	end

	-- Scan LibDataBroker plugins
	if LibsDataBar.ldb and LibsDataBar.ldb.registeredObjects then
		for ldbName, wrapper in pairs(LibsDataBar.ldb.registeredObjects) do
			if wrapper and wrapper.plugin then self:AddPluginToList(wrapper.plugin.id, wrapper.plugin, 'ldb') end
		end
	end

	LibsDataBar:DebugLog('info', string.format('Catalogued %d plugins', self:GetPluginCount()), 'plugins')
end

---Add a plugin to the managed list
---@param pluginId string Plugin ID
---@param plugin table Plugin object
---@param type string Plugin type ("native" or "ldb")
function PluginManager:AddPluginToList(pluginId, plugin, type)
	self.pluginList[pluginId] = {
		plugin = plugin,
		type = type,
		performance = {
			updateTime = 0,
			memoryUsage = 0,
			errorCount = 0,
			callCount = 0,
			efficiency = 100,
		},
		status = {
			enabled = true,
			loaded = true,
			bars = {},
			lastError = nil,
			validationScore = nil,
		},
		lastUpdate = GetTime(),
	}

	-- Get validation score if available
	if LibsDataBar.validator then
		local result = LibsDataBar.validator:ValidatePlugin(plugin)
		self.pluginList[pluginId].status.validationScore = result.score
	end

	-- Check which bars the plugin is added to
	for barId, bar in pairs(LibsDataBar.bars or {}) do
		if bar.plugins and bar.plugins[pluginId] then self.pluginList[pluginId].status.bars[barId] = true end
	end
end

---Start performance monitoring for plugins
function PluginManager:StartPerformanceMonitoring()
	-- Hook into plugin update calls to track performance
	self:HookPluginMethods()

	-- Start auto-refresh timer
	if not self.refreshTimer then self.refreshTimer = C_Timer.NewTicker(5, function()
		self:UpdatePluginMetrics()
	end) end
end

---Hook plugin methods for performance tracking
function PluginManager:HookPluginMethods()
	for pluginId, pluginInfo in pairs(self.pluginList) do
		local plugin = pluginInfo.plugin

		-- Hook GetText method for performance tracking
		if plugin.GetText and not plugin._originalGetText then
			plugin._originalGetText = plugin.GetText
			plugin.GetText = function(self, ...)
				local startTime = GetTime()
				local startMemory = collectgarbage('count')

				local success, result = pcall(plugin._originalGetText, self, ...)

				local endTime = GetTime()
				local endMemory = collectgarbage('count')

				-- Update performance metrics
				local pluginInfo = LibsDataBar.pluginManager.pluginList[pluginId]
				if pluginInfo then
					local updateTime = (endTime - startTime) * 1000 -- Convert to ms
					local memoryDelta = endMemory - startMemory

					pluginInfo.performance.callCount = pluginInfo.performance.callCount + 1
					pluginInfo.performance.updateTime = (pluginInfo.performance.updateTime + updateTime) / 2 -- Rolling average
					pluginInfo.performance.memoryUsage = (pluginInfo.performance.memoryUsage + memoryDelta) / 2

					if not success then
						pluginInfo.performance.errorCount = pluginInfo.performance.errorCount + 1
						pluginInfo.status.lastError = tostring(result)
					end

					-- Calculate efficiency score
					pluginInfo.performance.efficiency = LibsDataBar.pluginManager:CalculateEfficiency(pluginInfo)
				end

				if success then
					return result
				else
					LibsDataBar:DebugLog('error', 'Plugin error in ' .. pluginId .. ': ' .. tostring(result), 'plugins')
					return 'Error'
				end
			end
		end
	end
end

---Calculate plugin efficiency score
---@param pluginInfo PluginInfo Plugin information
---@return number efficiency Efficiency score (0-100)
function PluginManager:CalculateEfficiency(pluginInfo)
	local perf = pluginInfo.performance
	local score = 100

	-- Penalize slow update times (> 1ms is concerning)
	if perf.updateTime > 1 then score = score - math.min(perf.updateTime * 10, 30) end

	-- Penalize high memory usage (> 1KB per call is concerning)
	if perf.memoryUsage > 1 then score = score - math.min(perf.memoryUsage * 5, 20) end

	-- Penalize errors
	local errorRate = perf.callCount > 0 and (perf.errorCount / perf.callCount) or 0
	score = score - (errorRate * 50)

	return math.max(score, 0)
end

---Update plugin metrics
function PluginManager:UpdatePluginMetrics()
	for pluginId, pluginInfo in pairs(self.pluginList) do
		-- Update bar status
		pluginInfo.status.bars = {}
		for barId, bar in pairs(LibsDataBar.bars or {}) do
			if bar.plugins and bar.plugins[pluginId] then pluginInfo.status.bars[barId] = true end
		end

		pluginInfo.lastUpdate = GetTime()
	end
end

---Show the plugin management interface
function PluginManager:Show()
	if self.managementFrame then
		self.managementFrame:Hide()
		self.managementFrame = nil
	end

	-- Refresh plugin data
	self:ScanPlugins()

	-- Create main management frame
	self.managementFrame = AceGUI:Create('Frame')
	self.managementFrame:SetTitle('LibsDataBar Plugin Manager')
	self.managementFrame:SetStatusText(string.format('%d plugins found', self:GetPluginCount()))
	self.managementFrame:SetLayout('Flow')
	self.managementFrame:SetWidth(900)
	self.managementFrame:SetHeight(700)

	self.managementFrame:SetCallback('OnClose', function(widget)
		self:Hide()
	end)

	-- Create interface elements
	self:CreateFilterControls()
	self:CreatePluginList()
	self:CreateActionButtons()
end

---Hide the plugin management interface
function PluginManager:Hide()
	if self.managementFrame then
		AceGUI:Release(self.managementFrame)
		self.managementFrame = nil
	end
end

---Create filter and search controls
function PluginManager:CreateFilterControls()
	local controlGroup = AceGUI:Create('SimpleGroup')
	controlGroup:SetLayout('Flow')
	controlGroup:SetFullWidth(true)
	controlGroup:SetHeight(100)

	-- Search box
	local searchBox = AceGUI:Create('EditBox')
	searchBox:SetLabel('Search Plugins')
	searchBox:SetWidth(200)
	searchBox:SetText(self.filterSettings.searchText)
	searchBox:SetCallback('OnTextChanged', function(widget, event, text)
		self.filterSettings.searchText = text
		self:RefreshPluginList()
	end)
	controlGroup:AddChild(searchBox)

	-- Category filter
	local categoryFilter = AceGUI:Create('Dropdown')
	categoryFilter:SetLabel('Category')
	categoryFilter:SetWidth(150)

	local categories = { ['all'] = 'All Categories' }
	for key, name in pairs(PLUGIN_CATEGORIES) do
		categories[key] = name
	end
	categoryFilter:SetList(categories)
	categoryFilter:SetValue(self.filterSettings.category)
	categoryFilter:SetCallback('OnValueChanged', function(widget, event, value)
		self.filterSettings.category = value
		self:RefreshPluginList()
	end)
	controlGroup:AddChild(categoryFilter)

	-- Type filters
	local nativeCheck = AceGUI:Create('CheckBox')
	nativeCheck:SetLabel('Native')
	nativeCheck:SetValue(self.filterSettings.showNative)
	nativeCheck:SetCallback('OnValueChanged', function(widget, event, value)
		self.filterSettings.showNative = value
		self:RefreshPluginList()
	end)
	controlGroup:AddChild(nativeCheck)

	local ldbCheck = AceGUI:Create('CheckBox')
	ldbCheck:SetLabel('LDB')
	ldbCheck:SetValue(self.filterSettings.showLDB)
	ldbCheck:SetCallback('OnValueChanged', function(widget, event, value)
		self.filterSettings.showLDB = value
		self:RefreshPluginList()
	end)
	controlGroup:AddChild(ldbCheck)

	-- Status filters
	local enabledCheck = AceGUI:Create('CheckBox')
	enabledCheck:SetLabel('Enabled')
	enabledCheck:SetValue(self.filterSettings.showEnabled)
	enabledCheck:SetCallback('OnValueChanged', function(widget, event, value)
		self.filterSettings.showEnabled = value
		self:RefreshPluginList()
	end)
	controlGroup:AddChild(enabledCheck)

	local disabledCheck = AceGUI:Create('CheckBox')
	disabledCheck:SetLabel('Disabled')
	disabledCheck:SetValue(self.filterSettings.showDisabled)
	disabledCheck:SetCallback('OnValueChanged', function(widget, event, value)
		self.filterSettings.showDisabled = value
		self:RefreshPluginList()
	end)
	controlGroup:AddChild(disabledCheck)

	self.managementFrame:AddChild(controlGroup)
end

---Create the plugin list display
function PluginManager:CreatePluginList()
	-- Create scrollable container
	local scrollContainer = AceGUI:Create('ScrollFrame')
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetHeight(450)
	scrollContainer:SetLayout('List')

	self.pluginContainer = scrollContainer
	self:RefreshPluginList()

	self.managementFrame:AddChild(scrollContainer)
end

---Refresh the plugin list display
function PluginManager:RefreshPluginList()
	if not self.pluginContainer then return end

	self.pluginContainer:ReleaseChildren()

	local filteredPlugins = self:GetFilteredPlugins()
	local sortedPlugins = self:SortPlugins(filteredPlugins)

	for _, pluginInfo in ipairs(sortedPlugins) do
		local pluginWidget = self:CreatePluginWidget(pluginInfo)
		self.pluginContainer:AddChild(pluginWidget)
	end

	-- Update status text
	if self.managementFrame then self.managementFrame:SetStatusText(string.format('%d of %d plugins shown', #sortedPlugins, self:GetPluginCount())) end
end

---Get filtered plugin list
---@return table filteredPlugins Filtered plugin list
function PluginManager:GetFilteredPlugins()
	local filtered = {}

	for pluginId, pluginInfo in pairs(self.pluginList) do
		local plugin = pluginInfo.plugin

		-- Apply filters
		local passesFilter = true

		-- Type filter
		if not ((pluginInfo.type == 'native' and self.filterSettings.showNative) or (pluginInfo.type == 'ldb' and self.filterSettings.showLDB)) then passesFilter = false end

		-- Status filter
		if not ((pluginInfo.status.enabled and self.filterSettings.showEnabled) or (not pluginInfo.status.enabled and self.filterSettings.showDisabled)) then passesFilter = false end

		-- Category filter
		if self.filterSettings.category ~= 'all' then
			local pluginCategory = plugin.category or 'Custom'
			if pluginInfo.type == 'ldb' then pluginCategory = 'LDB' end
			if pluginCategory ~= self.filterSettings.category then passesFilter = false end
		end

		-- Search filter
		if self.filterSettings.searchText and self.filterSettings.searchText ~= '' then
			local searchText = self.filterSettings.searchText:lower()
			local pluginName = (plugin.name or pluginId):lower()
			local pluginDesc = (plugin.description or ''):lower()

			if not (pluginName:find(searchText) or pluginDesc:find(searchText) or pluginId:lower():find(searchText)) then passesFilter = false end
		end

		if passesFilter then table.insert(filtered, pluginInfo) end
	end

	return filtered
end

---Sort plugin list
---@param plugins table Plugin list to sort
---@return table sortedPlugins Sorted plugin list
function PluginManager:SortPlugins(plugins)
	table.sort(plugins, function(a, b)
		local field = self.sortSettings.field
		local aValue, bValue

		if field == 'name' then
			aValue = a.plugin.name or 'Unknown'
			bValue = b.plugin.name or 'Unknown'
		elseif field == 'efficiency' then
			aValue = a.performance.efficiency
			bValue = b.performance.efficiency
		elseif field == 'updateTime' then
			aValue = a.performance.updateTime
			bValue = b.performance.updateTime
		elseif field == 'memoryUsage' then
			aValue = a.performance.memoryUsage
			bValue = b.performance.memoryUsage
		elseif field == 'validationScore' then
			aValue = a.status.validationScore or 0
			bValue = b.status.validationScore or 0
		else
			aValue = a.plugin.name or 'Unknown'
			bValue = b.plugin.name or 'Unknown'
		end

		if self.sortSettings.ascending then
			return aValue < bValue
		else
			return aValue > bValue
		end
	end)

	return plugins
end

---Create a widget for a single plugin
---@param pluginInfo PluginInfo Plugin information
---@return AceGUIWidget widget Plugin widget
function PluginManager:CreatePluginWidget(pluginInfo)
	local plugin = pluginInfo.plugin
	local perf = pluginInfo.performance
	local status = pluginInfo.status

	local container = AceGUI:Create('SimpleGroup')
	container:SetLayout('Flow')
	container:SetFullWidth(true)
	container:SetHeight(60)

	-- Create background frame for alternating colors
	local bg = container.frame:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints()
	bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)

	-- Plugin name and info
	local nameLabel = AceGUI:Create('Label')
	nameLabel:SetText(string.format('|cffFFFFFF%s|r\n|cff888888%s|r', plugin.name or 'Unknown Plugin', plugin.description or 'No description'))
	nameLabel:SetWidth(300)
	container:AddChild(nameLabel)

	-- Performance metrics
	local perfLabel = AceGUI:Create('Label')
	local perfColor = perf.efficiency > 80 and '|cff00ff00' or (perf.efficiency > 60 and '|cffffff00' or '|cffff0000')
	perfLabel:SetText(string.format('%sEff: %d%%|r\n|cff888888%.2fms, %.1fKB|r', perfColor, perf.efficiency, perf.updateTime, perf.memoryUsage))
	perfLabel:SetWidth(100)
	container:AddChild(perfLabel)

	-- Validation score
	if status.validationScore then
		local scoreLabel = AceGUI:Create('Label')
		local scoreColor = status.validationScore > 80 and '|cff00ff00' or (status.validationScore > 60 and '|cffffff00' or '|cffff0000')
		scoreLabel:SetText(string.format('%sScore: %d|r', scoreColor, status.validationScore))
		scoreLabel:SetWidth(80)
		container:AddChild(scoreLabel)
	end

	-- Actions
	local actionGroup = AceGUI:Create('SimpleGroup')
	actionGroup:SetLayout('Flow')
	actionGroup:SetWidth(200)

	-- Enable/Disable button
	local toggleBtn = AceGUI:Create('Button')
	toggleBtn:SetText(status.enabled and 'Disable' or 'Enable')
	toggleBtn:SetWidth(80)
	toggleBtn:SetCallback('OnClick', function()
		self:TogglePlugin(plugin.id)
		self:RefreshPluginList()
	end)
	actionGroup:AddChild(toggleBtn)

	-- Reload button
	local reloadBtn = AceGUI:Create('Button')
	reloadBtn:SetText('Reload')
	reloadBtn:SetWidth(60)
	reloadBtn:SetCallback('OnClick', function()
		if LibsDataBar.hotReload then LibsDataBar.hotReload:ReloadPlugin(plugin.name) end
	end)
	actionGroup:AddChild(reloadBtn)

	-- Validate button
	local validateBtn = AceGUI:Create('Button')
	validateBtn:SetText('Validate')
	validateBtn:SetWidth(60)
	validateBtn:SetCallback('OnClick', function()
		if LibsDataBar.validator then
			local report = LibsDataBar.validator:GetValidationReport(plugin)
			print(report)
		end
	end)
	actionGroup:AddChild(validateBtn)

	container:AddChild(actionGroup)

	return container
end

---Toggle plugin enabled state
---@param pluginId string Plugin ID to toggle
function PluginManager:TogglePlugin(pluginId)
	local pluginInfo = self.pluginList[pluginId]
	if not pluginInfo then return end

	local plugin = pluginInfo.plugin
	local wasEnabled = pluginInfo.status.enabled

	if wasEnabled then
		-- Disable plugin - remove from all bars
		for barId, bar in pairs(LibsDataBar.bars or {}) do
			if bar.plugins and bar.plugins[pluginId] then bar:RemovePlugin(pluginId) end
		end
	else
		-- Enable plugin - add to main bar
		local mainBar = LibsDataBar.bars['main']
		if mainBar then mainBar:AddPlugin(plugin) end
	end

	pluginInfo.status.enabled = not wasEnabled
	LibsDataBar:DebugLog('info', string.format('Plugin %s %s', plugin.name, wasEnabled and 'disabled' or 'enabled'), 'plugins')
end

---Create action buttons
function PluginManager:CreateActionButtons()
	local buttonGroup = AceGUI:Create('SimpleGroup')
	buttonGroup:SetLayout('Flow')
	buttonGroup:SetFullWidth(true)

	-- Refresh button
	local refreshBtn = AceGUI:Create('Button')
	refreshBtn:SetText('Refresh')
	refreshBtn:SetWidth(100)
	refreshBtn:SetCallback('OnClick', function()
		self:ScanPlugins()
		self:RefreshPluginList()
		print('LibsDataBar: Plugin list refreshed')
	end)
	buttonGroup:AddChild(refreshBtn)

	-- Reload All button
	local reloadAllBtn = AceGUI:Create('Button')
	reloadAllBtn:SetText('Reload All')
	reloadAllBtn:SetWidth(100)
	reloadAllBtn:SetCallback('OnClick', function()
		if LibsDataBar.hotReload then LibsDataBar.hotReload:ReloadAllPlugins() end
		self:RefreshPluginList()
	end)
	buttonGroup:AddChild(reloadAllBtn)

	-- Validate All button
	local validateAllBtn = AceGUI:Create('Button')
	validateAllBtn:SetText('Validate All')
	validateAllBtn:SetWidth(100)
	validateAllBtn:SetCallback('OnClick', function()
		self:ValidateAllPlugins()
	end)
	buttonGroup:AddChild(validateAllBtn)

	-- Performance Report button
	local perfReportBtn = AceGUI:Create('Button')
	perfReportBtn:SetText('Performance Report')
	perfReportBtn:SetWidth(150)
	perfReportBtn:SetCallback('OnClick', function()
		self:ShowPerformanceReport()
	end)
	buttonGroup:AddChild(perfReportBtn)

	self.managementFrame:AddChild(buttonGroup)
end

---Validate all plugins
function PluginManager:ValidateAllPlugins()
	if not LibsDataBar.validator then
		print('LibsDataBar: Plugin validator not available')
		return
	end

	local results = {}
	for pluginId, pluginInfo in pairs(self.pluginList) do
		local result = LibsDataBar.validator:ValidatePlugin(pluginInfo.plugin)
		pluginInfo.status.validationScore = result.score
		table.insert(results, {
			name = pluginInfo.plugin.name or pluginId,
			score = result.score,
			isValid = result.isValid,
		})
	end

	-- Sort by score
	table.sort(results, function(a, b)
		return a.score > b.score
	end)

	print('LibsDataBar Plugin Validation Results:')
	for _, result in ipairs(results) do
		local status = result.isValid and 'VALID' or 'INVALID'
		print(string.format('  %s: %d/100 (%s)', result.name, result.score, status))
	end

	self:RefreshPluginList()
end

---Show performance report
function PluginManager:ShowPerformanceReport()
	local report = {}
	table.insert(report, '=== LibsDataBar Plugin Performance Report ===')
	table.insert(report, '')

	-- Sort by efficiency
	local sortedPlugins = {}
	for pluginId, pluginInfo in pairs(self.pluginList) do
		table.insert(sortedPlugins, {
			name = pluginInfo.plugin.name or pluginId,
			perf = pluginInfo.performance,
		})
	end

	table.sort(sortedPlugins, function(a, b)
		return a.perf.efficiency > b.perf.efficiency
	end)

	for _, item in ipairs(sortedPlugins) do
		local perf = item.perf
		table.insert(report, string.format('%s:', item.name))
		table.insert(report, string.format('  Efficiency: %d%%', perf.efficiency))
		table.insert(report, string.format('  Update Time: %.2fms', perf.updateTime))
		table.insert(report, string.format('  Memory Usage: %.2fKB', perf.memoryUsage))
		table.insert(report, string.format('  Calls: %d, Errors: %d', perf.callCount, perf.errorCount))
		table.insert(report, '')
	end

	local reportText = table.concat(report, '\n')
	print(reportText)
end

---Get total plugin count
---@return number count Total number of plugins
function PluginManager:GetPluginCount()
	local count = 0
	for _ in pairs(self.pluginList) do
		count = count + 1
	end
	return count
end

-- Add slash command for plugin manager
SLASH_LDB_PLUGINS1 = '/ldb-plugins'
SlashCmdList['LDB_PLUGINS'] = function(msg)
	LibsDataBar.pluginManager:Show()
end

-- Initialize when ready
LibsDataBar.pluginManager:Initialize()

LibsDataBar:DebugLog('info', 'Advanced plugin manager loaded successfully', 'plugins')
