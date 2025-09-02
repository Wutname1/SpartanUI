local SUI, L, print = SUI, SUI.L, SUI.print
---@class SUI.Module.AutoSell : SUI.Module
local module = SUI:GetModule('AutoSell')

local BAG_COUNT = 4
local markCounter = 0
local countLimit = 30
local usingDefaultBags = false
local markingFrame = nil

local function debugMsg(msg)
	SUI.Debug(msg, 'AutoSell.BagMarking')
end

-- Function to show the sell icon on an item button
local function showSellIcon(itemButton)
	if not itemButton.autoSellIcon then
		local texture = itemButton:CreateTexture(nil, 'OVERLAY')
		texture:SetAtlas('Levelup-Icon-Bag')
		texture:SetSize(16, 16)

		-- Position in bottom-left corner with padding
		texture:SetPoint('BOTTOMLEFT', 2, 2)

		itemButton.autoSellIcon = texture
	end

	itemButton.autoSellIcon:Show()
end

-- Function to hide the sell icon on an item button
local function hideSellIcon(itemButton)
	if itemButton.autoSellIcon then itemButton.autoSellIcon:Hide() end
end

-- Check if item should be marked and display/hide icon accordingly
local function displaySellIcon(bagNumber, slotNumber, itemButton)
	if not bagNumber or not slotNumber or not itemButton then return end

	local itemInfo, _, _, _, _, _, link, _, _, itemID = C_Container.GetContainerItemInfo(bagNumber, slotNumber)

	if SUI.IsRetail and itemInfo then
		if module:IsSellable(itemInfo.itemID, itemInfo.hyperlink, bagNumber, slotNumber) then
			showSellIcon(itemButton)
		else
			hideSellIcon(itemButton)
		end
	elseif not SUI.IsRetail and itemID then
		if module:IsSellable(itemID, link, bagNumber, slotNumber) then
			showSellIcon(itemButton)
		else
			hideSellIcon(itemButton)
		end
	else
		hideSellIcon(itemButton)
	end
end

-- Bag addon specific marking functions
local function markBagginsBags()
	if not Baggins or not Baggins.bagframes then return end

	for bagid, bag in ipairs(Baggins.bagframes) do
		for sectionid, section in ipairs(bag.sections) do
			for buttonid, itemButton in ipairs(section.items) do
				local itemsBagNumber = itemButton:GetParent():GetID()
				local itemsSlotNumber = itemButton:GetID()
				displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
			end
		end
	end
end

local function markBagnonBags()
	for slotNumber = 1, 250 do
		local itemButton = _G['BagnonContainerItem' .. slotNumber]

		if not itemButton then return end

		local itemButtonParent = itemButton:GetParent()
		if itemButtonParent then
			local itemsBagNumber = itemButtonParent:GetID()
			local itemsSlotNumber = itemButton:GetID()
			displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
		end
	end
end

local function markCombuctorBags()
	for bagNumber = 0, BAG_COUNT do
		for slotNumber = 1, 36 do
			local itemButton = _G['ContainerFrame' .. bagNumber + 1 .. 'Item' .. slotNumber]

			if itemButton then
				local itemButtonParent = itemButton:GetParent()
				if itemButtonParent then
					local itemsBagNumber = itemButtonParent:GetID()
					local itemsSlotNumber = itemButton:GetID()
					displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
				end
			end
		end
	end
end

local function markOneBagBags()
	for bagNumber = 0, BAG_COUNT do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local itemButton = _G['OneBagFrameBag' .. bagNumber .. 'Item' .. bagsSlotCount - slotNumber + 1]

			if itemButton then
				local itemsBagNumber = itemButton:GetParent():GetID()
				local itemsSlotNumber = itemButton:GetID()
				displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
			end
		end
	end
end

local function markBaudBagBags()
	for bagNumber = 0, BAG_COUNT do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local itemButton = _G['BaudBagSubBag' .. bagNumber .. 'Item' .. slotNumber]
			if itemButton then displaySellIcon(bagNumber, slotNumber, itemButton) end
		end
	end
end

