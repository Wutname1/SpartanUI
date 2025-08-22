---@diagnostic disable: duplicate-set-field
--[===[ File: Integration/API.lua
LibsDataBar External Integration API
Provides standardized hooks and callbacks for other addons to integrate with LibsDataBar
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

---@class LibsDataBarAPI
---@field registeredIntegrations table<string, Integration> Registered addon integrations
---@field callbacks table CallbackHandler callbacks
local API = {}

-- Ensure LibsDataBar has callback system initialized
if not LibsDataBar.callbacks then LibsDataBar.callbacks = LibStub('CallbackHandler-1.0'):New(LibsDataBar) end

-- Initialize API for LibsDataBar
LibsDataBar.API = LibsDataBar.API or setmetatable({
	registeredIntegrations = {},
	callbacks = LibsDataBar.callbacks,
}, { __index = API })

---@class Integration
---@field id string Integration identifier
---@field name string Display name
---@field version string Integration version
---@field addon string Addon name this integration is for
---@field onBarPositionChanged function Callback for bar position changes
---@field onBarCreated function Callback for bar creation
---@field onBarDestroyed function Callback for bar destruction
---@field onBarShown function Callback for bar show
---@field onBarHidden function Callback for bar hide
---@field onBarSizeChanged function Callback for bar size changes
---@field getOffsets function Function to get current bar offsets

---@class BarPositionData
---@field barId string Bar identifier
---@field position string Bar position (top, bottom, left, right, etc)
---@field anchor table Anchor coordinates {x, y}
---@field size table Bar dimensions {width, height}
---@field visible boolean Bar visibility
---@field timestamp number Event timestamp

---@class BarOffsets
---@field top number Total height of top-positioned bars
---@field bottom number Total height of bottom-positioned bars
---@field left number Total width of left-positioned bars
---@field right number Total width of right-positioned bars

---Register an addon integration with LibsDataBar
---@param integration Integration Integration configuration
---@return boolean success Whether registration was successful
function API:RegisterIntegration(integration)
	if not integration or not integration.id or not integration.addon then
		LibsDataBar:DebugLog('error', 'API: Integration registration failed - missing required fields')
		return false
	end

	if self.registeredIntegrations[integration.id] then LibsDataBar:DebugLog('warning', 'API: Integration ' .. integration.id .. ' already registered, updating') end

	-- Store the integration
	self.registeredIntegrations[integration.id] = integration

	-- Ensure callback system is available
	if not self.callbacks or not self.callbacks.RegisterCallback then
		LibsDataBar:DebugLog('error', 'Callback system not available for integration: ' .. integration.id)
		return false
	end

	-- Register callbacks if provided
	if integration.onBarPositionChanged then self.callbacks:RegisterCallback('LibsDataBar_BarPositionChanged', function(event, data)
		integration.onBarPositionChanged(data)
	end) end

	if integration.onBarCreated then self.callbacks:RegisterCallback('LibsDataBar_BarCreated', function(event, barId, bar)
		integration.onBarCreated(barId, bar)
	end) end

	if integration.onBarDestroyed then self.callbacks:RegisterCallback('LibsDataBar_BarDeleted', function(event, barId, bar)
		integration.onBarDestroyed(barId, bar)
	end) end

	if integration.onBarShown then self.callbacks:RegisterCallback('LibsDataBar_BarShown', function(event, barId)
		integration.onBarShown(barId)
	end) end

	if integration.onBarHidden then self.callbacks:RegisterCallback('LibsDataBar_BarHidden', function(event, barId)
		integration.onBarHidden(barId)
	end) end

	if integration.onBarSizeChanged then self.callbacks:RegisterCallback('LibsDataBar_BarSizeChanged', function(event, barId, newSize)
		integration.onBarSizeChanged(barId, newSize)
	end) end

	LibsDataBar:DebugLog('info', 'API: Registered integration for ' .. integration.addon .. ' (' .. integration.id .. ')')

	-- Fire integration registered event
	self.callbacks:Fire('LibsDataBar_IntegrationRegistered', integration.id, integration)

	return true
end

---Unregister an addon integration
---@param integrationId string Integration identifier
---@return boolean success Whether unregistration was successful
function API:UnregisterIntegration(integrationId)
	if not self.registeredIntegrations[integrationId] then
		LibsDataBar:DebugLog('warning', 'API: Cannot unregister unknown integration: ' .. integrationId)
		return false
	end

	local integration = self.registeredIntegrations[integrationId]
	self.registeredIntegrations[integrationId] = nil

	LibsDataBar:DebugLog('info', 'API: Unregistered integration: ' .. integrationId)

	-- Fire integration unregistered event
	self.callbacks:Fire('LibsDataBar_IntegrationUnregistered', integrationId, integration)

	return true
end

---Get list of registered integrations
---@return table<string, Integration> integrations All registered integrations
function API:GetRegisteredIntegrations()
	return self.registeredIntegrations
end

---Check if a specific addon has registered an integration
---@param addonName string Addon name to check
---@return boolean hasIntegration Whether the addon has an integration
---@return Integration? integration The integration if found
function API:HasIntegration(addonName)
	for _, integration in pairs(self.registeredIntegrations) do
		if integration.addon == addonName then return true, integration end
	end
	return false
end

---Get current bar offsets for layout calculations
---@return BarOffsets offsets Current bar offsets
function API:GetBarOffsets()
	local offsets = {
		top = 0,
		bottom = 0,
		left = 0,
		right = 0,
	}

	-- Calculate offsets from all visible bars
	for barId, bar in pairs(LibsDataBar.bars or {}) do
		if bar and bar.frame and bar.frame:IsVisible() then
			local position = bar.config and bar.config.position or 'bottom'
			local height = bar.frame:GetHeight() or 0
			local width = bar.frame:GetWidth() or 0

			if position == 'top' or position:find('^top') then
				offsets.top = offsets.top + height
			elseif position == 'bottom' or position:find('^bottom') then
				offsets.bottom = offsets.bottom + height
			elseif position == 'left' or position:find('^left') then
				offsets.left = offsets.left + width
			elseif position == 'right' or position:find('^right') then
				offsets.right = offsets.right + width
			end
		end
	end

	return offsets
end

---Get detailed information about a specific bar
---@param barId string Bar identifier
---@return BarPositionData? data Bar position data or nil if not found
function API:GetBarData(barId)
	local bar = LibsDataBar.bars and LibsDataBar.bars[barId]
	if not bar then return nil end

	return {
		barId = barId,
		position = bar.config and bar.config.position or 'bottom',
		anchor = bar.config and bar.config.anchor or { x = 0, y = 0 },
		size = {
			width = bar.frame and bar.frame:GetWidth() or 0,
			height = bar.frame and bar.frame:GetHeight() or 0,
		},
		visible = bar.frame and bar.frame:IsVisible() or false,
		timestamp = GetTime(),
	}
end

---Get list of all bar IDs
---@return table<string> barIds Array of bar identifiers
function API:GetBarList()
	local barIds = {}
	for barId in pairs(LibsDataBar.bars or {}) do
		table.insert(barIds, barId)
	end
	return barIds
end

---Manually trigger position change notification for integrations
---@param barId string Bar identifier
---@param changeType string Type of change ('move', 'resize', 'show', 'hide', 'create', 'destroy')
function API:NotifyPositionChange(barId, changeType)
	local data = self:GetBarData(barId)
	if not data then
		LibsDataBar:DebugLog('warning', 'API: Cannot notify position change for unknown bar: ' .. barId)
		return
	end

	data.changeType = changeType
	data.offsets = self:GetBarOffsets()

	-- Fire the callback
	self.callbacks:Fire('LibsDataBar_BarPositionChanged', data)

	LibsDataBar:DebugLog('debug', 'API: Notified position change for ' .. barId .. ' (' .. changeType .. ')')
end

---Initialize the API system
function API:Initialize()
	LibsDataBar:DebugLog('info', 'API: LibsDataBar Integration API initialized')

	-- Fire API ready event
	self.callbacks:Fire('LibsDataBar_APIReady')
end

-- Auto-initialize when this file loads
if LibsDataBar.callbacks then
	LibsDataBar.API:Initialize()
else
	-- Delay initialization if callbacks not ready
	C_Timer.After(1, function()
		if LibsDataBar.API then LibsDataBar.API:Initialize() end
	end)
end

---=== GLOBAL API FUNCTIONS FOR EXTERNAL ADDONS ===

-- Provide global functions that other addons can easily access
_G.LibsDataBar_RegisterIntegration = function(integration)
	if LibsDataBar and LibsDataBar.API then return LibsDataBar.API:RegisterIntegration(integration) end
	return false
end

_G.LibsDataBar_GetBarOffsets = function()
	if LibsDataBar and LibsDataBar.API then return LibsDataBar.API:GetBarOffsets() end
	return { top = 0, bottom = 0, left = 0, right = 0 }
end

_G.LibsDataBar_GetBarData = function(barId)
	if LibsDataBar and LibsDataBar.API then return LibsDataBar.API:GetBarData(barId) end
	return nil
end

_G.LibsDataBar_HasIntegration = function(addonName)
	if LibsDataBar and LibsDataBar.API then return LibsDataBar.API:HasIntegration(addonName) end
	return false
end

LibsDataBar:DebugLog('info', 'API: LibsDataBar Integration API loaded')
