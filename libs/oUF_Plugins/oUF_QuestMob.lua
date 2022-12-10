local _, ns = ...
local oUF = ns.oUF

local ThreatTooltip = THREAT_TOOLTIP:gsub('%%d', '%%d-')
local ScanTooltip = CreateFrame('GameTooltip', 'oUFQuestScanTooltip', _G.UIParent, 'GameTooltipTemplate')

local questIcons = {
	iconTypes = {'Default', 'Item', 'Skull', 'Chat'},
	indexByID = {}, --[questID] = questIndex
	activeQuests = {} --[questTitle] = questID
}

local typesLocalized = {
	enUS = {
		KILL = {'slain', 'destroy', 'eliminate', 'repel', 'kill', 'defeat'},
		CHAT = {'speak', 'talk', 'spoken'}
	},
	deDE = {
		KILL = {'besiegen', 'besiegt', 'getötet', 'töten', 'tötet', 'vernichtet', 'zerstört', 'genährt'},
		CHAT = {'befragt', 'sprecht'}
	},
	ruRU = {
		KILL = {'убит', 'уничтож', 'разбомблен', 'разбит', 'сразит'},
		CHAT = {'поговорит', 'спрашивать'}
	},
	esMX = {
		KILL = {'asesinad', 'destrui', 'elimin', 'repel', 'derrota'},
		CHAT = {'habla', 'pídele'}
	},
	ptBR = {
		KILL = {'morto', 'morta', 'matar', 'destrui', 'elimin', 'repel', 'derrota'},
		CHAT = {'falar', 'pedir'}
	},
	frFR = {
		KILL = {'tué', 'tuer', 'attaqué', 'attaque', 'abattre', 'abattu', 'détrui', 'élimin', 'repouss', 'vaincu', 'vaincre'},
		CHAT = {'parle', 'demande'}
	},
	koKR = {
		KILL = {'쓰러뜨리기', '물리치기', '공격', '파괴'},
		CHAT = {'대화'}
	},
	zhCN = {
		KILL = {'消灭', '摧毁', '击败', '毁灭', '击退'},
		CHAT = {'交谈', '谈一谈'}
	},
	zhTW = {
		KILL = {'毀滅', '擊退', '殺死'},
		CHAT = {'交談', '說話'}
	}
}

local questTypes = typesLocalized[GetLocale()] or typesLocalized.enUS

local function CheckTextForQuest(text)
	local x, y = strmatch(text, '(%d+)/(%d+)')
	if x and y then
		local diff = floor(y - x)
		if diff > 0 then
			return diff
		end
	elseif not strmatch(text, ThreatTooltip) then
		local progress = tonumber(strmatch(text, '([%d%.]+)%%'))
		if progress and progress <= 100 then
			return ceil(100 - progress), true
		end
	end
end

local function GetQuests(unitID)
	if IsInInstance() then
		return
	end

	ScanTooltip:SetOwner(_G.UIParent, 'ANCHOR_NONE')
	ScanTooltip:SetUnit(unitID)
	ScanTooltip:Show()

	local QuestList, notMyQuest, activeID
	for i = 3, ScanTooltip:NumLines() do
		local str = _G['oUFQuestScanTooltipTextLeft' .. i]
		local text = str and str:GetText()
		if not text or text == '' then
			return
		end

		if UnitIsPlayer(text) then
			notMyQuest = text ~= UnitName('player')
		elseif text and not notMyQuest then
			local count, percent = CheckTextForQuest(text)

			-- this line comes from one line up in the tooltip
			local activeQuest = questIcons.activeQuests[text]
			if activeQuest then
				activeID = activeQuest
			end

			if count then
				local type, index, texture, _
				if activeID then
					index = questIcons.indexByID[activeID]
					_, texture = GetQuestLogSpecialItemInfo(index)
				end

				if texture then
					type = 'QUEST_ITEM'
				else
					local lowerText = strlower(text)

					-- check kill type first
					for _, listText in ipairs(questTypes.KILL) do
						if strfind(lowerText, listText, nil, true) then
							type = 'KILL'
							break
						end
					end

					-- check chat type if kill type doesn't exist
					if not type then
						for _, listText in ipairs(questTypes.CHAT) do
							if strfind(lowerText, listText, nil, true) then
								type = 'CHAT'
								break
							end
						end
					end
				end

				if not QuestList then
					QuestList = {}
				end
				QuestList[#QuestList + 1] = {
					isPercent = percent,
					itemTexture = texture,
					objectiveCount = count,
					questType = type or 'DEFAULT',
					-- below keys are currently unused
					questLogIndex = index,
					questID = activeID
				}
			end
		end
	end

	ScanTooltip:Hide()
	return QuestList
