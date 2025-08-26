---@class LibsDisenchantAssist : AceAddon
local LibsDisenchantAssist = LibStub('AceAddon-3.0'):NewAddon('LibsDisenchantAssist', 'AceEvent-3.0', 'AceTimer-3.0')
_G.LibsDisenchantAssist = LibsDisenchantAssist

---@class LibsDisenchantAssistDB
---@field global LibsDisenchantAssistGlobalDB
---@field char LibsDisenchantAssistCharDB

---@class LibsDisenchantAssistGlobalDB
---@field itemFirstSeen table<number, number>
---@field options LibsDisenchantAssistOptions

---@class LibsDisenchantAssistCharDB
---@field windowPosition table
---@field minimap table

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

-- Database defaults
local defaults = {
	global = {
		itemFirstSeen = {},
		options = {
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
	},
	char = {
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
	
	-- Expose databases globally for subsystems
	LibsDisenchantAssistDB = self.db.global
	LibsDisenchantAssistCharDB = self.db.char
	
	-- Register chat commands
	self:RegisterChatCommands()
end

---Addon enabled
function LibsDisenchantAssist:OnEnable()
	self:Print('Enabled v1.0.0 - Use /libsde or /disenchantassist for commands')
end

---Handle profile changes
function LibsDisenchantAssist:OnProfileChanged()
	-- Update global references
	LibsDisenchantAssistDB = self.db.global
	LibsDisenchantAssistCharDB = self.db.char
	
	-- Notify subsystems of profile change
	if self.UI then
		self.UI:OnProfileChanged()
	end
	if self.ItemTracker then
		self.ItemTracker:OnProfileChanged()
	end
	if self.FilterSystem then
		self.FilterSystem:OnProfileChanged()
	end
	if self.DisenchantLogic then
		self.DisenchantLogic:OnProfileChanged()
	end
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
		if self.UI then
			self.UI:Show()
		end
	elseif command == 'hide' then
		if self.UI then
			self.UI:Hide()
		end
	elseif command == 'toggle' then
		if self.UI then
			self.UI:Toggle()
		end
	elseif command == 'options' then
		if self.UI then
			self.UI:Show()
			if not self.UI.isOptionsVisible then
				self.UI:ToggleOptions()
			end
		end
	elseif command == 'scan' then
		if self.ItemTracker then
			self.ItemTracker:ScanBagsForNewItems()
			self:Print('Scanned bags for new items.')
		end
	elseif command == 'stop' then
		if self.DisenchantLogic then
			self.DisenchantLogic:StopBatchDisenchant()
		end
	elseif command == 'help' then
		self:Print('Commands:')
		self:Print('/libsde or /libsde show - Show the main window')
		self:Print('/libsde hide - Hide the main window')
		self:Print('/libsde toggle - Toggle the main window')
		self:Print('/libsde options - Show options panel')
		self:Print('/libsde scan - Scan bags for new items')
		self:Print('/libsde stop - Stop batch disenchanting')
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
		if not current[keys[i]] then
			current[keys[i]] = {}
		end
		current = current[keys[i]]
	end
	
	current[keys[#keys]] = value
end

---Register as SpartanUI module
function LibsDisenchantAssist:RegisterSpartanUIModule()
	if not SUI or not SUI.opt or not SUI.opt.args or not SUI.opt.args.Modules then
		return
	end

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
				get = function() return self.db.global.options.enabled end,
				set = function(_, val) 
					self.db.global.options.enabled = val
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
				name = 'Exclude Today\'s Items',
				desc = 'Don\'t disenchant items gained today',
				type = 'toggle',
				order = 20,
				get = function() return self.db.global.options.excludeToday end,
				set = function(_, val) self.db.global.options.excludeToday = val end,
			},
			excludeHigherIlvl = {
				name = 'Exclude Higher Item Level',
				desc = 'Don\'t disenchant gear with higher item level than equipped',
				type = 'toggle',
				order = 30,
				get = function() return self.db.global.options.excludeHigherIlvl end,
				set = function(_, val) self.db.global.options.excludeHigherIlvl = val end,
			},
			excludeGearSets = {
				name = 'Exclude Equipment Sets',
				desc = 'Don\'t disenchant items that are part of saved equipment sets',
				type = 'toggle',
				order = 40,
				get = function() return self.db.global.options.excludeGearSets end,
				set = function(_, val) self.db.global.options.excludeGearSets = val end,
			},
			excludeWarbound = {
				name = 'Exclude Warbound Items',
				desc = 'Don\'t disenchant warbound items',
				type = 'toggle',
				order = 50,
				get = function() return self.db.global.options.excludeWarbound end,
				set = function(_, val) self.db.global.options.excludeWarbound = val end,
			},
			excludeBOE = {
				name = 'Exclude Bind on Equip',
				desc = 'Don\'t disenchant bind on equip items',
				type = 'toggle',
				order = 60,
				get = function() return self.db.global.options.excludeBOE end,
				set = function(_, val) self.db.global.options.excludeBOE = val end,
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
				get = function() return self.db.global.options.minIlvl end,
				set = function(_, val) self.db.global.options.minIlvl = val end,
			},
			maxIlvl = {
				name = 'Maximum Item Level',
				desc = 'Only disenchant items at or below this item level',
				type = 'range',
				min = 1,
				max = 1000,
				step = 1,
				order = 90,
				get = function() return self.db.global.options.maxIlvl end,
				set = function(_, val) self.db.global.options.maxIlvl = val end,
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
				get = function() return self.db.global.options.confirmDisenchant end,
				set = function(_, val) self.db.global.options.confirmDisenchant = val end,
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
					if self.UI then
						self.UI:Show()
					end
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
	if SUI.Handler and SUI.Handler.Options and SUI.Handler.Options.AddOptions then
		SUI.Handler.Options:AddOptions(optionsTable, 'LibsDisenchantAssist')
		self:Print('Registered with SpartanUI options system')
	else
		-- Fallback direct registration
		SUI.opt.args.Modules.args['LibsDisenchantAssist'] = optionsTable
		self:Print('Registered with SpartanUI (fallback method)')
	end
end