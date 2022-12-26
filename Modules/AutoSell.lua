local SUI, L, print = SUI, SUI.L, SUI.print
local module = SUI:NewModule('Module_AutoSell') ---@type SUI.Module
module.DisplayName = L['Auto sell']
module.description = 'Auto sells junk and more'
----------------------------------------------------------------------------------------------------
local MaxiLVL = 500

local Tooltip = CreateFrame('GameTooltip', 'AutoSellTooltip', nil, 'GameTooltipTemplate')
local LoadedOnce = false
local totalValue = 0

local ExcludedItems = {
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
}
local ExcludedTypes = {
	'Container',
	'Companions',
	'Holiday',
	'Mounts',
	'Projectiles',
	'Quest',
}

local function debugMsg(msg)
	SUI.Debug(msg, 'AutoSell')
end

local function SetupPage()
	---@type SUI.SetupWizard.PageData
	local PageData = {
		ID = 'Autosell',
		Name = L['Auto sell'],
		SubTitle = L['Auto sell'],
		Desc1 = L['Automatically vendor items when you visit a merchant.'],
		Desc2 = L['Crafting, consumables, and gearset items will not be sold by default.'],
		RequireDisplay = module.DB.FirstLaunch,
		Display = function()
			local SUI_Win = SUI.Setup.window.content
			local StdUi = SUI.StdUi

			--Container
			local AutoSell = CreateFrame('Frame', nil)
			AutoSell:SetParent(SUI_Win)
			AutoSell:SetAllPoints(SUI_Win)

			if SUI:IsModuleDisabled('AutoSell') then
				AutoSell.lblDisabled = StdUi:Label(AutoSell, 'Disabled', 20)
				AutoSell.lblDisabled:SetPoint('CENTER', AutoSell)
				-- Attaching
				SUI_Win.AutoSell = AutoSell
			else
				-- Quality Selling Options
				AutoSell.SellGray = StdUi:Checkbox(AutoSell, L['Sell gray'], 220, 20)
				AutoSell.SellWhite = StdUi:Checkbox(AutoSell, L['Sell white'], 220, 20)
				AutoSell.SellGreen = StdUi:Checkbox(AutoSell, L['Sell green'], 220, 20)
				AutoSell.SellBlue = StdUi:Checkbox(AutoSell, L['Sell blue'], 220, 20)
				AutoSell.SellPurple = StdUi:Checkbox(AutoSell, L['Sell purple'], 220, 20)

				-- Max iLVL
				AutoSell.iLVLDesc = StdUi:Label(AutoSell, L['Maximum iLVL to sell'], nil, nil, 350)
				AutoSell.iLVLLabel = StdUi:NumericBox(AutoSell, 80, 20, module.DB.MaxILVL)
				AutoSell.iLVLLabel:SetMaxValue(MaxiLVL)
				AutoSell.iLVLLabel:SetMinValue(1)
				AutoSell.iLVLLabel.OnValueChanged = function()
					local win = SUI.Setup.window.content.AutoSell

					if math.floor(AutoSell.iLVLLabel:GetValue()) ~= math.floor(AutoSell.iLVLSlider:GetValue()) then AutoSell.iLVLSlider:SetValue(math.floor(AutoSell.iLVLLabel:GetValue())) end
				end

				AutoSell.iLVLSlider = StdUi:Slider(AutoSell, MaxiLVL, 20, module.DB.MaxILVL, false, 1, MaxiLVL)
				AutoSell.iLVLSlider.OnValueChanged = function()
					local win = SUI.Setup.window.content.AutoSell

					if math.floor(AutoSell.iLVLLabel:GetValue()) ~= math.floor(AutoSell.iLVLSlider:GetValue()) then AutoSell.iLVLLabel:SetValue(math.floor(AutoSell.iLVLSlider:GetValue())) end
				end

				-- AutoRepair
				AutoSell.AutoRepair = StdUi:Checkbox(AutoSell, L['Auto repair'], 220, 20)

				-- Positioning
				StdUi:GlueTop(AutoSell.SellGray, SUI_Win, 0, -30)
				StdUi:GlueBelow(AutoSell.SellWhite, AutoSell.SellGray, 0, -5)
				StdUi:GlueBelow(AutoSell.SellGreen, AutoSell.SellWhite, 0, -5)
				StdUi:GlueBelow(AutoSell.SellBlue, AutoSell.SellGreen, 0, -5)
				StdUi:GlueBelow(AutoSell.SellPurple, AutoSell.SellBlue, 0, -5)
				StdUi:GlueBelow(AutoSell.iLVLDesc, AutoSell.SellPurple, 0, -5)
				StdUi:GlueBelow(AutoSell.iLVLSlider, AutoSell.iLVLDesc, -40, -5)
				StdUi:GlueRight(AutoSell.iLVLLabel, AutoSell.iLVLSlider, 2, 0)
				StdUi:GlueBelow(AutoSell.AutoRepair, AutoSell.iLVLSlider, 40, -5)

				-- Attaching
				SUI_Win.AutoSell = AutoSell

				-- Defaults
				AutoSell.SellGray:SetChecked(module.DB.Gray)
				AutoSell.SellWhite:SetChecked(module.DB.White)
				AutoSell.SellGreen:SetChecked(module.DB.Green)
				AutoSell.SellBlue:SetChecked(module.DB.Blue)
				AutoSell.SellPurple:SetChecked(module.DB.Purple)
				AutoSell.AutoRepair:SetChecked(module.DB.AutoRepair)
				AutoSell.iLVLLabel:SetValue(module.DB.MaxILVL)
			end
		end,
		Next = function()
			if SUI:IsModuleEnabled('AutoSell') then
				local SUI_Win = SUI.Setup.window.content.AutoSell

				module.DB.Gray = (SUI_Win.SellGray:GetChecked() == true or false)
				module.DB.White = (SUI_Win.SellWhite:GetChecked() == true or false)
				module.DB.Green = (SUI_Win.SellGreen:GetChecked() == true or false)
				module.DB.Blue = (SUI_Win.SellBlue:GetChecked() == true or false)
				module.DB.Purple = (SUI_Win.SellPurple:GetChecked() == true or false)
				module.DB.AutoRepair = (SUI_Win.AutoRepair:GetChecked() == true or false)
				module.DB.MaxILVL = SUI_Win.iLVLLabel:GetValue()
			end
			module.DB.FirstLaunch = false
		end,
		Skip = function()
			module.DB.FirstLaunch = false
		end,
	}
	SUI.Setup:AddPage(PageData)
