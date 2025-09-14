local SUI, L, print = SUI, SUI.L, SUI.print
---@class SUI.Module.AutoSell : SUI.Module
local module = SUI:GetModule('AutoSell')

local BAG_COUNT = 4
local usingDefaultBags = false
local markingFrame = nil
local lastMarkTime = 0
local MARK_THROTTLE = 0.5 -- Minimum time between marking operations (in seconds)
local vendorOpen = false
local markingTimer = nil -- Ace3 timer handle

local function debugMsg(msg, level)
	-- Use the BagMarking component of the AutoSell logger
	-- This creates the hierarchy: AutoSell -> BagMarking
	SUI.ModuleLog(module, msg, 'BagMarking', level or 'debug')
end

-- Function to show the sell icon on an item button
local function showSellIcon(itemButton)
	if not itemButton.autoSellIcon then
		local texture = itemButton:CreateTexture(nil, 'OVERLAY')
		texture:SetAtlas('Levelup-Icon-Bag')
		texture:SetSize(16, 16)

		-- Position in top-right corner with padding
		texture:SetPoint('TOPRIGHT', -2, -2)

		itemButton.autoSellIcon = texture
	end

	itemButton.autoSellIcon:Show()
end

-- Function to hide the sell icon on an item button
local function hideSellIcon(itemButton)
	if itemButton.autoSellIcon then
		itemButton.autoSellIcon:Hide()
	end
end

-- Check if item should be marked and display/hide icon accordingly
local function displaySellIcon(bagNumber, slotNumber, itemButton)
	if not bagNumber or not slotNumber or not itemButton then
		return
	end

	local itemInfo, _, _, _, _, _, link, _, _, itemID = C_Container.GetContainerItemInfo(bagNumber, slotNumber)

	if SUI.IsRetail and itemInfo then
		debugMsg('Checking item in bag ' .. bagNumber .. ' slot ' .. slotNumber .. ': ' .. tostring(itemInfo.itemID))
		local sellable = module:IsSellable(itemInfo.itemID, itemInfo.hyperlink, bagNumber, slotNumber)
		debugMsg('Marking result: ' .. tostring(sellable))
		if sellable then
			showSellIcon(itemButton)
		else
			hideSellIcon(itemButton)
		end
	elseif not SUI.IsRetail and itemID then
		debugMsg('Checking item in bag ' .. bagNumber .. ' slot ' .. slotNumber .. ': ' .. tostring(itemID))
		local sellable = module:IsSellable(itemID, link, bagNumber, slotNumber)
		debugMsg('Marking result: ' .. tostring(sellable))
		if sellable then
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
	if not Baggins or not Baggins.bagframes then
		return
	end

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

		if not itemButton then
			return
		end

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
			if itemButton then
				displaySellIcon(bagNumber, slotNumber, itemButton)
			end
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

			if bag and slot then
				displaySellIcon(bag, slot, itemButton)
			end
		end
	end
end

local function markArkInventoryBags()
	for bagNumber = 0, BAG_COUNT do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local itemButton = _G['ARKINV_Frame1ScrollContainerBag' .. bagNumber + 1 .. 'Item' .. slotNumber]
			if itemButton then
				displaySellIcon(bagNumber, slotNumber, itemButton)
			end
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
			if itemButton then
				displaySellIcon(bagNumber, slotNumber, itemButton)
			end
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
			if itemButton then
				displaySellIcon(bagNumber, slotNumber, itemButton)
			end
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
	if not LiteBagInventoryPanel or not LiteBagInventoryPanel.itemButtons then
		return
	end

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
			if itemButton then
				displaySellIcon(bagNumber, slotNumber, itemButton)
			end
		end
	end
end

