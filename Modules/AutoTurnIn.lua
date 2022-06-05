local SUI, L, StdUi = SUI, SUI.L, SUI.StdUi
local module = SUI:NewModule('Component_AutoTurnIn', 'AceTimer-3.0')
module.DisplayName = L['Auto turn in']
module.description = 'Auto accept and turn in quests'
----------------------------------------------------------------------------------------------------
local SelectAvailableQuest = C_GossipInfo.SelectAvailableQuest or SelectAvailableQuest
local SelectActiveQuest = C_GossipInfo.SelectActiveQuest or SelectActiveQuest
local GetGossipActiveQuests = C_GossipInfo.GetActiveQuests or GetGossipActiveQuests
local GetNumGossipOptions = C_GossipInfo.GetNumOptions or GetNumGossipOptions
local SelectGossipOption = C_GossipInfo.SelectOption or SelectGossipOption
local GetGossipAvailableQuests = C_GossipInfo.GetAvailableQuests or GetGossipAvailableQuests
local GetGossipOptions = C_GossipInfo.GetOptions or GetGossipOptions
local DB  ---@type AutoTurnInDB
---@class AutoTurnInDB
local DBDefaults = {
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
	armor = {},
	weapon = {},
	stat = {},
	secondary = {},
	GossipBlacklist = {
		-- General Blacklist
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
		'What are you offering here?'
	},
	WildcardBlackList = {
		'wartime donation',
		'work order',
		'supplies needed',
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
		'what you have on offer'
	},
	GossipWhitelist = {
		'Evacuate, now!',
		"I've cleared a path for you. You should leave.",
		'If you insist. The show must go on!',
		'Will you spar with me?',
		'I would like to challenge both of you to a spar.'
	}
}

