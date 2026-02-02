local SUI, L = SUI, SUI.L
---@class SUI.Module.QuestTools
local module = SUI:GetModule('QuestTools')
----------------------------------------------------------------------------------------------------

-- Garrison Bodyguard NPC IDs (Warlords of Draenor)
-- These NPCs open a gossip window that players often want to skip
local BodyguardNPCIDs = {
	-- Alliance Bodyguards
	[86945] = true, -- Defender Illona
	[86933] = true, -- Delvar Ironfist
	-- Horde Bodyguards
	[86927] = true, -- Vivianne
	[86934] = true, -- Aeda Brightdawn
	-- Neutral Bodyguards (Both factions)
	[86682] = true, -- Leorajh
	[86964] = true, -- Talonpriest Ishaal
	[86946] = true, -- Tormmok
}

---Check if the current gossip target is a garrison bodyguard
---@return boolean
function module:IsBodyguardGossip()
	local guid = UnitGUID('npc')
	if not guid then
		return false
	end

	-- Extract NPC ID from GUID (format: Creature-0-XXXX-XXXX-XXXX-XXXXXXXX-XXXX)
	local npcID = select(6, strsplit('-', guid))
	npcID = tonumber(npcID)

	if npcID and BodyguardNPCIDs[npcID] then
		return true
	end

	return false
end

function module:InitializeGossipHandler()
	-- Nothing special needed, just ensure module functions are available
end

