---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Location.lua
LibsDataBar Location Plugin
Displays zone, subzone, and player coordinates
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Plugin Definition
---@class LocationPlugin : Plugin
local LocationPlugin = {
	-- Required metadata
	id = 'LibsDataBar_Location',
	name = 'Location',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Information',
	description = 'Displays current zone and coordinates',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_updateInterval = 0.5,
	_lastUpdate = 0,
	_currentZone = '',
	_currentSubZone = '',
	_currentX = 0,
	_currentY = 0,
	_pvpType = '',
	_mapID = nil,
}

-- Plugin Configuration Defaults
local locationDefaults = {
	showZone = true,
	showSubZone = true,
	showCoordinates = true,
	showPvPStatus = true,
	coordinatesPrecision = 1,
	shortZoneNames = false,
	hideInInstance = false,
}

---Required: Get the display text for this plugin
---@return string text Display text
function LocationPlugin:GetText()
	local parts = {}
	local showZone = self:GetConfig('showZone')
	local showSubZone = self:GetConfig('showSubZone')
	local showCoords = self:GetConfig('showCoordinates')
	local showPvP = self:GetConfig('showPvPStatus')
	local hideInInstance = self:GetConfig('hideInInstance')
	local precision = self:GetConfig('coordinatesPrecision')

	-- Check if we're in an instance and should hide
	if hideInInstance and IsInInstance() then return 'Instance' end

	-- Zone information
	if showZone and self._currentZone ~= '' then
		local zoneName = self._currentZone
		if self:GetConfig('shortZoneNames') then
			-- Abbreviate common long zone names
			zoneName = zoneName:gsub('The ', ''):gsub('Stormwind City', 'SW'):gsub('Orgrimmar', 'Org')
			if #zoneName > 15 then zoneName = string.sub(zoneName, 1, 12) .. '...' end
		end
		tinsert(parts, zoneName)
	end

	-- Subzone information
	if showSubZone and self._currentSubZone ~= '' and self._currentSubZone ~= self._currentZone then
		local subZone = self._currentSubZone
		if self:GetConfig('shortZoneNames') and #subZone > 10 then subZone = string.sub(subZone, 1, 8) .. '...' end
		tinsert(parts, '(' .. subZone .. ')')
	end

	-- Coordinates
	if showCoords and self._currentX > 0 and self._currentY > 0 then
		local coordText = string.format('%.' .. precision .. 'f, %.' .. precision .. 'f', self._currentX, self._currentY)
		tinsert(parts, '[' .. coordText .. ']')
	end

	-- PvP Status
	if showPvP and self._pvpType ~= '' then
		local pvpColor = ''
		if self._pvpType == 'sanctuary' then
			pvpColor = '|cFF00FF00' -- Green for sanctuary
		elseif self._pvpType == 'arena' then
			pvpColor = '|cFFFF0000' -- Red for arena
		elseif self._pvpType == 'friendly' then
			pvpColor = '|cFF0080FF' -- Blue for friendly
		elseif self._pvpType == 'hostile' then
			pvpColor = '|cFFFF8000' -- Orange for hostile
		elseif self._pvpType == 'contested' then
			pvpColor = '|cFFFFFF00' -- Yellow for contested
		end

		if pvpColor ~= '' then tinsert(parts, pvpColor .. '●|r') end
	end

	return table.concat(parts, ' ')
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function LocationPlugin:GetIcon()
	return 'Interface\\Icons\\INV_Misc_Map_01'
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function LocationPlugin:GetTooltip()
	local tooltip = 'Location Information:\n\n'

	-- Zone details
	tooltip = tooltip .. 'Zone: ' .. (self._currentZone ~= '' and self._currentZone or 'Unknown') .. '\n'
	if self._currentSubZone ~= '' and self._currentSubZone ~= self._currentZone then tooltip = tooltip .. 'Subzone: ' .. self._currentSubZone .. '\n' end

	-- Coordinates
	if self._currentX > 0 and self._currentY > 0 then
		tooltip = tooltip .. string.format('Coordinates: %.2f, %.2f\n', self._currentX, self._currentY)
	else
		tooltip = tooltip .. 'Coordinates: Not available\n'
	end

	-- Map ID (for debugging)
	if self._mapID then tooltip = tooltip .. 'Map ID: ' .. self._mapID .. '\n' end

	-- PvP Status
	if self._pvpType ~= '' then
		local pvpName = self._pvpType
		if self._pvpType == 'sanctuary' then
			pvpName = 'Sanctuary (Safe zone)'
		elseif self._pvpType == 'arena' then
			pvpName = 'Arena (PvP zone)'
		elseif self._pvpType == 'friendly' then
			pvpName = 'Friendly territory'
		elseif self._pvpType == 'hostile' then
			pvpName = 'Hostile territory'
		elseif self._pvpType == 'contested' then
			pvpName = 'Contested territory'
		end
		tooltip = tooltip .. 'PvP Status: ' .. pvpName .. '\n'
	end

	-- Instance status
	local isInstance, instanceType = IsInInstance()
	if isInstance then tooltip = tooltip .. 'Instance Type: ' .. (instanceType or 'unknown') .. '\n' end

	tooltip = tooltip .. '\nLeft-click: Toggle coordinate display'
	tooltip = tooltip .. '\nRight-click: Configuration options'
	tooltip = tooltip .. '\nMiddle-click: Toggle PvP status display'

	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function LocationPlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Open the map
		if WorldMapFrame then
			if WorldMapFrame:IsShown() then
				HideUIPanel(WorldMapFrame)
			else
				ShowUIPanel(WorldMapFrame)
			end
		elseif ToggleWorldMap then
			-- Fallback for older versions
			ToggleWorldMap()
		end
		LibsDataBar:DebugLog('info', 'Location plugin opened map')
	elseif button == 'RightButton' then
		-- Show configuration menu (placeholder)
		LibsDataBar:DebugLog('info', 'Location configuration menu (coming in Phase 2)')
	elseif button == 'MiddleButton' then
		-- Toggle PvP status display
		local showPvP = not self:GetConfig('showPvPStatus')
		self:SetConfig('showPvPStatus', showPvP)
		LibsDataBar:DebugLog('info', 'Location PvP status display ' .. (showPvP and 'enabled' or 'disabled'))
	end
