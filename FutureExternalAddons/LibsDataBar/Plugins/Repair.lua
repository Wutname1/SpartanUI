---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Repair.lua
LibsDataBar Repair Plugin
Displays equipment durability and repair costs
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Plugin Definition
---@class RepairPlugin : Plugin
local RepairPlugin = {
	-- Required metadata
	id = 'LibsDataBar_Repair',
	name = 'Repair',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Equipment',
	description = 'Displays equipment durability and repair information',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_durabilityData = {},
	_averageDurability = 100,
	_lowestDurability = 100,
	_repairCost = 0,
	_brokenItems = {},
}

-- Plugin Configuration Defaults
local repairDefaults = {
	displayFormat = 'average', -- 'average', 'lowest', 'cost', 'broken'
	showPercent = true,
	colorByDurability = true,
	warnThreshold = 25, -- Warn when durability drops below this
	alertThreshold = 10, -- Alert when durability drops below this
	checkAllBags = false, -- Check items in bags too
	autoRepairNotify = true,
	showDetailedTooltip = true,
}

-- Equipment slot mappings
local EQUIPMENT_SLOTS = {
	HEADSLOT = 1,
	NECKSLOT = 2,
	SHOULDERSLOT = 3,
	SHIRTSLOT = 4,
	CHESTSLOT = 5,
	WAISTSLOT = 6,
	LEGSSLOT = 7,
	FEETSLOT = 8,
	WRISTSLOT = 9,
	HANDSSLOT = 10,
	FINGER0SLOT = 11,
	FINGER1SLOT = 12,
	TRINKET0SLOT = 13,
	TRINKET1SLOT = 14,
	BACKSLOT = 15,
	MAINHANDSLOT = 16,
	SECONDARYHANDSLOT = 17,
	RANGEDSLOT = 18,
	TABARDSLOT = 19,
}

---Required: Get the display text for this plugin
---@return string text Display text
function RepairPlugin:GetText()
	local displayFormat = self:GetConfig('displayFormat')
	local showPercent = self:GetConfig('showPercent')
	local colorByDurability = self:GetConfig('colorByDurability')

	self:UpdateDurabilityData()

	local text = ''
	local durability = self._averageDurability

	if displayFormat == 'average' then
		durability = self._averageDurability
		if showPercent then
			text = string.format('Dur: %.0f%%', durability)
		else
			text = string.format('Dur: %.0f', durability)
		end
	elseif displayFormat == 'lowest' then
		durability = self._lowestDurability
		if showPercent then
			text = string.format('Min: %.0f%%', durability)
		else
			text = string.format('Min: %.0f', durability)
		end
	elseif displayFormat == 'cost' then
		if self._repairCost > 0 then
			text = string.format('Repair: %s', self:FormatMoney(self._repairCost))
		else
			text = 'No Repairs Needed'
		end
		-- Don't apply durability coloring for cost display
		colorByDurability = false
	elseif displayFormat == 'broken' then
		local brokenCount = #self._brokenItems
		if brokenCount > 0 then
			text = string.format('%d Broken Item%s', brokenCount, brokenCount == 1 and '' or 's')
			durability = 0 -- Force red color for broken items
		else
			text = 'All Items OK'
			durability = 100
		end
	else
		-- Default to average
		durability = self._averageDurability
		text = string.format('Dur: %.0f%%', durability)
	end

	-- Apply color coding based on durability level
	if colorByDurability then text = self:ApplyDurabilityColor(text, durability) end

	return text
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function RepairPlugin:GetIcon()
	local brokenCount = #self._brokenItems
	local durability = math.min(self._averageDurability, self._lowestDurability)

	if brokenCount > 0 then
		return 'Interface\\Icons\\Trade_BlackSmithing' -- Broken items - blacksmith hammer
	elseif durability < self:GetConfig('alertThreshold') then
		return 'Interface\\Icons\\INV_Hammer_20' -- Critical durability - red hammer
	elseif durability < self:GetConfig('warnThreshold') then
		return 'Interface\\Icons\\INV_Hammer_15' -- Low durability - yellow hammer
	else
		return 'Interface\\Icons\\Trade_Engineering' -- Good durability - wrench/tools
	end
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function RepairPlugin:GetTooltip()
	self:UpdateDurabilityData()

	local tooltip = 'Equipment Durability:\\n\\n'

	-- Summary information
	tooltip = tooltip .. string.format('Average Durability: %.1f%%\\n', self._averageDurability)
	tooltip = tooltip .. string.format('Lowest Durability: %.1f%%\\n', self._lowestDurability)

	if self._repairCost > 0 then
		tooltip = tooltip .. string.format('Repair Cost: %s\\n', self:FormatMoney(self._repairCost))
	else
		tooltip = tooltip .. 'No repairs needed\\n'
	end

	-- Broken items
	local brokenCount = #self._brokenItems
	if brokenCount > 0 then
		tooltip = tooltip .. string.format('\\n|cFFFF0000Broken Items: %d|r\\n', brokenCount)
		for _, itemName in ipairs(self._brokenItems) do
			tooltip = tooltip .. '|cFFFF0000• ' .. itemName .. '|r\\n'
		end
	end

	-- Detailed item listing
	if self:GetConfig('showDetailedTooltip') and next(self._durabilityData) then
		tooltip = tooltip .. '\\nDetailed Durability:\\n'

		-- Sort items by durability (lowest first)
		local sortedItems = {}
		for slot, data in pairs(self._durabilityData) do
			table.insert(sortedItems, { slot = slot, data = data })
		end
		table.sort(sortedItems, function(a, b)
			return a.data.percent < b.data.percent
		end)

		for _, item in ipairs(sortedItems) do
			local data = item.data
			local color = self:GetDurabilityColorCode(data.percent)
			local slotName = self:GetSlotDisplayName(item.slot)
			tooltip = tooltip .. string.format('%s%s: %.0f%% (%d/%d)|r\\n', color, slotName, data.percent, data.current, data.max)
		end
	end

	tooltip = tooltip .. '\\nControls:\\n'
	tooltip = tooltip .. 'Left-click: Change display format\\n'
	tooltip = tooltip .. 'Right-click: Configuration options\\n'
	tooltip = tooltip .. 'Middle-click: Force durability scan'

	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function RepairPlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Cycle display formats
		self:CycleDisplayFormat()
	elseif button == 'RightButton' then
		-- Show configuration menu (placeholder)
		LibsDataBar:DebugLog('info', 'Repair configuration menu (coming in Phase 2)')
	elseif button == 'MiddleButton' then
		-- Force durability scan
		self:UpdateDurabilityData()
		LibsDataBar:DebugLog('info', 'Repair durability scan completed')
	end
