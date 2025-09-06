---@class LibsDisenchantAssist
local LibsDisenchantAssist = _G.LibsDisenchantAssist

---@class DisenchantLogic
local DisenchantLogic = {}

DisenchantLogic.isDisenchanting = false
DisenchantLogic.currentItem = nil
DisenchantLogic.itemQueue = {}
DisenchantLogic.DISENCHANT_SPELL_ID = 13262

---Handle profile changes
function DisenchantLogic:OnProfileChanged()
	-- Nothing specific needed for profile changes currently
end

---Initialize DisenchantLogic
function DisenchantLogic:Initialize()
	LibsDisenchantAssist:RegisterEvent('UNIT_SPELLCAST_START', function(event, unitID)
		if unitID == 'player' then self:OnSpellcastStart() end
	end)

	LibsDisenchantAssist:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED', function(event, unitID, _, spellID)
		if unitID == 'player' and spellID == self.DISENCHANT_SPELL_ID then self:OnDisenchantComplete() end
	end)

	LibsDisenchantAssist:RegisterEvent('UNIT_SPELLCAST_FAILED', function(event, unitID)
		if unitID == 'player' and self.isDisenchanting then self:OnDisenchantFailed() end
	end)

	LibsDisenchantAssist:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED', function(event, unitID)
		if unitID == 'player' and self.isDisenchanting then self:OnDisenchantInterrupted() end
	end)
end

---Check if player can disenchant
---@return boolean
function DisenchantLogic:CanDisenchant()
	if not C_SpellBook.IsSpellInSpellBook(self.DISENCHANT_SPELL_ID) then
		LibsDisenchantAssist:Print("You don't know how to disenchant!")
		return false
	end

	if not C_Spell.IsSpellUsable(self.DISENCHANT_SPELL_ID) then
		LibsDisenchantAssist:Print('Cannot disenchant right now.')
		return false
	end

	if UnitCastingInfo('player') or UnitChannelInfo('player') then
		LibsDisenchantAssist:Print('Cannot disenchant while casting.')
		return false
	end

	if #GetLootInfo() > 0 then
		LibsDisenchantAssist:Print('Cannot disenchant while loot window is open.')
		return false
	end

	return true
end

