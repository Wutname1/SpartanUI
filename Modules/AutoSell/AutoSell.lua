local SUI, L, print = SUI, SUI.L, SUI.print
---@class SUI.Module.AutoSell : SUI.Module
local module = SUI:NewModule('AutoSell')
module.DisplayName = L['Auto sell']
module.description = 'Auto sells junk and more'

----------------------------------------------------------------------------------------------------
local Tooltip = CreateFrame('GameTooltip', 'AutoSellTooltip', nil, 'GameTooltipTemplate')
local LoadedOnce = false
local totalValue = 0

---@class SUI.Module.AutoSell.DB
local DbDefaults = {
	FirstLaunch = true,
	NotCrafting = true,
	NotConsumables = true,
	NotInGearset = true,
	MaximumiLVL = 500,
	MaxILVL = 200,
	LastWowProjectID = WOW_PROJECT_ID,
	Gray = true,
	White = false,
	Green = false,
	Blue = false,
	Purple = false,
	GearTokens = false,
	AutoRepair = false,
	UseGuildBankRepair = false,
	ShowBagMarking = true,
	Blacklist = {
		Items = {
			-- Shadowlands
			180276, --Locked Toolbox Key
			175757, --Construct Supply Key
			27944, --Talisman of True Treasure Tracking
			156725, --red-crystal-monocle
			156726, --yellow-crystal-monocle
			156727, --green-crystal-monocle
			156724, --blue-crystal-monocle
			-- BFA
			168135, --Titans Blood
			166846, --spare parts
			168327, --chain ignitercoil
			166971, --empty energy cell
			170500, --energy cell
			166970, --energy cell
			169475, --Barnacled Lockbox
			137642, --Mark Of Honor
			168217, --Hardened Spring
			168136, --Azerokk's Fist
			168216, --Tempered Plating
			168215, --Machined Gear Assembly
			169334, --Strange Oceanic Sediment
			170193, --Sea Totem
			168802, --Nazjatar Battle Commendation
			171090, --Battleborn Sigil
			153647, --Tome of the quiet mind
			-- Cata
			71141, -- Eternal Ember
			-- Legion
			129276, -- Beginner's Guide to Dimensional Rifting
			-- MOP
			80914, -- Mourning Glory
			-- Misc Items
			141446, --Tome of the Tranquil Mind
			81055, -- Darkmoon ride ticket
			150372, -- Arsenal: The Warglaives of Azzinoth
			32837, -- Warglaive of Azzinoth
			--Professions
			6219, -- Arclight Spanner
			140209, --imported blacksmith hammer
			5956, -- Blacksmith Hammer
			7005, --skinning knife
			2901, --mining pick
			-- Classic WoW
			6256, -- Fishing Pole
			--Start Shredder Operating Manual pages
			16645,
			16646,
			16647,
			16648,
			16649,
			16650,
			16651,
			16652,
			16653,
			16654,
			16655,
			16656,
			2730,
			--End Shredder Operating Manual pages
			63207, -- Wrap of unity
			63206, -- Wrap of unity
		},
		Types = {
			'Container',
			'Companions',
			'Holiday',
			'Mounts',
			'Quest',
		},
	},
}

---@class SUI.Module.AutoSell.CharDB
---@field SellItems table<number, boolean>

local function debugMsg(msg)
	SUI.Debug(msg, 'AutoSell')
end

local function IsInGearset(bag, slot)
	local line
	Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	Tooltip:SetBagItem(bag, slot)

	for i = 1, Tooltip:NumLines() do
		line = _G['AutoSellTooltipTextLeft' .. i]
		if line:GetText():find(EQUIPMENT_SETS:format('.*')) then return true end
	end

	return false
end

---Check if an item would be sold by Blizzard's SellAllJunkItems
---@param item number
---@param quality number
---@return boolean
function module:WouldBlizzardSell(item, quality)
	-- Blizzard only sells gray (quality 0) junk items
	-- and only if SellAllJunkItems is enabled
	if SUI.IsRetail and quality == 0 and C_MerchantFrame and C_MerchantFrame.IsSellAllJunkEnabled then return C_MerchantFrame.IsSellAllJunkEnabled() end
	return false
end

