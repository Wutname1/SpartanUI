local SUI = SUI
local module = SUI:NewModule('Component_AutoTurnIn', 'AceTimer-3.0')
local L = SUI.L
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
local BlackList = {
	-- General Blacklist
	['I would like to buy from you.'] = true,
	['Make this inn your home.'] = true,
	["I'd like to heal and revive my battle pets."] = true,
	['Let me browse your goods.'] = true,
	['vendor'] = true,
	['binder'] = true,
	["I'm looking for a lost companion."] = true,
	['I need a ride to the top of the statue.'] = true,
	['Inn'] = true,
	['gossip'] = true,
	['Show me what you have available.'] = true,
	['Flight Master'] = true,
	['Guild Master & Vendor'] = true,
	['Void Storage'] = true,
	['Auction House'] = true,
	['Stable Master'] = true,
	['Zeppelin Master'] = true,
	['Battlemasters'] = true,
	['Barber'] = true,
	['Bank'] = true,
	['Other Continents'] = true,
	["Officer's Lounge"] = true,
	['Transmogrification'] = true,
	['I want to transmogrify my gear.'] = true,
	['transmogrify'] = true,
	-- WOTLK Blacklist
	['I am prepared to face Saragosa!'] = true,
	['What is the cause of this conflict?'] = true,
	['Can you spare a drake to take me to Lord Afrasastrasz in the middle of the temple?'] = true,
	['I must return to the world of shadows, Koltira. Send me back.'] = true,
	['I am ready to be teleported to Dalaran.'] = true,
	['Can I get a ride back to ground level, Lord Afrasastrasz?'] = true,
	['I would like to go to Lord Afrasastrasz in the middle of the temple.'] = true,
	['My lord, I need to get to the top of the temple.'] = true,
	['Yes, please, I would like to return to the ground level of the temple.'] = true,
	["Steward, please allow me to ride one of the drakes to the queen's chamber at the top of the temple."] = true,
	['I want to exchange my Ruby Essence for Amber Essence.'] = true,
	['What abilities do ruby drakes have?'] = true,
	['I want to fly on the wings of the bronze flight.'] = true,
	['I want to fly on the wings of the red flight.'] = true,
	['I want to exchange my Ruby Essence for Emerald Essence.'] = true,
	['What abilities do emerald drakes have?'] = true,
	['I want to fly on the wings of the green flight.'] = true,
	['I want to exchange my Amber Essence for Ruby Essence.'] = true,
	['What abilities do amber drakes have?'] = true,
	['I am ready.'] = true, -- This one is used alot but blacklisted due to trial of the champion
	["I am ready.  However, I'd like to skip the pageantry."] = true,
	-- MOP
	["I'm ready to be introduced to the instructors, High Elder."] = true,
	["Fine. Let's proceed with the introductions."] = true,
	['What is this place?'] = true,
	-- Legion
	['Your people treat you with contempt. Why? What did you do?'] = true,
	-- BFA
	['Warchief, may I ask why we want to capture Teldrassil?'] = true,
	['I am ready to go to the Undercity.'] = true,
	["I've heard this tale before... <Skip the scenario and begin your next mission.>"] = true
}
local anchor, scanningTooltip
local itemLevelPattern = _G.ITEM_LEVEL:gsub('%%d', '(%%d+)')

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

local function ScanTip(itemLink)
	-- Setup the scanning tooltip
	-- Why do this here and not in OnEnable? If the player is not questing there is no need for this to exsist.
	if not scanningTooltip then
		anchor = CreateFrame('Frame')
		anchor:Hide()
		scanningTooltip = _G.CreateFrame('GameTooltip', 'LibItemUpgradeInfoTooltip', nil, 'GameTooltipTemplate')
	end
	GameTooltip_SetDefaultAnchor(scanningTooltip, anchor)

	-- If the item is not in the cache populate it.
	if type(itemCache[itemLink].ilevel) == 'nil' then
		-- Load tooltip
		local itemString = itemLink:match('|H(.-)|h')
		local rc = pcall(scanningTooltip.SetHyperlink, scanningTooltip, itemString)
		if (not rc) then
			return 0
		end
		scanningTooltip:Show()

		-- Initalize the cache
		itemCache[itemLink] = {
			ilevel = nil
		}
		-- Find the iLVL inthe tooltip
		for i = 2, 6 do
			local label, text = _G['ItemUpgradeTooltipTextLeft' .. i], nil
			if label then
				text = label:GetText()
			end
			if text then
				if itemCache[itemLink].ilevel == nil then
					itemCache[itemLink].ilevel = tonumber(text:match(itemLevelPattern))
				end
			end
		end

		print('Figure out what to cache and what to return as the ilvl')
		-- Figure out what to cache and what to return as the ilvl
		itemCache[itemLink].ilevel = itemCache[itemLink].ilevel or 0
		itemLevel = GetDetailedItemLevelInfo(itemLink)
		if type(itemCache[itemLink].ilevel) == 'number' then
			itemCache[itemLink].ilevel = math.max(itemCache[itemLink].ilevel, 0)
		else
			itemCache[itemLink].ilevel = itemLevel
		end
		print(itemCache[itemLink].ilevel)

		-- Hide the scanning tooltip
		scanningTooltip:Hide()
	end
	-- return the ilvl
	return itemCache[itemLink].ilevel
