---@class LibsDisenchantAssist
local LibsDisenchantAssist = _G.LibsDisenchantAssist

---@class FilterSystem
LibsDisenchantAssist.FilterSystem = {}
local FilterSystem = LibsDisenchantAssist.FilterSystem

---Handle profile changes
function FilterSystem:OnProfileChanged()
    -- Nothing specific needed for profile changes currently
end

---Get all disenchantable items from bags
---@return table<number, table>
function FilterSystem:GetDisenchantableItems()
    local items = {}
    
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                if itemInfo and itemInfo.itemID then
                    local item = self:CreateItemInfo(bag, slot, itemInfo)
                    if item and self:CanDisenchantItem(item) then
                        table.insert(items, item)
                    end
                end
            end
        end
    end
    
    return self:FilterItems(items)
end

---Create item info structure
---@param bag number
---@param slot number
---@param containerItemInfo table
---@return table|nil
function FilterSystem:CreateItemInfo(bag, slot, containerItemInfo)
    local itemID = containerItemInfo.itemID
    local itemLink = C_Container.GetContainerItemLink(bag, slot)
    
    if not itemLink then return nil end
    
    local itemName, _, itemQuality, itemLevel, _, _, _, _, equipLoc, _, _, classID, subClassID = C_Item.GetItemInfo(itemID)
    
    if not itemName then return nil end
    
    return {
        bag = bag,
        slot = slot,
        itemID = itemID,
        itemLink = itemLink,
        itemName = itemName,
        itemLevel = itemLevel or 0,
        quality = itemQuality or 0,
        equipLoc = equipLoc,
        classID = classID,
        subClassID = subClassID,
        quantity = containerItemInfo.stackCount or 1,
        isBound = containerItemInfo.isBound,
        firstSeen = LibsDisenchantAssist.ItemTracker:GetItemFirstSeenDate(itemID),
        seenToday = LibsDisenchantAssist.ItemTracker:WasItemSeenToday(itemID)
    }
end

---Check if item can be disenchanted
---@param item table
---@return boolean
function FilterSystem:CanDisenchantItem(item)
    if item.classID ~= 2 and item.classID ~= 4 then
        return false
    end
    
    if item.quality < 2 or item.quality > 4 then
        return false
    end
    
    return C_Item.GetItemDisenchantInfo and C_Item.GetItemDisenchantInfo(item.itemID) ~= nil
end

---Apply filters to item list
---@param items table<number, table>
---@return table<number, table>
function FilterSystem:FilterItems(items)
    local filtered = {}
    local options = LibsDisenchantAssistDB.options
    
    for _, item in ipairs(items) do
        if self:PassesAllFilters(item, options) then
            table.insert(filtered, item)
        end
    end
    
    table.sort(filtered, function(a, b)
        if a.itemLevel == b.itemLevel then
            return a.itemName < b.itemName
        end
        return a.itemLevel < b.itemLevel
    end)
    
    return filtered
end

---Check if item passes all filter criteria
---@param item table
---@param options LibsDisenchantAssistOptions
---@return boolean
function FilterSystem:PassesAllFilters(item, options)
    if not options.enabled then
        return false
    end
    
    if options.excludeToday and item.seenToday then
        return false
    end
    
    if item.itemLevel < options.minIlvl or item.itemLevel > options.maxIlvl then
        return false
    end
    
    if options.excludeHigherIlvl and self:IsHigherThanEquipped(item) then
        return false
    end
    
    if options.excludeGearSets and self:IsInGearSet(item) then
        return false
    end
    
    if options.excludeWarbound and self:IsWarbound(item) then
        return false
    end
    
    if options.excludeBOE and self:IsBOE(item) then
        return false
    end
    
    return true
end

---Check if item has higher ilvl than currently equipped
---@param item table
---@return boolean
function FilterSystem:IsHigherThanEquipped(item)
    if not item.equipLoc or item.equipLoc == "" then
        return false
    end
    
    local slots = self:GetSlotsByEquipLoc(item.equipLoc)
    if not slots then return false end
    
    for _, slotID in ipairs(slots) do
        local equippedItemID = GetInventoryItemID("player", slotID)
        if equippedItemID then
            local _, _, _, equippedIlvl = C_Item.GetItemInfo(equippedItemID)
            if equippedIlvl and item.itemLevel > equippedIlvl then
                local equippedClassID = select(12, C_Item.GetItemInfo(equippedItemID))
                if equippedClassID == item.classID then
                    return true
                end
            end
        end
    end
    
    return false
end

---Get equipment slot IDs for equipment location
---@param equipLoc string
---@return table<number, number>|nil
function FilterSystem:GetSlotsByEquipLoc(equipLoc)
    local slotMap = {
        ["INVTYPE_HEAD"] = {1},
        ["INVTYPE_NECK"] = {2},
        ["INVTYPE_SHOULDER"] = {3},
        ["INVTYPE_BODY"] = {4},
        ["INVTYPE_CHEST"] = {5},
        ["INVTYPE_WAIST"] = {6},
        ["INVTYPE_LEGS"] = {7},
        ["INVTYPE_FEET"] = {8},
        ["INVTYPE_WRIST"] = {9},
        ["INVTYPE_HAND"] = {10},
        ["INVTYPE_FINGER"] = {11, 12},
        ["INVTYPE_TRINKET"] = {13, 14},
        ["INVTYPE_WEAPON"] = {16, 17},
        ["INVTYPE_SHIELD"] = {17},
        ["INVTYPE_RANGED"] = {18},
        ["INVTYPE_CLOAK"] = {15},
        ["INVTYPE_2HWEAPON"] = {16, 17},
        ["INVTYPE_WEAPONMAINHAND"] = {16},
        ["INVTYPE_WEAPONOFFHAND"] = {17},
        ["INVTYPE_HOLDABLE"] = {17},
        ["INVTYPE_THROWN"] = {18},
        ["INVTYPE_RANGEDRIGHT"] = {18}
    }
    return slotMap[equipLoc]
end

---Check if item is part of an equipment set
---@param item table
---@return boolean
function FilterSystem:IsInGearSet(item)
    local numSets = C_EquipmentSet.GetNumEquipmentSets()
    for i = 0, numSets - 1 do
        local setID = C_EquipmentSet.GetEquipmentSetID(i)
        if setID then
            local itemLocations = C_EquipmentSet.GetItemLocations(setID)
            for _, location in pairs(itemLocations) do
                if location then
                    local player, bank, bags, voidStorage, slot, bag = EquipmentManager_UnpackLocation(location)
                    if bags and bag == item.bag and slot == item.slot then
                        return true
                    end
                end
            end
        end
    end
    return false
end

---Check if item is account bound (warbound)
---@param item table
---@return boolean
function FilterSystem:IsWarbound(item)
    local itemInfo = C_Container.GetContainerItemInfo(item.bag, item.slot)
    return itemInfo and itemInfo.isAccountBound
end

---Check if item is Bind on Equip
---@param item table
---@return boolean
function FilterSystem:IsBOE(item)
    local tooltipData = C_TooltipInfo.GetBagItem(item.bag, item.slot)
    if not tooltipData then return false end
    
    for _, line in ipairs(tooltipData.lines) do
        if line.leftText and string.find(line.leftText, "Binds when equipped") then
            return true
        end
    end
    return false
end