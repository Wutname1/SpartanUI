local SUI, L = SUI, SUI.L
---@class SUI.Module.QuestTools
local module = SUI:GetModule('QuestTools', true) or SUI:NewModule('QuestTools')
----------------------------------------------------------------------------------------------------

local DefaultBlacklist = {
	QuestIDs = {},
	Gossip = {
		-- General Blacklist
		'Send me into the Black Temple.',
		'what do you have for me?',
		'show me your offerings.',
		'What is the Superbloom?',
		'i wish to buy from you.',
		'i would like to buy from you.',
		'make this inn your home.',
		"i'd like to heal and revive my battle pets.",
		'let me browse your goods.',
		"i'm looking for a lost companion.",
		'i need a ride to the top of the statue.',
		'show me what you have available.',
		'flight master',
		'guild master & vendor',
		'void storage',
		'auction house',
		'stable master',
		'zeppelin master',
		'other continents',
		"officer's lounge",
		'transmogrification',
		'i want to transmogrify my gear.',
		'The Enclave',
		'Bank',
		'Appearance Agitator',
		'Portal to Orgrimmar',
		'Inn',
		'Master of Conflict',
		'Mailbox',
		'Item Upgrade',
		'Item Upgrades',
		'Points of Interest',
		'Barber',
		'Rostrum of Transformation',
		'Crafting Orders',
		'Transmogrifier',
		-- wotlk blacklist
		'i am prepared to face saragosa!',
		'what is the cause of this conflict?',
		'can you spare a drake to take me to lord afrasastrasz in the middle of the temple?',
		'i must return to the world of shadows, koltira. send me back.',
		'i am ready to be teleported to dalaran.',
		'can i get a ride back to ground level, lord afrasastrasz?',
		'i would like to go to lord afrasastrasz in the middle of the temple.',
		'my lord, i need to get to the top of the temple.',
		'yes, please, i would like to return to the ground level of the temple.',
		"steward, please allow me to ride one of the drakes to the queen's chamber at the top of the temple.",
		'i want to exchange my ruby essence for amber essence.',
		'what abilities do ruby drakes have?',
		'i want to fly on the wings of the bronze flight.',
		'i want to fly on the wings of the red flight.',
		'i want to exchange my ruby essence for emerald essence.',
		'what abilities do emerald drakes have?',
		'i want to fly on the wings of the green flight.',
		'i want to exchange my amber essence for ruby essence.',
		'what abilities do amber drakes have?',
		'i am ready.', -- this one is used alot but blacklisted due to trial of the champion
		"i am ready.  however, i'd like to skip the pageantry.",
		-- mop
		"i'm ready to be introduced to the instructors, high elder.",
		"fine. let's proceed with the introductions.",
		'what is this place?',
		-- legion
		'your people treat you with contempt. why? what did you do?',
		-- bfa
		"yes, i'm ready to go to drustvar.",
		'warchief, may i ask why we want to capture teldrassil?',
		'i am ready to go to the undercity.',
		"i've heard this tale before... <skip the scenario and begin your next mission.>",
		'release me.',
		--- Shadowlands
		"Witness the Jailer's defeat.",
		'What is the Purpose?',
		'I am ready to choose my fate in the Shadowlands.',
		'What adventures await me if i join your covenant?',
		'Show me how I can help the Shadowlands.',
		'What are you offering here?',
	},
	Wildcard = {
		'wartime donation',
		'where do i stand',
		'how do i',
		'work order',
		'supplies needed',
		'like to build',
		'taxi',
		'trade',
		'train',
		'trainer',
		'repeat',
		'buy',
		'browse your',
		'my home',
		'reinforcements',
		'Set sail',
		'drustvar',
		'stormsong valley',
		'tiragarde sound',
		'tell me about the',
		'like to change',
		'goods',
		'take us back',
		'take me back',
		'and listen',
		'where I can fly',
		'seal of wartorn',
		'Threads of Fate',
		'What are the strengths of the',
		'covenant abilities again',
		'could you please reset the cooldown on my ability',
		'your home',
		'this inn',
		'what you have on offer',
		"i'd like to try the",
	},
}

local DefaultWhitelist = {
	Gossip = {
		-- TWW
		'Your general asked me to spar with you.',
		-- MISC
		'Evacuate, now!',
		"I've cleared a path for you. You should leave.",
		'If you insist. The show must go on!',
		'Will you spar with me?',
		'I would like to challenge both of you to a spar.',
		'<Request tithe>',
		--DF
		'We need explorers for an expedition to the Dragon Isles. Will you join us?',
		'We need artisans for an expedition to the Dragon Isles. Will you join us?',
		'We need scholars for an expedition to the Dragon Isles. Will you join us?',
		'<Ask Khadgar what happened.>',
		'Scalecommander Cindrethresh would like you to meet her at the zeppelin tower.',
		"Tell me of the Neltharion's downfall.",
		'Tell me of the Dawn of the Aspects.',
		"I'm here to test your combat skills.",
		--Event
		'Begin the battle.',
	},
}