function module:HandleGossipShow()
	local DB = module:GetDB()
	local GlobalDB = module:GetGlobalDB()

	-- Check for bodyguard gossip skip (hold Shift to override)
	if DB.hideBodyguardGossip and not IsShiftKeyDown() then
		if module:IsBodyguardGossip() then
			module.debug('Bodyguard detected, auto-closing gossip (hold Shift to override)')
			C_GossipInfo.CloseGossip()
			return
		end
	end

	if (not DB.AutoGossip) or (IsAltKeyDown()) then
		return
	end

	module:VarArgForActiveQuests(C_GossipInfo.GetActiveQuests())
	module:VarArgForAvailableQuests(C_GossipInfo.GetAvailableQuests())

	module.debug('------ [Debugging Gossip] ------')
	local options = C_GossipInfo.GetOptions()
	module.debug('Number of Options ' .. #options)

	for _, gossip in pairs(options) do
		module.debug('---Start Option Info---')
		module.debug('Gossip Name: ' .. tostring(gossip.name))
		module.debug('Gossip Rewards: ' .. tostring(gossip.rewards))
		module.debug('Gossip Status: ' .. tostring(gossip.status))
		module.debug('Gossip Flags: ' .. tostring(gossip.flags))

		-- Check if gossip is whitelisted
		local whitelist = DB.useGlobalDB and GlobalDB.Whitelist.Gossip or DB.Whitelist.Gossip
		local isWhitelisted = SUI:IsInTable(whitelist, gossip.name)
		module.debug('Is Whitelisted: ' .. tostring(isWhitelisted))

		-- Check if gossip is blacklisted
		local isBlacklisted = module.Blacklist.isBlacklisted(gossip.name)
		module.debug('Is Blacklisted: ' .. tostring(isBlacklisted))

		-- Check if gossip is a quest
		local isQuest = string.match(gossip.name, 'Quest') and true or false
		module.debug('Is a Quest: ' .. tostring(isQuest))

		-- Check the final condition
		local Allow = not isBlacklisted or (isWhitelisted or isQuest)
		module.debug('Final Condition: ' .. tostring(Allow))
		module.debug('---End Option Info---')

		if (gossip.status == 0) and Allow then
			-- If we are in safemode and gossip option not flagged as 'QUEST' then exit
			if DB.AutoGossipSafeMode and (not isWhitelisted and not isQuest) then
				module.debug(string.format('Safe mode active - not selecting gossip option "%s"', gossip.name))
				return
			end
			module.TempBlackList[gossip.name] = true
			module.debug(gossip.name .. '---BLACKLISTED')
			C_GossipInfo.SelectOption(gossip.gossipOptionID)

			if DB.ChatText then
				SUI:Print('Selecting: ' .. gossip.name)
			end
			return
		end
	end

	module:VarArgForActiveQuests(C_GossipInfo.GetActiveQuests())
	module:VarArgForAvailableQuests(C_GossipInfo.GetAvailableQuests())
end

---@param ... GossipQuestUIInfo[]
function module:VarArgForActiveQuests(...)
	module.debug('VarArgForActiveQuests')
	if ... then
		module.debug(#...)
	end

	for i, quest in pairs(...) do
		module.debug(quest.isComplete)
		module.debug(quest.frequency)
		module.debug(quest.title)
		if quest.isComplete and (not module.Blacklist.isBlacklisted(quest.title)) then
			local questInfo = module.Lquests[quest.title]
			module.debug('selecting.. ' .. quest.title)
			if questInfo then
				if module:GetItemAmount(questInfo.currency, questInfo.item) >= questInfo.amount then
					C_GossipInfo.SelectActiveQuest(quest.questID)
				end
			else
				C_GossipInfo.SelectActiveQuest(quest.questID)
			end
		end
	end
end

---@param ... GossipQuestUIInfo[]
function module:VarArgForAvailableQuests(...)
	local DB = module:GetDB()
	module.debug('VarArgForAvailableQuests')
	module.debug(#...)

	for i, quest in pairs(...) do
		local trivialORAllowed = (not quest.isTrivial) or DB.trivial
		local isRepeatableORAllowed = (not quest.repeatable) or DB.AcceptRepeatable

		-- Quest is appropriate if: (it is trivial and trivial are accepted) and (any quest accepted or (it is daily quest that is not in ignore list))
		if (trivialORAllowed and isRepeatableORAllowed) and not module.Blacklist.isBlacklisted(quest.title) and not module.Blacklist.isBlacklisted(quest.questID) then
			local questInfo = module.Lquests[quest.title]
			if questInfo and questInfo.amount then
				if module:GetItemAmount(questInfo.currency, questInfo.item) >= questInfo.amount then
					C_GossipInfo.SelectAvailableQuest(quest.questID)
				end
			else
				C_GossipInfo.SelectAvailableQuest(quest.questID)
			end
		else
			module.debug('Quest is not appropriate: ' .. quest.title)
			module.debug('-isImportant: ' .. tostring(quest.isImportant))
			module.debug('-isMeta: ' .. tostring(quest.isMeta))
			module.debug('-Trivial: ' .. tostring(trivialORAllowed))
			module.debug('-Repeatable: ' .. tostring(isRepeatableORAllowed))
			module.debug('-Blacklisted: ' .. tostring(module.Blacklist.isBlacklisted(quest.title)) .. ', ' .. tostring(module.Blacklist.isBlacklisted(quest.questID)))
		end
	end
end

function module:HandleQuestGreeting()
	local DB = module:GetDB()
	local numActiveQuests = GetNumActiveQuests()
	local numAvailableQuests = GetNumAvailableQuests()

	module.debug(numActiveQuests)
	module.debug(numAvailableQuests)

	for i = 1, numActiveQuests do
		local isComplete = select(2, GetActiveTitle(i))
		module.debug('Option ' .. i .. ' isComplete: ' .. tostring(isComplete))
		if isComplete then
			C_GossipInfo.SelectActiveQuest(i)
			if SelectActiveQuest then
				module.debug('Selecting Active Quest ' .. i)
				---@diagnostic disable-next-line: redundant-parameter
				SelectActiveQuest(i)
			end
		end
	end

	for i = 1, numAvailableQuests do
		if SUI.IsRetail then
			local isTrivial, frequency, isRepeatable, _, questID = GetAvailableQuestInfo(i - numActiveQuests)

			local trivialORAllowed = (not isTrivial) or DB.trivial
			local isDaily = (frequency == LE_QUEST_FREQUENCY_DAILY or frequency == LE_QUEST_FREQUENCY_WEEKLY)
			local isRepeatableORAllowed = (not isRepeatable or not isDaily) or DB.AcceptRepeatable
			if (trivialORAllowed and isRepeatableORAllowed) and (not module.Blacklist.isBlacklisted(questID)) and questID ~= 0 then
				module.debug('selecting ' .. i .. ' questId ' .. questID)
				---@diagnostic disable-next-line: redundant-parameter
				C_GossipInfo.SelectAvailableQuest(i)
			end
		else
			---@diagnostic disable-next-line: redundant-parameter
			C_GossipInfo.SelectAvailableQuest(i)
		end
	end
end
