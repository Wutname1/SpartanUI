local SUI, L, print = SUI, SUI.L, SUI.print
local module = SUI:NewModule('Component_MailOpenAll', 'AceEvent-3.0', 'AceTimer-3.0')
module.Displayname = L['Open all mail']
module.description = 'Quality of life update to the open all mail button'

local MAX_MAIL_SHOWN = 50
local mailIndex, attachIndex, numUnshownItems
local lastItem, lastNumAttach, lastNumGold
local wait, button, skipFlag
local invFull, invAlmostFull
local firstMailDaysLeft
local totalGold
module.RefreshMailTimer = nil

function module:OnInitialize()
	local defaults = {
		profile = {
			FirstLaunch = true,
			Silent = false,
			FreeSpace = 0
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('MailOpenAll', defaults)
	module.DB = module.Database.profile

	-- Migrate old settings
	if SUI.DB.MailOpenAll then
		print('Mail enhancements DB Migration')
		module.DB = SUI:MergeData(module.DB, SUI.DB.MailOpenAll, true)
		SUI.DB.MailOpenAll = nil
	end
end

local updateFrame = CreateFrame('Frame')
updateFrame:Hide()
updateFrame:SetScript(
	'OnShow',
	function(self)
		self.time = 0.50
		if invAlmostFull and self.time < 1.0 and not self.lootingMoney then
			self.time = 1.0
		end
		self.lootingMoney = nil
	end
)
updateFrame:SetScript(
	'OnUpdate',
	function(self, elapsed)
		self.time = self.time - elapsed
		if self.time <= 0 then
			self:Hide()
			module:ProcessNext()
		end
	end
)

function module:RefreshMail()
	local current, total = GetInboxNumItems()
	if current == MAX_MAIL_SHOWN or current == total then
		self.time = 10
		SUI:Print(L['Refreshing mailbox'])
		CheckInbox()
	else
		self:Hide()
		module:OpenMail()
	end
end

function module:OnEnable()
	module:BuildOptions()
	if SUI.DB.DisabledComponents.MailOpenAll then
		return
	end
	module:Enable()
end

function module:Enable()
	if not button then
		button = CreateFrame('Button', 'SUI_OpenAllMail', InboxFrame, 'UIPanelButtonTemplate')
		button:SetWidth(120)
		button:SetHeight(25)
		button:SetAllPoints(OpenAllMail)
		--button:SetPoint("CENTER", OpenAllMail, "TOP", 0, -42)
		button:SetText(L['Open All'])
		button:SetScript(
			'OnClick',
			function()
				module:OpenMail()
			end
		)
		button:SetFrameLevel(button:GetFrameLevel() + 1)
		OpenAllMail:Hide()
	end

	self:RegisterEvent('MAIL_SHOW')
end

function module:Disable()
	SUI:Print('Auto open mail disabled')
	self:Reset()
	button:Hide()
end

function module:MAIL_SHOW()
	mailIndex = select(1, GetInboxNumItems())
	if mailIndex == 0 then
		button:Hide()
		module.CheckTimer = module:ScheduleRepeatingTimer('MAIL_SHOW', .5)
		module.ResetTimer = module:ScheduleTimer('Reset', 2)
	else
		button:Show()
		module:CancelAllTimers()
	end

	self:RegisterEvent('MAIL_CLOSED', 'Reset')
	self:RegisterEvent('PLAYER_LEAVING_WORLD', 'Reset')
end

function module:OpenMail()
	-- refreshFrame:Hide()
	mailIndex, numUnshownItems = GetInboxNumItems()
	numUnshownItems = numUnshownItems - mailIndex
	attachIndex = ATTACHMENTS_MAX_RECEIVE
	invFull = nil
	invAlmostFull = nil
	skipFlag = false
	lastItem = false
	lastNumAttach = nil
	lastNumGold = nil
	wait = false
	if mailIndex == 0 then
		button:SetText(L['Open All'])
		return
	end
	firstMailDaysLeft = select(7, GetInboxHeaderInfo(1))

	button:SetText(L['Opening...'])

	self:RegisterEvent('UI_ERROR_MESSAGE')
	totalGold = 0
	self:ProcessNext()
end

function module:ProcessNext()
	local curFirstMailDaysLeft = select(7, GetInboxHeaderInfo(1))
	if curFirstMailDaysLeft ~= 0 and curFirstMailDaysLeft ~= firstMailDaysLeft then
		return -- self:OpenAll(true)
	end

	if mailIndex > 0 then
		if wait then
			local attachCount, goldCount = module:CountAttachments()
			if lastNumGold ~= goldCount then
				-- Process next mail, gold has been taken
				wait = false
				mailIndex = mailIndex - 1
				attachIndex = ATTACHMENTS_MAX_RECEIVE
				return self:ProcessNext() -- tail call
			elseif lastNumAttach ~= attachCount then
				-- Process next item, an attachment has been taken
				wait = false
				attachIndex = attachIndex - 1
				if lastItem then
					-- The item taken was the last item, process next mail
					lastItem = false
					mailIndex = mailIndex - 1
					attachIndex = ATTACHMENTS_MAX_RECEIVE
					return self:ProcessNext() -- tail call
				end
			else
				-- Wait longer until something in the mailbox changes
				updateFrame:Show()
				return
			end
		end

		local _, msgSubject, msgMoney, msgCOD, _, _, _, _, _, _, isGM = select(3, GetInboxHeaderInfo(mailIndex))

		if (msgCOD and msgCOD > 0) or (isGM) then
			skipFlag = true
			mailIndex = mailIndex - 1
			attachIndex = ATTACHMENTS_MAX_RECEIVE
			return self:ProcessNext() -- tail call
		end

		if (not invFull or msgMoney > 0) and not module.DB.Silent then
			local moneyString = msgMoney > 0 and ' [' .. module:FormatMoney(msgMoney) .. ']' or ''
			local playerName
			totalGold = totalGold + msgMoney
			if (mailType == 'AHSuccess' or mailType == 'AHWon') then
				playerName = select(3, GetInboxInvoiceInfo(mailIndex))
				playerName = playerName and (' (' .. playerName .. ')')
			end
			SUI:Print(format('%s %d: %s%s%s', L['Mail'], mailIndex, msgSubject or '', moneyString, (playerName or '')))
		end

		-- Find next attachment index
		while not GetInboxItemLink(mailIndex, attachIndex) and attachIndex > 0 do
			attachIndex = attachIndex - 1
		end

		-- bag space check
		if attachIndex > 0 and not invFull and module.DB.FreeSpace > 0 then
			local free = 0
			for bag = 0, NUM_BAG_SLOTS do
				local bagFree, bagFam = GetContainerNumFreeSlots(bag)
				if bagFam == 0 then
					free = free + bagFree
				end
			end
			if free <= module.DB.FreeSpace then
				invFull = true
				invAlmostFull = nil
				SUI:Print(format(L['Auto open disabled. There is only %d bagslots free.'], free))
			elseif free <= module.DB.FreeSpace + 1 then
				invAlmostFull = true
			end
		end

		-- If inventory is full, check if the item to be looted can stack with an existing stack
		local lootFlag = false
		if attachIndex > 0 and invFull then
			local _, _, _, count = GetInboxItem(mailIndex, attachIndex)
			local link = GetInboxItemLink(mailIndex, attachIndex)
			local itemID = strmatch(link, 'item:(%d+)')
			local stackSize = select(8, GetItemInfo(link))
			if itemID and stackSize and GetItemCount(itemID) > 0 then
				for bag = 0, NUM_BAG_SLOTS do
					for slot = 1, GetContainerNumSlots(bag) do
						local _, count2, _, _, _, _, link2 = GetContainerItemInfo(bag, slot)
						if link2 then
							local itemID2 = strmatch(link2, 'item:(%d+)')
							if itemID == itemID2 and count + count2 <= stackSize then
								lootFlag = true
								break
							end
						end
					end
					if lootFlag then
						break
					end
				end
			end
		end

		if attachIndex > 0 and (lootFlag or not invFull) then
			-- If there's attachments, take the item
			--SUI:Print("Getting Item from Message "..mailIndex..", "..attachIndex)
			lastNumAttach, lastNumGold = module:CountAttachments()
			TakeInboxItem(mailIndex, attachIndex)

			wait = true
			-- Find next attachment index backwards
			local attachIndex2 = attachIndex - 1
			while not GetInboxItemLink(mailIndex, attachIndex2) and attachIndex2 > 0 do
				attachIndex2 = attachIndex2 - 1
			end
			if attachIndex2 == 0 and msgMoney == 0 then
				lastItem = true
			end

			updateFrame:Show()
		elseif msgMoney > 0 then
			-- No attachments, but there is money
			--SUI:Print("Getting Gold from Message "..mailIndex)
			lastNumAttach, lastNumGold = module:CountAttachments()
			TakeInboxMoney(mailIndex)

			wait = true

			updateFrame.lootingMoney = true
			updateFrame:Show()
		else
			-- Mail has no item or money, go to next mail
			mailIndex = mailIndex - 1
			attachIndex = ATTACHMENTS_MAX_RECEIVE
			return self:ProcessNext() -- tail call
		end
	else
		-- Reached the end of opening all selected mail

		local numItems, totalItems = GetInboxNumItems()
		if numUnshownItems ~= totalItems - numItems then
			-- We will Open All again if the number of unshown items is different
			return --self:OpenAll(true) -- tail call
		elseif totalItems > numItems and numItems < MAX_MAIL_SHOWN then
			-- We only want to refresh if there's more items to show
			SUI:Print(L['Not all messages are shown, refreshing mailbox soon to continue Open All...'])
			-- refreshFrame:Show()
			module.RefreshMailTimer = module:ScheduleTimer('RefreshMail', 65)
			return
		end

		if skipFlag then
			SUI:Print(L['Some Messages May Have Been Skipped.'])
		end
		if (totalGold and totalGold > 0) and not module.DB.Silent then
			SUI:Print('Total money gained: ' .. module:FormatMoney(totalGold))
		end
		self:Reset()
	end
end

function module:Reset(event)
	updateFrame:Hide()
	module:CancelAllTimers()

	self:UnregisterEvent('UI_ERROR_MESSAGE')
	button:SetText(L['Open All'])
	InboxFrame_Update()
	if event == 'MAIL_CLOSED' or event == 'PLAYER_LEAVING_WORLD' then
		self:UnregisterEvent('MAIL_CLOSED')
		self:UnregisterEvent('PLAYER_LEAVING_WORLD')
	end
end

function module:UI_ERROR_MESSAGE(event, error_message)
	if error_message == ERR_INV_FULL then
		invFull = true
		wait = false
	elseif error_message == ERR_ITEM_MAX_COUNT then
		attachIndex = attachIndex - 1
		wait = false
	end
end

function module:FormatMoney(money)
	local gold = floor(money / 10000)
	local silver = floor((money - gold * 10000) / 100)
	local copper = mod(money, 100)
	if gold > 0 then
		return format(
			GOLD_AMOUNT_TEXTURE .. ' ' .. SILVER_AMOUNT_TEXTURE .. ' ' .. COPPER_AMOUNT_TEXTURE,
			gold,
			0,
			0,
			silver,
			0,
			0,
			copper,
			0,
			0
		)
	elseif silver > 0 then
		return format(SILVER_AMOUNT_TEXTURE .. ' ' .. COPPER_AMOUNT_TEXTURE, silver, 0, 0, copper, 0, 0)
	else
		return format(COPPER_AMOUNT_TEXTURE, copper, 0, 0)
	end
end

function module:CountAttachments()
	local numAttach, numGold = 0, 0
	for i = 1, GetInboxNumItems() do
		local msgMoney, _, _, msgItem = select(5, GetInboxHeaderInfo(i))
		numAttach = numAttach + (msgItem or 0)
		numGold = numGold + msgMoney
	end
	return numAttach, numGold
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['MailOpenAll'] = {
		type = 'group',
		name = L['Open all mail'],
		args = {
			Silent = {
				name = L['Silently open mail'],
				type = 'toggle',
				order = 1,
				width = 'full',
				get = function(info)
					return module.DB.Silent
				end,
				set = function(info, val)
					module.DB.Silent = val
				end
			},
			FreeSpace = {
				name = L['Bag free space to maintain'],
				type = 'range',
				order = 10,
				width = 'full',
				min = 0,
				max = 50,
				step = 1,
				set = function(info, val)
					module.DB.FreeSpace = val
				end,
				get = function(info)
					return module.DB.FreeSpace
				end
			}
		}
	}
end
