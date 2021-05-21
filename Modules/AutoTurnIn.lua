local SUI, L, print = SUI, SUI.L, SUI.print
local module = SUI:NewModule('Component_AutoTurnIn', 'AceTimer-3.0')
module.DisplayName = L['Auto turn in']
module.description = 'Auto accept and turn in quests'
----------------------------------------------------------------------------------------------------
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
local WildcardBlackList = {
	['wartime donation'] = true,
	['work order'] = true,
	['supplies needed'] = true,
	['taxi'] = true,
	['trade'] = true,
	['train'] = true,
	['repeat'] = true,
	['buy'] = true,
	['browse your'] = true,
	['my home'] = true,
	['reinforcements'] = true,
	['Set sail'] = true,
	['drustvar'] = true,
	['stormsong valley'] = true,
	['tiragarde sound'] = true,
	['tell me about the'] = true,
	['like to change'] = true,
	['goods'] = true,
	['take us back'] = true,
	['take me back'] = true,
	['and listen'] = true,
	['where I can fly'] = true,
	['seal of wartorn'] = true
}
local BlackList = {
	-- General Blacklist
	['i wish to buy from you.'] = true,
	['i would like to buy from you.'] = true,
	['make this inn your home.'] = true,
	["i'd like to heal and revive my battle pets."] = true,
	['let me browse your goods.'] = true,
	["i'm looking for a lost companion."] = true,
	['i need a ride to the top of the statue.'] = true,
	['show me what you have available.'] = true,
	['flight master'] = true,
	['guild master & vendor'] = true,
	['void storage'] = true,
	['auction house'] = true,
	['stable master'] = true,
	['zeppelin master'] = true,
	['other continents'] = true,
	["officer's lounge"] = true,
	['transmogrification'] = true,
	['i want to transmogrify my gear.'] = true,
	-- wotlk blacklist
	['i am prepared to face saragosa!'] = true,
	['what is the cause of this conflict?'] = true,
	['can you spare a drake to take me to lord afrasastrasz in the middle of the temple?'] = true,
	['i must return to the world of shadows, koltira. send me back.'] = true,
	['i am ready to be teleported to dalaran.'] = true,
	['can i get a ride back to ground level, lord afrasastrasz?'] = true,
	['i would like to go to lord afrasastrasz in the middle of the temple.'] = true,
	['my lord, i need to get to the top of the temple.'] = true,
	['yes, please, i would like to return to the ground level of the temple.'] = true,
	["steward, please allow me to ride one of the drakes to the queen's chamber at the top of the temple."] = true,
	['i want to exchange my ruby essence for amber essence.'] = true,
	['what abilities do ruby drakes have?'] = true,
	['i want to fly on the wings of the bronze flight.'] = true,
	['i want to fly on the wings of the red flight.'] = true,
	['i want to exchange my ruby essence for emerald essence.'] = true,
	['what abilities do emerald drakes have?'] = true,
	['i want to fly on the wings of the green flight.'] = true,
	['i want to exchange my amber essence for ruby essence.'] = true,
	['what abilities do amber drakes have?'] = true,
	['i am ready.'] = true, -- this one is used alot but blacklisted due to trial of the champion
	["i am ready.  however, i'd like to skip the pageantry."] = true,
	-- mop
	["i'm ready to be introduced to the instructors, high elder."] = true,
	["fine. let's proceed with the introductions."] = true,
	['what is this place?'] = true,
	-- legion
	['your people treat you with contempt. why? what did you do?'] = true,
	-- bfa
	["yes, i'm ready to go to drustvar."] = true,
	['warchief, may i ask why we want to capture teldrassil?'] = true,
	['i am ready to go to the undercity.'] = true,
	["i've heard this tale before... <skip the scenario and begin your next mission.>"] = true,
	['release me.'] = true
}

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

