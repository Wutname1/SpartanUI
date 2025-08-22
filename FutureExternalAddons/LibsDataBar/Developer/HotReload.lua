---@diagnostic disable: duplicate-set-field
--[===[ File: Developer/HotReload.lua
LibsDataBar Hot Reload System
Development workflow enhancement for rapid plugin testing
--]===]

-- Get the LibsDataBar addon
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

---@class HotReload
---@field enabled boolean Whether hot reload is enabled
---@field watchedFiles table<string, number> File paths and their last modified times
---@field reloadQueue table<string> Files queued for reload
---@field reloadTimer table|nil Timer for batched reloads
---@field developmentMode boolean Whether development mode is active
local HotReload = {}

-- Initialize HotReload for LibsDataBar
LibsDataBar.hotReload = LibsDataBar.hotReload or setmetatable({
	enabled = false,
	watchedFiles = {},
	reloadQueue = {},
	reloadTimer = nil,
	developmentMode = false,
}, { __index = HotReload })

---Initialize hot reload system
function HotReload:Initialize()
	-- Only enable in development mode
	self.developmentMode = LibsDataBar.config:GetConfig('global.developer.developmentMode') or false
	self.enabled = self.developmentMode and LibsDataBar.config:GetConfig('global.developer.hotReload') or false

	if self.enabled then
		self:StartWatching()
		LibsDataBar:DebugLog('info', 'Hot reload system initialized', 'wizard')
	else
		LibsDataBar:DebugLog('info', 'Hot reload system disabled (not in development mode)', 'wizard')
	end
end

---Start watching for file changes
function HotReload:StartWatching()
	-- Create a timer to periodically check for changes
	if not self.watchTimer then self.watchTimer = C_Timer.NewTicker(2, function()
		self:CheckForChanges()
	end) end
end

---Stop watching for file changes
function HotReload:StopWatching()
	if self.watchTimer then
		self.watchTimer:Cancel()
		self.watchTimer = nil
	end
end

---Enable/disable hot reload
---@param enabled boolean Whether to enable hot reload
function HotReload:SetEnabled(enabled)
	self.enabled = enabled
	LibsDataBar.config:SetConfig('global.developer.hotReload', enabled)

	if enabled and self.developmentMode then
		self:StartWatching()
		LibsDataBar:DebugLog('info', 'Hot reload enabled', 'wizard')
	else
		self:StopWatching()
		LibsDataBar:DebugLog('info', 'Hot reload disabled', 'wizard')
	end
end

---Add a file to watch list
---@param filePath string Path to file to watch
function HotReload:WatchFile(filePath)
	if not self.enabled then return end

	-- In WoW, we can't actually check file modification times
	-- But we can simulate this for development by tracking plugin registrations
	self.watchedFiles[filePath] = GetTime()
	LibsDataBar:DebugLog('debug', 'Watching file: ' .. filePath, 'wizard')
end

---Remove a file from watch list
---@param filePath string Path to file to stop watching
function HotReload:UnwatchFile(filePath)
	self.watchedFiles[filePath] = nil
	LibsDataBar:DebugLog('debug', 'Stopped watching file: ' .. filePath, 'wizard')
end

---Check for file changes (simulated)
function HotReload:CheckForChanges()
	if not self.enabled then return end

	-- In a real implementation, this would check file modification times
	-- For WoW development, we simulate this by detecting plugin re-registrations

	-- This is a placeholder for when we can detect actual file changes
	-- For now, developers will trigger reloads manually
end

---Queue a file for reload
---@param filePath string Path to file to reload
function HotReload:QueueReload(filePath)
	if not self.enabled then return end

	-- Add to reload queue
	for i, queued in ipairs(self.reloadQueue) do
		if queued == filePath then
			return -- Already queued
		end
	end

	table.insert(self.reloadQueue, filePath)
	LibsDataBar:DebugLog('debug', 'Queued for reload: ' .. filePath, 'wizard')

	-- Start batch reload timer
	if not self.reloadTimer then self.reloadTimer = C_Timer.NewTimer(0.5, function()
		self:ProcessReloadQueue()
		self.reloadTimer = nil
	end) end
end