local function markLUIBags()
	for bagNumber = 0, BAG_COUNT do
		local bagsSlotCount = C_Container.GetContainerNumSlots(bagNumber)
		for slotNumber = 1, bagsSlotCount do
			local itemButton = _G['LUIBags_Item' .. bagNumber .. '_' .. slotNumber]
			if itemButton then
				displaySellIcon(bagNumber, slotNumber, itemButton)
			end
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
	debugMsg('markNormalBags() called', 'debug')

	local combinedBags = _G['ContainerFrameCombinedBags']
	debugMsg('CombinedBags frame: ' .. tostring(combinedBags), 'debug')
	debugMsg('CombinedBags shown: ' .. tostring(combinedBags and combinedBags:IsShown()), 'debug')

	-- Check individual containers first
	local anyContainerShown = false
	for containerNumber = 0, BAG_COUNT do
		local container = _G['ContainerFrame' .. containerNumber + 1]
		local isShown = container and container:IsShown()
		debugMsg('Container ' .. containerNumber .. ': frame=' .. tostring(container) .. ', shown=' .. tostring(isShown), 'debug')
		if isShown then
			anyContainerShown = true
		end
	end
	debugMsg('Any individual container shown: ' .. tostring(anyContainerShown), 'debug')

	-- Use the proper WoW API method to enumerate item buttons
	if combinedBags and combinedBags:IsShown() then
		debugMsg('Combined bags are shown - using EnumerateValidItems', 'info')

		-- Use the WoW API method to get all item buttons
		if combinedBags.EnumerateValidItems then
			local itemCount = 0
			for i, itemButton in combinedBags:EnumerateValidItems() do
				itemCount = itemCount + 1
				local bagID = itemButton:GetBagID()
				local slotID = itemButton:GetID()

				debugMsg('Item button ' .. itemCount .. ': bagID=' .. tostring(bagID) .. ', slotID=' .. tostring(slotID), 'debug')
				displaySellIcon(bagID, slotID, itemButton)
			end
			debugMsg('Processed ' .. itemCount .. ' item buttons via EnumerateValidItems', 'info')
		else
			debugMsg('Combined bags frame does not have EnumerateValidItems method', 'warning')
		end
	else
		-- Handle individual container frames
		for containerNumber = 0, BAG_COUNT do
			local container = _G['ContainerFrame' .. containerNumber + 1]

			if container and container:IsShown() then
				debugMsg('Processing individual container ' .. containerNumber .. ' with EnumerateValidItems', 'info')

				if container.EnumerateValidItems then
					local itemCount = 0
					for i, itemButton in container:EnumerateValidItems() do
						itemCount = itemCount + 1
						local bagID = itemButton:GetBagID()
						local slotID = itemButton:GetID()

						debugMsg('Container ' .. containerNumber .. ' item ' .. itemCount .. ': bagID=' .. tostring(bagID) .. ', slotID=' .. tostring(slotID), 'debug')
						displaySellIcon(bagID, slotID, itemButton)
					end
					debugMsg('Processed ' .. itemCount .. ' items in container ' .. containerNumber, 'info')
				else
					debugMsg('Container ' .. containerNumber .. ' does not have EnumerateValidItems method', 'warning')
				end
			else
				debugMsg('Skipping container ' .. containerNumber .. ' - not shown', 'debug')
			end
		end
	end
end

-- Main marking function that determines which bag addon is active
local function markItems()
	if SUI:IsModuleDisabled('AutoSell') then
		return
	end

	-- Throttle marking operations to prevent performance issues
	local currentTime = GetTime()
	local throttleTime = vendorOpen and 1.0 or MARK_THROTTLE -- More aggressive throttling when vendor is open
	if currentTime - lastMarkTime < throttleTime then
		return
	end
	lastMarkTime = currentTime

	debugMsg('Marking items for sale', 'info')

	if C_AddOns.IsAddOnLoaded('Baganator') then
		-- Baganator uses junk plugin API, no need for manual marking
		-- The junk plugin is registered during initialization and handles its own display
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

-- Start the marking timer when bags are opened
local function startMarkingTimer()
	if not markingTimer then
		debugMsg('Starting marking timer (1 second interval)', 'info')
		markingTimer = module:ScheduleRepeatingTimer(markItems, 1.0) -- Mark every second
	end
end

-- Stop the marking timer when bags are closed
local function stopMarkingTimer()
	if markingTimer then
		debugMsg('Stopping marking timer', 'info')
		module:CancelTimer(markingTimer)
		markingTimer = nil
	end
end

-- Handle Baggins specific events
local function handleBagginsOpened()
	startMarkingTimer()
end

-- Baganator junk plugin callback
local function baganatorJunkCallback(bagID, slotID, itemID, itemLink)
	-- Use the module's IsSellable logic to determine if item should show junk coin
	local isSellable = module:IsSellable(itemID, itemLink, bagID, slotID)
	return isSellable -- true = show junk coin, false/nil = don't show
end

