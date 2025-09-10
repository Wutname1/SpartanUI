local SUI, L, print = SUI, SUI.L, SUI.print
---@class SUI.Module.AutoSell : SUI.Module
local module = SUI:NewModule('AutoSell')
module.DisplayName = L['Auto sell']
module.description = 'Auto sells junk and more'

----------------------------------------------------------------------------------------------------
-- Configuration constants
local MAX_BAG_SLOTS = 12 -- Maximum number of bag slots to scan (0-12 covers all normal bags plus extras)

local Tooltip = CreateFrame('GameTooltip', 'AutoSellTooltip', nil, 'GameTooltipTemplate')
local LoadedOnce = false
local totalValue = 0

-- Performance cache for blacklist lookups
local blacklistLookup = {
	items = {},
	types = {},
	valid = false,
}

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
---@field Whitelist table<number, boolean> Character-specific whitelist items
---@field Blacklist table<number, boolean> Character-specific blacklist items

local function debugMsg(msg)
	SUI.Log(msg, 'AutoSell')
end

-- Build fast blacklist lookup tables
local function buildBlacklistLookup()
	if blacklistLookup.valid then return end

	-- Reset tables
	blacklistLookup.items = {}
	blacklistLookup.types = {}

	-- Build item blacklist lookup
	for _, itemID in ipairs(module.DB.Blacklist.Items) do
		blacklistLookup.items[itemID] = true
	end

	-- Build type blacklist lookup
	for _, itemType in ipairs(module.DB.Blacklist.Types) do
		blacklistLookup.types[itemType] = true
	end

	blacklistLookup.valid = true
end

-- Invalidate lookup cache when settings change
local function invalidateBlacklistLookup()
	blacklistLookup.valid = false
end

-- Module function to invalidate cache (accessible from Options.lua)
function module:InvalidateBlacklistCache()
	invalidateBlacklistLookup()

	-- Refresh bag markings when cache is invalidated
	if module.DB.ShowBagMarking and module.markItems then module.markItems() end

	-- Refresh Baganator when cache is invalidated
	if C_AddOns.IsAddOnLoaded('Baganator') and Baganator and Baganator.API then Baganator.API.RequestItemButtonsRefresh() end
end

