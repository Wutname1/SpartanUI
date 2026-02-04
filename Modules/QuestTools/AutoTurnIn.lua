local SUI, L = SUI, SUI.L
---@class SUI.Module.QuestTools
local module = SUI:GetModule('QuestTools')
----------------------------------------------------------------------------------------------------

function module:InitializeAutoTurnIn()
	-- Nothing special needed, just ensure module functions are available
end

-- Turns quest in printing reward text if `ChatText` option is set.
-- Prints appropriate message if item is taken by greed
-- Equips received reward if such option selected
function module:TurnInQuest(rewardIndex)
	local DB = module:GetDB()
	module.debug('TurnInQuest')
	module.debug(rewardIndex)

	if DB.ChatText then
		SUI:Print((UnitName('target') and UnitName('target') or '') .. '\n', GetRewardText())
	end

	if IsAltKeyDown() then
		SUI:Print('Override key held, turn in disabled')
		module:CancelAllTimers()
		return
	end

	if module.Blacklist.isBlacklisted(GetQuestID()) then
		SUI:Print('Quest is blacklisted, not turning in.')
		return
	end

	GetQuestReward(rewardIndex)
end