local ATI_Container = CreateFrame('Frame')
local IsMerchantOpen = false
local SLOTS = {
	['INVTYPE_AMMO'] = {'AmmoSlot'},
	['INVTYPE_HEAD'] = {'HeadSlot'},
	['INVTYPE_NECK'] = {'NeckSlot'},
	['INVTYPE_SHOULDER'] = {'ShoulderSlot'},
	['INVTYPE_CHEST'] = {'ChestSlot'},
	['INVTYPE_WAIST'] = {'WaistSlot'},
	['INVTYPE_LEGS'] = {'LegsSlot'},
	['INVTYPE_FEET'] = {'FeetSlot'},
	['INVTYPE_WRIST'] = {'WristSlot'},
	['INVTYPE_HAND'] = {'HandsSlot'},
	['INVTYPE_FINGER'] = {'Finger0Slot', 'Finger1Slot'},
	['INVTYPE_TRINKET'] = {'Trinket0Slot', 'Trinket1Slot'},
	['INVTYPE_CLOAK'] = {'BackSlot'},
	['INVTYPE_WEAPON'] = {'MainHandSlot', 'SecondaryHandSlot'},
	['INVTYPE_2HWEAPON'] = {'MainHandSlot'},
	['INVTYPE_RANGED'] = {'MainHandSlot'},
	['INVTYPE_RANGEDRIGHT'] = {'MainHandSlot'},
	['INVTYPE_WEAPONMAINHAND'] = {'MainHandSlot'},
	['INVTYPE_SHIELD'] = {'SecondaryHandSlot'},
	['INVTYPE_WEAPONOFFHAND'] = {'SecondaryHandSlot'},
	['INVTYPE_HOLDABLE'] = {'SecondaryHandSlot'}
}
local itemCache =
	setmetatable(
	{},
	{
		__index = function(table, key)
			return {}
		end
	}
)
local TempBlackList = {}
local Lquests = {
	-- Steamwheedle Cartel
	['Making Amends'] = {item = 'Runecloth', amount = 40, currency = false},
	['War at Sea'] = {item = 'Mageweave Cloth', amount = 40, currency = false},
	['Traitor to the Bloodsail'] = {item = 'Silk Cloth', amount = 40, currency = false},
	['Mending Old Wounds'] = {item = 'Linen Cloth', amount = 40, currency = false},
	-- Timbermaw Quests
	['Feathers for Grazle'] = {item = 'Deadwood Headdress Feather', amount = 5, currency = false},
	['Feathers for Nafien'] = {item = 'Deadwood Headdress Feather', amount = 5, currency = false},
	['More Beads for Salfa'] = {item = 'Winterfall Spirit Beads', amount = 5, currency = false},
	-- Cenarion
	['Encrypted Twilight Texts'] = {item = 'Encrypted Twilight Text', amount = 10, currency = false},
	['Still Believing'] = {item = 'Encrypted Twilight Text', amount = 10, currency = false},
	-- Thorium Brotherhood
	['Favor Amongst the Brotherhood, Blood of the Mountain'] = {
		item = 'Blood of the Mountain',
		amount = 1,
		currency = false
	},
	['Favor Amongst the Brotherhood, Core Leather'] = {item = 'Core Leather', amount = 2, currency = false},
	['Favor Amongst the Brotherhood, Dark Iron Ore'] = {item = 'Dark Iron Ore', amount = 10, currency = false},
	['Favor Amongst the Brotherhood, Fiery Core'] = {item = 'Fiery Core', amount = 1, currency = false},
	['Favor Amongst the Brotherhood, Lava Core'] = {item = 'Lava Core', amount = 1, currency = false},
	['Gaining Acceptance'] = {item = 'Dark Iron Residue', amount = 4, currency = false},
	['Gaining Even More Acceptance'] = {item = 'Dark Iron Residue', amount = 100, currency = false},
	--Burning Crusade, Lower City
	['More Feathers'] = {item = 'Arakkoa Feather', amount = 30, currency = false},
	--Aldor
	["More Marks of Kil'jaeden"] = {item = "Mark of Kil'jaeden", amount = 10, currency = false},
	['More Marks of Sargeras'] = {item = 'Mark of Sargeras', amount = 10, currency = false},
	['Fel Armaments'] = {item = 'Fel Armaments', amount = 10, currency = false},
	["Single Mark of Kil'jaeden"] = {item = "Mark of Kil'jaeden", amount = 1, currency = false},
	['Single Mark of Sargeras'] = {item = 'Mark of Sargeras', amount = 1, currency = false},
	['More Venom Sacs'] = {item = 'Dreadfang Venom Sac', amount = 8, currency = false},
	--Scryer
	['More Firewing Signets'] = {item = 'Firewing Signet', amount = 10, currency = false},
	['More Sunfury Signets'] = {item = 'Sunfury Signet', amount = 10, currency = false},
	['Arcane Tomes'] = {item = 'Arcane Tome', amount = 1, currency = false},
	['Single Firewing Signet'] = {item = 'Firewing Signet', amount = 1, currency = false},
	['Single Sunfury Signet'] = {item = 'Sunfury Signet', amount = 1, currency = false},
	['More Basilisk Eyes'] = {item = 'Dampscale Basilisk Eye', amount = 8, currency = false},
	--Skettis
	['More Shadow Dust'] = {item = 'Shadow Dust', amount = 6, currency = false},
	--SporeGar
	['Bring Me Another Shrubbery!'] = {item = 'Sanguine Hibiscus', amount = 5, currency = false},
	['More Fertile Spores'] = {item = 'Fertile Spores', amount = 6, currency = false},
	['More Glowcaps'] = {item = 'Glowcap', amount = 10, currency = false},
	['More Spore Sacs'] = {item = 'Mature Spore Sac', amount = 10, currency = false},
	['More Tendrils!'] = {item = 'Bog Lord Tendril', amount = 6, currency = false},
	-- Halaa
	["Oshu'gun Crystal Powder"] = {item = "Oshu'gun Crystal Powder Sample", amount = 10, currency = false},
	["Hodir's Tribute"] = {item = 'Relic of Ulduar', amount = 10, currency = false},
	['Remember Everfrost!'] = {item = 'Everfrost Chip', amount = 1, currency = false},
	['Additional Armaments'] = {item = 416, amount = 125, currency = true},
	['Calling the Ancients'] = {item = 416, amount = 125, currency = true},
	['Filling the Moonwell'] = {item = 416, amount = 125, currency = true},
	['Into the Fire'] = {donotaccept = true},
	['The Forlorn Spire'] = {donotaccept = true},
	['Fun for the Little Ones'] = {item = 393, amount = 15, currency = true},
	--MoP
	['Seeds of Fear'] = {item = 'Dread Amber Shards', amount = 5, currency = false},
	['A Dish for Jogu'] = {item = 'Sauteed Carrots', amount = 5, currency = false},
	['A Dish for Ella'] = {item = 'Shrimp Dumplings', amount = 5, currency = false},
	['Valley Stir Fry'] = {item = 'Valley Stir Fry', amount = 5, currency = false},
	['A Dish for Farmer Fung'] = {item = 'Wildfowl Roast', amount = 5, currency = false},
	['A Dish for Fish'] = {item = 'Twin Fish Platter', amount = 5, currency = false},
	['Swirling Mist Soup'] = {item = 'Swirling Mist Soup', amount = 5, currency = false},
	['A Dish for Haohan'] = {item = 'Charbroiled Tiger Steak', amount = 5, currency = false},
	['A Dish for Old Hillpaw'] = {item = 'Braised Turtle', amount = 5, currency = false},
	['A Dish for Sho'] = {item = 'Eternal Blossom Fish', amount = 5, currency = false},
	['A Dish for Tina'] = {item = 'Fire Spirit Salmon', amount = 5, currency = false},
	['Replenishing the Pantry'] = {item = 'Bundle of Groceries', amount = 1, currency = false},
	--MOP timeless Island
	['Great Turtle Meat'] = {item = 'Great Turtle Meat', amount = 1, currency = false},
	['Heavy Yak Flank'] = {item = 'Heavy Yak Flank', amount = 1, currency = false},
	['Meaty Crane Leg'] = {item = 'Meaty Crane Leg', amount = 1, currency = false},
	['Pristine Firestorm Egg'] = {item = 'Pristine Firestorm Egg', amount = 1, currency = false},
	['Thick Tiger Haunch'] = {item = 'Thick Tiger Haunch', amount = 1, currency = false}
}
local function debug(content)
	SUI.Debug(content, 'AutoTurnIn')