local function IsInGearset(bag, slot)
	-- Skip gearset check if called without valid bag/slot (like from Baganator)
	if not bag or not slot or bag < 0 or slot < 1 then return false end

	local success, result = pcall(function()
		local line
		Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
		Tooltip:SetBagItem(bag, slot)

		for i = 1, Tooltip:NumLines() do
			line = _G['AutoSellTooltipTextLeft' .. i]
			if line and line:GetText() and line:GetText():find(EQUIPMENT_SETS:format('.*')) then return true end
		end
		return false
	end)

	if not success then
		debugMsg('IsInGearset error: ' .. tostring(result))
		return false
	end

	return result
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
	if not item then
		debugMsg('IsSellable: item is nil, returning false')
		return false
	end
	local name, _, quality, _, _, itemType, itemSubType, _, equipSlot, _, vendorPrice, _, _, _, expacID, _, isCraftingReagent = C_Item.GetItemInfo(ilink)
	if vendorPrice == 0 or name == nil then
		debugMsg('IsSellable: no vendor price or name for item ' .. tostring(item))
		return false
	end

	-- Check character-specific blacklist FIRST (highest priority)
	if module.CharDB.Blacklist[item] then
		debugMsg('--Decision: Not selling (character blacklist)--')
		return false
	end

	-- Check character-specific whitelist (overrides ALL other rules)
	if module.CharDB.Whitelist[item] then
		debugMsg('--Decision: Selling (character whitelist overrides all rules)--')
		debugMsg('Item: ' .. (name or 'Unknown') .. ' (Link: ' .. ilink .. ')')
		debugMsg('Vendor Price: ' .. tostring(vendorPrice))
		return true
	end

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
	if module.DB.NotInGearset and C_EquipmentSet.CanUseEquipmentSets() and IsInGearset(bag, slot) then return false end
	-- Gear Tokens
	if quality == 4 and itemType == 'Miscellaneous' and itemSubType == 'Junk' and equipSlot == '' and not module.DB.GearTokens then return false end

	--Crafting Items
	if
		(
			(itemType == 'Gem' or itemType == 'Reagent' or itemType == 'Recipes' or itemType == 'Trade Goods' or itemType == 'Tradeskill')
			or (itemType == 'Miscellaneous' and itemSubType == 'Reagent')
			or (itemType == 'Item Enhancement')
			or isCraftingReagent
		) and module.DB.NotCrafting
	then
		return false
	end

	-- Dont sell pets
	if itemSubType == 'Companion Pets' then return false end
	-- Transmog tokens
	if expacID == 9 and (itemType == 'Miscellaneous' or (itemType == 'Armor' and itemSubType == 'Miscellaneous')) and iLevel == 0 and quality >= 2 then return false end

	--Consumables
	if module.DB.NotConsumables and (itemType == 'Consumable' or itemSubType == 'Consumables') and quality ~= 0 then return false end --Some junk is labeled as consumable

	-- Check for items with "Use:" in tooltip (profession enhancement items, etc.)
	if bag and slot then
		local hasUseText = pcall(function()
			Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
			Tooltip:SetBagItem(bag, slot)
			
			for i = 1, Tooltip:NumLines() do
				local line = _G['AutoSellTooltipTextLeft' .. i]
				if line and line:GetText() then
					local text = line:GetText():lower()
					if text:find('^use:') or text:find('^%s*use:') then
						Tooltip:Hide()
						return true
					end
				end
			end
			Tooltip:Hide()
			return false
		end)
		
		if hasUseText then
			debugMsg('Item has "Use:" text in tooltip - skipping')
			return false
		end
	end

	if string.find(name, '') and quality == 1 then return false end

	-- Check profile blacklists (optimized lookups)
	buildBlacklistLookup()
	if not blacklistLookup.items[item] and not blacklistLookup.types[itemType] and not blacklistLookup.types[itemSubType] then
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
			for bag = 0, MAX_BAG_SLOTS do
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
	debugMsg('Starting to scan bags for sellable items...')
	-- Scan through all possible bag slots (0-12 covers all normal bags plus extras)
	for bag = 0, MAX_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemInfo, _, _, _, _, _, link, _, _, itemID = C_Container.GetContainerItemInfo(bag, slot)
			if SUI.IsRetail and itemInfo then
				local iLevel = SUI:GetiLVL(itemInfo.hyperlink)
				if iLevel and iLevel > highestILVL then highestILVL = iLevel end
				local sellable = module:IsSellable(itemInfo.itemID, itemInfo.hyperlink, bag, slot)
				if sellable then
					ItemToSell[#ItemToSell + 1] = { bag, slot }
					totalValue = totalValue + (select(11, C_Item.GetItemInfo(itemInfo.itemID)) * itemInfo.stackCount)
				end
			elseif not SUI.IsRetail and itemID then
				local iLevel = SUI:GetiLVL(link)
				if iLevel and iLevel > highestILVL then highestILVL = iLevel end
				local sellable = module:IsSellable(itemID, link, bag, slot)
				if sellable then
					ItemToSell[#ItemToSell + 1] = { bag, slot }
					totalValue = totalValue + (select(11, C_Item.GetItemInfo(itemID)) * select(2, C_Container.GetContainerItemInfo(bag, slot)))
				end
			end
		end
	end
	debugMsg('Finished scanning bags. Found ' .. #ItemToSell .. ' items to sell.')

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
	-- Scan through all possible bag slots (0-12 covers all normal bags plus extras)
	for bag = 0, MAX_BAG_SLOTS do
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
		for bag = 0, MAX_BAG_SLOTS do
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

---Debug item sellability with detailed output
function module:DebugItemSellability(link)
	local itemID = tonumber(string.match(link, 'item:(%d+)'))
	if not itemID then
		print('|cffFFFF00AutoSell Debug:|r Could not extract item ID from link')
		return
	end

	local name, _, quality, _, _, itemType, itemSubType, _, equipSlot, _, vendorPrice, _, _, bindType, expacID, _, isCraftingReagent = C_Item.GetItemInfo(link)
	local actualItemLevel, previewLevel, sparseItemLevel = C_Item.GetDetailedItemLevelInfo(link)

	if not name then
		print('|cffFFFF00AutoSell Debug:|r Item info not available')
		return
	end

	-- Find the actual bag/slot for this item to use exact same call as marking/selling
	local actualBag, actualSlot = nil, nil
	for bag = 0, MAX_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
			if itemInfo and itemInfo.itemID == itemID then
				actualBag, actualSlot = bag, slot
				break
			end
		end
		if actualBag then break end
	end

	local iLevel = SUI:GetiLVL(link)
	local qualityColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or 'ffffffff'

	print('|cffFFFF00=== AutoSell Debug ===|r')
	print(string.format('Item: |c%s%s|r (ID: %d)', qualityColor, name, itemID))
	print(string.format('Quality: %d (%s)', quality, _G['ITEM_QUALITY' .. quality .. '_DESC'] or 'Unknown'))
	print(string.format('Type: %s / %s', itemType or 'nil', itemSubType or 'nil'))
	print(string.format('iLevel: %s', iLevel and tostring(iLevel) or 'nil'))
	print(string.format('Vendor Price: %s', vendorPrice and tostring(vendorPrice) or '0'))
	print(string.format('Equip Slot: %s', equipSlot or 'none'))
	print(string.format('Expansion ID: %s', expacID and tostring(expacID) or 'nil'))
	print(string.format('Bind Type: %s', bindType and _G['BIND_' .. bindType] or 'nil'))
	print(string.format('Is Crafting Reagent: %s', isCraftingReagent and 'Yes' or 'No'))
	print(string.format('Actual Item Level: %s', actualItemLevel and tostring(actualItemLevel) or 'nil'))
	print(string.format('Preview Item Level: %s', previewLevel and tostring(previewLevel) or 'nil'))
	print(string.format('Sparse Item Level: %s', sparseItemLevel and tostring(sparseItemLevel) or 'nil'))

	-- Tooltip Analysis
	print('|cffFFFF00--- Tooltip Analysis ------|r')
	if actualBag and actualSlot then
		local success, tooltipText = pcall(function()
			Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
			Tooltip:SetBagItem(actualBag, actualSlot)
			
			local lines = {}
			for i = 1, Tooltip:NumLines() do
				local leftText = _G['AutoSellTooltipTextLeft' .. i]
				local rightText = _G['AutoSellTooltipTextRight' .. i]
				if leftText and leftText:GetText() then
					local lineText = leftText:GetText()
					if rightText and rightText:GetText() then
						lineText = lineText .. ' | ' .. rightText:GetText()
					end
					table.insert(lines, lineText)
				end
			end
			return table.concat(lines, '\n')
		end)
		
		if success and tooltipText then
			print('Tooltip Content:')
			for line in tooltipText:gmatch('[^\n]+') do
				print('  ' .. line)
			end
		else
			print('|cffFF0000ERROR:|r Could not read tooltip: ' .. tostring(tooltipText))
		end
		
		Tooltip:Hide()
	else
		print('|cffFFFFFF WARNING:|r Could not dump tooltip - item not found in bags')
	end

	-- Check each condition
	print('|cffFFFF00--- Sell Decision Process ------|r')

	-- Basic checks
	if vendorPrice == 0 then
		print('|cffFF0000BLOCKED:|r No vendor value')
		return
	end

	-- Character blacklist
	if module.CharDB.Blacklist[itemID] then
		print('|cffFF0000BLOCKED:|r In character blacklist')
		return
	end

	-- Character whitelist
	print('Debug: Checking CharDB.Whitelist[' .. tostring(itemID) .. '] = ' .. tostring(module.CharDB.Whitelist[itemID]))
	if module.CharDB.Whitelist[itemID] then
		print('|cff00FF00ALLOWED:|r In character whitelist (overrides all rules)')
		print('|cff00FF00RESULT:|r Item should be marked with sell icon')

		-- Final decision check to verify the actual function using EXACT same parameters as marking/selling
		if actualBag and actualSlot then
			local itemInfo = C_Container.GetContainerItemInfo(actualBag, actualSlot)
			if itemInfo then
				local finalDecision = module:IsSellable(itemInfo.itemID, itemInfo.hyperlink, actualBag, actualSlot)
				print(string.format('|cffFFFFFF--- FINAL DECISION (exact call): %s ---|r', finalDecision and '|cff00FF00WILL SELL|r' or '|cffFF0000WILL NOT SELL|r'))
			end
		else
			print('|cffFFFF00WARNING:|r Could not find item in bags for exact test')
		end
		return
	end

	-- Quality checks
	local qualityBlocked = false
	if quality == 0 and not module.DB.Gray then
		print('|cffFF0000BLOCKED:|r Gray quality disabled')
		qualityBlocked = true
	elseif quality == 1 and not module.DB.White then
		print('|cffFF0000BLOCKED:|r White quality disabled')
		qualityBlocked = true
	elseif quality == 2 and not module.DB.Green then
		print('|cffFF0000BLOCKED:|r Green quality disabled')
		qualityBlocked = true
	elseif quality == 3 and not module.DB.Blue then
		print('|cffFF0000BLOCKED:|r Blue quality disabled')
		qualityBlocked = true
	elseif quality == 4 and not module.DB.Purple then
		print('|cffFF0000BLOCKED:|r Purple quality disabled')
		qualityBlocked = true
	else
		print('|cff00FF00PASSED:|r Quality check')
	end

	-- iLevel check
	if iLevel and iLevel > module.DB.MaxILVL then
		print(string.format('|cffFF0000BLOCKED:|r iLevel %d > max %d', iLevel, module.DB.MaxILVL))
		qualityBlocked = true
	else
		print(string.format('|cff00FF00PASSED:|r iLevel check (max: %d)', module.DB.MaxILVL))
	end

	if qualityBlocked then return end

	-- Gearset check (can't easily test without bag/slot)
	print('|cffFFFFFF SKIPPED:|r Gearset check (requires bag position)')

	-- Gear tokens check
	if quality == 4 and itemType == 'Miscellaneous' and itemSubType == 'Junk' and equipSlot == '' and not module.DB.GearTokens then
		print('|cffFF0000BLOCKED:|r Gear tokens disabled')
		return
	else
		print('|cff00FF00PASSED:|r Gear token check')
	end

	-- Crafting check
	local isCraftingItem = (itemType == 'Gem' or itemType == 'Reagent' or itemType == 'Recipes' or itemType == 'Trade Goods' or itemType == 'Tradeskill')
		or (itemType == 'Miscellaneous' and itemSubType == 'Reagent')
		or (itemType == 'Item Enhancement')
		or isCraftingReagent

	if isCraftingItem and module.DB.NotCrafting then
		print('|cffFF0000BLOCKED:|r Crafting items disabled (NotCrafting = ' .. tostring(module.DB.NotCrafting) .. ')')
		return
	else
		print('|cff00FF00PASSED:|r Crafting check (NotCrafting = ' .. tostring(module.DB.NotCrafting) .. ')')
	end

	-- Pet check
	if itemSubType == 'Companion Pets' then
		print('|cffFF0000BLOCKED:|r Companion pets never sold')
		return
	else
		print('|cff00FF00PASSED:|r Pet check')
	end

	-- Transmog tokens check
	if expacID == 9 and (itemType == 'Miscellaneous' or (itemType == 'Armor' and itemSubType == 'Miscellaneous')) and iLevel == 0 and quality >= 2 then
		print('|cffFF0000BLOCKED:|r Transmog token protection')
		return
	else
		print('|cff00FF00PASSED:|r Transmog token check')
	end

	-- Consumables check
	if module.DB.NotConsumables and (itemType == 'Consumable' or itemSubType == 'Consumables') and quality ~= 0 then
		print('|cffFF0000BLOCKED:|r Consumables disabled (NotConsumables = ' .. tostring(module.DB.NotConsumables) .. ')')
		return
	else
		print('|cff00FF00PASSED:|r Consumables check (NotConsumables = ' .. tostring(module.DB.NotConsumables) .. ')')
	end

	-- Use text check
	if actualBag and actualSlot then
		local hasUseText = pcall(function()
			Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
			Tooltip:SetBagItem(actualBag, actualSlot)
			
			for i = 1, Tooltip:NumLines() do
				local line = _G['AutoSellTooltipTextLeft' .. i]
				if line and line:GetText() then
					local text = line:GetText():lower()
					if text:find('^use:') or text:find('^%s*use:') then
						Tooltip:Hide()
						return true
					end
				end
			end
			Tooltip:Hide()
			return false
		end)
		
		if hasUseText then
			print('|cffFF0000BLOCKED:|r Item has "Use:" text in tooltip (profession enhancement protection)')
			return
		else
			print('|cff00FF00PASSED:|r Use text check (no "Use:" found)')
		end
	else
		print('|cffFFFFFF SKIPPED:|r Use text check (item not found in bags)')
	end

	-- Profile blacklist checks
	if SUI:IsInTable(module.DB.Blacklist.Items, itemID) then
		print('|cffFF0000BLOCKED:|r In profile item blacklist')
		return
	elseif SUI:IsInTable(module.DB.Blacklist.Types, itemType) then
		print("|cffFF0000BLOCKED:|r Item type '" .. itemType .. "' in profile type blacklist")
		return
	elseif SUI:IsInTable(module.DB.Blacklist.Types, itemSubType) then
		print("|cffFF0000BLOCKED:|r Item subtype '" .. itemSubType .. "' in profile type blacklist")
		return
	else
		print('|cff00FF00PASSED:|r Profile blacklist checks')
	end

	-- Final decision
	local finalDecision = module:IsSellable(itemID, link, 0, 1)
	print(string.format('|cffFFFFFF--- FINAL DECISION: %s ---|r', finalDecision and '|cff00FF00WILL SELL|r' or '|cffFF0000WILL NOT SELL|r'))

	if finalDecision then
		print('|cff00FF00RESULT:|r Item should be marked with sell icon')
	else
		print('|cffFF0000RESULT:|r Item should NOT be marked with sell icon')
	end
end

---Handle Alt+Right Click on items to add/remove from character-specific lists
function module:HandleItemClick(link)
	if not IsAltKeyDown() then return end

	-- Control+Alt+Right Click for debugging
	if IsControlKeyDown() then
		module:DebugItemSellability(link)
		return
	end

	-- Extract item ID from hyperlink using string matching
	local itemID = tonumber(string.match(link, 'item:(%d+)'))
	if not itemID then return end

	local itemName, _, quality = C_Item.GetItemInfo(itemID)
	if not itemName then return end

	-- Find the actual bag/slot for this item to use exact same call as marking/selling
	local actualBag, actualSlot, actualItemInfo = nil, nil, nil
	for bag = 0, MAX_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
			if itemInfo and itemInfo.itemID == itemID then
				actualBag, actualSlot, actualItemInfo = bag, slot, itemInfo
				break
			end
		end
		if actualBag then break end
	end

	-- Check current state of this item
	local isInCharBlacklist = module.CharDB.Blacklist[itemID]
	local isInCharWhitelist = module.CharDB.Whitelist[itemID]
	local isSellable = false
	if actualItemInfo then isSellable = module:IsSellable(actualItemInfo.itemID, actualItemInfo.hyperlink, actualBag, actualSlot) end

	if isInCharWhitelist then
		-- State 1: In whitelist -> Move to blacklist
		module.CharDB.Whitelist[itemID] = nil
		module.CharDB.Blacklist[itemID] = true
		print(string.format('|cffFFFF00AutoSell:|r %s added to character blacklist (will not be sold)', ITEM_QUALITY_COLORS[quality].hex .. (itemName or 'Unknown') .. '|r'))
	elseif isInCharBlacklist then
		-- State 2: In blacklist -> Remove from all lists (use default behavior)
		module.CharDB.Blacklist[itemID] = nil
		print(string.format('|cffFFFF00AutoSell:|r %s removed from character lists (using default rules)', ITEM_QUALITY_COLORS[quality].hex .. (itemName or 'Unknown') .. '|r'))
	else
		-- State 3: Not in any character list -> Add to whitelist
		module.CharDB.Whitelist[itemID] = true
		print(string.format('|cffFFFF00AutoSell:|r %s added to character whitelist (will be sold)', ITEM_QUALITY_COLORS[quality].hex .. (itemName or 'Unknown') .. '|r'))
	end

	-- Refresh bag markings if enabled
	if module.DB.ShowBagMarking and module.markItems then module.markItems() end

	-- Request refresh for Baganator if loaded
	if C_AddOns.IsAddOnLoaded('Baganator') and Baganator and Baganator.API then
		-- Request refresh so junk plugin can re-evaluate all items
		Baganator.API.RequestItemButtonsRefresh()
	end
end

---Set up click handler for Alt+Right Click functionality
function module:SetupClickHandler()
	-- Hook the global modified item click handler
	hooksecurefunc('HandleModifiedItemClick', function(link)
		module:HandleItemClick(link)
	end)
end

function module:OnInitialize()
	local CharDbDefaults = {
		Whitelist = {},
		Blacklist = {},
	}

	module.Database = SUI.SpartanUIDB:RegisterNamespace('AutoSell', { profile = DbDefaults, char = CharDbDefaults })
	module.DB = module.Database.profile ---@type SUI.Module.AutoSell.DB
	module.CharDB = module.Database.char ---@type SUI.Module.AutoSell.CharDB

	-- Handle potential item level squish after DB is initialized
	HandleItemLevelSquish()

	-- Set up Alt+Right Click handling
	module:SetupClickHandler()
end

function module:OnEnable()
	if not LoadedOnce then module:InitializeOptions() end
	if SUI:IsModuleDisabled(module) then return end

	module:RegisterEvent('MERCHANT_SHOW')
	module:RegisterEvent('MERCHANT_CLOSED')

	module:CreateMiniVendorPanels()

	-- Initialize bag marking system if enabled
	if module.DB.ShowBagMarking then module:InitializeBagMarking() end

	-- Build blacklist cache on enable for better performance
	buildBlacklistLookup()

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
