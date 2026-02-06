local SUI, L = SUI, SUI.L
---@class SUI.Module.UIEnhancements
local module = SUI:GetModule('UIEnhancements')
----------------------------------------------------------------------------------------------------

-- Check if LootAlertSystem exists (may not in Classic versions)
if not LootAlertSystem then
	return
end

-- LibSharedMedia for sound customization
local LSM = SUI.Lib.LSM

-- Slot mapping from inventory type to equipment slot names
local INVTYPE_TO_SLOTS = {
	INVTYPE_AMMO = {},
	INVTYPE_HEAD = { 'HeadSlot' },
	INVTYPE_NECK = { 'NeckSlot' },
	INVTYPE_SHOULDER = { 'ShoulderSlot' },
	INVTYPE_BODY = { 'ShirtSlot' },
	INVTYPE_CHEST = { 'ChestSlot' },
	INVTYPE_ROBE = { 'ChestSlot' },
	INVTYPE_WAIST = { 'WaistSlot' },
	INVTYPE_LEGS = { 'LegsSlot' },
	INVTYPE_FEET = { 'FeetSlot' },
	INVTYPE_WRIST = { 'WristSlot' },
	INVTYPE_HAND = { 'HandsSlot' },
	INVTYPE_FINGER = { 'Finger0Slot', 'Finger1Slot' },
	INVTYPE_TRINKET = { 'Trinket0Slot', 'Trinket1Slot' },
	INVTYPE_CLOAK = { 'BackSlot' },
	INVTYPE_WEAPON = { 'MainHandSlot', 'SecondaryHandSlot' },
	INVTYPE_2HWEAPON = { 'MainHandSlot' },
	INVTYPE_WEAPONMAINHAND = { 'MainHandSlot' },
	INVTYPE_WEAPONOFFHAND = { 'SecondaryHandSlot' },
	INVTYPE_HOLDABLE = { 'SecondaryHandSlot' },
	INVTYPE_SHIELD = { 'SecondaryHandSlot' },
	INVTYPE_RANGED = { 'MainHandSlot' },
	INVTYPE_RANGEDRIGHT = { 'MainHandSlot' },
	INVTYPE_THROWN = { 'MainHandSlot' },
	INVTYPE_RELIC = {},
	INVTYPE_TABARD = { 'TabardSlot' },
}

-- State tracking
local State = {
	valid = false,
	currentFrame = nil,
	isWaitingForEquip = false,
	isEquipped = false,
}

-- UI Constants
local POPUP_WIDTH = 190
local POPUP_HEIGHT = 28
local CONTENT_SIZE = 16

-- UI Frame
local popupFrame = nil
local eventFrame = nil
local lootAlertHooked = false

----------------------------------------------------------------------------------------------------
-- Utility Functions
----------------------------------------------------------------------------------------------------

---Check if an item link is equippable gear (armor or weapon)
---@param itemLink string
---@return boolean
local function IsEquippableGearLink(itemLink)
	if not itemLink then
		return false
	end

	local _, _, _, itemEquipLoc, _, classID = C_Item.GetItemInfoInstant(itemLink)
	if not itemEquipLoc or itemEquipLoc == '' then
		return false
	end

	return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
end

---Get item level from an item link
---@param itemLink string
---@return number|nil
local function GetItemLevel(itemLink)
	if not itemLink then
		return nil
	end

	local itemLevel = nil
	if C_Item and C_Item.GetDetailedItemLevelInfo then
		itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
	elseif GetDetailedItemLevelInfo then
		itemLevel = GetDetailedItemLevelInfo(itemLink)
	end

	if type(itemLevel) ~= 'number' then
		return nil
	end
	return itemLevel
end