end
-- turns quest in printing reward text if `ChatText` option is set.
-- prints appropriate message if item is taken by greed
-- equips received reward if such option selected
function module:TurnInQuest(rewardIndex)
	if (DB.ChatText) then
		SUI:Print((UnitName('target') and UnitName('target') or '') .. '\n', GetRewardText())
	end
	if IsAltKeyDown() then
		SUI:Print('Override key held, turn in disabled')
		module:CancelAllTimers()
		return
	end
	if module:blacklisted(GetTitleText()) then
		SUI:Print('Quest is blacklisted, not turning in.')
		return
	end

	GetQuestReward(rewardIndex)
end

function module:EquipItem(ItemToEquip)
	if (InCombatLockdown()) then
		return
	end

	local EquipItemName = GetItemInfo(ItemToEquip)
	local EquipILvl = GetDetailedItemLevelInfo(ItemToEquip)
	local ItemFound = false

	-- Make sure it is in the bags
	for bag = 0, NUM_BAG_SLOTS do
		if ItemFound then
			return
		end
		for slot = 1, GetContainerNumSlots(bag), 1 do
			local link = GetContainerItemLink(bag, slot)
			if (link) then
				local slotItemName = GetItemInfo(link)
				local SlotILvl = GetDetailedItemLevelInfo(link)
				if (slotItemName == EquipItemName) and (SlotILvl == EquipILvl) then
					if IsMerchantOpen then
						SUI:Print(L['Unable to equip'] .. ' ' .. link)
						module:CancelAllTimers()
					else
						SUI:Print(L['Equipping reward'] .. ' ' .. link)
						UseContainerItem(bag, slot)
						module:CancelAllTimers()
						ItemFound = true
						return
					end
				end
			end
		end
	end
end

function module.MERCHANT_SHOW()
	IsMerchantOpen = true
end

function module.MERCHANT_CLOSED()
	IsMerchantOpen = false
end

function module.QUEST_DETAIL()
	if (DB.AcceptGeneralQuests) then
		QuestInfoDescriptionText:SetAlphaGradient(0, -1)
		QuestInfoDescriptionText:SetAlpha(1)

		if DB.ChatText then
			local title = GetTitleText()
			local objText = GetObjectiveText()
			if title and title ~= '' then
				SUI:Print(objText)
			end
			if objText and objText ~= '' then
				SUI:Print(L['Quest Objectives'])
				debug('    ' .. objText)
			end
		end
		if (not IsAltKeyDown()) then
			AcceptQuest()
		end
	end
end