end

local function BuildOptions()
	--@type AceConfigOptionsTable
	local optTable = {
		type = 'group',
		name = L['Auto sell'],
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
		end,
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		args = {
			NotCrafting = {
				name = L["Don't sell crafting items"],
				type = 'toggle',
				order = 1,
				width = 'full',
			},
			NotConsumables = {
				name = L["Don't sell consumables"],
				type = 'toggle',
				order = 2,
				width = 'full',
			},
			NotInGearset = {
				name = L["Don't sell items in a equipment set"],
				type = 'toggle',
				order = 3,
				width = 'full',
			},
			GearTokens = {
				name = L['Sell tier tokens'],
				type = 'toggle',
				order = 4,
				width = 'full',
			},
			MaxILVL = {
				name = L['Maximum iLVL to sell'],
				type = 'range',
				order = 10,
				width = 'full',
				min = 1,
				max = MaxiLVL,
				step = 1,
			},
			Gray = {
				name = L['Sell gray'],
				type = 'toggle',
				order = 20,
				width = 'double',
			},
			White = {
				name = L['Sell white'],
				type = 'toggle',
				order = 21,
				width = 'double',
			},
			Green = {
				name = L['Sell green'],
				type = 'toggle',
				order = 22,
				width = 'double',
			},
			Blue = {
				name = L['Sell blue'],
				type = 'toggle',
				order = 23,
				width = 'double',
			},
			Purple = {
				name = L['Sell purple'],
				type = 'toggle',
				order = 24,
				width = 'double',
			},
			line1 = { name = '', type = 'header', order = 200 },
			AutoRepair = {
				name = L['Auto repair'],
				type = 'toggle',
				order = 201,
			},
			UseGuildBankRepair = {
				name = L['Use guild bank repair if possible'],
				type = 'toggle',
				order = 202,
			},
			line2 = { name = '', type = 'header', order = 600 },
		},
	}

	SUI.Options:AddOptions(optTable, 'AutoSell')
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