function module:IsSellable(item, ilink, bag, slot)
	if not item then return false end
	local name, _, quality, _, _, itemType, itemSubType, _, equipSlot, _, vendorPrice, _, _, _, expacID, _, isCraftingReagent = C_Item.GetItemInfo(ilink)
	if vendorPrice == 0 or name == nil then return false end
	-- 0. Poor (gray): Broken I.W.I.N. Button
	-- 1. Common (white): Archmage Vargoth's Staff
	-- 2. Uncommon (green): X-52 Rocket Helmet
	-- 3. Rare / Superior (blue): Onyxia Scale Cloak
	-- 4. Epic (purple): Talisman of Ephemeral Power
	-- 5. Legendary (orange): Fragment of Val'anyr
	-- 6. Artifact (golden yellow): The Twin Blades of Azzinoth
	-- 7. Heirloom (light yellow): Bloodied Arcanite Reaper
	local iLevel = SUI:GetiLVL(ilink)

	-- Quality check
	if
		(quality == 0 and not module.DB.Gray)
		or (quality == 1 and not module.DB.White)
		or (quality == 2 and not module.DB.Green)
		or (quality == 3 and not module.DB.Blue)
		or (quality == 4 and not module.DB.Purple)
		or (iLevel and iLevel > module.DB.MaxILVL)
	then
		return false
	end

	--Gearset detection
	if C_EquipmentSet.CanUseEquipmentSets() and IsInGearset(bag, slot) then return false end
	-- Gear Tokens
	if quality == 4 and itemType == 'Miscellaneous' and itemSubType == 'Junk' and equipSlot == '' and not module.DB.GearTokens then return false end

	--Crafting Items
	if
		(
			(itemType == 'Gem' or itemType == 'Reagent' or itemType == 'Recipes' or itemType == 'Trade Goods' or itemType == 'Tradeskill')
			or (itemType == 'Miscellaneous' and itemSubType == 'Reagent')
			or (itemType == 'Item Enhancement')
			or isCraftingReagent
		) and not module.DB.NotCrafting
	then
		return false
	end

	-- Dont sell pets
	if itemSubType == 'Companion Pets' then return false end
	-- Transmog tokens
	if expacID == 9 and (itemType == 'Miscellaneous' or (itemType == 'Armor' and itemSubType == 'Miscellaneous')) and iLevel == 0 and quality >= 2 then return false end

	--Consumables
	if module.DB.NotConsumables and (itemType == 'Consumable' or itemSubType == 'Consumables') and quality ~= 0 then return false end --Some junk is labeled as consumable

	if string.find(name, '') and quality == 1 then return false end

	if not SUI:IsInTable(module.DB.Blacklist.Items, item) and not SUI:IsInTable(module.DB.Blacklist.Types, itemType) and not SUI:IsInTable(module.DB.Blacklist.Types, itemSubType) then
		debugMsg('--Decision: Selling--')
		debugMsg('Item: ' .. (name or 'Unknown') .. ' (Link: ' .. ilink .. ')')
		debugMsg('Expansion ID: ' .. tostring(expacID))
		debugMsg('Item Level: ' .. tostring(iLevel))
		debugMsg('Item Type: ' .. itemType)
		debugMsg('Item Sub-Type: ' .. itemSubType)
		debugMsg('Vendor Price: ' .. tostring(vendorPrice))
		return true
	end

	return false
end