function module.QUEST_COMPLETE()
	if not DB.TurnInEnabled then
		return
	end

	-- Look for the item that is the best upgrade and whats worth the most.
	local GreedID, GreedValue, UpgradeID = nil, 0, nil
	local GreedLink, UpgradeLink, UpgradeAmmount = nil, nil, 0
	local QuestRewardsWeapon = false
	for i = 1, GetNumQuestChoices() do
		if SUI.IsClassic then
			SUI:Print(L['Canceling turn in, quest rewards items.'])
			return
		end

		-- Load the items information
		local link = GetQuestItemLink('choice', i)
		if (link == nil) then
			return
		end
		local itemName, _, _, _, _, _, _, _, itemEquipLoc, _, itemSellPrice = GetItemInfo(link)
		local QuestItemTrueiLVL = SUI:GetiLVL(link)

		-- Check the items value
		if itemSellPrice > GreedValue then
			GreedValue = itemSellPrice
			GreedID = i
			GreedLink = link
		end

		-- See if the item is an upgrade
		local slot = SLOTS[itemEquipLoc]
		if (slot) then
			local firstSlot = GetInventorySlotInfo(slot[1])
			local firstinvLink = GetInventoryItemLink('player', firstSlot)
			local EquipedLevel = SUI:GetiLVL(firstinvLink)

			if EquipedLevel then
				-- If reward is a ring, trinket or one-handed weapons all slots must be checked in order to swap with a lesser ilevel
				if (#slot > 1) then
					local secondSlot = GetInventorySlotInfo(slot[2])
					local secondinvLink = GetInventoryItemLink('player', secondSlot)
				-- if (invLink) then
				-- 	local eq2Level = SUI:GetiLVL(invLink)
				-- 	if (EquipedLevel > eq2Level) then
				-- 		debug('Slot ' .. #slot .. ' is lower (' .. EquipedLevel .. '>' .. eq2Level .. ')')
				-- 		firstSlot = secondSlot
				-- 		EquipedLevel = eq2Level
				-- 		firstinvLink = secondinvLink
				-- 	end
				-- end
				end

				-- comparing lowest equipped item level with reward's item level
				debug('iLVL Comparisson ' .. link .. ' - ' .. QuestItemTrueiLVL .. '-' .. EquipedLevel .. ' - ' .. firstinvLink)

				if (QuestItemTrueiLVL > EquipedLevel) and ((QuestItemTrueiLVL - EquipedLevel) > UpgradeAmmount) then
					UpgradeLink = link
					UpgradeID = i
					UpgradeAmmount = (QuestItemTrueiLVL - EquipedLevel)
				end
			end

			-- Check if it is a weapon, do this last incase it only rewards one item
			if slot[1] == 'MainHandSlot' or slot[1] == 'SecondaryHandSlot' then
				QuestRewardsWeapon = 'weapon'
			elseif slot[1] == 'Trinket0Slot' then
				QuestRewardsWeapon = 'trinket'
			end
		end
	end

	-- If there is more than one reward check that we are allowed to select it.
	if GetNumQuestChoices() > 1 then
		if QuestRewardsWeapon then
			SUI:Print(L['Canceling turn in, quest rewards'] .. ' ' .. QuestRewardsWeapon .. '.')
		elseif DB.lootreward then
			if (GreedID and not UpgradeID) then
				SUI:Print('Grabbing item to vendor ' .. GreedLink .. ' worth ' .. SUI:GoldFormattedValue(GreedValue))
				module:TurnInQuest(GreedID)
			elseif UpgradeID then
				SUI:Print('Upgrade found! Grabbing ' .. UpgradeLink)
				module:TurnInQuest(UpgradeID)
				if DB.autoequip then
					module.equipTimer = module:ScheduleRepeatingTimer('EquipItem', .5, UpgradeLink)
				end
			end
		else
			if (GreedID and not UpgradeID) then
				SUI:Print('Would vendor: ' .. GreedLink .. ' worth ' .. SUI:GoldFormattedValue(GreedValue))
			elseif UpgradeLink then
				SUI:Print('Would select upgrade ' .. UpgradeLink)
			end
		end
	else
		if (GreedID and not UpgradeID) then
			SUI:Print('Quest rewards vendor item ' .. GreedLink .. ' worth ' .. SUI:GoldFormattedValue(GreedValue))
			module:TurnInQuest(GreedID)
		elseif UpgradeID then
			SUI:Print('Quest rewards a upgrade ' .. UpgradeLink)
			module:TurnInQuest(UpgradeID)
			if DB.autoequip then
				module.equipTimer = module:ScheduleRepeatingTimer('EquipItem', .5, UpgradeLink)
			end
		else
			debug(L['No Reward, turning in.'])
			module:TurnInQuest(1)
		end
	end
end

function module:GetItemAmount(isCurrency, item)
	local amount = isCurrency and select(2, GetCurrencyInfo(item)) or GetItemCount(item, nil, true)
	return amount and amount or 0
end

---@param ... GossipQuestUIInfo[]
function module:VarArgForActiveQuests(...)
	debug('VarArgForActiveQuests')
	debug(#...)

	if SUI.IsRetail then
		for i, quest in pairs(...) do
			debug(quest.isComplete)
			debug(quest.frequency)
			debug(quest.title)
			if (quest.isComplete) and (not module:blacklisted(quest.title)) then
				-- if self:isAppropriate(questname, true) then
				local questInfo = Lquests[quest.title]
				debug('selecting.. ' .. quest.title)
				if questInfo then
					if module:GetItemAmount(questInfo.currency, questInfo.item) >= questInfo.amount then
						C_GossipInfo.SelectActiveQuest(i)
					end
				else
					C_GossipInfo.SelectActiveQuest(i)
				end
			-- end
			end
		end
	else
		local INDEX_CONST = 6

		for i = 1, select('#', ...), INDEX_CONST do
			---@diagnostic disable-next-line: redundant-parameter
			local name = select(i * 1, GetGossipActiveQuests(i))
			local isComplete = select(i + 3, ...) -- complete status
			if (isComplete) and (not module:blacklisted(name)) then
				local questname = select(i, ...)
				-- if self:isAppropriate(questname, true) then
				local quest = Lquests[questname]
				if quest then
					if module:GetItemAmount(quest.currency, quest.item) >= quest.amount then
						SelectGossipActiveQuest(math.floor(i / INDEX_CONST) + 1)
					end
				else
					SelectGossipActiveQuest(math.floor(i / INDEX_CONST) + 1)
				end
			-- end
			end
		end
	end
end

-- like previous function this one works around `nil` values in a list.
---@param ... GossipQuestUIInfo[]
function module:VarArgForAvailableQuests(...)
	debug('VarArgForAvailableQuests')
	if SUI.IsRetail then
		debug(#...)
		local INDEX_CONST = 6 -- was '5' in Cataclysm
		for i, quest in pairs(...) do
			local trivialORAllowed = (not quest.isTrivial) or DB.trivial
			local isRepeatableORAllowed = (not quest.repeatable) or DB.AcceptRepeatable

			-- Quest is appropriate if: (it is trivial and trivial are accepted) and (any quest accepted or (it is daily quest that is not in ignore list))
			if (trivialORAllowed and isRepeatableORAllowed) and (not module:blacklisted(quest.title)) then
				local questInfo = Lquests[quest.title]
				if questInfo and questInfo.amount then
					if self:GetItemAmount(questInfo.currency, questInfo.item) >= questInfo.amount then
						C_GossipInfo.SelectAvailableQuest(math.floor(i / INDEX_CONST) + 1)
					end
				else
					C_GossipInfo.SelectAvailableQuest(math.floor(i / INDEX_CONST) + 1)
				end
			end
		end
	else
		local INDEX_CONST = 6 -- was '5' in Cataclysm
		for i = 1, select('#', ...), INDEX_CONST do
			---@diagnostic disable-next-line: redundant-parameter
			local name = select(i * 1, GetGossipAvailableQuests(i))
			local isTrivial = select(i + 2, ...)
			local isDaily = select(i + 3, ...)
			local isRepeatable = select(i + 4, ...)
			local trivialORAllowed = (not isTrivial) or DB.trivial
			local isRepeatableORAllowed = (not isRepeatable or not isDaily) or DB.AcceptRepeatable

			-- Quest is appropriate if: (it is trivial and trivial are accepted) and (any quest accepted or (it is daily quest that is not in ignore list))
			if (trivialORAllowed and isRepeatableORAllowed) and (not module:blacklisted(name)) then
				local questInfo = Lquests[name]
				if questInfo and questInfo.amount then
					if self:GetItemAmount(questInfo.currency, questInfo.item) >= questInfo.amount then
						SelectGossipAvailableQuest(math.floor(i / INDEX_CONST) + 1)
					end
				else
					SelectGossipAvailableQuest(math.floor(i / INDEX_CONST) + 1)
				end
			end
		end
	end
end

function module:FirstLaunch()
	local PageData = {
		ID = 'Autoturnin',
		Name = L['Auto TurnIn'],
		SubTitle = L['Auto TurnIn'],
		Desc1 = L['Automatically accept and turn in quests.'],
		Desc2 = L['Holding ALT while talking to a NPC will temporarily disable the auto turnin module.'],
		RequireDisplay = DB.FirstLaunch,
		Display = function()
			local SUI_Win = SUI.Setup.window.content
			local StdUi = SUI.StdUi

			--Container
			local ATI = CreateFrame('Frame', nil)
			ATI:SetParent(SUI_Win)
			ATI:SetAllPoints(SUI_Win)

			if SUI:IsModuleDisabled('AutoTurnIn') then
				ATI.lblDisabled = StdUi:Label(ATI, 'Disabled', 20)
				ATI.lblDisabled:SetPoint('CENTER', ATI)
			else
				-- Setup checkboxes
				ATI.options = {}
				ATI.options.AcceptGeneralQuests = StdUi:Checkbox(ATI, L['Accept quests'], 220, 20)
				ATI.options.TurnInEnabled = StdUi:Checkbox(ATI, L['Turn in completed quests'], 220, 20)
				ATI.options.AutoGossip = StdUi:Checkbox(ATI, L['Auto gossip'], 220, 20)
				ATI.options.AutoGossipSafeMode = StdUi:Checkbox(ATI, L['Auto gossip safe mode'], 220, 20)
				ATI.options.autoequip =
					StdUi:Checkbox(ATI, L['Auto equip upgrade quest rewards'] .. ' - ' .. L['Based on iLVL'], 400, 20)

				-- Positioning
				StdUi:GlueTop(ATI.options.AcceptGeneralQuests, SUI_Win, -80, -30)
				StdUi:GlueBelow(ATI.options.AutoGossip, ATI.options.AcceptGeneralQuests, 0, -5)
				StdUi:GlueBelow(ATI.options.AutoGossipSafeMode, ATI.options.AutoGossip, 0, -5, 'LEFT')
				StdUi:GlueBelow(ATI.options.autoequip, ATI.options.AutoGossipSafeMode, 0, -5, 'LEFT')

				-- Retail only options
				if SUI.IsRetail then
					ATI.options.lootreward = StdUi:Checkbox(ATI, L['Auto select quest reward'], 220, 20)
					StdUi:GlueBelow(ATI.options.lootreward, ATI.options.TurnInEnabled, 0, -5)
					ATI.options.DoCampainQuests = StdUi:Checkbox(ATI, L['Accept/Complete Campaign Quests'], 220, 20)
					StdUi:GlueBelow(ATI.options.DoCampainQuests, ATI.options.lootreward, 0, -5, 'LEFT')
				end

				StdUi:GlueRight(ATI.options.TurnInEnabled, ATI.options.AcceptGeneralQuests, 5, 0)

				-- Defaults
				for key, object in pairs(ATI.options) do
					object:SetChecked(DB[key])
				end
			end
			SUI_Win.ATI = ATI
		end,
		Next = function()
			if SUI:IsModuleEnabled('AutoTurnIn') then
				local window = SUI.Setup.window
				local ATI = window.content.ATI

				for key, object in pairs(ATI.options) do
					DB[key] = object:GetChecked()
				end
			end
			DB.FirstLaunch = false
		end,
		Skip = function()
			DB.FirstLaunch = false
		end
	}
	SUI.Setup:AddPage(PageData)
end

function module:blacklisted(name)
	name = tostring(name)
	if SUI:IsInTable(DB.GossipBlacklist, name) or SUI:IsInTable(TempBlackList, name) then
		debug(name .. ' - IS BLACKLISTED')
		return true
	end

	for _, key in pairs(DB.WildcardBlackList) do
		if string.find(string.lower(name), string.lower(key)) then
			debug(name .. ' - IS BLACKLISTED')
			return true
		end
	end

	return false
end

function module.QUEST_GREETING()
	local numActiveQuests = GetNumActiveQuests()
	local numAvailableQuests = GetNumAvailableQuests()
	if DB.debug then
		debug('TESTING NEEDED')
		return
	end
	debug(numActiveQuests)
	debug(numAvailableQuests)
	for i = 1, numActiveQuests do
		local isComplete = select(2, GetActiveTitle(i))
		if isComplete then
			SelectActiveQuest(i)
		end
	end

	for i = 1, numAvailableQuests do
		if SUI.IsRetail then
			local isTrivial, frequency, isRepeatable = GetAvailableQuestInfo(i - numActiveQuests)

			local trivialORAllowed = (not isTrivial) or DB.trivial
			local isDaily = (frequency == LE_QUEST_FREQUENCY_DAILY or frequency == LE_QUEST_FREQUENCY_WEEKLY)
			local isRepeatableORAllowed = (not isRepeatable or not isDaily) or DB.AcceptRepeatable

			-- if (trivialORAllowed and isRepeatableORAllowed) and (not module:blacklisted(name)) then
			if (trivialORAllowed and isRepeatableORAllowed) then
				SelectAvailableQuest(i)
			end
		else
			SelectAvailableQuest(i)
		end
	end
end

function module.GOSSIP_SHOW()
	if (not DB.AutoGossip) or (IsAltKeyDown()) then
		return
	end

	module:VarArgForActiveQuests(GetGossipActiveQuests())
	module:VarArgForAvailableQuests(GetGossipAvailableQuests())
	if not SUI.IsRetail then
		return
	end

	local options = GetGossipOptions()
	for k, gossip in pairs(options) do
		debug('------')
		debug(gossip.name)
		debug(gossip.type)
		debug(gossip.rewards)
		debug(gossip.spellID)
		debug(gossip.status)
		debug('------')
		local isWhitelisted = SUI:IsInTable(DB.GossipWhitelist, gossip.name)
		local isBlacklisted = module:blacklisted(gossip.name)
		if
			((gossip.type ~= 'gossip') or (gossip.type == 'gossip' and gossip.status == 0)) and
				(not isBlacklisted or isWhitelisted) and
				SUI.IsRetail
		 then
			-- If we are in safemode and gossip option flagged as 'QUEST' then exit
			if (DB.AutoGossipSafeMode and (not string.find(string.lower(gossip.type), 'quest'))) and not isWhitelisted then
				debug(string.format('Safe mode active not selection gossip option "%s"', gossip.name))
				return
			end
			TempBlackList[gossip.name] = true
			local opcount = GetNumGossipOptions()
			SelectGossipOption((opcount == 1) and 1 or math.floor(k / GetNumGossipOptions()) + 1)
			if DB.ChatText then
				SUI:Print('Selecting: ' .. gossip.name)
			end
			TempBlackList[gossip.name] = true
			debug(gossip.name .. '---BLACKLISTED')
			return
		end
	end

	module:VarArgForActiveQuests(GetGossipActiveQuests())
	module:VarArgForAvailableQuests(GetGossipAvailableQuests())
end

function module.QUEST_PROGRESS()
	if IsQuestCompletable() and DB.TurnInEnabled and (not module:blacklisted(GetTitleText())) then
		CompleteQuest()
	end
end

function module:OnInitialize()
	module.Database = SUI.SpartanUIDB:RegisterNamespace('AutoTurnIn', {profile = DBDefaults})
	DB = module.Database.profile

	-- Migrate old settings
	if SUI.DB.AutoTurnIn then
		debug('Auto turn in DB Migration')
		DB = SUI:MergeData(DB, SUI.DB.AutoTurnIn, true)
		SUI.DB.AutoTurnIn = nil
	end
end

function module:OnEnable()
	module:BuildOptions()
	module:FirstLaunch()
	local lastEvent = ''

	local function OnEvent(_, event)
		if SUI.DB.DisabledComponents.AutoTurnIn then
			return
		end

		debug(event)
		lastEvent = event

		if SUI.IsRetail then
			local QuestID = GetQuestID()
			local CampaignId = C_CampaignInfo.GetCampaignID(QuestID)
			if
				C_CampaignInfo.IsCampaignQuest(QuestID) and not DB.DoCampainQuests and
					C_CampaignInfo.GetCurrentChapterID(CampaignId) ~= nil
			 then
				debug(C_CampaignInfo.GetCampaignChapterInfo(C_CampaignInfo.GetCampaignID(GetQuestID())).name)
				debug(C_CampaignInfo.GetCurrentChapterID(CampaignId))

				SUI:Print(L['Current quest is a campaign quest, pausing AutoTurnIn'])
				return
			end
		end

		if IsAltKeyDown() then
			SUI:Print('Canceling Override key held disabled')
			module:CancelAllTimers()
			return
		end

		if module[event] then
			module[event]()
		end
	end

	ATI_Container:SetScript('OnEvent', OnEvent)
	ATI_Container:RegisterEvent('GOSSIP_SHOW') -- multiple quests, and NPC chat screen
	ATI_Container:RegisterEvent('QUEST_DETAIL') -- new quest screen
	ATI_Container:RegisterEvent('QUEST_GREETING')
	ATI_Container:RegisterEvent('QUEST_PROGRESS')
	ATI_Container:RegisterEvent('QUEST_COMPLETE') -- quest turn in screen
	ATI_Container:RegisterEvent('MERCHANT_SHOW')
	ATI_Container:RegisterEvent('MERCHANT_CLOSED')

	local IsCollapsed = true

	if SUI.IsRetail and SUI:IsModuleEnabled(module) then
		for _, v in ipairs({'QuestFrame', 'GossipFrame'}) do
			local OptionsPopdown = StdUi:Panel(_G[v], 330, 20)
			OptionsPopdown:SetScale(.95)
			OptionsPopdown:SetPoint('TOP', _G[v], 'BOTTOM', 0, -2)
			OptionsPopdown.title = StdUi:Label(OptionsPopdown, '|cffffffffSpartan|cffe21f1fUI|r AutoTurnIn', 12)
			OptionsPopdown.title:SetPoint('CENTER')

			-- OptionsPopdown.CloseButton = StdUi:Button(OptionsPopdown, 15, 15, 'X')
			OptionsPopdown.minimizeButton = StdUi:Button(OptionsPopdown, 15, 15, '-')

			StdUi:GlueRight(OptionsPopdown.minimizeButton, OptionsPopdown, -5, 0, true)
			-- StdUi:GlueRight(OptionsPopdown.CloseButton, OptionsPopdown, -5, 0, true)
			-- StdUi:GlueLeft(OptionsPopdown.minimizeButton, OptionsPopdown.CloseButton, -2, 0)

			OptionsPopdown.minimizeButton:SetScript(
				'OnClick',
				function()
					if OptionsPopdown.Panel:IsVisible() then
						OptionsPopdown.Panel:Hide()
						IsCollapsed = true
					else
						OptionsPopdown.Panel:Show()
						IsCollapsed = false
					end
				end
			)
			OptionsPopdown:HookScript(
				'OnShow',
				function()
					if IsCollapsed then
						OptionsPopdown.Panel:Hide()
					else
						OptionsPopdown.Panel:Show()
					end
				end
			)

			local Panel = StdUi:Panel(OptionsPopdown, OptionsPopdown:GetWidth(), 62)
			Panel:SetPoint('TOP', OptionsPopdown, 'BOTTOM', 0, -1)
			Panel:Hide()
			local options = {}
			options.DoCampainQuests = StdUi:Checkbox(Panel, L['Accept/Complete Campaign Quests'], nil, 20)
			options.AcceptGeneralQuests = StdUi:Checkbox(Panel, L['Accept quests'], nil, 20)
			options.TurnInEnabled = StdUi:Checkbox(Panel, L['Turn in completed quests'], nil, 20)
			options.AutoGossip = StdUi:Checkbox(Panel, L['Auto gossip'], nil, 20)
			options.AutoGossipSafeMode = StdUi:Checkbox(Panel, L['Auto gossip safe mode'], nil, 20)
			for setting, Checkbox in pairs(options) do
				Checkbox:SetChecked(DB[setting])
				Checkbox:HookScript(
					'OnClick',
					function()
						DB[setting] = Checkbox:GetChecked()
						if Checkbox:GetChecked() then
							OnEvent(nil, lastEvent)
						end
					end
				)
			end

			StdUi:GlueTop(options.DoCampainQuests, Panel, 5, -2, 'LEFT')

			StdUi:GlueBelow(options.AcceptGeneralQuests, options.DoCampainQuests, 0, 2, 'LEFT')
			StdUi:GlueRight(options.TurnInEnabled, options.AcceptGeneralQuests, 0, 0)

			StdUi:GlueBelow(options.AutoGossip, options.AcceptGeneralQuests, 0, 2, 'LEFT')
			StdUi:GlueRight(options.AutoGossipSafeMode, options.AutoGossip, 0, 0)

			OptionsPopdown.Panel = Panel
			OptionsPopdown.Panel.options = options
		end
	end
end

function module:OnDisable()
	ATI_Container:UnregisterEvent('GOSSIP_SHOW') -- multiple quests, and NPC chat screen
	ATI_Container:UnregisterEvent('QUEST_DETAIL') -- new quest screen
	ATI_Container:UnregisterEvent('QUEST_GREETING')
	ATI_Container:UnregisterEvent('QUEST_PROGRESS')
	ATI_Container:UnregisterEvent('QUEST_COMPLETE') -- quest turn in screen
	ATI_Container:UnregisterEvent('MERCHANT_SHOW')
	ATI_Container:UnregisterEvent('MERCHANT_CLOSED')
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['AutoTurnIn'] = {
		type = 'group',
		name = L['Auto TurnIn'],
		get = function(info)
			return DB[info[#info]]
		end,
		set = function(info, val)
			DB[info[#info]] = val
		end,
		args = {
			DoCampainQuests = {
				name = L['Accept/Complete Campaign Quests'],
				type = 'toggle',
				width = 'double',
				order = 1
			},
			QuestAccepting = {
				name = L['Quest accepting'],
				type = 'group',
				inline = true,
				order = 10,
				width = 'full',
				get = function(info)
					return DB[info[#info]]
				end,
				set = function(info, val)
					DB[info[#info]] = val
				end,
				args = {
					AcceptGeneralQuests = {
						name = L['Accept quests'],
						type = 'toggle',
						order = 10
					},
					trivial = {
						name = L['Accept trivial quests'],
						type = 'toggle',
						order = 20
					},
					AcceptRepeatable = {
						name = L['Accept repeatable'],
						type = 'toggle',
						order = 30
					},
					AutoGossip = {
						name = L['Auto gossip'],
						type = 'toggle',
						order = 15
					},
					AutoGossipSafeMode = {
						name = L['Auto gossip safe mode'],
						type = 'toggle',
						order = 16
					}
				}
			},
			QuestTurnIn = {
				name = L['Quest turn in'],
				type = 'group',
				inline = true,
				order = 20,
				width = 'full',
				get = function(info)
					return DB[info[#info]]
				end,
				set = function(info, val)
					DB[info[#info]] = val
				end,
				args = {
					TurnInEnabled = {
						name = L['Turn in completed quests'],
						type = 'toggle',
						order = 10
					},
					lootreward = {
						name = L['Auto select quest reward'],
						type = 'toggle',
						order = 30
					},
					autoequip = {
						name = L['Auto equip upgrade quest rewards'],
						desc = L['Based on iLVL'],
						type = 'toggle',
						order = 30
					}
				}
			},
			ChatText = {
				name = L['Output quest text in chat'],
				type = 'toggle',
				width = 'double',
				order = 30
			},
			debug = {
				name = L['Debug mode'],
				type = 'toggle',
				width = 'full',
				order = 900
			}
		}
	}
	if SUI.IsClassic then
		SUI.opt.args.ModSetting.args.AutoTurnIn.args.QuestTurnIn.args.AutoSelectLoot.hidden = true
		SUI.opt.args.ModSetting.args.AutoTurnIn.args.QuestTurnIn.args.autoequip.hidden = true

		SUI.opt.args.ModSetting.args.AutoTurnIn.args.QuestAccepting.args.trivial.hidden = true
		SUI.opt.args.ModSetting.args.AutoTurnIn.args.QuestAccepting.args.AcceptRepeatable.hidden = true
	end
end