---Process the reload queue
function HotReload:ProcessReloadQueue()
	if #self.reloadQueue == 0 then return end

	LibsDataBar:DebugLog('info', 'Processing reload queue: ' .. #self.reloadQueue .. ' files', 'wizard')

	for _, filePath in ipairs(self.reloadQueue) do
		self:ReloadFile(filePath)
	end

	-- Clear queue
	self.reloadQueue = {}

	-- Trigger post-reload cleanup
	self:PostReloadCleanup()
end

---Reload a specific file (simulated)
---@param filePath string Path to file to reload
function HotReload:ReloadFile(filePath)
	LibsDataBar:DebugLog('info', 'Reloading file: ' .. filePath, 'wizard')

	-- In WoW, we can't actually reload individual files
	-- Instead, we provide mechanisms to reload plugin components

	if filePath:find('Plugin') or filePath:find('.lua') then
		-- Try to reload plugin by name
		local pluginName = filePath:match('([^/\\]+)%.lua$')
		if pluginName then self:ReloadPlugin(pluginName) end
	end
end

---Reload a specific plugin
---@param pluginName string Name of plugin to reload
function HotReload:ReloadPlugin(pluginName)
	-- Find plugin by name or ID
	local plugin = nil
	for pluginId, p in pairs(LibsDataBar.plugins or {}) do
		if p.name == pluginName or pluginId == pluginName or pluginId:find(pluginName) then
			plugin = p
			break
		end
	end

	if not plugin then
		LibsDataBar:DebugLog('warning', 'Plugin not found for reload: ' .. pluginName, 'wizard')
		return
	end

	LibsDataBar:DebugLog('info', 'Reloading plugin: ' .. plugin.name, 'wizard')

	-- Disable plugin
	if plugin.OnDisable then pcall(plugin.OnDisable, plugin) end

	-- Remove from all bars
	for barId, bar in pairs(LibsDataBar.bars or {}) do
		if bar.plugins and bar.plugins[plugin.id] then bar:RemovePlugin(plugin.id) end
	end

	-- Re-initialize plugin
	if plugin.OnInitialize then pcall(plugin.OnInitialize, plugin) end

	-- Re-enable plugin
	if plugin.OnEnable then pcall(plugin.OnEnable, plugin) end

	-- Re-add to main bar
	local mainBar = LibsDataBar.bars['main']
	if mainBar then mainBar:AddPlugin(plugin) end

	LibsDataBar:DebugLog('info', 'Plugin reloaded successfully: ' .. plugin.name, 'wizard')
end

---Reload all plugins
function HotReload:ReloadAllPlugins()
	LibsDataBar:DebugLog('info', 'Reloading all plugins', 'wizard')

	for pluginId, plugin in pairs(LibsDataBar.plugins or {}) do
		if plugin and plugin.name then self:ReloadPlugin(plugin.name) end
	end

	LibsDataBar:DebugLog('info', 'All plugins reloaded', 'wizard')
end

---Reload theme system
function HotReload:ReloadThemes()
	LibsDataBar:DebugLog('info', 'Reloading theme system', 'wizard')

	if LibsDataBar.themes then
		-- Refresh current theme
		local currentTheme = LibsDataBar.themes.currentTheme
		if currentTheme then LibsDataBar.themes:SetCurrentTheme(currentTheme) end
	end

	LibsDataBar:DebugLog('info', 'Theme system reloaded', 'wizard')
end

---Reload configuration system
function HotReload:ReloadConfig()
	LibsDataBar:DebugLog('info', 'Reloading configuration system', 'wizard')

	if LibsDataBar.config then
		-- Trigger config refresh
		LibsDataBar.config:RefreshCache()
	end

	LibsDataBar:DebugLog('info', 'Configuration system reloaded', 'wizard')
end

---Post-reload cleanup
function HotReload:PostReloadCleanup()
	-- Force garbage collection
	collectgarbage('collect')

	-- Update all bars
	for barId, bar in pairs(LibsDataBar.bars or {}) do
		if bar.UpdateLayout then bar:UpdateLayout() end
		if bar.UpdateDisplay then bar:UpdateDisplay() end
	end

	-- Trigger validation if available
	if LibsDataBar.validator then
		for pluginId, plugin in pairs(LibsDataBar.plugins or {}) do
			if plugin then LibsDataBar.validator:ValidatePlugin(plugin) end
		end
	end

	LibsDataBar:DebugLog('info', 'Post-reload cleanup completed', 'wizard')
end

---Create a development testing environment
function HotReload:CreateTestEnvironment()
	LibsDataBar:DebugLog('info', 'Creating development test environment', 'wizard')

	-- Create test bar if it doesn't exist
	local testBar = LibsDataBar.bars['test']
	if not testBar then
		testBar = LibsDataBar:CreateDataBar('test', {
			position = 'top',
			size = { width = 400, height = 24 },
			appearance = {
				background = { show = true, color = { 0, 0, 1, 0.3 } },
			},
		})
	end

	-- Add all available plugins to test bar
	for pluginId, plugin in pairs(LibsDataBar.plugins or {}) do
		if plugin and not testBar.plugins[pluginId] then testBar:AddPlugin(plugin) end
	end

	print('LibsDataBar: Test environment created with test bar')
	LibsDataBar:DebugLog('info', 'Test environment ready', 'wizard')
end

---Destroy test environment
function HotReload:DestroyTestEnvironment()
	local testBar = LibsDataBar.bars['test']
	if testBar then
		LibsDataBar:DeleteBar('test')
		print('LibsDataBar: Test environment destroyed')
		LibsDataBar:DebugLog('info', 'Test environment destroyed', 'wizard')
	end
end

-- Add slash commands for hot reload
SLASH_LDB_RELOAD1 = '/ldb-reload'
SLASH_LDB_RELOAD2 = '/ldb-hr'
SlashCmdList['LDB_RELOAD'] = function(msg)
	local args = { strsplit(' ', msg) }
	local command = args[1] or ''

	if command == 'on' then
		LibsDataBar.hotReload:SetEnabled(true)
		print('LibsDataBar hot reload enabled')
	elseif command == 'off' then
		LibsDataBar.hotReload:SetEnabled(false)
		print('LibsDataBar hot reload disabled')
	elseif command == 'plugin' then
		local pluginName = args[2]
		if pluginName then
			LibsDataBar.hotReload:ReloadPlugin(pluginName)
		else
			print('Usage: /ldb-reload plugin <name>')
		end
	elseif command == 'plugins' then
		LibsDataBar.hotReload:ReloadAllPlugins()
		print('LibsDataBar: All plugins reloaded')
	elseif command == 'themes' then
		LibsDataBar.hotReload:ReloadThemes()
		print('LibsDataBar: Themes reloaded')
	elseif command == 'config' then
		LibsDataBar.hotReload:ReloadConfig()
		print('LibsDataBar: Configuration reloaded')
	elseif command == 'all' then
		LibsDataBar.hotReload:ReloadAllPlugins()
		LibsDataBar.hotReload:ReloadThemes()
		LibsDataBar.hotReload:ReloadConfig()
		print('LibsDataBar: Full system reload completed')
	elseif command == 'test' then
		LibsDataBar.hotReload:CreateTestEnvironment()
	elseif command == 'notest' then
		LibsDataBar.hotReload:DestroyTestEnvironment()
	else
		print('LibsDataBar Hot Reload Commands:')
		print('  /ldb-reload on/off - Enable/disable hot reload')
		print('  /ldb-reload plugin <name> - Reload specific plugin')
		print('  /ldb-reload plugins - Reload all plugins')
		print('  /ldb-reload themes - Reload theme system')
		print('  /ldb-reload config - Reload configuration')
		print('  /ldb-reload all - Full system reload')
		print('  /ldb-reload test - Create test environment')
		print('  /ldb-reload notest - Destroy test environment')
	end
end

-- Development mode toggle
SLASH_LDB_DEV1 = '/ldb-dev'
SlashCmdList['LDB_DEV'] = function(msg)
	local devMode = not LibsDataBar.hotReload.developmentMode
	LibsDataBar.hotReload.developmentMode = devMode
	LibsDataBar.config:SetConfig('global.developer.developmentMode', devMode)

	if devMode then
		LibsDataBar.hotReload:Initialize()
		LibsDataBar.hotReload:CreateTestEnvironment()
		print('LibsDataBar: Development mode ENABLED')
	else
		LibsDataBar.hotReload:SetEnabled(false)
		LibsDataBar.hotReload:DestroyTestEnvironment()
		print('LibsDataBar: Development mode DISABLED')
	end
end

-- Initialize when ready
LibsDataBar.hotReload:Initialize()

LibsDataBar:DebugLog('info', 'Hot reload system loaded successfully', 'wizard')