local function markBetterBags()
	for slotNumber = 1, 1000 do
		local itemButton = _G['BetterBagsItemButton' .. slotNumber]
		if itemButton then
			local itemButtonParent = itemButton:GetParent()
			if itemButtonParent then
				local itemsBagNumber = itemButtonParent:GetID()
				local itemsSlotNumber = itemButton:GetID()
				displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
			end
		end
	end
end

local function markAdiBagBags()
	for slotNumber = 1, 1000 do
		local itemButton = _G['AdiBagsItemButton' .. slotNumber]
		if itemButton then
			local _, bag, slot = strsplit('-', tostring(itemButton))

			bag = tonumber(bag)
			slot = tonumber(slot)

			if bag and slot then displaySellIcon(bag, slot, itemButton) end
		end
	end
end

local function markArkInventoryBags()
	for bagNumber = 0, BAG_COUNT do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local itemButton = _G['ARKINV_Frame1ScrollContainerBag' .. bagNumber + 1 .. 'Item' .. slotNumber]
			if itemButton then displaySellIcon(bagNumber, slotNumber, itemButton) end
		end
	end
end

local function markCargBagsNivayaBags()
	local totalSlotCount = 0
	for bagNumber = 0, BAG_COUNT do
		totalSlotCount = totalSlotCount + C_Container.GetContainerNumSlots(bagNumber)
	end

	totalSlotCount = totalSlotCount * 5

	for slotNumber = 1, totalSlotCount do
		local itemButton = _G['NivayaSlot' .. slotNumber]
		if itemButton then
			local itemsBag = itemButton:GetParent()

			if itemsBag then
				local itemsBagNumber = itemsBag:GetID()
				local itemsSlotNumber = itemButton:GetID()
				displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
			end
		end
	end
end

local function markMonoBags()
	local totalSlotCount = 0
	for bagNumber = 0, BAG_COUNT do
		totalSlotCount = totalSlotCount + C_Container.GetContainerNumSlots(bagNumber)
	end

	for slotNumber = 1, totalSlotCount do
		local itemButton = _G['m_BagsSlot' .. slotNumber]
		if itemButton then
			local itemsBagNumber = itemButton:GetParent():GetID()
			local itemsSlotNumber = itemButton:GetID()
			displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
		end
	end
end

local function markDerpyBags()
	for bagNumber = 0, BAG_COUNT do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local itemButton = _G['StuffingBag' .. bagNumber .. '_' .. slotNumber]
			if itemButton then displaySellIcon(bagNumber, slotNumber, itemButton) end
		end
	end
end

local function markElvUIBags()
	for bagNumber = 0, BAG_COUNT + 1 do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local containerFrameName = 'ElvUI_ContainerFrameBag'
			local containerFrameBagNumber = bagNumber - 1

			if bagNumber == 0 then
				containerFrameBagNumber = 1
				containerFrameName = containerFrameName .. '-'
			end

			local itemButton = _G[containerFrameName .. containerFrameBagNumber .. 'Slot' .. slotNumber]
			if itemButton then displaySellIcon(bagNumber, slotNumber, itemButton) end
		end
	end
end

local function markInventorianBags()
	for bagNumber = 0, NUM_CONTAINER_FRAMES do
		for slotNumber = 1, 36 do
			local itemButton = _G['ContainerFrame' .. bagNumber + 1 .. 'Item' .. slotNumber]

			if itemButton then
				local itemButtonParent = itemButton:GetParent()
				if itemButtonParent then
					local itemsBagNumber = itemButtonParent:GetID()
					local itemsSlotNumber = itemButton:GetID()
					displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
				end
			end
		end
	end
end

local function markLiteBagBags()
	if not LiteBagInventoryPanel or not LiteBagInventoryPanel.itemButtons then return end

	for i = 1, LiteBagInventoryPanel.size do
		local button = LiteBagInventoryPanel.itemButtons[i]
		if button then
			local itemsBagNumber = button:GetParent():GetID()
			local itemsSlotNumber = button:GetID()
			displaySellIcon(itemsBagNumber, itemsSlotNumber, button)
		end
	end
end

