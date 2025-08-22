---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/LDBAdapter.lua
LibDataBroker 1.1 Compatibility Layer
Provides full LDB plugin integration and automatic discovery
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Check for LibDataBroker
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if not LDB then
	LibsDataBar:DebugLog('warning', 'LibDataBroker-1.1 not found - LDB adapter disabled')
	return
end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring
local tinsert = table.insert

---@class LDBAdapter  
---@field registeredObjects table<string, LDBPluginWrapper> Registered LDB objects
---@field autoDiscovery boolean Whether to auto-discover LDB objects
local LDBAdapter = {}
LDBAdapter.__index = LDBAdapter

-- Initialize LDB adapter for LibsDataBar
LibsDataBar.ldb = LibsDataBar.ldb or setmetatable({
	registeredObjects = {},
	autoDiscovery = true,
}, LDBAdapter)

---@class LDBPluginWrapper
---@field ldbObject table Original LDB data object
---@field plugin Plugin LibsDataBar plugin interface
---@field id string Plugin identifier
---@field name string Plugin display name
local LDBPluginWrapper = {}
LDBPluginWrapper.__index = LDBPluginWrapper

---Initialize the LDB adapter
function LDBAdapter:Initialize()
	if not LDB then return end

	-- Register callbacks with LibDataBroker
	LDB.RegisterCallback(self, 'LibDataBroker_DataObjectCreated', 'OnLDBObjectCreated')
	LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged', 'OnLDBObjectChanged')

	-- Auto-discover existing LDB objects if enabled
	if self.autoDiscovery then self:DiscoverExistingObjects() end

	LibsDataBar:DebugLog('info', 'LDBAdapter initialized - auto-discovery: ' .. tostring(self.autoDiscovery))
end

---Discover and register existing LDB data objects
function LDBAdapter:DiscoverExistingObjects()
	if not LDB or not LDB.GetDataObjectByName then return end

	local discoveredCount = 0

	-- Get all data objects from LDB
	for name, dataObject in LDB:DataObjectIterator() do
		if self:IsValidLDBObject(dataObject) then
			self:RegisterLDBObject(name, dataObject)
			discoveredCount = discoveredCount + 1
		end
	end

	LibsDataBar:DebugLog('info', 'Auto-discovered ' .. discoveredCount .. ' LDB objects')
end

---Check if an LDB object is valid for registration
---@param dataObject table LDB data object
---@return boolean valid Whether the object is valid
function LDBAdapter:IsValidLDBObject(dataObject)
	if not dataObject or type(dataObject) ~= 'table' then return false end

	-- Must have either text or label
	if not dataObject.text and not dataObject.label then return false end

	-- Must be a data source
	if dataObject.type ~= 'data source' then return false end

	return true
end

---Register an LDB data object as a LibsDataBar plugin
---@param name string LDB object name
---@param dataObject table LDB data object
---@return boolean success Whether registration was successful
function LDBAdapter:RegisterLDBObject(name, dataObject)
	if not self:IsValidLDBObject(dataObject) then
		LibsDataBar:DebugLog('warning', 'Invalid LDB object for registration: ' .. tostring(name))
		return false
	end

	if self.registeredObjects[name] then
		LibsDataBar:DebugLog('warning', 'LDB object already registered: ' .. name)
		return false
	end

	-- Create wrapper
	local wrapper = self:CreateLDBWrapper(name, dataObject)
	if not wrapper then
		LibsDataBar:DebugLog('error', 'Failed to create LDB wrapper for: ' .. name)
		return false
	end

	-- Store the wrapper for bar discovery
	self.registeredObjects[name] = wrapper
	LibsDataBar:DebugLog('info', 'Registered LDB object: ' .. name)
	return true
end

