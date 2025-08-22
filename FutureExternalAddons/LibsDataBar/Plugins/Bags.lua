---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Bags.lua
LibsDataBar Bags Plugin
Displays bag space and inventory information
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

-- Plugin Definition
---@class BagsPlugin : Plugin
local BagsPlugin = {
	-- Required metadata
	id = 'LibsDataBar_Bags',
	name = 'Bags',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Information',
	description = 'Displays bag space and inventory information',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_usedSlots = 0,
	_totalSlots = 0,
	_freeSlots = 0,
	_bagData = {},
}

-- Plugin Configuration Defaults
local bagsDefaults = {
	showUsed = true,
	showTotal = true,
	showFree = false,
	showPercent = false,
	colorByFull = true,
	includeBankBags = false,
	showBagDetails = true,
	showProfessionBags = true,
}

---Required: Get the display text for this plugin
---@return string text Display text
function BagsPlugin:GetText()
	local parts = {}
	local showUsed = self:GetConfig('showUsed')
	local showTotal = self:GetConfig('showTotal')
	local showFree = self:GetConfig('showFree')
	local showPercent = self:GetConfig('showPercent')
	local colorByFull = self:GetConfig('colorByFull')

	self:UpdateBagData()

	local used = self._usedSlots
	local total = self._totalSlots
	local free = self._freeSlots
	local percent = total > 0 and (used / total * 100) or 0

	local text = ''

	-- Build display text
	if showFree then
		text = tostring(free)
	elseif showUsed and showTotal then
		text = string.format('%d/%d', used, total)
	elseif showUsed then
		text = tostring(used)
	elseif showTotal then
		text = tostring(total)
	else
		text = string.format('%d/%d', used, total) -- fallback
	end

	if showPercent then text = text .. string.format(' (%.0f%%)', percent) end

	-- Apply color coding based on fullness
	if colorByFull and total > 0 then
		local fullnessRatio = used / total
		if fullnessRatio >= 0.9 then
			text = '|cFFFF0000' .. text .. '|r' -- Red when nearly full
		elseif fullnessRatio >= 0.75 then
			text = '|cFFFF8000' .. text .. '|r' -- Orange when getting full
		elseif fullnessRatio >= 0.5 then
			text = '|cFFFFFF00' .. text .. '|r' -- Yellow when half full
		else
			text = '|cFF00FF00' .. text .. '|r' -- Green when plenty of space
		end
	end

	return text
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function BagsPlugin:GetIcon()
	return 'Interface\\Icons\\INV_Misc_Bag_08'
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function BagsPlugin:GetTooltip()
	self:UpdateBagData()

	local tooltip = 'Bag Information:\n\n'

	-- Overall stats
	tooltip = tooltip .. string.format('Used: %d slots\n', self._usedSlots)
	tooltip = tooltip .. string.format('Free: %d slots\n', self._freeSlots)
	tooltip = tooltip .. string.format('Total: %d slots\n', self._totalSlots)

	if self._totalSlots > 0 then
		local percent = self._usedSlots / self._totalSlots * 100
		tooltip = tooltip .. string.format('Usage: %.1f%%\n', percent)
	end

	-- Individual bag details
	if self:GetConfig('showBagDetails') and #self._bagData > 0 then
		tooltip = tooltip .. '\nBag Details:\n'
		for i, bagInfo in ipairs(self._bagData) do
			local bagName = bagInfo.name or ('Bag ' .. bagInfo.id)
			if bagInfo.isProfession then bagName = bagName .. ' (Prof)' end
			tooltip = tooltip .. string.format('%s: %d/%d\n', bagName, bagInfo.used, bagInfo.total)
		end
	end

	-- Quality breakdown (if available)
	local qualityCounts = self:GetItemQualityCounts()
	if qualityCounts and next(qualityCounts) then
		tooltip = tooltip .. '\nItem Quality Breakdown:\n'
		for quality, count in pairs(qualityCounts) do
			local qualityName = _G['ITEM_QUALITY' .. quality .. '_DESC'] or ('Quality ' .. quality)
			local r, g, b = C_Item.GetItemQualityColor(quality)
			tooltip = tooltip .. string.format('|cFF%02x%02x%02x%s: %d|r\n', r * 255, g * 255, b * 255, qualityName, count)
		end
	end

	tooltip = tooltip .. '\nLeft-click: Toggle free space display'
	tooltip = tooltip .. '\nRight-click: Configuration options'
	tooltip = tooltip .. '\nMiddle-click: Toggle percentage display'

	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function BagsPlugin:OnClick(button)
	if button == 'LeftButton' then
		-- Open/close bags
		if IsShiftKeyDown() then
			-- Shift+click opens all bags
			ToggleAllBags()
		else
			-- Regular click toggles backpack
			ToggleBag(0)
		end
		LibsDataBar:DebugLog('info', 'Bags plugin toggled bags')
	elseif button == 'RightButton' then
		-- Show configuration menu (placeholder)
		LibsDataBar:DebugLog('info', 'Bags configuration menu (coming in Phase 2)')
	elseif button == 'MiddleButton' then
		-- Toggle percentage display
		local showPercent = not self:GetConfig('showPercent')
		self:SetConfig('showPercent', showPercent)
		LibsDataBar:DebugLog('info', 'Bags percentage display ' .. (showPercent and 'enabled' or 'disabled'))
	end
