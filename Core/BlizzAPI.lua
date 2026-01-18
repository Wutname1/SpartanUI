---@class SUI
local SUI = SUI

---@class SUI.BlizzAPI
---API Compatibility Layer
---Normalizes Blizzard API differences between retail and classic versions.
---Uses nil checks so backported APIs work automatically.
SUI.BlizzAPI = {}

local BlizzAPI = SUI.BlizzAPI

-- ============================================
-- MERCHANT API
-- ============================================

---@class MerchantItemInfo
---@field name string?
---@field texture number
---@field price number
---@field stackCount number
---@field numAvailable number
---@field isPurchasable boolean
---@field isUsable boolean
---@field hasExtendedCost boolean
---@field currencyID number?
---@field spellID number?
---@field isQuestStartItem boolean?

---Get merchant item info (normalized to retail MerchantItemInfo structure)
---@param index number
---@return MerchantItemInfo
function BlizzAPI.GetMerchantItemInfo(index)
	-- Use modern API if available (retail, or backported to classic)
	if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
		return C_MerchantFrame.GetItemInfo(index)
	end

	-- Fallback to classic API, wrap in retail-style table
	local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = GetMerchantItemInfo(index)
	return {
		name = name,
		texture = texture,
		price = price,
		stackCount = quantity,
		numAvailable = numAvailable,
		isPurchasable = isPurchasable,
		isUsable = isUsable,
		hasExtendedCost = extendedCost and true or false,
		currencyID = currencyID,
		spellID = spellID,
		isQuestStartItem = false, -- Not available in classic
	}
end

-- ============================================
-- SPELL API
-- ============================================

---@class SpellInfo
---@field name string
---@field iconID number
---@field castTime number
---@field minRange number
---@field maxRange number
---@field spellID number
---@field originalIconID number?

---Get spell info (normalized to retail structure)
---@param spellID number
---@return SpellInfo?
function BlizzAPI.GetSpellInfo(spellID)
	-- Use modern API if available
	if C_Spell and C_Spell.GetSpellInfo then
		return C_Spell.GetSpellInfo(spellID)
	end

	-- Fallback to classic API
	local name, _, icon, castTime, minRange, maxRange, returnedSpellID = GetSpellInfo(spellID)
	if not name then return nil end
	return {
		name = name,
		iconID = icon,
		castTime = castTime,
		minRange = minRange,
		maxRange = maxRange,
		spellID = returnedSpellID or spellID,
		originalIconID = icon,
	}
end

---Get spell name
---@param spellID number
---@return string?
function BlizzAPI.GetSpellName(spellID)
	if C_Spell and C_Spell.GetSpellName then
		return C_Spell.GetSpellName(spellID)
	end

	local name = GetSpellInfo(spellID)
	return name
end

---Get spell texture/icon
---@param spellID number
---@return number?
function BlizzAPI.GetSpellTexture(spellID)
	if C_Spell and C_Spell.GetSpellTexture then
		return C_Spell.GetSpellTexture(spellID)
	end

	local _, _, icon = GetSpellInfo(spellID)
	return icon
end

-- ============================================
-- ITEM API
-- ============================================

---@class ItemInfo
---@field itemName string
---@field itemLink string
---@field itemQuality number
---@field itemLevel number
---@field itemMinLevel number
---@field itemType string
---@field itemSubType string
---@field itemStackCount number
---@field itemEquipLoc string
---@field itemTexture number
---@field sellPrice number
---@field classID number
---@field subClassID number
---@field bindType number
---@field expacID number
---@field itemSetID number?
---@field isCraftingReagent boolean

---Get item info (normalized)
---@param itemID number|string
---@return ItemInfo?
function BlizzAPI.GetItemInfo(itemID)
	-- Use modern API if available
	if C_Item and C_Item.GetItemInfo then
		return C_Item.GetItemInfo(itemID)
	end

	-- Fallback to classic API
	local name, link, quality, level, minLevel, type, subType, stackCount,
		equipLoc, texture, sellPrice, classID, subClassID, bindType,
		expacID, setID, isCraftingReagent = GetItemInfo(itemID)
	if not name then return nil end
	return {
		itemName = name,
		itemLink = link,
		itemQuality = quality,
		itemLevel = level,
		itemMinLevel = minLevel,
		itemType = type,
		itemSubType = subType,
		itemStackCount = stackCount,
		itemEquipLoc = equipLoc,
		itemTexture = texture,
		sellPrice = sellPrice,
		classID = classID,
		subClassID = subClassID,
		bindType = bindType,
		expacID = expacID,
		itemSetID = setID,
		isCraftingReagent = isCraftingReagent or false,
	}
end

-- ============================================
-- CONTAINER/BAG API
-- ============================================

---Get container item info
---@param bagID number
---@param slot number
---@return table?
function BlizzAPI.GetContainerItemInfo(bagID, slot)
	-- Use modern API if available
	if C_Container and C_Container.GetContainerItemInfo then
		return C_Container.GetContainerItemInfo(bagID, slot)
	end

	-- Fallback to classic API
	local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID, isBound = GetContainerItemInfo(bagID, slot)
	if not icon then return nil end
	return {
		iconFileID = icon,
		stackCount = itemCount,
		isLocked = locked,
		quality = quality,
		isReadable = readable,
		hasLoot = lootable,
		hyperlink = itemLink,
		isFiltered = isFiltered,
		hasNoValue = noValue,
		itemID = itemID,
		isBound = isBound,
	}
end

---Get number of container slots
---@param bagID number
---@return number
function BlizzAPI.GetContainerNumSlots(bagID)
	if C_Container and C_Container.GetContainerNumSlots then
		return C_Container.GetContainerNumSlots(bagID)
	end
	return GetContainerNumSlots(bagID)
end

-- ============================================
-- FEATURE DETECTION
-- ============================================

---Check if EditMode is available
---@return boolean
function BlizzAPI.HasEditMode()
	return C_EditMode ~= nil
end

---Check if modern spell API is available
---@return boolean
function BlizzAPI.HasModernSpellAPI()
	return C_Spell ~= nil and C_Spell.GetSpellInfo ~= nil
end

---Check if modern item API is available
---@return boolean
function BlizzAPI.HasModernItemAPI()
	return C_Item ~= nil and C_Item.GetItemInfo ~= nil
end

---Check if modern container API is available
---@return boolean
function BlizzAPI.HasModernContainerAPI()
	return C_Container ~= nil and C_Container.GetContainerItemInfo ~= nil
end

-- ============================================
-- SPECIALIZATION API (Retail only)
-- ============================================

---Get current specialization info
---@return number? specID
---@return string? specName
---@return string? description
---@return number? icon
---@return string? role
function BlizzAPI.GetSpecialization()
	if GetSpecialization then
		local spec = GetSpecialization()
		if spec and GetSpecializationInfo then
			return GetSpecializationInfo(spec)
		end
	end
	return nil
end

---Get specialization role (TANK, HEALER, DAMAGER)
---@return string?
function BlizzAPI.GetSpecializationRole()
	if GetSpecialization and GetSpecializationRole then
		local spec = GetSpecialization()
		if spec then
			return GetSpecializationRole(spec)
		end
	end
	return nil
end

-- ============================================
-- TITLE API (Retail only)
-- ============================================

---Get title name by ID
---@param titleID number
---@return string?
function BlizzAPI.GetTitleName(titleID)
	if GetTitleName then
		return GetTitleName(titleID)
	end
	return nil
end

---Get current title ID
---@return number?
function BlizzAPI.GetCurrentTitle()
	if GetCurrentTitle then
		return GetCurrentTitle()
	end
	return nil
end
