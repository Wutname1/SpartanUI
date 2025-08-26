---@class LibsDisenchantAssist
local LibsDisenchantAssist = _G.LibsDisenchantAssist

---@class ItemTracker
local ItemTracker = {}

---Initialize ItemTracker
function ItemTracker:Initialize()
	LibsDisenchantAssist:RegisterEvent('LOOT_READY', function()
		self:TrackLootedItems()
	end)

	LibsDisenchantAssist:RegisterEvent('BAG_UPDATE_DELAYED', function()
		self:ScanBagsForNewItems()
	end)
end

---Handle profile changes
function ItemTracker:OnProfileChanged()
	-- Nothing specific needed for profile changes currently
end

---Track newly looted items
function ItemTracker:TrackLootedItems()
	local currentTime = time()
	local numLootItems = GetNumLootItems()

	for i = 1, numLootItems do
		local itemLink = GetLootSlotLink(i)
		if itemLink then
			local itemID = self:GetItemIDFromLink(itemLink)
			if itemID then self:RecordFirstSeen(itemID, currentTime) end
		end
	end
end

---Scan bags for new items
function ItemTracker:ScanBagsForNewItems()
	local currentTime = time()

	for bag = 0, 4 do
		local numSlots = C_Container.GetContainerNumSlots(bag)
		if numSlots then
			for slot = 1, numSlots do
				local itemID = C_Container.GetContainerItemID(bag, slot)
				if itemID and not LibsDisenchantAssist.DBC.itemFirstSeen[itemID] then self:RecordFirstSeen(itemID, currentTime) end
			end
		end
	end
end

---Record first seen timestamp for an item
---@param itemID number
---@param timestamp number
function ItemTracker:RecordFirstSeen(itemID, timestamp)
	if not LibsDisenchantAssist.DBC.itemFirstSeen[itemID] then LibsDisenchantAssist.DBC.itemFirstSeen[itemID] = timestamp end
end

---Get formatted first seen date for an item
---@param itemID number
---@return string
function ItemTracker:GetItemFirstSeenDate(itemID)
	local timestamp = LibsDisenchantAssist.DBC.itemFirstSeen[itemID]
	if timestamp then return date('%m/%d/%y', timestamp) end
	return 'Unknown'
end

---Check if item was first seen today
---@param itemID number
---@return boolean
function ItemTracker:WasItemSeenToday(itemID)
	local timestamp = LibsDisenchantAssist.DBC.itemFirstSeen[itemID]
	if not timestamp then return true end

	local today = date('%j', time())
	local itemDay = date('%j', timestamp)
	return today == itemDay
end

---Extract item ID from item link
---@param itemLink string|nil
---@return number|nil
function ItemTracker:GetItemIDFromLink(itemLink)
	if not itemLink then return nil end
	return tonumber(string.match(itemLink, 'item:(%d+)'))
end

LibsDisenchantAssist.ItemTracker = ItemTracker