end

---Update durability data by scanning equipment
function RepairPlugin:UpdateDurabilityData()
	self._durabilityData = {}
	self._brokenItems = {}
	local totalDurability = 0
	local itemCount = 0
	local lowestDurability = 100
	local totalRepairCost = 0

	-- Scan equipped items
	for slotName, slotID in pairs(EQUIPMENT_SLOTS) do
		local current, maximum = GetInventoryItemDurability(slotID)
		if current and maximum and maximum > 0 then
			local percent = (current / maximum) * 100
			local itemLink = GetInventoryItemLink('player', slotID)
			local itemName = itemLink and C_Item.GetItemInfo(itemLink) or ('Slot ' .. slotID)

			self._durabilityData[slotID] = {
				current = current,
				max = maximum,
				percent = percent,
				name = itemName,
				slot = slotName,
			}

			totalDurability = totalDurability + percent
			itemCount = itemCount + 1

			if percent < lowestDurability then lowestDurability = percent end

			-- Check for broken items
			if current == 0 then table.insert(self._brokenItems, itemName) end

			-- Estimate repair cost (this is a rough estimate since we can't get exact costs from API)
			if current < maximum then
				local itemLevel = self:GetItemLevel(slotID)
				local repairCost = self:EstimateRepairCost(slotID, current, maximum, itemLevel)
				totalRepairCost = totalRepairCost + repairCost
			end
		end
	end

	-- Calculate averages
	self._averageDurability = itemCount > 0 and (totalDurability / itemCount) or 100
	self._lowestDurability = itemCount > 0 and lowestDurability or 100
	self._repairCost = totalRepairCost

	-- Check for warnings/alerts
	self:CheckDurabilityWarnings()
end

---Get item level for repair cost estimation
---@param slotID number Equipment slot ID
---@return number itemLevel Item level
function RepairPlugin:GetItemLevel(slotID)
	local itemLink = GetInventoryItemLink('player', slotID)
	if itemLink then
		local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
		return itemLevel or 1
	end
	return 1
end

---Estimate repair cost for an item
---@param slotID number Equipment slot ID
---@param current number Current durability
---@param maximum number Maximum durability
---@param itemLevel number Item level
---@return number cost Estimated repair cost in copper
function RepairPlugin:EstimateRepairCost(slotID, current, maximum, itemLevel)
	if current >= maximum then return 0 end

	-- This is a rough estimation formula - actual repair costs are complex
	local damagePercent = 1 - (current / maximum)
	local baseCost = itemLevel * 100 -- Base cost per item level

	-- Different slots have different repair cost multipliers
	local slotMultiplier = 1
	if slotID == EQUIPMENT_SLOTS.CHESTSLOT or slotID == EQUIPMENT_SLOTS.LEGSSLOT then
		slotMultiplier = 1.5 -- Chest and legs cost more
	elseif slotID == EQUIPMENT_SLOTS.MAINHANDSLOT or slotID == EQUIPMENT_SLOTS.SECONDARYHANDSLOT then
		slotMultiplier = 1.3 -- Weapons cost more
	elseif slotID == EQUIPMENT_SLOTS.HEADSLOT then
		slotMultiplier = 1.2 -- Head costs more
	end

	return math.floor(baseCost * damagePercent * slotMultiplier)
end

---Check for durability warnings and alerts
function RepairPlugin:CheckDurabilityWarnings()
	local warnThreshold = self:GetConfig('warnThreshold')
	local alertThreshold = self:GetConfig('alertThreshold')
	local autoNotify = self:GetConfig('autoRepairNotify')

	if not autoNotify then return end

	local brokenCount = #self._brokenItems

	-- Alert for broken items
	if brokenCount > 0 then
		LibsDataBar:DebugLog('warning', string.format('You have %d broken item%s!', brokenCount, brokenCount == 1 and '' or 's'))
	-- Alert for very low durability
	elseif self._lowestDurability <= alertThreshold then
		LibsDataBar:DebugLog('warning', string.format('Equipment durability critical: %.0f%%', self._lowestDurability))
	-- Warn for low durability
	elseif self._lowestDurability <= warnThreshold then
		LibsDataBar:DebugLog('info', string.format('Equipment durability low: %.0f%%', self._lowestDurability))
	end
end

---Apply color coding based on durability level
---@param text string Text to color
---@param durability number Durability percentage (0-100)
---@return string coloredText Colored text
function RepairPlugin:ApplyDurabilityColor(text, durability)
	return self:GetDurabilityColorCode(durability) .. text .. '|r'
end

---Get color code for durability level
---@param durability number Durability percentage (0-100)
---@return string colorCode WoW color code
function RepairPlugin:GetDurabilityColorCode(durability)
	local alertThreshold = self:GetConfig('alertThreshold')
	local warnThreshold = self:GetConfig('warnThreshold')

	if durability == 0 then
		return '|cFFFF0000' -- Red for broken (0%)
	elseif durability <= alertThreshold then
		return '|cFFFF4500' -- Orange-red for critical
	elseif durability <= warnThreshold then
		return '|cFFFFFF00' -- Yellow for low
	elseif durability < 75 then
		return '|cFFFFFFFF' -- White for moderate
	else
		return '|cFF00FF00' -- Green for good
	end
end

---Get display name for equipment slot
---@param slotID number Equipment slot ID
---@return string name Display name for the slot
function RepairPlugin:GetSlotDisplayName(slotID)
	local slotNames = {
		[1] = 'Head',
		[2] = 'Neck',
		[3] = 'Shoulder',
		[4] = 'Shirt',
		[5] = 'Chest',
		[6] = 'Waist',
		[7] = 'Legs',
		[8] = 'Feet',
		[9] = 'Wrist',
		[10] = 'Hands',
		[11] = 'Ring 1',
		[12] = 'Ring 2',
		[13] = 'Trinket 1',
		[14] = 'Trinket 2',
		[15] = 'Back',
		[16] = 'Main Hand',
		[17] = 'Off Hand',
		[18] = 'Ranged',
		[19] = 'Tabard',
	}
	return slotNames[slotID] or ('Slot ' .. slotID)
end

---Format money amount for display
---@param copper number Amount in copper
---@return string formatted Formatted money string
function RepairPlugin:FormatMoney(copper)
	if copper <= 0 then return '0c' end

	local gold = math.floor(copper / 10000)
	local silver = math.floor((copper % 10000) / 100)
	local copperAmount = copper % 100

	local parts = {}
	if gold > 0 then table.insert(parts, gold .. 'g') end
	if silver > 0 then table.insert(parts, silver .. 's') end
	if copperAmount > 0 or #parts == 0 then table.insert(parts, copperAmount .. 'c') end

	return table.concat(parts, ' ')
end

---Cycle through different display formats
function RepairPlugin:CycleDisplayFormat()
	local formats = { 'average', 'lowest', 'cost', 'broken' }
	local current = self:GetConfig('displayFormat')
	local currentIndex = 1

	-- Find current format index
	for i, format in ipairs(formats) do
		if format == current then
			currentIndex = i
			break
		end
	end

	-- Move to next format (wrap around)
	local nextIndex = currentIndex < #formats and currentIndex + 1 or 1
	local nextFormat = formats[nextIndex]

	self:SetConfig('displayFormat', nextFormat)
	LibsDataBar:DebugLog('info', 'Repair display format changed to: ' .. nextFormat)
end

---Get configuration options
---@return table options AceConfig options table
function RepairPlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			displayFormat = {
				type = 'select',
				name = 'Display Format',
				desc = 'Choose how to display durability information',
				order = 10,
				values = {
					average = 'Average Durability',
					lowest = 'Lowest Durability',
					cost = 'Repair Cost',
					broken = 'Broken Items',
				},
				get = function()
					return self:GetConfig('displayFormat')
				end,
				set = function(_, value)
					self:SetConfig('displayFormat', value)
				end,
			},
			colorByDurability = {
				type = 'toggle',
				name = 'Color by Durability',
				desc = 'Use colors to indicate durability level',
				order = 20,
				get = function()
					return self:GetConfig('colorByDurability')
				end,
				set = function(_, value)
					self:SetConfig('colorByDurability', value)
				end,
			},
			warnThreshold = {
				type = 'range',
				name = 'Warning Threshold',
				desc = 'Show warning when durability drops below this percentage',
				order = 30,
				min = 1,
				max = 50,
				step = 1,
				get = function()
					return self:GetConfig('warnThreshold')
				end,
				set = function(_, value)
					self:SetConfig('warnThreshold', value)
				end,
			},
			alertThreshold = {
				type = 'range',
				name = 'Alert Threshold',
				desc = 'Show alert when durability drops below this percentage',
				order = 40,
				min = 1,
				max = 25,
				step = 1,
				get = function()
					return self:GetConfig('alertThreshold')
				end,
				set = function(_, value)
					self:SetConfig('alertThreshold', value)
				end,
			},
			autoRepairNotify = {
				type = 'toggle',
				name = 'Auto Repair Notifications',
				desc = 'Automatically notify when repairs are needed',
				order = 50,
				get = function()
					return self:GetConfig('autoRepairNotify')
				end,
				set = function(_, value)
					self:SetConfig('autoRepairNotify', value)
				end,
			},
			showDetailedTooltip = {
				type = 'toggle',
				name = 'Show Detailed Tooltip',
				desc = 'Include per-item durability in tooltip',
				order = 60,
				get = function()
					return self:GetConfig('showDetailedTooltip')
				end,
				set = function(_, value)
					self:SetConfig('showDetailedTooltip', value)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function RepairPlugin:GetDefaultConfig()
	return repairDefaults
end

---Lifecycle: Plugin initialization
function RepairPlugin:OnInitialize()
	self:UpdateDurabilityData()
	LibsDataBar:DebugLog('info', 'Repair plugin initialized')
end

---Lifecycle: Plugin enabled
function RepairPlugin:OnEnable()
	-- Register for durability-related events
	self:RegisterEvent('UPDATE_INVENTORY_DURABILITY', 'OnDurabilityUpdate')
	self:RegisterEvent('MERCHANT_SHOW', 'OnMerchantShow')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnDurabilityUpdate')
	LibsDataBar:DebugLog('info', 'Repair plugin enabled')
end

---Lifecycle: Plugin disabled
function RepairPlugin:OnDisable()
	self:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Repair plugin disabled')
end

---Event handler for durability updates
function RepairPlugin:OnDurabilityUpdate()
	self:UpdateDurabilityData()
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Event handler for merchant interaction
function RepairPlugin:OnMerchantShow()
	-- Update durability when visiting a merchant (potential repair opportunity)
	self:UpdateDurabilityData()
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Helper: Register for an event
---@param event string Event name
---@param method string Method name to call
function RepairPlugin:RegisterEvent(event, method)
	LibsDataBar.events:RegisterEvent(event, function(...)
		if self[method] then self[method](self, ...) end
	end, { owner = self.id })
end

---Helper: Unregister all events
function RepairPlugin:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Repair plugin events unregistered')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function RepairPlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or repairDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function RepairPlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize and register the plugin
RepairPlugin:OnInitialize()

-- Register with LibsDataBar
if LibsDataBar:RegisterPlugin(RepairPlugin) then
	LibsDataBar:DebugLog('info', 'Repair plugin registered successfully')
else
	LibsDataBar:DebugLog('error', 'Failed to register Repair plugin')
end

-- Return plugin for external access
return RepairPlugin