---@class SUI.Module.QuestTools.GlobalDB
module.GlobalDBDefaults = {
	Blacklist = DefaultBlacklist,
	Whitelist = DefaultWhitelist,
}

---@class SUI.Module.QuestTools.DB
module.DBDefaults = {
	ChatText = true,
	FirstLaunch = true,
	debug = false,
	TurnInEnabled = true,
	AutoGossip = true,
	AutoGossipSafeMode = true,
	AcceptGeneralQuests = true,
	DoCampainQuests = false,
	AcceptRepeatable = false,
	trivial = false,
	lootreward = false,
	autoequip = false,
	hideBodyguardGossip = false,
	armor = {},
	weapon = {},
	stat = {},
	secondary = {},
	useGlobalDB = true,
	Blacklist = DefaultBlacklist,
	Whitelist = DefaultWhitelist,
}

-- Blacklist API
module.Blacklist = {}
module.Whitelist = {}

---@enum ListTypes
---| 'QuestIDs'
---| 'Gossip'
---| 'Wildcard'

function module:InitializeBlacklist()
	-- Nothing special needed, just ensure module functions are available
end

---Returns true if blacklisted
---@param lookupId string|number
---@return boolean
function module.Blacklist.isBlacklisted(lookupId)
	local name = tostring(lookupId)
	local DB = module:GetDB()
	local GlobalDB = module:GetGlobalDB()

	-- Determine which blacklist to use
	local blacklistDB = DB.useGlobalDB and GlobalDB.Blacklist or DB.Blacklist
	local gossipBlacklist = blacklistDB.Gossip
	local questBlacklist = blacklistDB.QuestIDs
	local wildcardBlacklist = blacklistDB.Wildcard

	-- Function to perform a case-insensitive search
	local function isInPairSearch(blacklist, checkName)
		for _, key in pairs(blacklist) do
			if string.find(string.lower(checkName), string.lower(key)) then
				return true
			end
		end
		return false
	end

	-- Check for direct match in blacklists or wildcard match
	if SUI:IsInTable(gossipBlacklist, name) or SUI:IsInTable(module.TempBlackList, name) then
		module.debug(name .. '---IS BLACKLISTED')
		return true
	elseif isInPairSearch(wildcardBlacklist, name) or isInPairSearch(questBlacklist, name) then
		module.debug(name .. ' - IS BLACKLISTED')
		return true
	end

	-- Not blacklisted
	module.debug(name .. '---IS NOT BLACKLISTED')
	return false
end

local function Add(list, id, mode, temp, index)
	local DB = module:GetDB()
	local GlobalDB = module:GetGlobalDB()

	if temp then
		module.TempBlackList[id] = true
	else
		local database = DB.useGlobalDB and GlobalDB[list][mode] or DB[list][mode]
		if index then
			database[index] = id
		else
			database[#database + 1] = id
		end
	end
end

---@param id string|number
---@param mode ListTypes
---@param temp? boolean
---@param index? number
function module.Blacklist.Add(id, mode, temp, index)
	Add('Blacklist', id, mode, temp, index)
end

---@param id string|number
---@param mode ListTypes
---@param temp? boolean
---@param index? number
function module.Whitelist.Add(id, mode, temp, index)
	Add('Whitelist', id, mode, temp, index)
end

---@param mode ListTypes
---@return table<number, any>
function module.Blacklist.Get(mode)
	local DB = module:GetDB()
	local GlobalDB = module:GetGlobalDB()
	return DB.useGlobalDB and GlobalDB.Blacklist[mode] or DB.Blacklist[mode]
end

---@param mode ListTypes
---@return table<number, any>
function module.Whitelist.Get(mode)
	local DB = module:GetDB()
	local GlobalDB = module:GetGlobalDB()
	return DB.useGlobalDB and GlobalDB.Whitelist[mode] or DB.Whitelist[mode]
end

local function Remove(list, id, mode, temp, index)
	local DB = module:GetDB()
	local GlobalDB = module:GetGlobalDB()
	local name = tostring(id)

	if temp then
		module.TempBlackList[name] = nil
	else
		local database = DB.useGlobalDB and GlobalDB[list][mode] or DB[list][mode]
		if index then
			database[index] = nil
		else
			database[name] = nil
		end
	end
end

---@param id string|number
---@param mode ListTypes
---@param temp? boolean
---@param index? number
function module.Blacklist.Remove(id, mode, temp, index)
	Remove('Blacklist', id, mode, temp, index)
end

---@param id string|number
---@param mode ListTypes
---@param temp? boolean
---@param index? number
function module.Whitelist.Remove(id, mode, temp, index)
	Remove('Whitelist', id, mode, temp, index)
end

-- Placeholder for UI refresh
function module:RefreshBlacklistUI()
	-- Will be implemented in Options.lua
	if module.buildItemList then
		module.buildItemList('QuestIDs')
	end
end
