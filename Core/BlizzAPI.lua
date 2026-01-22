--[[
	BlizzAPI.lua - Blizzard API Compatibility Layer

	PURPOSE:
	This file provides wrapper functions for Blizzard APIs that have DIFFERENT signatures
	or return values between WoW versions (Retail vs Classic variants).

	IMPORTANT NOTES:
	- As of Patch 1.15.2 (Dec 2024), many APIs were unified across all WoW versions
	- C_Item.*, C_Spell.*, and C_Container.* APIs are now IDENTICAL across all versions
	- These unified APIs should be called DIRECTLY - no wrapper needed
	- This file should ONLY contain wrappers for APIs that still differ between versions

	UNIFIED APIs (use directly, no wrapper):
	- C_Item.GetItemInfo() - Available in ALL versions (1.15.2+)
	- C_Item.GetDetailedItemLevelInfo() - Available in ALL versions (1.15.2+)
	- C_Spell.GetSpellInfo() - Available in ALL versions
	- C_Container.GetContainerItemInfo() - Available in ALL versions (1.15.0+)
	- C_Container.GetContainerNumSlots() - Available in ALL versions (1.15.0+)

	APIs THAT STILL NEED WRAPPERS:
	- Merchant APIs (C_MerchantFrame vs GetMerchantItemInfo - different return structures)

	USAGE:
	Only add wrappers here when an API has genuinely different signatures or return types
	across WoW versions. Document the differences clearly.
]]
---@class SUI
local SUI = SUI

---@class SUI.BlizzAPI
local BlizzAPI = {}

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
		isQuestStartItem = false -- Not available in classic
	}
end

-- ============================================
-- FEATURE DETECTION
-- ============================================

---Check if EditMode is available (being progressively backported to classic clients)
---Prefer checking C_EditMode directly where needed rather than using this wrapper
---@return boolean
function BlizzAPI.HasEditMode()
	return C_EditMode ~= nil
end

function BlizzAPI.issecretvalue(value)
	if not issecretvalue then
		return false
	end
	return issecretvalue(value)
end

function BlizzAPI.canaccessvalue(value)
	if not canaccessvalue then
		return true
	end
	return canaccessvalue(value)
end

function BlizzAPI.canaccesstable(table)
	if not canaccesstable then
		return false
	end
	return canaccesstable(table)
end

SUI.BlizzAPI = BlizzAPI