end

---Optional: Update callback
---@param elapsed number Time elapsed since last update
function LocationPlugin:OnUpdate(elapsed)
	self._lastUpdate = self._lastUpdate + elapsed
	if self._lastUpdate >= self._updateInterval then
		self:UpdateLocationData()
		self._lastUpdate = 0

		-- Update LDB object if available
		if self._ldbObject and self._ldbObject.UpdateLDB then self._ldbObject:UpdateLDB() end

		-- Fire update event (for legacy compatibility)
		if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
	end
end

---Update location data
function LocationPlugin:UpdateLocationData()
	-- Get zone information
	local newZone = GetRealZoneText() or ''
	local newSubZone = GetSubZoneText() or ''
	local newPvPType = C_PvP.GetZonePVPInfo() or ''

	-- Get coordinates
	local newX, newY = 0, 0
	local mapID = C_Map.GetBestMapForUnit('player')
	if mapID then
		local position = C_Map.GetPlayerMapPosition(mapID, 'player')
		if position then
			local x, y = position:GetXY()
			newX = x * 100
			newY = y * 100
		end
	end

	-- Check if anything changed
	local changed = false
	if newZone ~= self._currentZone or newSubZone ~= self._currentSubZone or newPvPType ~= self._pvpType or mapID ~= self._mapID then changed = true end

	if math.abs(newX - self._currentX) > 0.1 or math.abs(newY - self._currentY) > 0.1 then changed = true end

	-- Update stored values
	self._currentZone = newZone
	self._currentSubZone = newSubZone
	self._currentX = newX
	self._currentY = newY
	self._pvpType = newPvPType
	self._mapID = mapID

	return changed
end

