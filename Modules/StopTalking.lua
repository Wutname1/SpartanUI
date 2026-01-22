local SUI = SUI
if not SUI.IsRetail then
	return
end
---@class SUI.Module.StopTalking : SUI.Module
local module = SUI:NewModule('StopTalking')
local L = SUI.L
module.Displayname = L['Stop Talking']
module.description = 'Mutes the talking head frame once you have heard it.'
----------------------------------------------------------------------------------------------------
local HeardLines = {}

function module:OnInitialize()
	---@class SUI.Module.StopTalking.DB
	local defaults = {
		persist = true,
		chatOutput = true,
		global = true,
		stopAll = false,
		history = {},
		whitelist = {},
		pageSize = 20,
		currentBlacklistPage = 1,
		currentWhitelistPage = 1,
		searchBlacklist = '',
		searchWhitelist = '',
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('StopTalking', { profile = defaults, global = defaults })
	module.DB = module.Database.profile ---@type SUI.Module.StopTalking.DB
	module.DBGlobal = module.Database.global ---@type SUI.Module.StopTalking.DB
end

-- Helper function to truncate text to a specific number of words
local function TruncateToWords(text, wordCount)
	if not text then
		return ''
	end

	local words = {}
	for word in string.gmatch(text, '%S+') do
		table.insert(words, word)
		if #words >= wordCount then
			break
		end
	end

	local truncated = table.concat(words, ' ')
	if #words >= wordCount and text ~= truncated then
		truncated = truncated .. '...'
	end

	return truncated
end

function module:CleanupDatabase()
	-- Cleanup function to ensure all database items are strings
	local function cleanTable(tbl)
		if not tbl then
			return
		end
		local keysToRemove = {}

		-- First scan through the table and identify corrupted entries
		for key, value in pairs(tbl) do
			if type(value) ~= 'string' then
				-- If the key is a string, we can use it as a replacement for corrupted value
				if type(key) == 'string' then
					tbl[key] = key
				else
					-- If the key isn't a string, mark for deletion
					table.insert(keysToRemove, key)
				end
			end
		end

		-- Remove corrupted entries
		for _, key in ipairs(keysToRemove) do
			tbl[key] = nil
		end
	end

	-- Clean local database
	cleanTable(module.DB.history)
	cleanTable(module.DB.whitelist)

	-- Clean global database
	cleanTable(module.DBGlobal.history)
	cleanTable(module.DBGlobal.whitelist)

	SUI:Print('StopTalking database cleaned')
end

local buildItemList
local OptionTable = {
	name = L['Stop Talking'],
	type = 'group',
	get = function(info)
		return module.DB[info[#info]]
	end,
	set = function(info, val)
		module.DB[info[#info]] = val
	end,
	disabled = function()
		return SUI:IsModuleDisabled(module)
	end,
	childGroups = 'tab',
	args = {},
}

function module:BuildOptions()
	buildItemList = function(listType, mode)
		if not mode then
			mode = 'Blacklist'
		end
		local isBlacklist = (mode == 'Blacklist')

		local listOpts = OptionTable.args[mode].args.list.args
		table.wipe(listOpts)

		local sourceList = isBlacklist and (module.DBGlobal.global and module.DBGlobal.history or module.DB.history) or (module.DBGlobal.global and module.DBGlobal.whitelist or module.DB.whitelist)

		-- Apply search filter
		local filteredItems = {}
		local searchText = isBlacklist and (module.DB.searchBlacklist or '') or (module.DB.searchWhitelist or '')
		searchText = string.lower(searchText)

		for itemId, entry in pairs(sourceList) do
			-- Skip any non-string entries
			if type(entry) == 'string' and (searchText == '' or string.find(string.lower(entry), searchText)) then
				table.insert(filteredItems, { id = itemId, text = entry })
			end
		end

		-- Sort the filtered items to ensure consistent ordering
		table.sort(filteredItems, function(a, b)
			return a.text < b.text
		end)

		-- Pagination variables
		local pageSize = module.DB.pageSize or 20
		local currentPage = isBlacklist and module.DB.currentBlacklistPage or module.DB.currentWhitelistPage
		local totalItems = #filteredItems
		local totalPages = math.ceil(totalItems / pageSize)

		-- Ensure current page is valid
		if currentPage > totalPages then
			currentPage = totalPages
			if isBlacklist then
				module.DB.currentBlacklistPage = currentPage
			else
				module.DB.currentWhitelistPage = currentPage
			end
		end
		if currentPage < 1 then
			currentPage = 1
		end

		-- Add pagination controls
		listOpts['paginationInfo'] = {
			type = 'description',
			width = 'full',
			fontSize = 'medium',
			order = 1,
			name = L['Page'] .. ' ' .. currentPage .. '/' .. (totalPages == 0 and 1 or totalPages) .. ' (' .. totalItems .. ' ' .. (totalItems == 1 and L['item'] or L['items']) .. ')',
		}

		-- Search box
		local searchFieldName = isBlacklist and 'searchBlacklist' or 'searchWhitelist'
		listOpts['searchField'] = {
			type = 'input',
			name = L['Search'],
			width = 'full',
			order = 2,
			get = function()
				return module.DB[searchFieldName]
			end,
			set = function(_, val)
				module.DB[searchFieldName] = val
				if isBlacklist then
					module.DB.currentBlacklistPage = 1
				else
					module.DB.currentWhitelistPage = 1
				end
				buildItemList(listType, mode)
			end,
		}

		-- Previous page button
		listOpts['prevPage'] = {
			type = 'execute',
			name = L['Previous Page'],
			width = 'half',
			order = 3,
			disabled = currentPage <= 1,
			func = function()
				if isBlacklist then
					module.DB.currentBlacklistPage = module.DB.currentBlacklistPage - 1
				else
					module.DB.currentWhitelistPage = module.DB.currentWhitelistPage - 1
				end
				buildItemList(listType, mode)
			end,
		}

		-- Next page button
		listOpts['nextPage'] = {
			type = 'execute',
			name = L['Next Page'],
			width = 'half',
			order = 4,
			disabled = currentPage >= totalPages,
			func = function()
				if isBlacklist then
					module.DB.currentBlacklistPage = module.DB.currentBlacklistPage + 1
				else
					module.DB.currentWhitelistPage = module.DB.currentWhitelistPage + 1
				end
				buildItemList(listType, mode)
			end,
		}

		-- Separator
		listOpts['separator'] = {
			type = 'header',
			name = '',
			width = 'full',
			order = 5,
		}

		-- Calculate which items to show on the current page
		local startIndex = ((currentPage - 1) * pageSize) + 1
		local endIndex = math.min(startIndex + pageSize - 1, totalItems)

		-- Display items for the current page
		if totalItems > 0 then
			for i = startIndex, endIndex do
				local item = filteredItems[i]
				if item then
					local count = i
					local itemId = item.id
					local entry = item.text
					local buttonText = isBlacklist and L['Move to Whitelist'] or L['Move to Blacklist']
					local targetList = isBlacklist and 'whitelist' or 'history'

					-- Truncate entry to first 18 words
					local displayText = TruncateToWords(entry, 18)

					-- Create the entry label
					listOpts[tostring(count) .. 'label'] = {
						type = 'description',
						width = 'double',
						fontSize = 'medium',
						order = count * 3 + 10,
						name = displayText,
					}

					-- Create the delete button
					listOpts[tostring(count) .. 'delete'] = {
						type = 'execute',
						name = L['Delete'],
						width = 'half',
						order = (count * 3) + 11,
						func = function()
							if module.DBGlobal.global then
								if isBlacklist then
									module.DBGlobal.history[itemId] = nil
								else
									module.DBGlobal.whitelist[itemId] = nil
								end
							else
								if isBlacklist then
									module.DB.history[itemId] = nil
								else
									module.DB.whitelist[itemId] = nil
								end
							end
							buildItemList(listType, mode)
						end,
					}

					-- Create the move button
					listOpts[tostring(count) .. 'move'] = {
						type = 'execute',
						name = buttonText,
						width = 'half',
						order = (count * 3) + 12,
						func = function()
							local value = entry
							if module.DBGlobal.global then
								module.DBGlobal[targetList][itemId] = value
								if isBlacklist then
									module.DBGlobal.history[itemId] = nil
								else
									module.DBGlobal.whitelist[itemId] = nil
								end
							else
								module.DB[targetList][itemId] = value
								if isBlacklist then
									module.DB.history[itemId] = nil
								else
									module.DB.whitelist[itemId] = nil
								end
							end

							-- Rebuild both lists
							buildItemList(listType, 'Blacklist')
							buildItemList(listType, 'Whitelist')
						end,
					}
				end
			end
		else
			listOpts['noItems'] = {
				type = 'description',
				width = 'full',
				order = 10,
				name = L['No items found'],
			}
		end
	end

	OptionTable.args = {
		global = {
			name = L['Remember voice lines across all characters'],
			type = 'toggle',
			order = 0.5,
			width = 'full',
			get = function(info)
				return module.DBGlobal.global
			end,
			set = function(info, val)
				module.DBGlobal.global = val
				buildItemList('history', 'Blacklist')
				buildItemList('whitelist', 'Whitelist')
			end,
		},
		persist = {
			name = L['Keep track of voice lines forever'],
			type = 'toggle',
			order = 1,
			width = 'full',
		},
		stopAll = {
			name = L['Stop ALL voice lines'],
			desc = L['Immediately close all talking head voice lines, ignoring blacklist/whitelist settings'],
			type = 'toggle',
			order = 1.5,
			width = 'full',
		},
		chatOutput = {
			name = L['Display heard voice lines in the chat.'],
			type = 'toggle',
			order = 2,
			width = 'full',
		},
		cleanDatabase = {
			name = L['Clean Database'],
			type = 'execute',
			order = 3,
			width = 'full',
			func = function()
				module:CleanupDatabase()
				buildItemList('history', 'Blacklist')
				buildItemList('whitelist', 'Whitelist')
				SUI:Print('StopTalking database cleaned')
			end,
		},
		pageSize = {
			name = L['Items per page'],
			type = 'range',
			order = 4,
			width = 'full',
			min = 10,
			max = 50,
			step = 5,
			set = function(info, val)
				module.DB.pageSize = val
				module.DB.currentBlacklistPage = 1
				module.DB.currentWhitelistPage = 1
				buildItemList('history', 'Blacklist')
				buildItemList('whitelist', 'Whitelist')
			end,
		},
		Blacklist = {
			type = 'group',
			name = 'Blacklisted voice lines',
			order = 30,
			args = {
				create = {
					name = 'Add voice line to blacklist',
					type = 'input',
					order = 1,
					width = 'full',
					set = function(info, input)
						if input and input ~= '' then
							if module.DBGlobal.global then
								module.DBGlobal.history[input] = input
							else
								module.DB.history[input] = input
							end
							buildItemList('history', 'Blacklist')
						end
					end,
				},
				list = {
					order = 3,
					type = 'group',
					inline = true,
					name = 'Voice lines',
					args = {},
				},
			},
		},
		Whitelist = {
			type = 'group',
			name = 'Whitelisted voice lines',
			order = 40,
			args = {
				create = {
					name = 'Add voice line to whitelist',
					type = 'input',
					order = 1,
					width = 'full',
					set = function(info, input)
						if input and input ~= '' then
							if module.DBGlobal.global then
								module.DBGlobal.whitelist[input] = input
							else
								module.DB.whitelist[input] = input
							end
							buildItemList('whitelist', 'Whitelist')
						end
					end,
				},
				list = {
					order = 3,
					type = 'group',
					inline = true,
					name = 'Voice lines',
					args = {},
				},
			},
		},
	}

	SUI.Options:AddOptions(OptionTable, 'Stop Talking', 'Module')

	buildItemList('history', 'Blacklist')
	buildItemList('whitelist', 'Whitelist')
end

function module:TALKINGHEAD_REQUESTED()
	if SUI:IsModuleDisabled(module) then
		TalkingHeadFrame:PlayCurrent()
		return
	end

	local _, _, vo, _, _, _, name, text = C_TalkingHead.GetCurrentLineInfo()
	if not vo then
		return
	end

	-- If stopAll is enabled, immediately close all voice lines
	if module.DB.stopAll then
		if module.DB.chatOutput and name and text then
			SUI:Print(name)
			print(text)
		end
		TalkingHeadFrame:CloseImmediately()
		return
	end

	local persist = module.DB.persist
	local history = module.DBGlobal.global and module.DBGlobal.history or module.DB.history
	local whitelist = module.DBGlobal.global and module.DBGlobal.whitelist or module.DB.whitelist

	-- Check both persistent storage and session-based HeardLines
	if (persist and history[vo] and not whitelist[vo]) or (not persist and HeardLines[vo] and not whitelist[vo]) then
		-- Line has been heard before
		if module.DB.chatOutput and name and text then
			SUI:Print(name)
			print(text)
		end
		TalkingHeadFrame:CloseImmediately()
	else
		-- New line, play it and store it
		TalkingHeadFrame:PlayCurrent()
		if persist then
			history[vo] = name .. ' - ' .. text
		else
			HeardLines[vo] = name .. ' - ' .. text
		end
	end
end

function module:OnEnable()
	if SUI:IsModuleDisabled(module) then
		return
	end

	--Import Globals if active
	if module.DBGlobal.global then
		for k, v in pairs(module.DB.history) do
			module.DBGlobal.history[k] = v
		end
		module.DB.history = {}
	end

	-- Build the options
	self:BuildOptions()

	module:RegisterEvent('TALKINGHEAD_REQUESTED')
	TalkingHeadFrame:UnregisterEvent('TALKINGHEAD_REQUESTED')
end