-- turns quest in printing reward text if `ChatText` option is set.
-- prints appropriate message if item is taken by greed
-- equips received reward if such option selected
function module:TurnInQuest(rewardIndex)
	if (module.DB.ChatText) then
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
	if (module.DB.AcceptGeneralQuests) then
		QuestInfoDescriptionText:SetAlphaGradient(0, -1)
		QuestInfoDescriptionText:SetAlpha(1)

		if module.DB.ChatText then
			local title = GetTitleText()
			local objText = GetObjectiveText()
			if title and title ~= '' then
				SUI:Print(objText)
			end
			if objText and objText ~= '' then
				SUI:Print(L['Quest Objectives'])
				print('    ' .. objText)
			end
		end
		if (not IsAltKeyDown()) then
			AcceptQuest()
		end
	end
end

function module.QUEST_COMPLETE()
	if not module.DB.TurnInEnabled then
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
		local itemName, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc, _, itemSellPrice = GetItemInfo(link)
		local QuestItemTrueiLVL = SUI:GetiLVL(link, itemQuality, itemLevel)

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
					if (invLink) then
						local eq2Level = SUI:GetiLVL(invLink)
						if (EquipedLevel > eq2Level) then
							if (module.DB.debug) then
								print('Slot ' .. #slot .. ' is lower (' .. EquipedLevel .. '>' .. eq2Level .. ')')
							end
							firstSlot = secondSlot
							EquipedLevel = eq2Level
							firstinvLink = secondinvLink
						end
					end
				end

				-- comparing lowest equipped item level with reward's item level
				if (module.DB.debug) then
					print('iLVL Comparisson ' .. link .. ' - ' .. QuestItemTrueiLVL .. '-' .. EquipedLevel .. ' - ' .. firstinvLink)
				end

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
		elseif module.DB.lootreward then
			if (GreedID and not UpgradeID) then
				SUI:Print('Grabbing item to vendor ' .. GreedLink .. ' worth ' .. SUI:GoldFormattedValue(GreedValue))
				if not module.DB.debug then
					module:TurnInQuest(GreedID)
				end
			elseif UpgradeID then
				SUI:Print('Upgrade found! Grabbing ' .. UpgradeLink)
				if not module.DB.debug then
					module:TurnInQuest(UpgradeID)
					if module.DB.autoequip then
						module.equipTimer = module:ScheduleRepeatingTimer('EquipItem', .5, UpgradeLink)
					end
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
			if module.DB.autoequip then
				module.equipTimer = module:ScheduleRepeatingTimer('EquipItem', .5, UpgradeLink)
			end
		else
			if (module.DB.debug) then
				SUI:Print(L['No Reward, turning in.'])
			end
			module:TurnInQuest(1)
		end
	end
end

function module:GetItemAmount(isCurrency, item)
	local amount = isCurrency and select(2, GetCurrencyInfo(item)) or GetItemCount(item, nil, true)
	return amount and amount or 0
end

function module:VarArgForActiveQuests(...)
	if module.DB.debug then
		print('VarArgForActiveQuests')
	end
	local INDEX_CONST = 6

	for i = 1, select('#', ...), INDEX_CONST do
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

-- like previous function this one works around `nil` values in a list.
function module:VarArgForAvailableQuests(...)
	if module.DB.debug then
		print('VarArgForAvailableQuests')
	end
	local INDEX_CONST = 6 -- was '5' in Cataclysm
	for i = 1, select('#', ...), INDEX_CONST do
		local name = select(i * 1, GetGossipAvailableQuests(i))
		local isTrivial = select(i + 2, ...)
		local isDaily = select(i + 3, ...)
		local isRepeatable = select(i + 4, ...)
		local trivialORAllowed = (not isTrivial) or module.DB.trivial
		local isRepeatableORAllowed = (not isRepeatable or not isDaily) or module.DB.AcceptRepeatable

		-- Quest is appropriate if: (it is trivial and trivial are accepted) and (any quest accepted or (it is daily quest that is not in ignore list))
		if (trivialORAllowed and isRepeatableORAllowed) and (not module:blacklisted(name)) then
			if quest and quest.amount then
				if self:GetItemAmount(quest.currency, quest.item) >= quest.amount then
					SelectGossipAvailableQuest(math.floor(i / INDEX_CONST) + 1)
				end
			else
				SelectGossipAvailableQuest(math.floor(i / INDEX_CONST) + 1)
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
		RequireDisplay = module.DB.FirstLaunch,
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi

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
				end

				StdUi:GlueRight(ATI.options.TurnInEnabled, ATI.options.AcceptGeneralQuests, 5, 0)

				-- Defaults
				for key, object in pairs(ATI.options) do
					object:SetChecked(module.DB[key])
				end
			end
			SUI_Win.ATI = ATI
		end,
		Next = function()
			if SUI:IsModuleEnabled('AutoTurnIn') then
				local window = SUI:GetModule('SetupWizard').window
				local ATI = window.content.ATI

				for key, object in pairs(ATI.options) do
					module.DB[key] = object:GetChecked()
				end
			end
			module.DB.FirstLaunch = false
		end,
		Skip = function()
			module.DB.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end

function module:blacklisted(name)
	name = tostring(name)
	if BlackList[name] then
		if module.DB.debug then
			print(name .. ' - IS BLACKLISTED')
		end
		return true
	end

	for k2, _ in pairs(WildcardBlackList) do
		if string.find(string.lower(name), string.lower(k2)) then
			if module.DB.debug then
				print(name .. ' - IS BLACKLISTED')
			end
			return true
		end
	end

	return false
end

function module.QUEST_GREETING()
	local numActiveQuests = GetNumActiveQuests()
	local numAvailableQuests = GetNumAvailableQuests()

	for i = 1, numActiveQuests do
		local isComplete = select(2, GetActiveTitle(i))
		if isComplete then
			SelectActiveQuest(i)
		end
	end

	for i = 1, numAvailableQuests do
		if SUI.IsRetail then
			local isTrivial, frequency, isRepeatable = GetAvailableQuestInfo(i - numActiveQuests)

			local trivialORAllowed = (not isTrivial) or module.DB.trivial
			local isDaily = (frequency == LE_QUEST_FREQUENCY_DAILY or frequency == LE_QUEST_FREQUENCY_WEEKLY)
			local isRepeatableORAllowed = (not isRepeatable or not isDaily) or module.DB.AcceptRepeatable

			if (trivialORAllowed and isRepeatableORAllowed) and (not module:blacklisted(name)) then
				SelectAvailableQuest(i)
			end
		else
			SelectAvailableQuest(i)
		end
	end
end

function module.GOSSIP_SHOW()
	if (not module.DB.AutoGossip) or (IsAltKeyDown()) or (SUI.IsRetail) then
		return
	end

	module:VarArgForActiveQuests(GetGossipActiveQuests())
	module:VarArgForAvailableQuests(GetGossipAvailableQuests())

	local options = {GetGossipOptions()}
	if #options > 7 then
		if module.DB.debug then
			print('Too many gossip options (' .. #options .. ')')
		end
		return
	end
	for k, v in pairs(options) do
		if (v ~= 'gossip') and (not module:blacklisted(v)) and string.find(v, ' ') then
			-- If we are in safemode and gossip option flagged as 'QUEST' then exit
			if module.DB.AutoGossipSafeMode and (not string.find(string.lower(v), 'quest')) then
				return
			end
			BlackList[v] = true
			local opcount = GetNumGossipOptions()
			SelectGossipOption((opcount == 1) and 1 or math.floor(k / GetNumGossipOptions()) + 1)
			if module.DB.ChatText then
				SUI:Print('Selecting: ' .. v)
			end
			if module.DB.debug then
				module.DB.Blacklist[v] = true
				print(v .. '---BLACKLISTED')
			end
			return
		end
	end

	module:VarArgForActiveQuests(GetGossipActiveQuests())
	module:VarArgForAvailableQuests(GetGossipAvailableQuests())
end

function module.QUEST_PROGRESS()
	if IsQuestCompletable() and module.DB.TurnInEnabled and (not module:blacklisted(GetTitleText())) then
		CompleteQuest()
	end
end

function module:OnInitialize()
	local defaults = {
		profile = {
			ChatText = true,
			FirstLaunch = true,
			debug = false,
			TurnInEnabled = true,
			AutoGossip = true,
			AutoGossipSafeMode = true,
			AcceptGeneralQuests = true,
			AcceptRepeatable = false,
			trivial = false,
			lootreward = false,
			autoequip = false,
			armor = {},
			weapon = {},
			stat = {},
			secondary = {},
			Blacklist = {}
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('AutoTurnIn', defaults)
	module.DB = module.Database.profile

	-- Migrate old settings
	if SUI.DB.AutoTurnIn then
		print('Auto turn in DB Migration')
		module.DB = SUI:MergeData(module.DB, SUI.DB.AutoTurnIn, true)
		SUI.DB.AutoTurnIn = nil
	end
end

function module:OnEnable()
	module:BuildOptions()
	module:FirstLaunch()

	ATI_Container:SetScript(
		'OnEvent',
		function(_, event)
			if SUI.DB.DisabledComponents.AutoTurnIn then
				return
			end

			if module.DB.debug then
				print(event)
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
	)
	ATI_Container:RegisterEvent('GOSSIP_SHOW') -- multiple quests, and NPC chat screen
	ATI_Container:RegisterEvent('QUEST_DETAIL') -- new quest screen
	ATI_Container:RegisterEvent('QUEST_GREETING')
	ATI_Container:RegisterEvent('QUEST_PROGRESS')
	ATI_Container:RegisterEvent('QUEST_COMPLETE') -- quest turn in screen
	ATI_Container:RegisterEvent('MERCHANT_SHOW')
	ATI_Container:RegisterEvent('MERCHANT_CLOSED')
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
		args = {
			QuestAccepting = {
				name = L['Quest accepting'],
				type = 'group',
				inline = true,
				order = 10,
				width = 'full',
				args = {
					AcceptGeneralQuests = {
						name = L['Accept quests'],
						type = 'toggle',
						order = 10,
						get = function(info)
							return module.DB.AcceptGeneralQuests
						end,
						set = function(info, val)
							module.DB.AcceptGeneralQuests = val
						end
					},
					trivial = {
						name = L['Accept trivial quests'],
						type = 'toggle',
						order = 20,
						get = function(info)
							return module.DB.trivial
						end,
						set = function(info, val)
							module.DB.trivial = val
						end
					},
					AcceptRepeatable = {
						name = L['Accept repeatable'],
						type = 'toggle',
						order = 30,
						get = function(info)
							return module.DB.AcceptRepeatable
						end,
						set = function(info, val)
							module.DB.AcceptRepeatable = val
						end
					},
					AutoGossip = {
						name = L['Auto gossip'],
						type = 'toggle',
						order = 15,
						get = function(info)
							return module.DB.AutoGossip
						end,
						set = function(info, val)
							module.DB.AutoGossip = val
						end
					},
					AutoGossipMode = {
						name = L['Auto gossip safe mode'],
						type = 'toggle',
						order = 16,
						get = function(info)
							return module.DB.AutoGossipSafeMode
						end,
						set = function(info, val)
							module.DB.AutoGossipSafeMode = val
						end
					}
				}
			},
			QuestTurnIn = {
				name = L['Quest turn in'],
				type = 'group',
				inline = true,
				order = 20,
				width = 'full',
				args = {
					TurnInEnabled = {
						name = L['Turn in completed quests'],
						type = 'toggle',
						order = 10,
						get = function(info)
							return module.DB.TurnInEnabled
						end,
						set = function(info, val)
							module.DB.TurnInEnabled = val
						end
					},
					AutoSelectLoot = {
						name = L['Auto select quest reward'],
						type = 'toggle',
						order = 30,
						get = function(info)
							return module.DB.lootreward
						end,
						set = function(info, val)
							module.DB.lootreward = val
						end
					},
					autoequip = {
						name = L['Auto equip upgrade quest rewards'],
						desc = L['Based on iLVL'],
						type = 'toggle',
						order = 30,
						get = function(info)
							return module.DB.autoequip
						end,
						set = function(info, val)
							module.DB.autoequip = val
						end
					}
				}
			},
			ChatText = {
				name = L['Output quest text in chat'],
				type = 'toggle',
				width = 'double',
				order = 30,
				get = function(info)
					return module.DB.ChatText
				end,
				set = function(info, val)
					module.DB.ChatText = val
				end
			},
			debugMode = {
				name = L['Debug mode'],
				type = 'toggle',
				width = 'full',
				order = 900,
				get = function(info)
					return module.DB.debug
				end,
				set = function(info, val)
					module.DB.debug = val
				end
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
