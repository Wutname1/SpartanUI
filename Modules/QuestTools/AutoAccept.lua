local SUI, L = SUI, SUI.L
---@class SUI.Module.QuestTools
local module = SUI:GetModule('QuestTools')
----------------------------------------------------------------------------------------------------

local QUESTDETAILHistory = {}

function module:InitializeAutoAccept()
	-- Nothing special needed, just ensure module functions are available
end

function module:HandleQuestDetail()
	local DB = module:GetDB()
	module.debug('QUEST_DETAIL')
	module.debug(GetTitleText())
	module.debug(GetObjectiveText())
	module.debug(GetQuestID())

	if DB.AcceptGeneralQuests then
		if DB.ChatText then
			local title = GetTitleText()
			local objText = GetObjectiveText()
			if title and title ~= '' and not QUESTDETAILHistory[title] then
				QUESTDETAILHistory[title] = objText
				SUI:Print(title)
				if objText and objText ~= '' then
					SUI:Print(L['Quest Objectives'])
					print(objText)
					module.debug('    ' .. objText)
				end
			end
		end

		if not IsAltKeyDown() and not module.Blacklist.isBlacklisted(GetQuestID()) then
			AcceptQuest()
		end
	end
end

function module:HandleQuestProgress()
	local DB = module:GetDB()
	if IsQuestCompletable() and DB.TurnInEnabled and (not module.Blacklist.isBlacklisted(GetTitleText())) then
		CompleteQuest()
	end
end
