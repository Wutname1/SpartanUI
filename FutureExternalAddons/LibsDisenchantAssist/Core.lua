---@class LibsDisenchantAssist : AceAddon, AceEvent-3.0, AceTimer-3.0
local LibsDisenchantAssist = LibStub('AceAddon-3.0'):NewAddon('LibsDisenchantAssist', 'AceEvent-3.0', 'AceTimer-3.0')
_G.LibsDisenchantAssist = LibsDisenchantAssist

---@class LibsDisenchantAssistDB
---@field global LibsDisenchantAssistGlobalDB
---@field char LibsDisenchantAssistCharDB

---@class LibsDisenchantAssistGlobalDB

---@class LibsDisenchantAssistCharDB
---@field windowPosition table
---@field minimap table
---@field itemFirstSeen table<number, number>

---@class LibsDisenchantAssistOptions
---@field enabled boolean
---@field excludeToday boolean
---@field excludeHigherIlvl boolean
---@field excludeGearSets boolean
---@field excludeWarbound boolean
---@field excludeBOE boolean
---@field minIlvl number
---@field maxIlvl number
---@field confirmDisenchant boolean

local AceDB = LibStub('AceDB-3.0')

-- Database defaults following SpartanUI pattern
local defaults = {
	profile = {
		-- User preferences that should be shared across characters
		enabled = true,
		excludeToday = true,
		excludeHigherIlvl = true,
		excludeGearSets = true,
		excludeWarbound = false,
		excludeBOE = false,
		minIlvl = 1,
		maxIlvl = 999,
		confirmDisenchant = true,
	},
	global = {
		-- Truly global data shared across all characters and profiles (none currently)
	},
	char = {
		-- Character-specific data that should not be shared
		itemFirstSeen = {}, -- Each character's item discovery history
		blacklist = {}, -- Character-specific blacklisted items
		windowPosition = { point = 'CENTER', x = 0, y = 0 },
		minimap = { hide = false },
	},
}

---Addon initialization
function LibsDisenchantAssist:OnInitialize()
	-- Initialize database
	self.db = AceDB:New('LibsDisenchantAssistDB', defaults, true)

	-- Setup profile callbacks
	self.db.RegisterCallback(self, 'OnProfileChanged', 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileCopied', 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileReset', 'OnProfileChanged')

	-- Attach database to addon object following SpartanUI pattern
	self.DB = self.db.profile ---@type LibsDisenchantAssistOptions (main settings)
	self.DBG = self.db.global ---@type LibsDisenchantAssistGlobalDB
	self.DBC = self.db.char ---@type LibsDisenchantAssistCharDB

	-- Register chat commands
	self:RegisterChatCommands()

	-- Register as LibDataBroker object for addon display systems
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if LDB then
		local disenchantLDB = LDB:NewDataObject('LibsDisenchantAssist', {
			type = 'launcher',
			text = 'Disenchant Assist',
			icon = 'Interface\\Icons\\INV_Enchant_Disenchant',
			label = "Lib's - Disenchant Assist",

			OnClick = function(self, button)
				if button == 'LeftButton' then
					LibsDisenchantAssist.UI:Toggle()
				elseif button == 'RightButton' then
					LibsDisenchantAssist.UI:Show()
					if LibsDisenchantAssist.UI.isOptionsVisible == false then LibsDisenchantAssist.UI:ToggleOptions() end
				end
			end,

			OnTooltipShow = function(tooltip)
				if not tooltip then return end

				tooltip:AddLine("|cff00ff00Lib's - Disenchant Assist|r")
				tooltip:AddLine(' ')

				-- Show current stats
				local items = LibsDisenchantAssist.FilterSystem:GetDisenchantableItems()
				local count = #items

				if count > 0 then
					tooltip:AddLine(string.format('|cffFFFFFF%d items|r ready to disenchant', count))
				else
					tooltip:AddLine('|cff888888No items to disenchant|r')
				end

				tooltip:AddLine(' ')
				tooltip:AddLine('|cffFFFFFFLeft Click:|r |cff00ffffToggle main window|r')
				tooltip:AddLine('|cffFFFFFFRight Click:|r |cff00ffffShow options panel|r')
			end,

			-- Update method for refreshing display
			UpdateLDB = function(self)
				local items = LibsDisenchantAssist.FilterSystem:GetDisenchantableItems()
				local count = #items

				if count > 0 then
					self.text = string.format('DE: %d', count)
				else
					self.text = 'DE: 0'
				end
			end,
		})

		-- Store reference for updates
		LibsDisenchantAssist._ldbObject = disenchantLDB

		-- Setup LibDBIcon for minimap button if available
		local LibDBIcon = LibStub:GetLibrary('LibDBIcon-1.0', true)
		if LibDBIcon then LibDBIcon:Register('LibsDisenchantAssist', disenchantLDB, LibsDisenchantAssist.DBC.minimap) end

		LibsDisenchantAssist:Print('Registered with LibDataBroker system')
	else
		LibsDisenchantAssist:Print('LibDataBroker not available - no minimap button')
	end