end

---Update bag data
function BagsPlugin:UpdateBagData()
	local totalSlots = 0
	local usedSlots = 0
	local bagData = {}

	-- Standard bags (0-4: backpack + 4 bags)
	for bagID = 0, 4 do
		local bagSlots = C_Container.GetContainerNumSlots(bagID)
		if bagSlots > 0 then
			local freeSlots = C_Container.GetContainerNumFreeSlots(bagID)
			local used = bagSlots - freeSlots

			totalSlots = totalSlots + bagSlots
			usedSlots = usedSlots + used

			-- Get bag info
			local bagName = ''
			local isProfession = false
			if bagID > 0 then
				local inventoryID = C_Container.ContainerIDToInventoryID(bagID)
				if inventoryID then
					local itemLink = GetInventoryItemLink('player', inventoryID)
					if itemLink then
						bagName = C_Item.GetItemInfo(itemLink) or ''
						isProfession = self:IsProfessionBag(bagID)
					end
				end
			else
				bagName = 'Backpack'
			end

			table.insert(bagData, {
				id = bagID,
				name = bagName,
				used = used,
				total = bagSlots,
				free = freeSlots,
				isProfession = isProfession,
			})
		end
	end

	-- Bank bags (if enabled)
	if self:GetConfig('includeBankBags') then
		for bagID = 5, 11 do -- Bank slots
			local bagSlots = C_Container.GetContainerNumSlots(bagID)
			if bagSlots > 0 then
				local freeSlots = C_Container.GetContainerNumFreeSlots(bagID)
				local used = bagSlots - freeSlots

				totalSlots = totalSlots + bagSlots
				usedSlots = usedSlots + used

				table.insert(bagData, {
					id = bagID,
					name = 'Bank ' .. (bagID - 4),
					used = used,
					total = bagSlots,
					free = freeSlots,
					isProfession = false,
				})
			end
		end
	end

	self._usedSlots = usedSlots
	self._totalSlots = totalSlots
	self._freeSlots = totalSlots - usedSlots
	self._bagData = bagData
end

---Check if a bag is a profession bag
---@param bagID number Bag ID to check
---@return boolean isProfession True if this is a profession bag
function BagsPlugin:IsProfessionBag(bagID)
	local inventoryID = C_Container.ContainerIDToInventoryID(bagID)
	if not inventoryID then return false end

	local itemLink = GetInventoryItemLink('player', inventoryID)
	if not itemLink then return false end

	local itemID = GetItemInfoFromHyperlink(itemLink)
	if not itemID then return false end

	-- Check item class and subclass for profession bags
	local itemType, itemSubType, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemID)

	-- Class 1 (Container) with subclass indicating profession
	if classID == 1 then
		-- Profession bag subclasses:
		-- 1 = Soul bag, 2 = Herb bag, 3 = Enchanting bag, 4 = Engineering bag,
		-- 5 = Keyring, 6 = Gem bag, 7 = Mining bag, 8 = Leatherworking bag,
		-- 9 = Inscription bag, 10 = Tackle box, 11 = Cooking bag
		return subclassID > 0 and subclassID ~= 1 -- Exclude soul bags which are special
	end

	return false
end

---Get item quality counts in bags
---@return table? qualityCounts Table of quality -> count mappings
function BagsPlugin:GetItemQualityCounts()
	local qualityCounts = {}

	-- Scan all bag slots
	for bagID = 0, 4 do
		local bagSlots = C_Container.GetContainerNumSlots(bagID)
		if bagSlots > 0 then
			for slot = 1, bagSlots do
				local itemInfo = C_Container.GetContainerItemInfo(bagID, slot)
				if itemInfo and itemInfo.hyperlink then
					local quality = itemInfo.quality or 0
					qualityCounts[quality] = (qualityCounts[quality] or 0) + (itemInfo.stackCount or 1)
				end
			end
		end
	end

	return next(qualityCounts) and qualityCounts or nil
end