function module:SellTrash()
	--Reset Locals
	totalValue = 0
	local ItemToSell = {}
	local highestILVL = 0
	local blizzardSoldItems = false

	-- First, try to use Blizzard's sell junk function if available
	if SUI.IsRetail and C_MerchantFrame and C_MerchantFrame.IsSellAllJunkEnabled and C_MerchantFrame.SellAllJunkItems then
		if C_MerchantFrame.IsSellAllJunkEnabled() then
			-- Count gray items that Blizzard will sell
			local grayItemCount = 0
			for bag = 0, 4 do
				for slot = 1, C_Container.GetContainerNumSlots(bag) do
					local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
					if itemInfo then
						local _, _, quality = C_Item.GetItemInfo(itemInfo.itemID)
						if quality == 0 then -- Gray items
							grayItemCount = grayItemCount + 1
						end
					end
				end
			end

			if grayItemCount > 0 then
				debugMsg('Using Blizzard SellAllJunkItems for ' .. grayItemCount .. ' gray items')
				C_MerchantFrame.SellAllJunkItems()
				-- blizzardSoldItems = true
				-- Schedule our additional selling after a delay to let Blizzard's sell complete
				-- module:ScheduleTimer('SellAdditionalItems', 1.0)
				-- return
			end
		end
	end

	--Find Items to sell and track highest iLVL
	for bag = 0, 4 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemInfo, _, _, _, _, _, link, _, _, itemID = C_Container.GetContainerItemInfo(bag, slot)
			if SUI.IsRetail and itemInfo then
				local iLevel = SUI:GetiLVL(itemInfo.hyperlink)
				if iLevel and iLevel > highestILVL then highestILVL = iLevel end
				if module:IsSellable(itemInfo.itemID, itemInfo.hyperlink, bag, slot) then
					ItemToSell[#ItemToSell + 1] = { bag, slot }
					totalValue = totalValue + (select(11, C_Item.GetItemInfo(itemInfo.itemID)) * itemInfo.stackCount)
				end
			elseif not SUI.IsRetail and itemID then
				local iLevel = SUI:GetiLVL(link)
				if iLevel and iLevel > highestILVL then highestILVL = iLevel end
				if module:IsSellable(itemID, link, bag, slot) then
					ItemToSell[#ItemToSell + 1] = { bag, slot }
					totalValue = totalValue + (select(11, C_Item.GetItemInfo(itemID)) * select(2, C_Container.GetContainerItemInfo(bag, slot)))
				end
			end
		end
	end

	-- Auto-increase MaximumiLVL if we detected higher iLVL items
	if highestILVL > 0 and (highestILVL + 50) > module.DB.MaximumiLVL then
		module.DB.MaximumiLVL = highestILVL + 50
		debugMsg('Auto-increased MaximumiLVL to: ' .. module.DB.MaximumiLVL .. ' (highest detected: ' .. highestILVL .. ')')
	end

	--Sell Items if needed
	if #ItemToSell == 0 then
		SUI:Print(L['No items are to be auto sold'])
	else
		SUI:Print('Need to sell ' .. #ItemToSell .. ' additional item(s) for ' .. SUI:GoldFormattedValue(totalValue))
		--Start Loop to sell, reset locals
		module:ScheduleRepeatingTimer('SellTrashInBag', 0.2, ItemToSell)
	end
end

function module:SellAdditionalItems()
	--Reset Locals
	local ItemToSell = {}
	local highestILVL = 0

	--Find Items to sell and track highest iLVL (excluding gray items already sold by Blizzard)
	for bag = 0, 4 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemInfo, _, _, _, _, _, link, _, _, itemID = C_Container.GetContainerItemInfo(bag, slot)
			if SUI.IsRetail and itemInfo then
				local iLevel = SUI:GetiLVL(itemInfo.hyperlink)
				if iLevel and iLevel > highestILVL then highestILVL = iLevel end
				-- Skip gray items as they were already handled by Blizzard
				local _, _, quality = C_Item.GetItemInfo(itemInfo.itemID)
				if quality ~= 0 and module:IsSellable(itemInfo.itemID, itemInfo.hyperlink, bag, slot) then
					ItemToSell[#ItemToSell + 1] = { bag, slot }
					totalValue = totalValue + (select(11, C_Item.GetItemInfo(itemInfo.itemID)) * itemInfo.stackCount)
				end
			elseif not SUI.IsRetail and itemID then
				local iLevel = SUI:GetiLVL(link)
				if iLevel and iLevel > highestILVL then highestILVL = iLevel end
				-- Skip gray items as they were already handled by Blizzard
				local _, _, quality = C_Item.GetItemInfo(itemID)
				if quality ~= 0 and module:IsSellable(itemID, link, bag, slot) then
					ItemToSell[#ItemToSell + 1] = { bag, slot }
					totalValue = totalValue + (select(11, C_Item.GetItemInfo(itemID)) * select(2, C_Container.GetContainerItemInfo(bag, slot)))
				end
			end
		end
	end

	-- Auto-increase MaximumiLVL if we detected higher iLVL items
	if highestILVL > 0 and (highestILVL + 50) > module.DB.MaximumiLVL then
		module.DB.MaximumiLVL = highestILVL + 50
		debugMsg('Auto-increased MaximumiLVL to: ' .. module.DB.MaximumiLVL .. ' (highest detected: ' .. highestILVL .. ')')
	end

	--Sell Items if needed
	if #ItemToSell == 0 then
		if totalValue == 0 then SUI:Print(L['No items are to be auto sold']) end
	else
		SUI:Print('Need to sell ' .. #ItemToSell .. ' additional item(s) for ' .. SUI:GoldFormattedValue(totalValue))
		--Start Loop to sell, reset locals
		module:ScheduleRepeatingTimer('SellTrashInBag', 0.2, ItemToSell)
	end
end

---Sell Items 5 at a time, sometimes it can sell stuff too fast for the game.
---@param ItemListing number
function module:SellTrashInBag(ItemListing)
	-- Grab an item to sell
	local item = table.remove(ItemListing)

	-- If the Table is empty then exit.
	if not item then
		module:CancelAllTimers()
		return
	end

	-- SELL!
	C_Container.UseContainerItem(item[1], item[2])

	-- If it was the last item stop timers
	if #ItemListing == 0 then module:CancelAllTimers() end
end

---@param personalFunds? boolean
function module:Repair(personalFunds)
	-- First see if this vendor can repair & we need to
	if not module.DB.AutoRepair or not CanMerchantRepair() or GetRepairAllCost() == 0 then return end

	if CanGuildBankRepair() and module.DB.UseGuildBankRepair and not personalFunds then
		SUI:Print(L['Auto repair cost'] .. ': ' .. SUI:GoldFormattedValue(GetRepairAllCost()) .. ' ' .. L['used guild funds'])
		RepairAllItems(true)
		module:ScheduleTimer('Repair', 0.7, true)
	else
		SUI:Print(L['Auto repair cost'] .. ': ' .. SUI:GoldFormattedValue(GetRepairAllCost()) .. ' ' .. L['used personal funds'])
		RepairAllItems()
	end
end

function module:MERCHANT_SHOW()
	if SUI:IsModuleDisabled('AutoSell') then return end
	module:ScheduleTimer('SellTrash', 0.2)
	module:Repair()
end

function module:MERCHANT_CLOSED()
	module:CancelAllTimers()
	if totalValue > 0 then totalValue = 0 end
end

local function HandleItemLevelSquish()
	-- Check if the WOW_PROJECT_ID has changed (indicating potential expansion change)
	if module.DB.LastWowProjectID ~= WOW_PROJECT_ID then
		debugMsg('Detected WOW_PROJECT_ID change from ' .. (module.DB.LastWowProjectID or 'unknown') .. ' to ' .. WOW_PROJECT_ID)

		-- Scan all items to find the new highest item level
		local newHighestILVL = 0
		for bag = 0, 4 do
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				local itemInfo, _, _, _, _, _, link, _, _, itemID = C_Container.GetContainerItemInfo(bag, slot)
				local iLevel = 0
				if SUI.IsRetail and itemInfo then
					iLevel = SUI:GetiLVL(itemInfo.hyperlink)
				elseif not SUI.IsRetail and itemID then
					iLevel = SUI:GetiLVL(link)
				end
				if iLevel and iLevel > newHighestILVL then newHighestILVL = iLevel end
			end
		end

		-- Add buffer to new highest level
		local newMaximumiLVL = newHighestILVL + 50

		-- Check if this represents a squish (new max is significantly lower than old max)
		if newMaximumiLVL > 0 and newMaximumiLVL < (module.DB.MaximumiLVL * 0.8) then
			local squishRatio = newMaximumiLVL / module.DB.MaximumiLVL
			local oldMaxILVL = module.DB.MaxILVL
			local newMaxILVL = math.floor(oldMaxILVL * squishRatio)

			-- Ensure we don't go below 1
			if newMaxILVL < 1 then newMaxILVL = 1 end

			debugMsg('Item level squish detected!')
			debugMsg('Old MaximumiLVL: ' .. module.DB.MaximumiLVL .. ' -> New: ' .. newMaximumiLVL)
			debugMsg('Old MaxILVL: ' .. oldMaxILVL .. ' -> New: ' .. newMaxILVL .. ' (ratio: ' .. string.format('%.2f', squishRatio) .. ')')

			-- Apply the adjustments
			module.DB.MaximumiLVL = newMaximumiLVL
			module.DB.MaxILVL = newMaxILVL

			SUI:Print('Item level squish detected! Adjusted sell threshold from ' .. oldMaxILVL .. ' to ' .. newMaxILVL)
		elseif newMaximumiLVL > module.DB.MaximumiLVL then
			-- Normal case: just increase the maximum if we found higher level items
			module.DB.MaximumiLVL = newMaximumiLVL
			debugMsg('Increased MaximumiLVL to: ' .. newMaximumiLVL)
		end

		-- Update the stored project ID
		module.DB.LastWowProjectID = WOW_PROJECT_ID
	end
end

function module:OnInitialize()
	module.Database = SUI.SpartanUIDB:RegisterNamespace('AutoSell', { profile = DbDefaults })
	module.DB = module.Database.profile ---@type SUI.Module.AutoSell.DB
	module.CharDB = module.Database.char ---@type SUI.Module.AutoSell.CharDB

	-- Handle potential item level squish after DB is initialized
	HandleItemLevelSquish()
end

function module:OnEnable()
	if not LoadedOnce then module:InitializeOptions() end
	if SUI:IsModuleDisabled(module) then return end

	module:RegisterEvent('MERCHANT_SHOW')
	module:RegisterEvent('MERCHANT_CLOSED')

	module:CreateMiniVendorPanels()
	
	-- Initialize bag marking system if enabled
	if module.DB.ShowBagMarking then
		module:InitializeBagMarking()
	end

	LoadedOnce = true
end

function module:OnDisable()
	SUI:Print('Autosell disabled')
	module:UnregisterEvent('MERCHANT_SHOW')
	module:UnregisterEvent('MERCHANT_CLOSED')

	-- Cleanup bag marking system
	module:CleanupBagMarking()

	-- Hide and cleanup vendor panels
	if module.VendorPanels then
		for _, panel in pairs(module.VendorPanels) do
			if panel then
				panel:Hide()
				if panel.Panel then panel.Panel:Hide() end
			end
		end
	end
end