---Create a LibsDataBar plugin wrapper for an LDB object
---@param name string LDB object name
---@param dataObject table LDB data object
---@return LDBPluginWrapper? wrapper Created wrapper or nil
function LDBAdapter:CreateLDBWrapper(name, dataObject)
	local wrapper = setmetatable({}, LDBPluginWrapper)

	wrapper.ldbObject = dataObject
	wrapper.id = 'LDB_' .. name
	wrapper.name = dataObject.label or name

	-- Create LibsDataBar plugin interface
	wrapper.plugin = {
		-- Required metadata
		id = wrapper.id,
		name = wrapper.name,
		version = '1.0.0',
		author = 'LDB Adapter',
		category = 'LibDataBroker',
		description = 'LibDataBroker plugin: ' .. name,
		type = 'ldb', -- Mark as LDB plugin

		-- LDB reference
		ldbObject = dataObject,
		ldbName = name,

		-- LibsDataBar interface methods
		GetText = function(self)
			return wrapper:GetText()
		end,

		GetIcon = function(self)
			return wrapper:GetIcon()
		end,

		UpdateTooltip = function(self, tooltip)
			return wrapper:UpdateTooltip(tooltip)
		end,

		OnClick = function(self, button)
			return wrapper:OnClick(button)
		end,

		OnUpdate = function(self, elapsed)
			return wrapper:OnUpdate(elapsed)
		end,

		-- Optional methods
		GetConfigOptions = function(self)
			return wrapper:GetConfigOptions()
		end,

		GetDefaultConfig = function(self)
			return {
				enabled = true,
				showIcon = dataObject.icon ~= nil,
				showText = true,
				updateInterval = 1.0,
			}
		end,

		-- Lifecycle methods
		OnInitialize = function(self)
			wrapper:OnInitialize()
		end,

		OnEnable = function(self)
			wrapper:OnEnable()
		end,

		OnDisable = function(self)
			wrapper:OnDisable()
		end,
	}

	return wrapper
end

---Get text from LDB object
---@return string? text Current text value
function LDBPluginWrapper:GetText()
	if not self.ldbObject then return nil end

	-- Use text or label
	local text = self.ldbObject.text or self.ldbObject.label

	-- Handle suffix
	if self.ldbObject.suffix then text = (text or '') .. ' ' .. self.ldbObject.suffix end

	return text
end

---Get icon from LDB object
---@return string? icon Current icon path
function LDBPluginWrapper:GetIcon()
	if not self.ldbObject then return nil end
	return self.ldbObject.icon
end

---Update tooltip using LDB object's tooltip handler
---@param tooltip GameTooltip Tooltip frame to update
function LDBPluginWrapper:UpdateTooltip(tooltip)
	if not self.ldbObject or not tooltip then return end

	-- Use LDB's OnTooltipShow if available
	if self.ldbObject.OnTooltipShow and type(self.ldbObject.OnTooltipShow) == 'function' then
		local success, result = pcall(self.ldbObject.OnTooltipShow, tooltip)
		if not success then
			tooltip:AddLine('Error loading LDB tooltip')
			LibsDataBar:DebugLog('error', 'LDB OnTooltipShow error for ' .. self.name .. ': ' .. tostring(result))
		end
	else
		-- Fallback tooltip
		tooltip:AddLine(self.name)
		if self.ldbObject.tooltiptext then tooltip:AddLine(self.ldbObject.tooltiptext, 1, 1, 1, true) end
	end
end

---Handle click events
---@param button string Mouse button
function LDBPluginWrapper:OnClick(button)
	if not self.ldbObject then return end

	-- Use LDB's OnClick if available
	if self.ldbObject.OnClick and type(self.ldbObject.OnClick) == 'function' then
		local success, result = pcall(self.ldbObject.OnClick, nil, button)
		if not success then LibsDataBar:DebugLog('error', 'LDB OnClick error for ' .. self.name .. ': ' .. tostring(result)) end
	end
end

---Handle update events (typically not used by LDB objects)
---@param elapsed number Time since last update
function LDBPluginWrapper:OnUpdate(elapsed)
	-- Most LDB objects don't use OnUpdate, they update via events
	-- This is here for compatibility
end

---Get configuration options for this LDB plugin
---@return table? options AceConfig options table
function LDBPluginWrapper:GetConfigOptions()
	-- Basic LDB plugin options
	return {
		type = 'group',
		name = self.name,
		desc = 'LibDataBroker plugin: ' .. self.ldbName,
		args = {
			header = {
				type = 'header',
				name = self.name,
				order = 1,
			},

			description = {
				type = 'description',
				name = 'This is a LibDataBroker plugin automatically integrated with LibsDataBar.',
				order = 2,
			},

			enabled = {
				type = 'toggle',
				name = 'Enable',
				desc = 'Enable/disable this LDB plugin',
				get = function()
					return LibsDataBar.config:GetPluginConfig(self.plugin.id, 'enabled')
				end,
				set = function(_, value)
					LibsDataBar.config:SetPluginConfig(self.plugin.id, 'enabled', value)
					if value then
						LibsDataBar:EnablePlugin(self.plugin.id)
					else
						LibsDataBar:DisablePlugin(self.plugin.id)
					end
				end,
				order = 3,
			},

			showIcon = {
				type = 'toggle',
				name = 'Show Icon',
				desc = 'Show the plugin icon',
				disabled = function()
					return not self.ldbObject.icon
				end,
				get = function()
					return LibsDataBar.config:GetPluginConfig(self.plugin.id, 'showIcon')
				end,
				set = function(_, value)
					LibsDataBar.config:SetPluginConfig(self.plugin.id, 'showIcon', value)
				end,
				order = 4,
			},

			showText = {
				type = 'toggle',
				name = 'Show Text',
				desc = 'Show the plugin text',
				get = function()
					return LibsDataBar.config:GetPluginConfig(self.plugin.id, 'showText')
				end,
				set = function(_, value)
					LibsDataBar.config:SetPluginConfig(self.plugin.id, 'showText', value)
				end,
				order = 5,
			},
		},
	}
