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
	---@diagnostic disable-next-line: deprecated
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
-- FEATURE DETECTION
-- ============================================

---Check if EditMode is available (being progressively backported to classic clients)
---Prefer checking C_EditMode directly where needed rather than using this wrapper
---@return boolean
function BlizzAPI.HasEditMode()
	return C_EditMode ~= nil
end

-- ============================================
-- SECRET VALUE API (Retail 12.0.0+)
-- ============================================
-- In Retail WoW 12.0.0+, certain aura properties become "secret values" during combat
-- when viewing other players' auras. These functions provide safe access patterns.
--
-- Classic/TBC/Wrath/Cata/MoP do NOT have secret values - all aura data is accessible.
-- These wrappers return safe defaults when the API doesn't exist.
--
-- Blizzard API reference: https://warcraft.wiki.gg/wiki/API_issecretvalue
-- ============================================

---Check if a value is a "secret value" (inaccessible during combat in Retail)
---Secret values cannot be used in comparisons, arithmetic, or string concatenation.
---@param value any The value to check
---@return boolean isSecret True if the value is secret and cannot be accessed
function BlizzAPI.issecretvalue(value)
	if not issecretvalue then
		return false -- Classic: no secret values exist, value is NOT secret
	end
	return issecretvalue(value)
end

---Check if a single value can be accessed (not a secret value)
---@param value any The value to check
---@return boolean canAccess True if the value can be safely read and used
function BlizzAPI.canaccessvalue(value)
	if not canaccessvalue then
		return true -- Classic: no secret values exist, value IS accessible
	end
	return canaccessvalue(value)
end

---Check if a table's contents can be accessed (no secret values within)
---Used primarily for aura data tables from C_UnitAuras functions.
---@param tbl table The table to check
---@return boolean canAccess True if the table contents can be safely read
function BlizzAPI.canaccesstable(tbl)
	if not canaccesstable then
		return true -- Classic: no secret values exist, table IS accessible
	end
	return canaccesstable(tbl)
end

SUI.BlizzAPI = BlizzAPI