---Get configuration options
---@return table options AceConfig options table
function LocationPlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			showZone = {
				type = 'toggle',
				name = 'Show Zone',
				desc = 'Display the current zone name',
				order = 10,
				get = function()
					return self:GetConfig('showZone')
				end,
				set = function(_, value)
					self:SetConfig('showZone', value)
				end,
			},
			showSubZone = {
				type = 'toggle',
				name = 'Show Subzone',
				desc = 'Display the current subzone name',
				order = 20,
				get = function()
					return self:GetConfig('showSubZone')
				end,
				set = function(_, value)
					self:SetConfig('showSubZone', value)
				end,
			},
			showCoordinates = {
				type = 'toggle',
				name = 'Show Coordinates',
				desc = 'Display player coordinates',
				order = 30,
				get = function()
					return self:GetConfig('showCoordinates')
				end,
				set = function(_, value)
					self:SetConfig('showCoordinates', value)
				end,
			},
			showPvPStatus = {
				type = 'toggle',
				name = 'Show PvP Status',
				desc = 'Display PvP zone status indicator',
				order = 40,
				get = function()
					return self:GetConfig('showPvPStatus')
				end,
				set = function(_, value)
					self:SetConfig('showPvPStatus', value)
				end,
			},
			coordinatesPrecision = {
				type = 'range',
				name = 'Coordinates Precision',
				desc = 'Number of decimal places for coordinates',
				order = 50,
				min = 0,
				max = 2,
				step = 1,
				get = function()
					return self:GetConfig('coordinatesPrecision')
				end,
				set = function(_, value)
					self:SetConfig('coordinatesPrecision', value)
				end,
			},
			shortZoneNames = {
				type = 'toggle',
				name = 'Abbreviate Zone Names',
				desc = 'Use shorter zone names to save space',
				order = 60,
				get = function()
					return self:GetConfig('shortZoneNames')
				end,
				set = function(_, value)
					self:SetConfig('shortZoneNames', value)
				end,
			},
			hideInInstance = {
				type = 'toggle',
				name = 'Hide in Instances',
				desc = 'Show minimal text when in dungeons/raids',
				order = 70,
				get = function()
					return self:GetConfig('hideInInstance')
				end,
				set = function(_, value)
					self:SetConfig('hideInInstance', value)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function LocationPlugin:GetDefaultConfig()
	return locationDefaults
end

---Lifecycle: Plugin initialization
function LocationPlugin:OnInitialize()
	self:UpdateLocationData()
	LibsDataBar:DebugLog('info', 'Location plugin initialized')
end

---Lifecycle: Plugin enabled
function LocationPlugin:OnEnable()
	-- Register for zone change events
	self:RegisterEvent('ZONE_CHANGED', 'OnZoneChanged')
	self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'OnZoneChanged')
	self:RegisterEvent('ZONE_CHANGED_INDOORS', 'OnZoneChanged')
	LibsDataBar:DebugLog('info', 'Location plugin enabled')
end

---Lifecycle: Plugin disabled
function LocationPlugin:OnDisable()
	self:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Location plugin disabled')
end

---Event handler for zone changes
function LocationPlugin:OnZoneChanged()
	self:UpdateLocationData()

	-- Update LDB object if available
	if self._ldbObject and self._ldbObject.UpdateLDB then self._ldbObject:UpdateLDB() end

	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Helper: Register for an event
---@param event string Event name
---@param method string Method name to call
function LocationPlugin:RegisterEvent(event, method)
	LibsDataBar.events:RegisterEvent(event, function(...)
		if self[method] then self[method](self, ...) end
	end, { owner = self.id })
end

---Helper: Unregister all events
function LocationPlugin:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Location plugin events unregistered')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function LocationPlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or locationDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function LocationPlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize the plugin
LocationPlugin:OnInitialize()

-- Register as LibDataBroker object for standardized plugin system
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
	local locationLDBObject = LDB:NewDataObject('LibsDataBar_Location', {
		type = 'data source',
		text = LocationPlugin:GetText(),
		icon = LocationPlugin:GetIcon(),
		label = LocationPlugin.name,

		-- Forward methods to LocationPlugin with database access preserved
		OnClick = function(self, button)
			LocationPlugin:OnClick(button)
		end,

		OnTooltipShow = function(tooltip)
			tooltip:SetText(LocationPlugin:GetTooltip())
		end,

		-- Update method to refresh LDB object
		UpdateLDB = function(self)
			self.text = LocationPlugin:GetText()
			self.icon = LocationPlugin:GetIcon()
		end,
	})

	-- Store reference for updates
	LocationPlugin._ldbObject = locationLDBObject

	LibsDataBar:DebugLog('info', 'Location plugin registered as LibDataBroker object')
else
	LibsDataBar:DebugLog('error', 'LibDataBroker not available for Location plugin')
end

-- Return plugin for external access
return LocationPlugin