local function markfamBagsBags()
	for bagNumber = 0, BAG_COUNT do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local itemButton = _G['famBagsButton_' .. bagNumber .. '_' .. slotNumber]
			if itemButton then displaySellIcon(bagNumber, slotNumber, itemButton) end
		end
	end
end

local function markLUIBags()
	for bagNumber = 0, BAG_COUNT do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local itemButton = _G['LUIBags_Item' .. bagNumber .. '_' .. slotNumber]
			if itemButton then displaySellIcon(bagNumber, slotNumber, itemButton) end
		end
	end
end

local function markRealUIBags()
	local totalSlotCount = 0
	for bagNumber = 0, BAG_COUNT do
		totalSlotCount = totalSlotCount + C_Container.GetContainerNumSlots(bagNumber)
	end

	totalSlotCount = totalSlotCount * 5

	for slotNumber = 1, totalSlotCount do
		local itemButton = _G['RealUIInventory_Slot' .. slotNumber]
		if itemButton then
			local itemsBag = itemButton:GetParent()

			if itemsBag then
				local itemsBagNumber = itemsBag:GetID()
				local itemsSlotNumber = itemButton:GetID()
				displaySellIcon(itemsBagNumber, itemsSlotNumber, itemButton)
			end
		end
	end
end

-- Default WoW bags (and compatible addons like bBag)
local function markNormalBags()
	for containerNumber = 0, BAG_COUNT do
		local container = _G['ContainerFrame' .. containerNumber + 1]
		local combinedBags = _G['ContainerFrameCombinedBags']

		if container and container:IsShown() then
			local bagsSlotCount = C_Container.GetContainerNumSlots(containerNumber)
			for slotNumber = 1, bagsSlotCount do
				local itemButton = _G['ContainerFrame' .. containerNumber + 1 .. 'Item' .. bagsSlotCount - slotNumber + 1]

				if itemButton then
					local bagNumber = itemButton:GetParent():GetID()
					local actualSlotNumber = itemButton:GetID()
					displaySellIcon(bagNumber, actualSlotNumber, itemButton)
				end
			end
		elseif combinedBags and combinedBags:IsShown() then
			local bagsSlotCount = C_Container.GetContainerNumSlots(containerNumber)
			for slotNumber = 1, bagsSlotCount do
				local itemButton = _G['ContainerFrame' .. containerNumber + 1 .. 'Item' .. bagsSlotCount - slotNumber + 1]
				if itemButton then
					local actualSlotNumber = itemButton:GetID()
					displaySellIcon(containerNumber, actualSlotNumber, itemButton)
				end
			end
		end
	end
end

-- Main marking function that determines which bag addon is active
local function markItems()
	if SUI:IsModuleDisabled('AutoSell') then return end

	debugMsg('Marking items for sale')

	if C_AddOns.IsAddOnLoaded('Baganator') then
		-- Baganator uses API-based corner widgets, no need for manual marking
		-- The corner widget is registered during initialization
		return
	elseif C_AddOns.IsAddOnLoaded('Baggins') then
		markBagginsBags()
	elseif C_AddOns.IsAddOnLoaded('Combuctor') then
		markCombuctorBags()
	elseif C_AddOns.IsAddOnLoaded('Bagnon') then
		markBagnonBags()
	elseif C_AddOns.IsAddOnLoaded('OneBag3') then
		markOneBagBags()
	elseif C_AddOns.IsAddOnLoaded('BaudBag') then
		markBaudBagBags()
	elseif C_AddOns.IsAddOnLoaded('AdiBags') then
		markAdiBagBags()
	elseif C_AddOns.IsAddOnLoaded('ArkInventory') then
		markArkInventoryBags()
	elseif C_AddOns.IsAddOnLoaded('famBags') then
		markfamBagsBags()
	elseif C_AddOns.IsAddOnLoaded('cargBags_Nivaya') then
		markCargBagsNivayaBags()
	elseif C_AddOns.IsAddOnLoaded('m_Bags') then
		markMonoBags()
	elseif C_AddOns.IsAddOnLoaded('DerpyStuffing') then
		markDerpyBags()
	elseif C_AddOns.IsAddOnLoaded('Inventorian') then
		markInventorianBags()
	elseif C_AddOns.IsAddOnLoaded('LiteBag') then
		markLiteBagBags()
	elseif C_AddOns.IsAddOnLoaded('ElvUI') and _G['ElvUI_ContainerFrame'] then
		markElvUIBags()
	elseif C_AddOns.IsAddOnLoaded('LUI') and _G['LUIBags_Item0_1'] then
		markLUIBags()
	elseif C_AddOns.IsAddOnLoaded('RealUI_Inventory') then
		markRealUIBags()
	elseif C_AddOns.IsAddOnLoaded('BetterBags') then
		markBetterBags()
	else
		usingDefaultBags = true
		markNormalBags()
	end