-- Register Baganator junk plugin
local function registerBaganatorPlugin()
	if not Baganator or not Baganator.API then
		debugMsg('Baganator API not available', 'warning')
		return
	end

	local success, err =
		pcall(
		function()
			Baganator.API.RegisterJunkPlugin(
				'SpartanUI AutoSell', -- label (shown in Baganator settings)
				'SpartanUI_AutoSell', -- id (unique identifier)
				baganatorJunkCallback -- callback function
			)
		end
	)

	if success then
		debugMsg('Baganator junk plugin registered successfully', 'info')
	else
		debugMsg('Baganator junk plugin registration failed: ' .. tostring(err), 'error')
	end
end

-- Initialize bag marking system
function module:InitializeBagMarking()
	if markingFrame then
		return
	end

	debugMsg('InitializeBagMarking() called', 'info')
	markingFrame = CreateFrame('Frame', 'AutoSellBagMarking', UIParent)
	markingFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
	markingFrame:RegisterEvent('BAG_UPDATE')
	markingFrame:RegisterEvent('BAG_UPDATE_DELAYED')
	markingFrame:RegisterEvent('MERCHANT_SHOW')
	markingFrame:RegisterEvent('MERCHANT_CLOSED')

	-- Register for bag open/close events to manage timer
	markingFrame:RegisterEvent('BAG_OPEN')
	markingFrame:RegisterEvent('BAG_CLOSED')

	-- Set up Baggins support if available
	if C_AddOns.IsAddOnLoaded('Baggins') and Baggins then
		Baggins:RegisterSignal('Baggins_BagOpened', handleBagginsOpened, Baggins)
	end

	-- Register Baganator junk plugin if available
	if C_AddOns.IsAddOnLoaded('Baganator') then
		registerBaganatorPlugin()
	end

	markingFrame:SetScript(
		'OnEvent',
		function(self, event, ...)
			if event == 'PLAYER_ENTERING_WORLD' then
				-- Register for bag updates after entering world
				debugMsg('Player entering world, setting up bag marking', 'info')
				-- Try to register Baganator plugin again in case it wasn't loaded yet
				if C_AddOns.IsAddOnLoaded('Baganator') then
					registerBaganatorPlugin()
				end
			elseif event == 'BAG_OPEN' then
				debugMsg('BAG_OPEN event - starting marking timer and marking immediately', 'info')
				-- Mark items immediately when bags are opened
				markItems()
				-- Start the repeating timer for continuous marking
				startMarkingTimer()
			elseif event == 'BAG_CLOSED' then
				debugMsg('BAG_CLOSED event - stopping marking timer', 'info')
				-- Stop the repeating timer when bags are closed
				stopMarkingTimer()
			elseif event == 'MERCHANT_SHOW' then
				vendorOpen = true
				-- Mark items when vendor opens (but throttled)
				markItems()
				-- Start timer if not already running
				startMarkingTimer()
			elseif event == 'MERCHANT_CLOSED' then
				vendorOpen = false
				-- Keep timer running if bags are still open, otherwise stop it
				local combinedBags = _G['ContainerFrameCombinedBags']
				local anyBagOpen = false
				for i = 0, BAG_COUNT do
					local container = _G['ContainerFrame' .. i + 1]
					if (container and container:IsShown()) or (combinedBags and combinedBags:IsShown()) then
						anyBagOpen = true
						break
					end
				end
				if not anyBagOpen then
					stopMarkingTimer()
				end
			elseif event == 'BAG_UPDATE' or event == 'BAG_UPDATE_DELAYED' then
				-- Only trigger immediate marking if timer isn't running
				if not markingTimer then
					-- When vendor is open, be much more conservative about marking
					if vendorOpen then
						-- Use longer delay and throttling when vendor is open to prevent spam
						C_Timer.After(0.5, markItems)
					else
						-- Normal marking when vendor is closed
						C_Timer.After(0.1, markItems)
					end
				end
			end
		end
	)

	debugMsg('Bag marking system initialized', 'info')
end

-- Cleanup function
function module:CleanupBagMarking()
	-- Stop any running timers
	stopMarkingTimer()

	if markingFrame then
		markingFrame:UnregisterAllEvents()
		markingFrame:SetScript('OnEvent', nil)
		markingFrame = nil
	end
	debugMsg('Bag marking system cleaned up', 'info')
end

-- Public interface
module.markItems = markItems
