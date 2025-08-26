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