end

-- OnUpdate handler for continuous marking
local function onUpdate()
	markCounter = markCounter + 1
	if markCounter <= countLimit then
		return
	else
		markCounter = 0
		markItems()
	end
end

-- Handle Baggins specific events
local function handleBagginsOpened()
	if markCounter == 0 then markingFrame:SetScript('OnUpdate', onUpdate) end
end

-- Register Baganator corner widget
local function registerBaganatorWidget()
	if not Baganator or not Baganator.API then return end
	
	local function onUpdate(cornerFrame, itemDetails)
		if not itemDetails or not itemDetails.itemID then
			return nil
		end
		
		local isSellable = module:IsSellable(itemDetails.itemID, itemDetails.itemLink, itemDetails.bagID, itemDetails.slotID)
		if isSellable then
			cornerFrame:Show()
			return true
		else
			cornerFrame:Hide()
			return false
		end
	end
	
	local function onInit(itemButton)
		local texture = itemButton:CreateTexture(nil, 'OVERLAY')
		texture:SetAtlas('Levelup-Icon-Bag')
		texture:SetSize(16, 16)
		return texture
	end
	
	Baganator.API.RegisterCornerWidget(
		'AutoSell', -- label
		'SpartanUI_AutoSell', -- id
		onUpdate, -- onUpdate callback
		onInit, -- onInit callback
		{corner = 'bottom_left', priority = 1}, -- defaultPosition
		false -- isFast
	)
	
	debugMsg('Baganator corner widget registered')
end

-- Initialize bag marking system
function module:InitializeBagMarking()
	if markingFrame then return end

	markingFrame = CreateFrame('Frame', 'AutoSellBagMarking', UIParent)
	markingFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
	markingFrame:RegisterEvent('BAG_UPDATE')
	markingFrame:RegisterEvent('BAG_UPDATE_DELAYED')

	-- Initial marking setup with delay
	countLimit = 400
	markingFrame:SetScript('OnUpdate', onUpdate)

	-- Set up Baggins support if available
	if C_AddOns.IsAddOnLoaded('Baggins') and Baggins then Baggins:RegisterSignal('Baggins_BagOpened', handleBagginsOpened, Baggins) end

	-- Register Baganator widget if available
	if C_AddOns.IsAddOnLoaded('Baganator') then
		registerBaganatorWidget()
	end

	markingFrame:SetScript('OnEvent', function(self, event, ...)
		if event == 'PLAYER_ENTERING_WORLD' then
			-- Register for bag updates after entering world
			debugMsg('Player entering world, setting up bag marking')
			-- Try to register Baganator widget again in case it wasn't loaded yet
			if C_AddOns.IsAddOnLoaded('Baganator') then
				registerBaganatorWidget()
			end
		elseif event == 'BAG_UPDATE' or event == 'BAG_UPDATE_DELAYED' then
			-- Delay marking slightly to allow bag contents to update
			C_Timer.After(0.1, markItems)
		end
	end)

	debugMsg('Bag marking system initialized')
end

-- Cleanup function
function module:CleanupBagMarking()
	if markingFrame then
		markingFrame:UnregisterAllEvents()
		markingFrame:SetScript('OnUpdate', nil)
		markingFrame:SetScript('OnEvent', nil)
		markingFrame = nil
	end
	debugMsg('Bag marking system cleaned up')
end

-- Public interface
module.markItems = markItems