function module:IsSellable(item, ilink, bag, slot)
	if not item then return false end
	local name, _, quality, _, _, itemType, itemSubType, _, equipSlot, _, vendorPrice, _, _, _, expacID, _, isCraftingReagent = GetItemInfo(ilink)
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
	if module.DB.NotConsumables and (itemType == 'Consumable' or itemSubType == 'Consumables') then return false end

	if string.find(name, '') and quality == 1 then return false end

	if not SUI:IsInTable(ExcludedItems, item) and not SUI:IsInTable(ExcludedTypes, itemType) and not SUI:IsInTable(ExcludedTypes, itemSubType) then --Legion identified some junk as consumable
		debugMsg('--Selling--')
		debugMsg(item)
		debugMsg(name)
		debugMsg(ilink)
		debugMsg(expacID)
		debugMsg('ilvl: ' .. iLevel)
		debugMsg('type: ' .. itemType)
		debugMsg('sub type: ' .. itemSubType)
		return true
	end

	return false
end

function module:SellTrash()
	--Reset Locals
	totalValue = 0
	-- ItemsToSellTotal = 0
	local ItemToSell = {}

	--Find Items to sell
	for bag = 0, 4 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemInfo, _, _, _, _, _, link, _, _, itemID = C_Container.GetContainerItemInfo(bag, slot)
			if SUI.IsRetail and itemInfo and module:IsSellable(itemInfo.itemID, itemInfo.hyperlink, bag, slot) then
				ItemToSell[#ItemToSell + 1] = { bag, slot }
				totalValue = totalValue + (select(11, GetItemInfo(itemInfo.itemID)) * itemInfo.stackCount)
			elseif not SUI.IsRetail and module:IsSellable(itemID, link, bag, slot) then
				ItemToSell[#ItemToSell + 1] = { bag, slot }
				totalValue = totalValue + (select(11, GetItemInfo(itemID)) * select(2, C_Container.GetContainerItemInfo(bag, slot)))
			end
		end
	end

	--Sell Items if needed
	if #ItemToSell == 0 then
		SUI:Print(L['No items are to be auto sold'])
	else
		SUI:Print('Need to sell ' .. #ItemToSell .. ' item(s) for ' .. SUI:GoldFormattedValue(totalValue))
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

function module:OnInitialize()
	---@class AutoSell.DB
	local defaults = {
		FirstLaunch = true,
		NotCrafting = true,
		NotConsumables = true,
		NotInGearset = true,
		MaxILVL = 200,
		Gray = true,
		White = false,
		Green = false,
		Blue = false,
		Purple = false,
		GearTokens = false,
		AutoRepair = false,
		UseGuildBankRepair = false,
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('AutoSell', { profile = defaults })
	module.DB = module.Database.profile ---@type AutoSell.DB
end

function module:OnEnable()
	if not LoadedOnce then
		BuildOptions()
		SetupPage()
	end
	if SUI:IsModuleDisabled(module) then return end

	module:RegisterEvent('MERCHANT_SHOW')
	module:RegisterEvent('MERCHANT_CLOSED')
	LoadedOnce = true
end

function module:OnDisable()
	SUI:Print('Autosell disabled')
	module:UnregisterEvent('MERCHANT_SHOW')
	module:UnregisterEvent('MERCHANT_CLOSED')
end