end

---Initialize the LDB wrapper
function LDBPluginWrapper:OnInitialize()
	LibsDataBar:DebugLog('debug', 'LDB wrapper initialized: ' .. self.name)
end

---Enable the LDB wrapper
function LDBPluginWrapper:OnEnable()
	LibsDataBar:DebugLog('debug', 'LDB wrapper enabled: ' .. self.name)
end

---Disable the LDB wrapper
function LDBPluginWrapper:OnDisable()
	LibsDataBar:DebugLog('debug', 'LDB wrapper disabled: ' .. self.name)
end

---Handle LDB object creation
---@param name string Object name
---@param dataObject table LDB data object
function LDBAdapter:OnLDBObjectCreated(name, dataObject)
	if self.autoDiscovery then self:RegisterLDBObject(name, dataObject) end
end

---Handle LDB object attribute changes
---@param name string Object name
---@param key string Changed attribute
---@param value any New value
---@param dataObject table LDB data object
function LDBAdapter:OnLDBObjectChanged(name, key, value, dataObject)
	local wrapper = self.registeredObjects[name]
	if not wrapper then return end

	-- Handle common attribute changes
	if key == 'text' or key == 'label' or key == 'suffix' then
		-- Text changed - trigger button update
		if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginTextChanged', wrapper.plugin.id, wrapper:GetText()) end
	elseif key == 'icon' then
		-- Icon changed - trigger button update
		if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginIconChanged', wrapper.plugin.id, value) end
	end

	LibsDataBar:DebugLog('debug', 'LDB attribute changed: ' .. name .. '.' .. key .. ' = ' .. tostring(value))
end

---Unregister an LDB object
---@param name string LDB object name
---@return boolean success Whether unregistration was successful
function LDBAdapter:UnregisterLDBObject(name)
	local wrapper = self.registeredObjects[name]
	if not wrapper then return false end

	-- Remove from registry
	self.registeredObjects[name] = nil

	LibsDataBar:DebugLog('info', 'Unregistered LDB object: ' .. name)
	return true
end

---Get registered LDB object wrapper
---@param name string LDB object name
---@return LDBPluginWrapper? wrapper Wrapper or nil
function LDBAdapter:GetLDBWrapper(name)
	return self.registeredObjects[name]
end

---Get list of registered LDB object names
---@return table names Array of LDB object names
function LDBAdapter:GetRegisteredNames()
	local names = {}
	for name, _ in pairs(self.registeredObjects) do
		tinsert(names, name)
	end
	return names
end

---Enable or disable auto-discovery
---@param enabled boolean Whether to enable auto-discovery
function LDBAdapter:SetAutoDiscovery(enabled)
	self.autoDiscovery = enabled
	LibsDataBar:DebugLog('info', 'LDB auto-discovery ' .. (enabled and 'enabled' or 'disabled'))
end

---Manual registration of LDB object by name
---@param name string LDB object name
---@return boolean success Whether registration was successful
function LDBAdapter:RegisterByName(name)
	if not LDB then return false end

	local dataObject = LDB:GetDataObjectByName(name)
	if not dataObject then
		LibsDataBar:DebugLog('warning', 'LDB object not found: ' .. name)
		return false
	end

	return self:RegisterLDBObject(name, dataObject)
end

---Clean up LDB adapter
function LDBAdapter:Cleanup()
	if not LDB then return end

	-- Unregister all LDB objects
	for name, _ in pairs(self.registeredObjects) do
		self:UnregisterLDBObject(name)
	end

	-- Unregister LDB callbacks
	LDB.UnregisterCallback(self, 'LibDataBroker_DataObjectCreated')
	LDB.UnregisterCallback(self, 'LibDataBroker_AttributeChanged')

	LibsDataBar:DebugLog('info', 'LDBAdapter cleaned up')
end

-- Initialize the LDB adapter when this file loads
if LibsDataBar.ldb then LibsDataBar.ldb:Initialize() end

-- Make adapter available for external access
LibsDataBar.LDBAdapter = LDBAdapter

LibsDataBar:DebugLog('info', 'LDBAdapter loaded successfully')