---Parse an item link to extract ID and bonus IDs
---@param itemLink string
---@return number|nil itemID
---@return table bonusIDs
local function ParseItemLink(itemLink)
	if not itemLink then
		return nil, {}
	end

	local itemString = itemLink:match('|Hitem:([^|]+)|')
	if not itemString then
		return nil, {}
	end

	local parts = { strsplit(':', itemString) }
	local itemID = tonumber(parts[1])
	if not itemID then
		return nil, {}
	end

	local bonusIDs = {}

	-- Remove trailing empty parts
	while #parts > 0 and parts[#parts] == '' do
		parts[#parts] = nil
	end

	-- Find modifier count index
	local modifierCountIndex = nil
	for i = #parts, 2, -1 do
		local modifierCount = tonumber(parts[i])
		if modifierCount and modifierCount >= 0 and modifierCount <= 20 then
			if i + (2 * modifierCount) == #parts then
				modifierCountIndex = i
				break
			end
		end
	end

	-- Extract bonus IDs
	if modifierCountIndex then
		local numBonusesIndex = modifierCountIndex - 1
		local numBonuses = tonumber(parts[numBonusesIndex]) or 0
		if numBonuses > 0 then
			local firstBonusIndex = numBonusesIndex - numBonuses
			if firstBonusIndex >= 2 then
				for i = firstBonusIndex, (numBonusesIndex - 1) do
					local bonusID = tonumber(parts[i])
					if bonusID then
						bonusIDs[bonusID] = true
					end
				end
			end
		end
	end

	return itemID, bonusIDs
end

---Check if two item links match (same item ID, bonus IDs, and item level)
---@param linkA string
---@param linkB string
---@return boolean
local function ItemLinksMatch(linkA, linkB)
	local idA, bonusA = ParseItemLink(linkA)
	local idB, bonusB = ParseItemLink(linkB)

	if not idA or not idB or idA ~= idB then
		return false
	end

	local ilvlA = GetItemLevel(linkA)
	local ilvlB = GetItemLevel(linkB)
	if type(ilvlA) == 'number' and type(ilvlB) == 'number' and ilvlA ~= ilvlB then
		return false
	end

	for k in pairs(bonusA) do
		if not bonusB[k] then
			return false
		end
	end
	for k in pairs(bonusB) do
		if not bonusA[k] then
			return false
		end
	end

	return true
end

---Check if an item is equipped by the player
---@param itemLink string
---@return boolean
local function IsItemEquippedByPlayer(itemLink)
	if not itemLink then
		return false
	end

	local _, _, _, itemEquipLoc = C_Item.GetItemInfoInstant(itemLink)
	if not itemEquipLoc or itemEquipLoc == '' then
		return false
	end

	local slotNames = INVTYPE_TO_SLOTS[itemEquipLoc]
	if not slotNames or #slotNames == 0 then
		return false
	end

	for _, slotName in ipairs(slotNames) do
		local slotId = GetInventorySlotInfo(slotName)
		if slotId then
			local equippedLink = GetInventoryItemLink('player', slotId)
			if equippedLink and ItemLinksMatch(equippedLink, itemLink) then
				return true
			end
		end
	end

	return false
end

---Calculate the item level delta between a new item and currently equipped item(s)
---@param itemLink string
---@return number delta
local function CalculateItemLevelDelta(itemLink)
	if not itemLink then
		return 0
	end

	local newItemLevel = GetItemLevel(itemLink)
	if not newItemLevel then
		return 0
	end

	local _, _, _, itemEquipLoc = C_Item.GetItemInfoInstant(itemLink)
	if not itemEquipLoc or itemEquipLoc == '' then
		return 0
	end

	local slotNames = INVTYPE_TO_SLOTS[itemEquipLoc]
	if not slotNames or #slotNames == 0 then
		return 0
	end

	-- Find the lowest item level in the applicable slots
	local equippedItemLevel = nil
	for _, slotName in ipairs(slotNames) do
		local slotId = GetInventorySlotInfo(slotName)
		if slotId then
			local equippedLink = GetInventoryItemLink('player', slotId)
			local ilvl = GetItemLevel(equippedLink)
			if type(ilvl) == 'number' then
				if equippedItemLevel == nil or ilvl < equippedItemLevel then
					equippedItemLevel = ilvl
				end
			end
		end
	end

	if equippedItemLevel == nil then
		equippedItemLevel = 0
	end

	return newItemLevel - equippedItemLevel
end

----------------------------------------------------------------------------------------------------
-- Pawn Integration (optional - uses Pawn if available, falls back to item level)
----------------------------------------------------------------------------------------------------

---Check if Pawn addon is available and ready
---@return boolean
local function IsPawnAvailable()
	return PawnIsReady and PawnIsReady() and PawnGetItemData and PawnIsItemAnUpgrade
end

---Get upgrade info from Pawn
---@param itemLink string
---@return number|nil percentUpgrade The best upgrade percentage (as whole number, e.g., 5 for 5%)
---@return string|nil scaleName The localized scale name for the best upgrade
---@return boolean usedPawn Whether Pawn was used for the calculation
local function GetPawnUpgradeInfo(itemLink)
	if not itemLink then
		return nil, nil, false
	end
	if not IsPawnAvailable() then
		return nil, nil, false
	end

	local Item = PawnGetItemData(itemLink)
	if not Item then
		return nil, nil, false
	end

	local UpgradeTable = PawnIsItemAnUpgrade(Item)
	if not UpgradeTable or #UpgradeTable == 0 then
		-- Pawn says it's not an upgrade - return 0% with Pawn flag
		return 0, nil, true
	end

	-- Find the best upgrade percentage across all scales
	local bestPercent = 0
	local bestScaleName = nil
	for _, upgradeInfo in ipairs(UpgradeTable) do
		if upgradeInfo.PercentUpgrade and upgradeInfo.PercentUpgrade > bestPercent then
			bestPercent = upgradeInfo.PercentUpgrade
			bestScaleName = upgradeInfo.LocalizedScaleName
		end
	end

	-- Convert from decimal (0.05) to whole number (5)
	return math.floor(bestPercent * 100 + 0.5), bestScaleName, true
end

---Get comparison info for an item (Pawn-preferred, falls back to item level)
---@param itemLink string
---@return number value The comparison value (percent for Pawn, item level delta otherwise)
---@return boolean isPawnValue Whether the value is from Pawn (true) or item level (false)
---@return string|nil scaleName The Pawn scale name if using Pawn
local function GetItemComparisonInfo(itemLink)
	-- Try Pawn first
	local pawnPercent, scaleName, usedPawn = GetPawnUpgradeInfo(itemLink)
	if usedPawn then
		return pawnPercent or 0, true, scaleName
	end

	-- Fall back to item level delta
	local ilvlDelta = CalculateItemLevelDelta(itemLink)
	return ilvlDelta, false, nil
end

----------------------------------------------------------------------------------------------------
-- Upgrade Notification System
----------------------------------------------------------------------------------------------------

-- Track items we've already notified about to avoid duplicates
local notifiedItems = {}

---Play the upgrade notification sound
local function PlayUpgradeSound()
	local DB = module:GetDB()
	if not DB.lootAlertSound then
		return
	end

	local soundFile = LSM:Fetch('sound', DB.lootAlertSoundName or 'None')
	if soundFile and soundFile ~= 'None' then
		PlaySoundFile(soundFile, 'Master')
	end
end

---Print upgrade notification to chat
---@param itemLink string
---@param comparisonValue number
---@param isPawnValue boolean
local function PrintUpgradeNotification(itemLink, comparisonValue, isPawnValue)
	local DB = module:GetDB()
	if not DB.lootAlertChat then
		return
	end

	local upgradeText
	if isPawnValue then
		upgradeText = '+' .. comparisonValue .. '% via Pawn'
	else
		upgradeText = '+' .. comparisonValue .. ' ilvl'
	end

	SUI:Print(L['Upgrade looted:'] .. ' ' .. itemLink .. ' (' .. upgradeText .. ')')
end

---Check if an item is an upgrade and trigger notifications
---@param itemLink string
---@return boolean isUpgrade
---@return number comparisonValue
---@return boolean isPawnValue
local function CheckAndNotifyUpgrade(itemLink)
	if not itemLink then
		return false, 0, false
	end

	-- Check if we've already notified about this item
	local itemID = ParseItemLink(itemLink)
	if itemID and notifiedItems[itemID] then
		return false, 0, false
	end

	local comparisonValue, isPawnValue, scaleName = GetItemComparisonInfo(itemLink)

	-- Only notify for upgrades (positive value)
	if comparisonValue > 0 then
		-- Mark as notified
		if itemID then
			notifiedItems[itemID] = true
		end

		-- Trigger notifications
		PlayUpgradeSound()
		PrintUpgradeNotification(itemLink, comparisonValue, isPawnValue)

		return true, comparisonValue, isPawnValue
	end

	return false, comparisonValue, isPawnValue
end

---Clear the notified items cache (called periodically or on zone change)
local function ClearNotifiedItemsCache()
	wipe(notifiedItems)
end

----------------------------------------------------------------------------------------------------
-- State Management
----------------------------------------------------------------------------------------------------

local function ResetState()
	State.valid = false
	State.currentFrame = nil
	State.isWaitingForEquip = false
	State.isEquipped = false
end

local function InitSession(frame)
	ResetState()
	State.valid = true
	State.currentFrame = frame
	State.isEquipped = IsItemEquippedByPlayer(frame and frame.hyperlink)
end

----------------------------------------------------------------------------------------------------
-- UI Creation and Management
----------------------------------------------------------------------------------------------------

local function CreatePopupFrame()
	local frame = CreateFrame('Frame', 'SUI_LootAlertPopup', UIParent, 'BackdropTemplate')
	frame:SetSize(POPUP_WIDTH, POPUP_HEIGHT)
	frame:SetFrameStrata('TOOLTIP')
	frame:SetFrameLevel(1000)
	frame:Hide()

	-- Background
	frame:SetBackdrop({
		bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
		edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

	-- Left side: Instruction text
	frame.InstructionText = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	frame.InstructionText:SetPoint('LEFT', frame, 'LEFT', 8, 0)
	frame.InstructionText:SetTextColor(1, 1, 1)

	-- Right side: Item level delta
	frame.DeltaText = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	frame.DeltaText:SetPoint('RIGHT', frame, 'RIGHT', -8, 0)

	-- Spinner icon (for equipping state)
	frame.SpinnerIcon = frame:CreateTexture(nil, 'OVERLAY')
	frame.SpinnerIcon:SetSize(CONTENT_SIZE, CONTENT_SIZE)
	frame.SpinnerIcon:SetPoint('RIGHT', frame, 'RIGHT', -8, 0)
	frame.SpinnerIcon:SetTexture('Interface\\TimeManager\\ResetButton')
	frame.SpinnerIcon:Hide()

	-- Spinner animation
	frame.SpinnerAnimGroup = frame.SpinnerIcon:CreateAnimationGroup()
	local spinnerRotate = frame.SpinnerAnimGroup:CreateAnimation('Rotation')
	spinnerRotate:SetDuration(1)
	spinnerRotate:SetDegrees(-360)
	frame.SpinnerAnimGroup:SetLooping('REPEAT')

	-- Tick icon (for equipped state)
	frame.TickIcon = frame:CreateTexture(nil, 'OVERLAY')
	frame.TickIcon:SetSize(CONTENT_SIZE, CONTENT_SIZE)
	frame.TickIcon:SetPoint('RIGHT', frame, 'RIGHT', -8, 0)
	frame.TickIcon:SetTexture('Interface\\RaidFrame\\ReadyCheck-Ready')
	frame.TickIcon:Hide()

	-- Intro animation
	frame.IntroAnimGroup = frame:CreateAnimationGroup()
	local introAlpha = frame.IntroAnimGroup:CreateAnimation('Alpha')
	introAlpha:SetFromAlpha(0)
	introAlpha:SetToAlpha(1)
	introAlpha:SetDuration(0.2)
	introAlpha:SetSmoothing('OUT')

	-- Outro animation
	frame.OutroAnimGroup = frame:CreateAnimationGroup()
	local outroAlpha = frame.OutroAnimGroup:CreateAnimation('Alpha')
	outroAlpha:SetFromAlpha(1)
	outroAlpha:SetToAlpha(0)
	outroAlpha:SetDuration(0.2)
	outroAlpha:SetSmoothing('OUT')
	frame.OutroAnimGroup:SetScript('OnFinished', function()
		frame:Hide()
	end)

	frame.owner = nil
	frame.hidden = true

	return frame
end

local function SetOwner(frame)
	if not popupFrame then
		return
	end
	popupFrame.owner = frame
	popupFrame:ClearAllPoints()
	popupFrame:SetPoint('BOTTOM', frame, 'TOP', 0, -4)
end

local function GetOwner()
	return popupFrame and popupFrame.owner
end

local function ShowPopupFrame()
	if not popupFrame then
		return
	end
	if popupFrame.OutroAnimGroup:IsPlaying() then
		popupFrame.OutroAnimGroup:Stop()
	end

	popupFrame.hidden = false
	popupFrame:Show()
	popupFrame.IntroAnimGroup:Play()
end

local function HidePopupFrame()
	if not popupFrame then
		return
	end
	if popupFrame.IntroAnimGroup:IsPlaying() then
		popupFrame.IntroAnimGroup:Stop()
	end

	popupFrame.hidden = true
	popupFrame.OutroAnimGroup:Play()
end

---@param comparisonValue number The comparison value (percent for Pawn, item level delta otherwise)
---@param isPawnValue boolean Whether the value is from Pawn
---@param scaleName? string The Pawn scale name if using Pawn
local function SetItemComparisonState(comparisonValue, isPawnValue, scaleName)
	if not popupFrame then
		return
	end

	local inCombat = InCombatLockdown()
	local atVendor = MerchantFrame and MerchantFrame:IsShown()
	local isBlocked = inCombat or atVendor

	-- Set instruction text
	local instructionText
	if inCombat then
		instructionText = L['In Combat']
	elseif atVendor then
		instructionText = L['At Vendor']
	else
		instructionText = '|A:newplayertutorial-icon-mouse-leftbutton:16:12|a ' .. L['Click to Equip']
	end
	popupFrame.InstructionText:SetText(instructionText)
	popupFrame.InstructionText:SetTextColor(isBlocked and 1 or 1, isBlocked and 0.3 or 1, isBlocked and 0.3 or 1)

	-- Set comparison text and color based on source
	local displayText
	if isPawnValue then
		-- Pawn percentage display
		if comparisonValue > 0 then
			displayText = '+' .. comparisonValue .. '%'
		elseif comparisonValue < 0 then
			displayText = comparisonValue .. '%'
		else
			displayText = '0%'
		end
	else
		-- Item level delta display
		displayText = (comparisonValue >= 0 and '+' or '') .. comparisonValue .. ' ilvl'
	end
	popupFrame.DeltaText:SetText(displayText)

	-- Color based on upgrade/downgrade/sidegrade
	if comparisonValue > 0 then
		popupFrame.DeltaText:SetTextColor(0.2, 1, 0.2) -- Green for upgrade
	elseif comparisonValue < 0 then
		popupFrame.DeltaText:SetTextColor(1, 0.2, 0.2) -- Red for downgrade
	else
		popupFrame.DeltaText:SetTextColor(0.6, 0.6, 0.6) -- Gray for sidegrade
	end

	-- Show delta, hide spinner and tick
	popupFrame.DeltaText:Show()
	popupFrame.SpinnerIcon:Hide()
	popupFrame.SpinnerAnimGroup:Stop()
	popupFrame.TickIcon:Hide()
end

local function SetSpinnerState()
	if not popupFrame then
		return
	end

	popupFrame.InstructionText:SetText(L['Equipping...'])
	popupFrame.InstructionText:SetTextColor(1, 1, 1)

	popupFrame.DeltaText:Hide()
	popupFrame.SpinnerIcon:Show()
	popupFrame.SpinnerAnimGroup:Play()
	popupFrame.TickIcon:Hide()
end

local function SetEquippedState()
	if not popupFrame then
		return
	end

	popupFrame.InstructionText:SetText(L['Equipped!'])
	popupFrame.InstructionText:SetTextColor(0.2, 1, 0.2)

	popupFrame.DeltaText:Hide()
	popupFrame.SpinnerIcon:Hide()
	popupFrame.SpinnerAnimGroup:Stop()
	popupFrame.TickIcon:Show()
end

local function UpdatePopupState()
	if not popupFrame then
		return
	end

	if not State.valid then
		if not popupFrame.hidden then
			HidePopupFrame()
		end
		return
	elseif popupFrame.hidden then
		ShowPopupFrame()
	end

	if not State.currentFrame then
		return
	end

	if State.isEquipped then
		SetEquippedState()
	elseif State.isWaitingForEquip then
		SetSpinnerState()
	else
		local comparisonValue, isPawnValue, scaleName = GetItemComparisonInfo(State.currentFrame.hyperlink)
		SetItemComparisonState(comparisonValue, isPawnValue, scaleName)
	end
end

----------------------------------------------------------------------------------------------------
-- Loot Alert Hooks
----------------------------------------------------------------------------------------------------

local function LootAlertFrame_OnEnter(self)
	local DB = module:GetDB()
	if not DB.lootAlertPopup then
		return
	end
	if not IsEquippableGearLink(self.hyperlink) then
		return
	end

	if State.currentFrame ~= self then
		InitSession(self)
	end

	-- Show tooltip
	GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	if self.hyperlink then
		GameTooltip:SetHyperlink(self.hyperlink)
		GameTooltip:Show()
	end

	SetOwner(self)
	UpdatePopupState()
end

local function LootAlertFrame_OnLeave(self)
	local DB = module:GetDB()
	if not DB.lootAlertPopup then
		return
	end
	if not IsEquippableGearLink(self.hyperlink) then
		return
	end

	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end

	if not State.isWaitingForEquip then
		ResetState()
	end

	UpdatePopupState()
end

local function LootAlertFrame_OnClick(frame, button)
	local DB = module:GetDB()
	if not DB.lootAlertPopup then
		return
	end
	if InCombatLockdown() then
		return
	end
	if MerchantFrame and MerchantFrame:IsShown() then
		return
	end

	if button == 'LeftButton' then
		local targetLink = frame.hyperlink
		if not targetLink then
			return
		end
		if not IsEquippableGearLink(targetLink) then
			return
		end

		-- Find the item in bags and equip it
		for bag = 0, NUM_BAG_SLOTS do
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				local info = C_Container.GetContainerItemInfo(bag, slot)
				if info and ItemLinksMatch(info.hyperlink, targetLink) then
					C_Container.UseContainerItem(bag, slot)
					State.isWaitingForEquip = true
					UpdatePopupState()
					return
				end
			end
		end
	end
end

local function LootAlertFrame_OnHide(frame)
	-- Prevent hiding if we have an active upgrade timer
	if frame.__suiUpgradeHideTimer then
		-- Timer is still running, keep the alert visible
		frame:Show()
		return
	end

	if GetOwner() == frame then
		ResetState()
		UpdatePopupState()
	end
end

----------------------------------------------------------------------------------------------------
-- Event Handling
----------------------------------------------------------------------------------------------------

local function OnEvent(_, event)
	if event == 'PLAYER_EQUIPMENT_CHANGED' then
		if State.currentFrame and State.isWaitingForEquip then
			State.isWaitingForEquip = false
			State.isEquipped = IsItemEquippedByPlayer(State.currentFrame.hyperlink)
			UpdatePopupState()

			-- Update tooltip if visible
			if GameTooltip:IsShown() and GameTooltip:IsOwned(State.currentFrame) and State.currentFrame.hyperlink then
				GameTooltip:Hide()
				GameTooltip:SetOwner(State.currentFrame, 'ANCHOR_RIGHT')
				GameTooltip:SetHyperlink(State.currentFrame.hyperlink)
				GameTooltip:Show()
			end
		end
	elseif event == 'PLAYER_REGEN_ENABLED' or event == 'MERCHANT_CLOSED' then
		if State.valid and not State.isEquipped and not State.isWaitingForEquip then
			UpdatePopupState()
		end
	elseif event == 'MERCHANT_SHOW' then
		if State.valid and not State.isEquipped and not State.isWaitingForEquip then
			UpdatePopupState()
		end
	elseif event == 'ZONE_CHANGED_NEW_AREA' or event == 'PLAYER_ENTERING_WORLD' then
		-- Clear notified items cache on zone change to allow re-notification
		ClearNotifiedItemsCache()
	end
end

---Create the upgrade badge on a loot alert frame
---@param alertFrame Frame
local function CreateUpgradeBadge(alertFrame)
	if alertFrame.__suiUpgradeBadge then
		return alertFrame.__suiUpgradeBadge
	end

	local badge = CreateFrame('Frame', nil, alertFrame, 'BackdropTemplate')
	badge:SetSize(70, 20)
	badge:SetPoint('TOPRIGHT', alertFrame, 'TOPRIGHT', -5, -5)
	badge:SetFrameLevel(alertFrame:GetFrameLevel() + 10)

	badge:SetBackdrop({
		bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
		edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	badge:SetBackdropColor(0.1, 0.4, 0.1, 0.95)
	badge:SetBackdropBorderColor(0.2, 0.8, 0.2, 1)

	badge.text = badge:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	badge.text:SetPoint('CENTER', badge, 'CENTER', 0, 0)
	badge.text:SetText(L['Upgrade!'])
	badge.text:SetTextColor(0.2, 1, 0.2)

	-- Glow animation
	badge.glowAnim = badge:CreateAnimationGroup()
	local glowPulse = badge.glowAnim:CreateAnimation('Alpha')
	glowPulse:SetFromAlpha(1)
	glowPulse:SetToAlpha(0.6)
	glowPulse:SetDuration(0.5)
	glowPulse:SetSmoothing('IN_OUT')
	badge.glowAnim:SetLooping('BOUNCE')

	badge:Hide()
	alertFrame.__suiUpgradeBadge = badge
	return badge
end

---Show or hide the upgrade badge on an alert frame
---@param alertFrame Frame
---@param isUpgrade boolean
local function UpdateUpgradeBadge(alertFrame, isUpgrade)
	local badge = alertFrame.__suiUpgradeBadge
	if not badge then
		return
	end

	if isUpgrade then
		badge:Show()
		badge.glowAnim:Play()

		-- Cancel any existing hide timer
		if alertFrame.__suiUpgradeHideTimer then
			alertFrame.__suiUpgradeHideTimer:Cancel()
			alertFrame.__suiUpgradeHideTimer = nil
		end

		-- Extend the alert display time for upgrades by 20 seconds
		alertFrame.__suiUpgradeHideTimer = C_Timer.NewTimer(20, function()
			-- Allow the alert to hide normally after the extended time
			alertFrame.__suiUpgradeHideTimer = nil
		end)
	else
		badge:Hide()
		badge.glowAnim:Stop()

		-- Cancel upgrade timer if switching from upgrade to non-upgrade
		if alertFrame.__suiUpgradeHideTimer then
			alertFrame.__suiUpgradeHideTimer:Cancel()
			alertFrame.__suiUpgradeHideTimer = nil
		end
	end
end

local function SetupLootAlertHook()
	if lootAlertHooked then
		return
	end

	hooksecurefunc(LootAlertSystem, 'ShowAlert', function(self)
		local DB = module:GetDB()
		if not DB.lootAlertPopup then
			return
		end

		for alertFrame in self.alertFramePool:EnumerateActive() do
			-- Initialize frame if needed
			if not alertFrame.__suiLootAlertInitialized then
				alertFrame.__suiLootAlertInitialized = true

				-- Create upgrade badge
				CreateUpgradeBadge(alertFrame)

				-- Register click handlers
				alertFrame:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
				alertFrame:HookScript('OnEnter', LootAlertFrame_OnEnter)
				alertFrame:HookScript('OnLeave', LootAlertFrame_OnLeave)
				alertFrame:HookScript('OnMouseUp', LootAlertFrame_OnClick)
				alertFrame:HookScript('OnHide', LootAlertFrame_OnHide)
			end

			-- Check for upgrade and show notifications (this runs every time an alert shows)
			if alertFrame.hyperlink and IsEquippableGearLink(alertFrame.hyperlink) then
				local isUpgrade, comparisonValue, isPawnValue = CheckAndNotifyUpgrade(alertFrame.hyperlink)
				UpdateUpgradeBadge(alertFrame, isUpgrade)
			else
				UpdateUpgradeBadge(alertFrame, false)
			end
		end
	end)

	lootAlertHooked = true
end

----------------------------------------------------------------------------------------------------
-- Module Integration
----------------------------------------------------------------------------------------------------

function module:InitializeLootAlertPopup()
	local DB = module:GetDB()
	if not DB.lootAlertPopup then
		return
	end

	-- Create popup frame if needed
	if not popupFrame then
		popupFrame = CreatePopupFrame()
	end

	-- Create event frame if needed
	if not eventFrame then
		eventFrame = CreateFrame('Frame')
		eventFrame:SetScript('OnEvent', OnEvent)
	end

	eventFrame:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
	eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
	eventFrame:RegisterEvent('MERCHANT_SHOW')
	eventFrame:RegisterEvent('MERCHANT_CLOSED')
	eventFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')

	-- Setup loot alert hook
	SetupLootAlertHook()
end

function module:RestoreLootAlertPopup()
	if eventFrame then
		eventFrame:UnregisterAllEvents()
	end

	if popupFrame then
		popupFrame:Hide()
		popupFrame.SpinnerAnimGroup:Stop()
	end

	ResetState()
end

function module:ApplyLootAlertPopupSettings()
	local DB = module:GetDB()
	if DB.lootAlertPopup then
		module:InitializeLootAlertPopup()
	else
		module:RestoreLootAlertPopup()
	end
end