---Disenchant a single item
---@param item table
---@return boolean
function DisenchantLogic:DisenchantItem(item)
	if not self:CanDisenchant() then return false end

	if not item or not item.bag or not item.slot then
		LibsDisenchantAssist:Print('Invalid item data.')
		return false
	end

	local itemInfo = C_Container.GetContainerItemInfo(item.bag, item.slot)
	if not itemInfo then
		LibsDisenchantAssist:Print('Item no longer exists in that location.')
		return false
	end

	if LibsDisenchantAssist.DB.confirmDisenchant then
		StaticPopupDialogs['LIBS_DISENCHANT_CONFIRM'] = {
			text = 'Disenchant ' .. item.itemLink .. '?',
			button1 = 'Yes',
			button2 = 'No',
			OnAccept = function()
				self:PerformDisenchant(item)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show('LIBS_DISENCHANT_CONFIRM')
	else
		self:PerformDisenchant(item)
	end

	return true
end

---Perform the actual disenchant action
---@param item table
function DisenchantLogic:PerformDisenchant(item)
	self.isDisenchanting = true
	self.currentItem = item

	C_Container.UseContainerItem(item.bag, item.slot)

	C_Timer.After(0.1, function()
		if CursorHasSpell() then
			if CursorHasSpell() then
				ClearCursor()
				self.isDisenchanting = false
				self.currentItem = nil
				LibsDisenchantAssist:Print('Failed to start disenchanting ' .. item.itemLink)
			end
		end
	end)
end

---Disenchant all filtered items
function DisenchantLogic:DisenchantAll()
	LibsDisenchantAssist:Print("=== DISENCHANT ALL DEBUG START ===")
	
	if self.isDisenchanting then
		LibsDisenchantAssist:Print('Already disenchanting an item.')
		LibsDisenchantAssist:Print("=== DISENCHANT ALL DEBUG END ===")
		return
	end

	-- Check if we can disenchant at all
	if not self:CanDisenchant() then
		LibsDisenchantAssist:Print('Cannot disenchant right now (see previous messages)')
		LibsDisenchantAssist:Print("=== DISENCHANT ALL DEBUG END ===")
		return
	end

	LibsDisenchantAssist:Print('Getting disenchantable items...')
	local items = LibsDisenchantAssist.FilterSystem:GetDisenchantableItems()
	LibsDisenchantAssist:Print('Found ' .. #items .. ' items to disenchant')

	if #items == 0 then
		LibsDisenchantAssist:Print('No items to disenchant.')
		LibsDisenchantAssist:Print("=== DISENCHANT ALL DEBUG END ===")
		return
	end

	-- Debug: Show the items we're about to disenchant
	LibsDisenchantAssist:Print('Items to disenchant:')
	for i, item in ipairs(items) do
		LibsDisenchantAssist:Print('  ' .. i .. '. ' .. (item.itemLink or item.itemName or 'Unknown') .. ' (Bag: ' .. item.bag .. ', Slot: ' .. item.slot .. ')')
	end

	LibsDisenchantAssist:Print('Confirmation setting: ' .. tostring(LibsDisenchantAssist.DB.confirmDisenchant))

	if LibsDisenchantAssist.DB.confirmDisenchant then
		LibsDisenchantAssist:Print('Showing confirmation dialog...')
		StaticPopupDialogs['LIBS_DISENCHANT_ALL_CONFIRM'] = {
			text = 'Disenchant ' .. #items .. ' items?',
			button1 = 'Yes',
			button2 = 'No',
			OnAccept = function()
				LibsDisenchantAssist:Print('User confirmed - starting batch disenchant')
				self:StartBatchDisenchant(items)
			end,
			OnCancel = function()
				LibsDisenchantAssist:Print('User cancelled disenchant')
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show('LIBS_DISENCHANT_ALL_CONFIRM')
	else
		LibsDisenchantAssist:Print('No confirmation needed - starting batch disenchant')
		self:StartBatchDisenchant(items)
	end
	
	LibsDisenchantAssist:Print("=== DISENCHANT ALL DEBUG END ===")
end

---Start batch disenchant process
---@param items table<number, table>
function DisenchantLogic:StartBatchDisenchant(items)
	self.itemQueue = {}

	for i, item in ipairs(items) do
		table.insert(self.itemQueue, item)
	end

	LibsDisenchantAssist:Print('Starting batch disenchant of ' .. #self.itemQueue .. ' items...')
	self:ProcessNextItem()
end

---Process next item in queue
function DisenchantLogic:ProcessNextItem()
	if #self.itemQueue == 0 then
		LibsDisenchantAssist:Print('Batch disenchant complete!')
		return
	end

	local nextItem = table.remove(self.itemQueue, 1)

	local itemInfo = C_Container.GetContainerItemInfo(nextItem.bag, nextItem.slot)
	if not itemInfo or itemInfo.itemID ~= nextItem.itemID then
		self:ProcessNextItem()
		return
	end

	self:PerformDisenchant(nextItem)
end

---Handle spellcast start event
function DisenchantLogic:OnSpellcastStart()
	local name, _, _, _, _, _, _, _, spellId = UnitCastingInfo('player')
	if spellId == self.DISENCHANT_SPELL_ID and self.currentItem then LibsDisenchantAssist:Print('Disenchanting ' .. self.currentItem.itemLink .. '...') end
end

---Handle successful disenchant completion
function DisenchantLogic:OnDisenchantComplete()
	if self.currentItem then
		LibsDisenchantAssist:Print('Successfully disenchanted ' .. self.currentItem.itemLink)
		self.currentItem = nil
	end

	self.isDisenchanting = false

	C_Timer.After(0.5, function()
		if LibsDisenchantAssist.UI and LibsDisenchantAssist.UI.frame and LibsDisenchantAssist.UI.frame:IsVisible() then LibsDisenchantAssist.UI:RefreshItemList() end

		if #self.itemQueue > 0 then C_Timer.After(1, function()
			self:ProcessNextItem()
		end) end
	end)
end

---Handle disenchant failure
function DisenchantLogic:OnDisenchantFailed()
	if self.currentItem then
		LibsDisenchantAssist:Print('Failed to disenchant ' .. self.currentItem.itemLink)
		self.currentItem = nil
	end

	self.isDisenchanting = false
	self.itemQueue = {}
end

---Handle disenchant interruption
function DisenchantLogic:OnDisenchantInterrupted()
	if self.currentItem then
		LibsDisenchantAssist:Print('Disenchant interrupted for ' .. self.currentItem.itemLink)
		self.currentItem = nil
	end

	self.isDisenchanting = false
	self.itemQueue = {}
end

---Stop batch disenchant process
function DisenchantLogic:StopBatchDisenchant()
	if #self.itemQueue > 0 then
		LibsDisenchantAssist:Print('Stopped batch disenchant. ' .. #self.itemQueue .. ' items remaining.')
		self.itemQueue = {}
	end
end

LibsDisenchantAssist.DisenchantLogic = DisenchantLogic
