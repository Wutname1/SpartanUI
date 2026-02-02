local SUI, L = SUI, SUI.L
---@class SUI.Module.QuestTools
local module = SUI:GetModule('QuestTools')
----------------------------------------------------------------------------------------------------

local SLOTS = {
	['INVTYPE_AMMO'] = { 'AmmoSlot' },
	['INVTYPE_HEAD'] = { 'HeadSlot' },
	['INVTYPE_NECK'] = { 'NeckSlot' },
	['INVTYPE_SHOULDER'] = { 'ShoulderSlot' },
	['INVTYPE_CHEST'] = { 'ChestSlot' },
	['INVTYPE_WAIST'] = { 'WaistSlot' },
	['INVTYPE_LEGS'] = { 'LegsSlot' },
	['INVTYPE_FEET'] = { 'FeetSlot' },
	['INVTYPE_WRIST'] = { 'WristSlot' },
	['INVTYPE_HAND'] = { 'HandsSlot' },
	['INVTYPE_FINGER'] = { 'Finger0Slot', 'Finger1Slot' },
	['INVTYPE_TRINKET'] = { 'Trinket0Slot', 'Trinket1Slot' },
	['INVTYPE_CLOAK'] = { 'BackSlot' },
	['INVTYPE_WEAPON'] = { 'MainHandSlot', 'SecondaryHandSlot' },
	['INVTYPE_2HWEAPON'] = { 'MainHandSlot' },
	['INVTYPE_RANGED'] = { 'MainHandSlot' },
	['INVTYPE_RANGEDRIGHT'] = { 'MainHandSlot' },
	['INVTYPE_WEAPONMAINHAND'] = { 'MainHandSlot' },
	['INVTYPE_SHIELD'] = { 'SecondaryHandSlot' },
	['INVTYPE_WEAPONOFFHAND'] = { 'SecondaryHandSlot' },
	['INVTYPE_HOLDABLE'] = { 'SecondaryHandSlot' },
}

function module:InitializeRewardSelection()
	-- Nothing special needed, just ensure module functions are available
end

function module:EquipItem(ItemToEquip)
	if InCombatLockdown() then
		return
	end

	local EquipItemName = C_Item.GetItemInfo(ItemToEquip)
	local EquipILvl = C_Item.GetDetailedItemLevelInfo(ItemToEquip)
	local ItemFound = false

	-- Make sure it is in the bags
	for bag = 0, NUM_BAG_SLOTS do
		if ItemFound then
			return
		end
		for slot = 1, C_Container.GetContainerNumSlots(bag), 1 do
			local link = C_Container.GetContainerItemLink(bag, slot)
			if link then
				local slotItemName = C_Item.GetItemInfo(link)
				local SlotILvl = C_Item.GetDetailedItemLevelInfo(link)
				if (slotItemName == EquipItemName) and (SlotILvl == EquipILvl) then
					if module.IsMerchantOpen then
						SUI:Print(L['Unable to equip'] .. ' ' .. link)
						module:CancelAllTimers()
					else
						SUI:Print(L['Equipping reward'] .. ' ' .. link)
						C_Container.UseContainerItem(bag, slot)
						module:CancelAllTimers()
						ItemFound = true
						return
					end
				end
			end
		end
	end
end

function module:HandleQuestComplete()
	local DB = module:GetDB()

	if not DB.TurnInEnabled then
		return
	end

	-- Look for the item that is the best upgrade and whats worth the most.
	local GreedID, GreedValue, UpgradeID = nil, 0, nil
	local GreedLink, UpgradeLink, UpgradeAmmount = nil, nil, 0
	local QuestRewardsWeapon = false

	for i = 1, GetNumQuestChoices() do
		-- Load the items information
		local link = GetQuestItemLink('choice', i)
		module.debug(link)
		if link == nil then
			return
		end
		local itemName, _, _, _, _, _, _, _, itemEquipLoc, _, itemSellPrice = C_Item.GetItemInfo(link)
		local QuestItemTrueiLVL = SUI:GetiLVL(link) or 0

		-- Check the items value
		if itemSellPrice > GreedValue then
			GreedValue = itemSellPrice
			GreedID = i
			GreedLink = link
		end

		-- See if the item is an upgrade
		local slot = SLOTS[itemEquipLoc]
		if slot then
			local firstSlot = GetInventorySlotInfo(slot[1])
			local firstinvLink = GetInventoryItemLink('player', firstSlot)
			local EquipedLevel = SUI:GetiLVL(firstinvLink) or 0

			if EquipedLevel then
				-- If reward is a ring, trinket or one-handed weapons all slots must be checked in order to swap with a lesser ilevel
				if #slot > 1 then
					local secondSlot = GetInventorySlotInfo(slot[2])
					local secondinvLink = GetInventoryItemLink('player', secondSlot)
				end

				-- comparing lowest equipped item level with reward's item level
				module.debug('iLVL Comparisson ' .. link .. ' - ' .. QuestItemTrueiLVL .. '-' .. EquipedLevel .. ' - ' .. (firstinvLink or ''))

				if (QuestItemTrueiLVL > EquipedLevel) and ((QuestItemTrueiLVL - EquipedLevel) > UpgradeAmmount) then
					UpgradeLink = link
					UpgradeID = i
					UpgradeAmmount = (QuestItemTrueiLVL - EquipedLevel)
				end
			end

			-- Check if it is a weapon, do this last incase it only rewards one item
			if slot[1] == 'MainHandSlot' or slot[1] == 'SecondaryHandSlot' then
				QuestRewardsWeapon = true
			elseif slot[1] == 'Trinket0Slot' then
				QuestRewardsWeapon = true
			end
		end
	end

	module.debug(GetNumQuestChoices())
	-- If there is more than one reward check that we are allowed to select it.
	if GetNumQuestChoices() > 1 then
		if QuestRewardsWeapon then
			-- SUI:Print(L['Canceling turn in, quest rewards'] .. ' ' .. QuestRewardsWeapon .. '.')
		elseif DB.lootreward then
			if GreedID and not UpgradeID then
				SUI:Print('Grabbing item to vendor ' .. GreedLink .. ' worth ' .. SUI:GoldFormattedValue(GreedValue))
				module:TurnInQuest(GreedID)
			elseif UpgradeID then
				SUI:Print('Upgrade found! Grabbing ' .. UpgradeLink)
				module:TurnInQuest(UpgradeID)
			end
		else
			if GreedID and not UpgradeID then
				SUI:Print('Would vendor: ' .. GreedLink .. ' worth ' .. SUI:GoldFormattedValue(GreedValue))
			elseif UpgradeLink then
				SUI:Print('Would select upgrade ' .. UpgradeLink)
			end
		end
	else
		if GreedID and not UpgradeID then
			SUI:Print('Quest rewards vendor item ' .. GreedLink .. ' worth ' .. SUI:GoldFormattedValue(GreedValue))
			module:TurnInQuest(GreedID)
		elseif UpgradeID then
			SUI:Print('Quest rewards a upgrade ' .. UpgradeLink)
			module:TurnInQuest(UpgradeID)
		else
			module.debug(L['No Reward, turning in.'])
			module:TurnInQuest(1)
		end
	end
end