---Get configuration options
---@return table options AceConfig options table
function BagsPlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			showUsed = {
				type = 'toggle',
				name = 'Show Used Slots',
				desc = 'Display the number of used bag slots',
				order = 10,
				get = function()
					return self:GetConfig('showUsed')
				end,
				set = function(_, value)
					self:SetConfig('showUsed', value)
				end,
			},
			showTotal = {
				type = 'toggle',
				name = 'Show Total Slots',
				desc = 'Display the total number of bag slots',
				order = 20,
				get = function()
					return self:GetConfig('showTotal')
				end,
				set = function(_, value)
					self:SetConfig('showTotal', value)
				end,
			},
			showFree = {
				type = 'toggle',
				name = 'Show Free Slots',
				desc = 'Display the number of free bag slots',
				order = 30,
				get = function()
					return self:GetConfig('showFree')
				end,
				set = function(_, value)
					self:SetConfig('showFree', value)
				end,
			},
			showPercent = {
				type = 'toggle',
				name = 'Show Percentage',
				desc = 'Display usage as a percentage',
				order = 40,
				get = function()
					return self:GetConfig('showPercent')
				end,
				set = function(_, value)
					self:SetConfig('showPercent', value)
				end,
			},
			colorByFull = {
				type = 'toggle',
				name = 'Color by Fullness',
				desc = 'Use colors to indicate how full bags are',
				order = 50,
				get = function()
					return self:GetConfig('colorByFull')
				end,
				set = function(_, value)
					self:SetConfig('colorByFull', value)
				end,
			},
			includeBankBags = {
				type = 'toggle',
				name = 'Include Bank Bags',
				desc = 'Include bank bag slots in the count',
				order = 60,
				get = function()
					return self:GetConfig('includeBankBags')
				end,
				set = function(_, value)
					self:SetConfig('includeBankBags', value)
				end,
			},
			showBagDetails = {
				type = 'toggle',
				name = 'Show Bag Details in Tooltip',
				desc = 'Show individual bag information in tooltip',
				order = 70,
				get = function()
					return self:GetConfig('showBagDetails')
				end,
				set = function(_, value)
					self:SetConfig('showBagDetails', value)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function BagsPlugin:GetDefaultConfig()
	return bagsDefaults
end

---Lifecycle: Plugin initialization
function BagsPlugin:OnInitialize()
	self:UpdateBagData()
	LibsDataBar:DebugLog('info', 'Bags plugin initialized')
end

---Lifecycle: Plugin enabled
function BagsPlugin:OnEnable()
	-- Register for bag events
	self:RegisterEvent('BAG_UPDATE', 'OnBagUpdate')
	self:RegisterEvent('BAG_UPDATE_DELAYED', 'OnBagUpdate')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', 'OnBankUpdate')
	LibsDataBar:DebugLog('info', 'Bags plugin enabled')
end

---Lifecycle: Plugin disabled
function BagsPlugin:OnDisable()
	self:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Bags plugin disabled')
end

---Event handler for bag updates
function BagsPlugin:OnBagUpdate()
	self:UpdateBagData()
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
end

---Event handler for bank updates
function BagsPlugin:OnBankUpdate()
	if self:GetConfig('includeBankBags') then
		self:UpdateBagData()
		if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
	end
end

---Helper: Register for an event
---@param event string Event name
---@param method string Method name to call
function BagsPlugin:RegisterEvent(event, method)
	LibsDataBar.events:RegisterEvent(event, function(...)
		if self[method] then self[method](self, ...) end
	end, { owner = self.id })
end

---Helper: Unregister all events
function BagsPlugin:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Bags plugin events unregistered')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function BagsPlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or bagsDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function BagsPlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize the plugin
BagsPlugin:OnInitialize()

-- Register as LibDataBroker object for standardized plugin system
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
	local bagsLDBObject = LDB:NewDataObject('LibsDataBar_Bags', {
		type = 'data source',
		text = BagsPlugin:GetText(),
		icon = BagsPlugin:GetIcon(),
		label = BagsPlugin.name,

		-- Forward methods to BagsPlugin with database access preserved
		OnClick = function(self, button)
			BagsPlugin:OnClick(button)
		end,

		OnTooltipShow = function(tooltip)
			local tooltipText = BagsPlugin:GetTooltip()
			-- Handle both \n and \\n newline formats
			tooltipText = tooltipText:gsub('\\n', '\n')
			local lines = {strsplit('\n', tooltipText)}
			for i, line in ipairs(lines) do
				if i == 1 then
					tooltip:SetText(line)
				else
					tooltip:AddLine(line, 1, 1, 1, true)
				end
			end
		end,

		-- Update method to refresh LDB object
		UpdateLDB = function(self)
			self.text = BagsPlugin:GetText()
			self.icon = BagsPlugin:GetIcon()
		end,
	})

	-- Store reference for updates
	BagsPlugin._ldbObject = bagsLDBObject

	LibsDataBar:DebugLog('info', 'Bags plugin registered as LibDataBroker object')
else
	LibsDataBar:DebugLog('error', 'LibDataBroker not available for Bags plugin')
end

-- Return plugin for external access
return BagsPlugin