end

local function hideIcons(element)
	for _, object in pairs(questIcons.iconTypes) do
		local icon = element[object]
		icon:Hide()

		if icon.Text then
			icon.Text:SetText('')
		end
	end
end

local function Update(self, event, arg1)
	local element = self.QuestMob
	if not element then
		return
	end

	local unit = (event == 'UNIT_NAME_UPDATE' and arg1) or self.unit
	if unit ~= self.unit then
		return
	end

	if element.PreUpdate then
		element:PreUpdate()
	end

	hideIcons(element)

	local QuestList = GetQuests(unit)
	if QuestList then
		element:Show()
	else
		element:Hide()
		return
	end

	local shownCount
	for i = 1, #QuestList do
		local quest = QuestList[i]
		local objectiveCount = quest.objectiveCount
		local questType = quest.questType
		local isPercent = quest.isPercent

		if isPercent or objectiveCount > 0 then
			local icon
			if questType == 'DEFAULT' then
				icon = element.Default
			elseif questType == 'KILL' then
				icon = element.Skull
			elseif questType == 'CHAT' then
				icon = element.Chat
			elseif questType == 'QUEST_ITEM' then
				icon = element.Item
			end

			if icon and not icon:IsShown() then
				-- 	shownCount = (shownCount and shownCount + 1) or 0

				-- 	local size = icon.size or 25
				-- 	local setPosition = icon.position or 'TOPLEFT'
				-- 	local newPosition = E.InversePoints[setPosition]
				-- 	local offset = shownCount * (5 + size)

				icon:Show()
				-- 	icon:ClearAllPoints()
				-- 	icon:Point(newPosition, element, newPosition, (strmatch(setPosition, 'LEFT') and -offset) or offset, 0)

				if questType ~= 'CHAT' and icon.Text and (isPercent or objectiveCount > 1) then
					icon.Text:SetText((isPercent and objectiveCount .. '%') or objectiveCount)
				end

				if questType == 'QUEST_ITEM' then
					element.Item:SetTexture(quest.itemTexture)
				end
			end
		end
	end

	if element.PostUpdate then
		return element:PostUpdate()
	end
end

local function Path(self, ...)
	return (self.QuestMob.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.QuestMob
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if element.Default:IsObjectType('Texture') and not element.Default:GetAtlas() then
			element.Default:SetAtlas('SmallQuestBang')
		end
		if element.Skull:IsObjectType('Texture') and not element.Skull:GetTexture() then
			element.Skull:SetTexture([[Interface\WorldMap\Skull_64Red.PNG]])
		end
		if element.Chat:IsObjectType('StatusBar') and not element.Chat:GetTexture() then
			element.Chat:SetTexture([[Interface\WorldMap\ChatBubble_64.PNG]])
		end

		self:RegisterEvent('QUEST_LOG_UPDATE', Path, true)
		self:RegisterEvent('UNIT_NAME_UPDATE', Path, true)
		self:RegisterEvent('PLAYER_ENTERING_WORLD', Path, true)
	end
end

local function Disable(self)
	local element = self.QuestMob
	if element then
		element:Hide()
		hideIcons(element)

		self:UnregisterEvent('QUEST_LOG_UPDATE', Path)
		self:UnregisterEvent('UNIT_NAME_UPDATE', Path)
		self:UnregisterEvent('PLAYER_ENTERING_WORLD', Path)
	end
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('QUEST_ACCEPTED')
frame:RegisterEvent('QUEST_REMOVED')
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:SetScript(
	'OnEvent',
	function(self, event)
		wipe(questIcons.indexByID)
		wipe(questIcons.activeQuests)

		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local id = C_QuestLog.GetQuestIDForLogIndex(i)
			if id and id > 0 then
				questIcons.indexByID[id] = i

				local title = C_QuestLog.GetTitleForLogIndex(i)
				if title then
					questIcons.activeQuests[title] = id
				end
			end
		end

		if event == 'PLAYER_ENTERING_WORLD' then
			self:UnregisterEvent(event)
		end
	end
)

oUF:AddElement('QuestMob', Path, Enable, Disable)