end

---Addon enabled
function LibsDisenchantAssist:OnEnable()
	self:Print('Enabled v1.0.0 - Use /libsde or /disenchantassist for commands')
end

---Handle profile changes
function LibsDisenchantAssist:OnProfileChanged()
	-- Update database references
	self.DB = self.db.profile
	self.DBG = self.db.global
	self.DBC = self.db.char

	-- Notify subsystems of profile change
	if self.UI then self.UI:OnProfileChanged() end
	if self.ItemTracker then self.ItemTracker:OnProfileChanged() end
	if self.FilterSystem then self.FilterSystem:OnProfileChanged() end
	if self.DisenchantLogic then self.DisenchantLogic:OnProfileChanged() end
end

---Register chat commands
function LibsDisenchantAssist:RegisterChatCommands()
	-- Register slash commands
	SLASH_LIBSDISENCHANTASSIST1 = '/libsde'
	SLASH_LIBSDISENCHANTASSIST2 = '/disenchantassist'

	SlashCmdList['LIBSDISENCHANTASSIST'] = function(msg)
		self:HandleChatCommand(msg)
	end
end

---Handle chat command
---@param msg string
function LibsDisenchantAssist:HandleChatCommand(msg)
	local command = string.lower(string.trim(msg or ''))

	if command == '' or command == 'show' then
		if self.UI then self.UI:Show() end
	elseif command == 'hide' then
		if self.UI then self.UI:Hide() end
	elseif command == 'toggle' then
		if self.UI then self.UI:Toggle() end
	elseif command == 'options' then
		if self.UI then
			self.UI:Show()
			if not self.UI.isOptionsVisible then self.UI:ToggleOptions() end
		end
	elseif command == 'scan' then
		if self.ItemTracker then
			self.ItemTracker:ScanBagsForNewItems()
			self:Print('Scanned bags for new items.')
		end
	elseif command == 'stop' then
		if self.DisenchantLogic then self.DisenchantLogic:StopBatchDisenchant() end
	elseif command == 'debug' then
		self:DebugOutput()
	elseif command == 'help' then
		self:Print('Commands:')
		self:Print('/libsde or /libsde show - Show the main window')
		self:Print('/libsde hide - Hide the main window')
		self:Print('/libsde toggle - Toggle the main window')
		self:Print('/libsde options - Show options panel')
		self:Print('/libsde scan - Scan bags for new items')
		self:Print('/libsde stop - Stop batch disenchanting')
		self:Print('/libsde debug - Output detailed detection/filter debug info')
		self:Print('/libsde help - Show this help')
	else
		self:Print('Unknown command: ' .. command .. ". Type '/libsde help' for commands.")
	end
end

---Print addon message with prefix
---@param message string
function LibsDisenchantAssist:Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Lib's Disenchant Assist:|r " .. message)
end