end

function module:GetiLVL(itemLink)
	if not itemLink then
		return 0
	end

	local itemQuality, itemLevel = select(3, GetItemInfo(itemLink))

	-- if a heirloom return a huge number so we dont replace it.
	if (itemQuality == 7) then
		return math.huge
	end

	-- Scan the tooltip, itemLevel is a fallback incase tooltip does not contain the data
	local effectiveILvl = GetDetailedItemLevelInfo(itemLink)
	return (effectiveILvl or itemLevel)
end

-- turns quest in printing reward text if `showrewardtext` option is set.
-- prints appropriate message if item is taken by greed
-- equips received reward if such option selected
function module:TurnInQuest(rewardIndex)
	if (SUI.DB.AutoTurnIn.showrewardtext) then
		SUI:Print((UnitName('target') and UnitName('target') or '') .. '\n', GetRewardText())
	end
	if IsAltKeyDown() then
		SUI:Print('Canceling loot selection')
		module:CancelAllTimers()
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
	if (SUI.DB.AutoTurnIn.AcceptGeneralQuests) and (not IsAltKeyDown()) then
		QuestInfoDescriptionText:SetAlphaGradient(0, -1)
		QuestInfoDescriptionText:SetAlpha(1)
		AcceptQuest()
	end
end

function module.QUEST_COMPLETE()
	if not SUI.DB.AutoTurnIn.TurnInEnabled then
		return
	end

	-- Look for the item that is the best upgrade and whats worth the most.
	local GreedID, GreedValue, UpgradeID = nil, 0, nil
	local GreedLink, UpgradeLink = nil, nil
	for i = 1, GetNumQuestChoices() do
		-- Load the items information
		local link = GetQuestItemLink('choice', i)
		if (link == nil) then
			return
		end
		local itemName, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc, _, itemSellPrice = GetItemInfo(link)
		local QuestItemTrueiLVL = module:GetiLVL(link, itemQuality, itemLevel)

		-- Check the items value
		if itemSellPrice > GreedValue then
			GreedValue = itemSellPrice
			GreedID = i
			GreedLink = link
		end

		-- See if the item is an upgrade
		if (SUI.DB.AutoTurnIn.autoequip) then
			-- Compares reward and already equipped item levels. If reward ilevel is greater than equipped item, auto equip reward
			local slot = SLOTS[itemEquipLoc]
			if (slot) then
				local firstSlot = GetInventorySlotInfo(slot[1])
				local invLink = GetInventoryItemLink('player', firstSlot)
				local EquipedLevel = module:GetiLVL(invLink)

				if EquipedLevel then
					-- If reward is a ring, trinket or one-handed weapons all slots must be checked in order to swap with a lesser ilevel
					if (#slot > 1) then
						local secondSlot = GetInventorySlotInfo(slot[2])
						invLink = GetInventoryItemLink('player', secondSlot)
						if (invLink) then
							local eq2Level = module:GetiLVL(invLink)
							firstSlot = (EquipedLevel > eq2Level) and secondSlot or firstSlot
							EquipedLevel = (EquipedLevel > eq2Level) and eq2Level or EquipedLevel
						end
					end

					-- comparing lowest equipped item level with reward's item level
					if (SUI.DB.AutoTurnIn.debug) then
						print('iLVL Comparisson ' .. QuestItemTrueiLVL .. '-' .. EquipedLevel)
					end
					if (QuestItemTrueiLVL > EquipedLevel) then
						UpgradeLink = link
						UpgradeID = i
					end
				end
			end
		end
	end

	-- If there is more than one reward check that we are allowed to select it.
	if GetNumQuestChoices() > 1 then
		if SUI.DB.AutoTurnIn.lootreward then
			if (GreedID and not UpgradeID) then
				SUI:Print('Grabbing item to vendor ' .. GreedLink .. ' worth ' .. SUI:GoldFormattedValue(GreedValue))
				module:TurnInQuest(GreedID)
			elseif UpgradeID then
				SUI:Print('Upgrade found! Grabbing ' .. UpgradeLink)
				module:TurnInQuest(UpgradeID)
				module.equipTimer = module:ScheduleRepeatingTimer('EquipItem', .5, UpgradeLink)
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
			module.equipTimer = module:ScheduleRepeatingTimer('EquipItem', .5, UpgradeLink)
		else
			if (SUI.DB.AutoTurnIn.debug) then
				SUI:Print('No Reward, turning in.')
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
	if SUI.DB.AutoTurnIn.debug then
		print('VarArgForActiveQuests')
	end
	local INDEX_CONST = 6

	for i = 1, select('#', ...), INDEX_CONST do
		local isComplete = select(i + 3, ...) -- complete status
		if (isComplete) then
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
	if SUI.DB.AutoTurnIn.debug then
		print('VarArgForAvailableQuests')
	end
	local INDEX_CONST = 6 -- was '5' in Cataclysm
	for i = 1, select('#', ...), INDEX_CONST do
		local isTrivial = select(i + 2, ...)
		local isDaily = select(i + 3, ...)
		local isRepeatable = select(i + 4, ...)
		local trivialORAllowed = (not isTrivial) or SUI.DB.AutoTurnIn.trivial
		local isRepeatableORAllowed = (not isRepeatable or not isDaily) or SUI.DB.AutoTurnIn.AcceptRepeatable

		-- Quest is appropriate if: (it is trivial and trivial are accepted) and (any quest accepted or (it is daily quest that is not in ignore list))
		if (trivialORAllowed and isRepeatableORAllowed) then
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
		Name = 'Auto turn in',
		SubTitle = 'Auto turn in',
		Desc1 = 'Automatically accept and turn in quests.',
		Desc2 = 'Holding Alt while talking to a NPC will disable turn in & accepting quests. Holding Control will disable auto gossip.',
		RequireDisplay = SUI.DB.AutoTurnIn.FirstLaunch,
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi
			if not SUI.DB.EnabledComponents.AutoTurnIn then
				window.Skip:Click()
			end

			--Container
			local ATI = CreateFrame('Frame', nil)
			ATI:SetParent(SUI_Win)
			ATI:SetAllPoints(SUI_Win)

			-- Setup checkboxes
			ATI.options = {}
			ATI.options.AcceptGeneralQuests = StdUi:Checkbox(ATI, 'Accept quests', 220, 20)
			ATI.options.TurnInEnabled = StdUi:Checkbox(ATI, 'Enable turning in quests', 220, 20)
			ATI.options.AutoGossip = StdUi:Checkbox(ATI, 'Auto gossip', 220, 20)
			ATI.options.lootreward = StdUi:Checkbox(ATI, 'Auto select loot', 220, 20)
			ATI.options.autoequip = StdUi:Checkbox(ATI, 'Auto equip upgrade quest rewards', 350, 20)

			-- Positioning
			StdUi:GlueTop(ATI.options.AcceptGeneralQuests, SUI_Win, -80, -30)
			StdUi:GlueBelow(ATI.options.AutoGossip, ATI.options.AcceptGeneralQuests, 0, -5)
			StdUi:GlueBelow(ATI.options.autoequip, ATI.options.AutoGossip, 0, -5, 'LEFT')

			StdUi:GlueRight(ATI.options.TurnInEnabled, ATI.options.AcceptGeneralQuests, 5, 0)
			StdUi:GlueBelow(ATI.options.lootreward, ATI.options.TurnInEnabled, 0, -5)

			-- Defaults
			for key, object in pairs(ATI.options) do
				object:SetChecked(SUI.DB.AutoTurnIn[key])
			end

			SUI_Win.ATI = ATI
		end,
		Next = function()
			local window = SUI:GetModule('SetupWizard').window
			local ATI = window.content.ATI

			for key, object in pairs(ATI.options) do
				SUI.DB.AutoTurnIn[key] = object:GetChecked()
			end

			-- window.Skip:Click()
		end,
		Skip = function()
			SUI.DB.AutoTurnIn.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end

function module.GOSSIP_SHOW()
	if (not SUI.DB.AutoTurnIn.AutoGossip) or (IsControlKeyDown()) then
		return
	end

	local options = {GetGossipOptions()}
	if #options > 7 then
		if SUI.DB.AutoTurnIn.debug then
			print('Too many gossip options (' .. #options .. ')')
		end
		return
	end
	for k, v in pairs(options) do
		SUI.DB.AutoTurnIn.AlwaysRepeat[v] = true
		if (v ~= 'gossip') and (not BlackList[v]) and (not string.find(v, 'Train')) then
			BlackList[v] = true
			local opcount = GetNumGossipOptions()
			SelectGossipOption((opcount == 1) and 1 or math.floor(k / GetNumGossipOptions()) + 1)
			if SUI.DB.AutoTurnIn.debug then
				print(v .. '---BLACKLISTED')
			end
		end
	end

	module:VarArgForActiveQuests(GetGossipActiveQuests())
	module:VarArgForAvailableQuests(GetGossipAvailableQuests())
end

function module.QUEST_PROGRESS()
	if IsQuestCompletable() and SUI.DB.AutoTurnIn.TurnInEnabled then
		CompleteQuest()
	end
end

function module:OnInitialize()
	local Defaults = {
		FirstLaunch = true,
		debug = false,
		TurnInEnabled = true,
		AutoGossip = true,
		AcceptGeneralQuests = true,
		AcceptRepeatable = false,
		trivial = false,
		lootreward = true,
		showrewardtext = true,
		autoequip = false,
		armor = {},
		weapon = {},
		stat = {},
		secondary = {},
		AlwaysRepeat = {}
	}
	if not SUI.DB.AutoTurnIn then
		SUI.DB.AutoTurnIn = Defaults
	else
		SUI.DB.AutoTurnIn = SUI:MergeData(SUI.DB.AutoTurnIn, Defaults, false)
	end
end

function module:OnEnable()
	module:BuildOptions()
	module:FirstLaunch()

	ATI_Container:SetScript(
		'OnEvent',
		function(_, event)
			if not SUI.DB.EnabledComponents.AutoTurnIn then
				return
			end
			if SUI.DB.AutoTurnIn.debug then
				print(event)
			end

			if module[event] then
				module[event]()
			end
		end
	)
	ATI_Container:RegisterEvent('GOSSIP_SHOW') -- multiple quests, and NPC chat screen
	ATI_Container:RegisterEvent('QUEST_DETAIL') -- new quest screen
	ATI_Container:RegisterEvent('QUEST_PROGRESS')
	ATI_Container:RegisterEvent('QUEST_COMPLETE') -- quest turn in screen
	ATI_Container:RegisterEvent('MERCHANT_SHOW')
	ATI_Container:RegisterEvent('MERCHANT_CLOSED')
end

function module:OnDisable()
	ATI_Container = nil
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['AutoTurnIn'] = {
		type = 'group',
		name = 'Auto TurnIn',
		args = {
			QuestAccepting = {
				name = 'Quest accepting',
				type = 'group',
				inline = true,
				order = 10,
				width = 'full',
				args = {
					AcceptGeneralQuests = {
						name = 'Accept Quests',
						type = 'toggle',
						order = 10,
						get = function(info)
							return SUI.DB.AutoTurnIn.AcceptGeneralQuests
						end,
						set = function(info, val)
							SUI.DB.AutoTurnIn.AcceptGeneralQuests = val
						end
					},
					trivial = {
						name = 'Accept trivial quests',
						type = 'toggle',
						order = 20,
						get = function(info)
							return SUI.DB.AutoTurnIn.trivial
						end,
						set = function(info, val)
							SUI.DB.AutoTurnIn.trivial = val
						end
					},
					AcceptRepeatable = {
						name = 'Accept repeatable',
						type = 'toggle',
						order = 30,
						get = function(info)
							return SUI.DB.AutoTurnIn.AcceptRepeatable
						end,
						set = function(info, val)
							SUI.DB.AutoTurnIn.AcceptRepeatable = val
						end
					},
					AutoGossip = {
						name = 'Auto Gossip',
						type = 'toggle',
						order = 15,
						get = function(info)
							return SUI.DB.AutoTurnIn.AutoGossip
						end,
						set = function(info, val)
							SUI.DB.AutoTurnIn.AutoGossip = val
						end
					}
				}
			},
			QuestTurnIn = {
				name = 'Quest turn in',
				type = 'group',
				inline = true,
				order = 20,
				width = 'full',
				args = {
					TurnInEnabled = {
						name = 'Turn in Quests',
						type = 'toggle',
						order = 10,
						get = function(info)
							return SUI.DB.AutoTurnIn.TurnInEnabled
						end,
						set = function(info, val)
							SUI.DB.AutoTurnIn.TurnInEnabled = val
						end
					},
					AutoSelectLoot = {
						name = 'Auto select loot',
						type = 'toggle',
						order = 30,
						get = function(info)
							return SUI.DB.AutoTurnIn.lootreward
						end,
						set = function(info, val)
							SUI.DB.AutoTurnIn.lootreward = val
						end
					},
					autoequip = {
						name = 'Auto equip upgrades',
						type = 'toggle',
						order = 30,
						get = function(info)
							return SUI.DB.AutoTurnIn.autoequip
						end,
						set = function(info, val)
							SUI.DB.AutoTurnIn.autoequip = val
						end
					}
				}
			},
			debugMode = {
				name = 'Debug Mode',
				type = 'toggle',
				order = 900,
				get = function(info)
					return SUI.DB.AutoTurnIn.debug
				end,
				set = function(info, val)
					SUI.DB.AutoTurnIn.debug = val
				end
			}
		}
	}
end

function module:HideOptions()
	SUI.opt.args['ModSetting'].args['AutoTurnIn'].disabled = true
end