---Debug print function - uses SpartanUI debug window if available, otherwise chat
---@param message string
function LibsDisenchantAssist:DebugPrint(message)
	if SUI and SUI.Log then
		SUI.Log(message, 'Disenchant Assist')
	else
		self:Print('[DEBUG] ' .. message)
	end
end

---Debug output function - outputs all detection and decision logic
function LibsDisenchantAssist:DebugOutput()
	self:DebugPrint('=== DEBUG OUTPUT START ===')

	-- Show current settings
	self:DebugPrint('Current Settings:')
	self:DebugPrint('- Enabled: ' .. tostring(self.DB.enabled))
	self:DebugPrint('- Exclude Today: ' .. tostring(self.DB.excludeToday))
	self:DebugPrint('- Exclude Higher iLvl: ' .. tostring(self.DB.excludeHigherIlvl))
	self:DebugPrint('- Exclude Gear Sets: ' .. tostring(self.DB.excludeGearSets))
	self:DebugPrint('- Exclude Warbound: ' .. tostring(self.DB.excludeWarbound))
	self:DebugPrint('- Exclude BOE: ' .. tostring(self.DB.excludeBOE))
	self:DebugPrint('- Min iLvl: ' .. self.DB.minIlvl)
	self:DebugPrint('- Max iLvl: ' .. self.DB.maxIlvl)

	-- Scan all bags and show detailed item analysis
	self:DebugPrint('Scanning bags for items...')
	local totalItems = 0
	local disenchantableItems = 0
	local filteredOutItems = 0

	for bag = 0, 4 do
		local numSlots = C_Container.GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
				if itemInfo and itemInfo.itemID then
					totalItems = totalItems + 1
					local item = self.FilterSystem:CreateItemInfo(bag, slot, itemInfo)
					if item then
						local canDisenchant = self.FilterSystem:CanDisenchantItem(item)
						local passesFilters = self.FilterSystem:PassesAllFilters(item, self.DB)

						self:DebugPrint('Item: ' .. (item.itemLink or 'Unknown') .. ' (Bag ' .. bag .. ', Slot ' .. slot .. ')')
						self:DebugPrint('  - Item ID: ' .. item.itemID)
						self:DebugPrint('  - Class ID: ' .. (item.classID or 'nil'))
						self:DebugPrint('  - Quality: ' .. (item.quality or 'nil'))
						self:DebugPrint('  - iLvl: ' .. (item.itemLevel or 'nil'))
						self:DebugPrint('  - Can Disenchant: ' .. tostring(canDisenchant))

						if canDisenchant then
							disenchantableItems = disenchantableItems + 1

							-- Test each filter individually
							local reasons = {}
							if not self.DB.enabled then table.insert(reasons, 'Addon disabled') end

							if self.DB.excludeToday and item.seenToday then table.insert(reasons, 'Seen today') end

							if item.itemLevel < self.DB.minIlvl then table.insert(reasons, 'Below min iLvl') end

							if item.itemLevel > self.DB.maxIlvl then table.insert(reasons, 'Above max iLvl') end

							if self.DB.excludeHigherIlvl and self.FilterSystem:IsHigherThanEquipped(item) then table.insert(reasons, 'Higher than equipped') end

							if self.DB.excludeGearSets and self.FilterSystem:IsInGearSet(item) then table.insert(reasons, 'In gear set') end

							if self.DB.excludeWarbound and self.FilterSystem:IsWarbound(item) then table.insert(reasons, 'Warbound') end

							if self.DB.excludeBOE and self.FilterSystem:IsBOE(item) then table.insert(reasons, 'BOE') end

							if #reasons > 0 then
								filteredOutItems = filteredOutItems + 1
								self:DebugPrint('  - FILTERED OUT: ' .. table.concat(reasons, ', '))
							else
								self:DebugPrint('  - PASSES ALL FILTERS')
							end
						else
							-- Show why it can't be disenchanted
							local reasons = {}
							if item.classID ~= 2 and item.classID ~= 4 then table.insert(reasons, 'Wrong item class (not Weapons/Armor)') end
							if item.quality < 2 or item.quality > 4 then table.insert(reasons, 'Wrong quality (not Uncommon-Epic)') end
							if not item.itemLevel or item.itemLevel < 1 then table.insert(reasons, 'No item level') end

							self:DebugPrint('  - Cannot disenchant: ' .. table.concat(reasons, ', '))
						end

						self:DebugPrint('  ---')
					end
				end
			end
		end
	end

	-- Show final results
	self:DebugPrint('=== SUMMARY ===')
	self:DebugPrint('Total items in bags: ' .. totalItems)
	self:DebugPrint('Items that can be disenchanted: ' .. disenchantableItems)
	self:DebugPrint('Items filtered out: ' .. filteredOutItems)
	self:DebugPrint('Items that would be shown: ' .. (disenchantableItems - filteredOutItems))

	-- Get final filtered list
	local finalItems = self.FilterSystem:GetDisenchantableItems()
	self:DebugPrint('Final filtered list count: ' .. #finalItems)

	if #finalItems > 0 then
		self:DebugPrint('Final items to disenchant:')
		for i, item in ipairs(finalItems) do
			self:DebugPrint('  ' .. i .. '. ' .. item.itemLink .. ' (iLvl: ' .. item.itemLevel .. ')')
		end
	else
		self:DebugPrint('No items in final list!')
	end

	self:DebugPrint('=== DEBUG OUTPUT END ===')
end

---Add an item to the blacklist
---@param item table The item to blacklist
function LibsDisenchantAssist:BlacklistItem(item)
	if not item or not item.itemID then
		self:Print('Error: Invalid item for blacklisting')
		return
	end

	-- Add to character-specific blacklist (stored by itemID)
	if not self.DBC.blacklist then self.DBC.blacklist = {} end

	self.DBC.blacklist[item.itemID] = true
	self:Print('Blacklisted: ' .. (item.itemLink or item.itemName or 'Unknown Item'))
end

---Check if an item is blacklisted
---@param itemID number The item ID to check
---@return boolean
function LibsDisenchantAssist:IsItemBlacklisted(itemID)
	return self.DBC.blacklist and self.DBC.blacklist[itemID] or false
end

---Get configuration value
---@param key string
---@return any
function LibsDisenchantAssist:GetConfig(key)
	local keys = { strsplit('.', key) }
	local current = self.db.global

	for i = 1, #keys do
		if current[keys[i]] then
			current = current[keys[i]]
		else
			return nil
		end
	end

	return current
end

---Set configuration value
---@param key string
---@param value any
function LibsDisenchantAssist:SetConfig(key, value)
	local keys = { strsplit('.', key) }
	local current = self.db.global

	for i = 1, #keys - 1 do
		if not current[keys[i]] then current[keys[i]] = {} end
		current = current[keys[i]]
	end

	current[keys[#keys]] = value
end

---Register as SpartanUI module
function LibsDisenchantAssist:RegisterSpartanUIModule()
	if not SUI or not SUI.opt or not SUI.opt.args or not SUI.opt.args.Modules then return end

	-- Create options table for SpartanUI integration
	local optionsTable = {
		name = "Lib's - Disenchant Assist",
		type = 'group',
		desc = 'Smart disenchanting with advanced filtering options',
		args = {
			enabled = {
				name = 'Enable Disenchant Assist',
				desc = 'Enable or disable the disenchant assist addon',
				type = 'toggle',
				order = 10,
				get = function()
					return self.db.profile.options.enabled
				end,
				set = function(_, val)
					self.db.profile.options.enabled = val
					if self.UI then
						if val then
							self.UI:Show()
						else
							self.UI:Hide()
						end
					end
				end,
			},
			excludeToday = {
				name = "Exclude Today's Items",
				desc = "Don't disenchant items gained today",
				type = 'toggle',
				order = 20,
				get = function()
					return self.db.profile.options.excludeToday
				end,
				set = function(_, val)
					self.db.profile.options.excludeToday = val
				end,
			},
			excludeHigherIlvl = {
				name = 'Exclude Higher Item Level',
				desc = "Don't disenchant gear with higher item level than equipped",
				type = 'toggle',
				order = 30,
				get = function()
					return self.db.profile.options.excludeHigherIlvl
				end,
				set = function(_, val)
					self.db.profile.options.excludeHigherIlvl = val
				end,
			},
			excludeGearSets = {
				name = 'Exclude Equipment Sets',
				desc = "Don't disenchant items that are part of saved equipment sets",
				type = 'toggle',
				order = 40,
				get = function()
					return self.db.profile.options.excludeGearSets
				end,
				set = function(_, val)
					self.db.profile.options.excludeGearSets = val
				end,
			},
			excludeWarbound = {
				name = 'Exclude Warbound Items',
				desc = "Don't disenchant warbound items",
				type = 'toggle',
				order = 50,
				get = function()
					return self.db.profile.options.excludeWarbound
				end,
				set = function(_, val)
					self.db.profile.options.excludeWarbound = val
				end,
			},
			excludeBOE = {
				name = 'Exclude Bind on Equip',
				desc = "Don't disenchant bind on equip items",
				type = 'toggle',
				order = 60,
				get = function()
					return self.db.profile.options.excludeBOE
				end,
				set = function(_, val)
					self.db.profile.options.excludeBOE = val
				end,
			},
			spacer1 = {
				name = '',
				type = 'header',
				order = 70,
			},
			minIlvl = {
				name = 'Minimum Item Level',
				desc = 'Only disenchant items at or above this item level',
				type = 'range',
				min = 1,
				max = 1000,
				step = 1,
				order = 80,
				get = function()
					return self.db.profile.options.minIlvl
				end,
				set = function(_, val)
					self.db.profile.options.minIlvl = val
				end,
			},
			maxIlvl = {
				name = 'Maximum Item Level',
				desc = 'Only disenchant items at or below this item level',
				type = 'range',
				min = 1,
				max = 1000,
				step = 1,
				order = 90,
				get = function()
					return self.db.profile.options.maxIlvl
				end,
				set = function(_, val)
					self.db.profile.options.maxIlvl = val
				end,
			},
			spacer2 = {
				name = '',
				type = 'header',
				order = 100,
			},
			confirmDisenchant = {
				name = 'Confirm Disenchant',
				desc = 'Show confirmation dialog before disenchanting items',
				type = 'toggle',
				order = 110,
				get = function()
					return self.db.profile.options.confirmDisenchant
				end,
				set = function(_, val)
					self.db.profile.options.confirmDisenchant = val
				end,
			},
			spacer3 = {
				name = '',
				type = 'header',
				order = 120,
			},
			showUI = {
				name = 'Show Main Window',
				desc = 'Open the disenchant assistant main window',
				type = 'execute',
				order = 130,
				func = function()
					if self.UI then self.UI:Show() end
				end,
			},
			scanBags = {
				name = 'Scan Bags',
				desc = 'Manually scan bags for new items',
				type = 'execute',
				order = 140,
				func = function()
					if self.ItemTracker then
						self.ItemTracker:ScanBagsForNewItems()
						self:Print('Scanned bags for new items.')
					end
				end,
			},
		},
	}

	-- Register options with SpartanUI
	if SUI.Handlers and SUI.Handlers.Options and SUI.Handlers.Options.AddOptions then
		SUI.Handlers.Options:AddOptions(optionsTable, 'LibsDisenchantAssist')
		self:Print('Registered with SpartanUI options system')
	else
		-- Fallback direct registration
		SUI.opt.args.Modules.args['LibsDisenchantAssist'] = optionsTable
		self:Print('Registered with SpartanUI (fallback method)')
	end
end
