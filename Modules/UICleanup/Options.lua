local SUI, L = SUI, SUI.L
---@class SUI.Module.UICleanup
local module = SUI:GetModule('UICleanup')
----------------------------------------------------------------------------------------------------

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

local buildStopTalkingList

function module:BuildOptions()
	local DB = module:GetDB()
	local StopTalkingDB = module:GetStopTalkingDB()
	local StopTalkingDBGlobal = module:GetStopTalkingDBGlobal()

	---@type AceConfig.OptionsTable
	local OptionTable = {
		type = 'group',
		name = L['UI Cleanup'],
		childGroups = 'tab',
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		args = {
			general = {
				type = 'group',
				name = L['General'],
				order = 1,
				args = {
					hideErrorMessages = {
						name = L['Hide error messages'],
						desc = L['Hide red error messages like "Not enough rage"'],
						type = 'toggle',
						order = 1,
						width = 'full',
						get = function()
							return DB.hideErrorMessages
						end,
						set = function(_, val)
							DB.hideErrorMessages = val
							module:ApplyErrorMessageSettings()
						end,
					},
					hideZoneText = {
						name = L['Hide zone text'],
						desc = L['Hide zone name display when entering new areas'],
						type = 'toggle',
						order = 2,
						width = 'full',
						get = function()
							return DB.hideZoneText
						end,
						set = function(_, val)
							DB.hideZoneText = val
							module:ApplyFrameHidingSettings()
						end,
					},
					hideAlerts = {
						name = L['Hide alerts'],
						desc = L['Hide achievement and loot toast frames'],
						type = 'toggle',
						order = 3,
						width = 'full',
						get = function()
							return DB.hideAlerts
						end,
						set = function(_, val)
							DB.hideAlerts = val
							module:ApplyFrameHidingSettings()
						end,
					},
					hideBossBanner = {
						name = L['Hide boss banner'],
						desc = L['Hide boss defeat banner'],
						type = 'toggle',
						order = 4,
						width = 'full',
						get = function()
							return DB.hideBossBanner
						end,
						set = function(_, val)
							DB.hideBossBanner = val
							module:ApplyFrameHidingSettings()
						end,
					},
					hideEventToasts = {
						name = L['Hide event toasts'],
						desc = L['Hide level-up, pet battle rewards, etc.'],
						type = 'toggle',
						order = 5,
						width = 'full',
						get = function()
							return DB.hideEventToasts
						end,
						set = function(_, val)
							DB.hideEventToasts = val
							module:ApplyFrameHidingSettings()
						end,
					},
				},
			},
		},
	}

	-- Add StopTalking options (Retail only)
	if SUI.IsRetail and StopTalkingDB then
		buildStopTalkingList = function(listType, mode)
			if not mode then
				mode = 'Blacklist'
			end
			local isBlacklist = (mode == 'Blacklist')

			local listOpts = OptionTable.args.stopTalking.args[mode].args.list.args
			table.wipe(listOpts)

			local sourceList = isBlacklist and (StopTalkingDBGlobal.global and StopTalkingDBGlobal.history or StopTalkingDB.history)
				or (StopTalkingDBGlobal.global and StopTalkingDBGlobal.whitelist or StopTalkingDB.whitelist)

			-- Apply search filter
			local filteredItems = {}
			local searchText = isBlacklist and (StopTalkingDB.searchBlacklist or '') or (StopTalkingDB.searchWhitelist or '')
			searchText = string.lower(searchText)

			for itemId, entry in pairs(sourceList) do
				if type(entry) == 'string' and (searchText == '' or string.find(string.lower(entry), searchText)) then
					table.insert(filteredItems, { id = itemId, text = entry })
				end
			end

			table.sort(filteredItems, function(a, b)
				return a.text < b.text
			end)

			-- Pagination
			local pageSize = StopTalkingDB.pageSize or 20
			local currentPage = isBlacklist and StopTalkingDB.currentBlacklistPage or StopTalkingDB.currentWhitelistPage
			local totalItems = #filteredItems
			local totalPages = math.ceil(totalItems / pageSize)

			if currentPage > totalPages then
				currentPage = totalPages
			end
			if currentPage < 1 then
				currentPage = 1
			end

			listOpts['paginationInfo'] = {
				type = 'description',
				width = 'full',
				fontSize = 'medium',
				order = 1,
				name = L['Page'] .. ' ' .. currentPage .. '/' .. (totalPages == 0 and 1 or totalPages) .. ' (' .. totalItems .. ' ' .. L['items'] .. ')',
			}

			local searchFieldName = isBlacklist and 'searchBlacklist' or 'searchWhitelist'
			listOpts['searchField'] = {
				type = 'input',
				name = L['Search'],
				width = 'full',
				order = 2,
				get = function()
					return StopTalkingDB[searchFieldName]
				end,
				set = function(_, val)
					StopTalkingDB[searchFieldName] = val
					if isBlacklist then
						StopTalkingDB.currentBlacklistPage = 1
					else
						StopTalkingDB.currentWhitelistPage = 1
					end
					buildStopTalkingList(listType, mode)
				end,
			}

			listOpts['prevPage'] = {
				type = 'execute',
				name = L['Previous Page'],
				width = 'half',
				order = 3,
				disabled = currentPage <= 1,
				func = function()
					if isBlacklist then
						StopTalkingDB.currentBlacklistPage = StopTalkingDB.currentBlacklistPage - 1
					else
						StopTalkingDB.currentWhitelistPage = StopTalkingDB.currentWhitelistPage - 1
					end
					buildStopTalkingList(listType, mode)
				end,
			}

			listOpts['nextPage'] = {
				type = 'execute',
				name = L['Next Page'],
				width = 'half',
				order = 4,
				disabled = currentPage >= totalPages,
				func = function()
					if isBlacklist then
						StopTalkingDB.currentBlacklistPage = StopTalkingDB.currentBlacklistPage + 1
					else
						StopTalkingDB.currentWhitelistPage = StopTalkingDB.currentWhitelistPage + 1
					end
					buildStopTalkingList(listType, mode)
				end,
			}

			listOpts['separator'] = {
				type = 'header',
				name = '',
				width = 'full',
				order = 5,
			}

			local startIndex = ((currentPage - 1) * pageSize) + 1
			local endIndex = math.min(startIndex + pageSize - 1, totalItems)

			if totalItems > 0 then
				for i = startIndex, endIndex do
					local item = filteredItems[i]
					if item then
						local count = i
						local itemId = item.id
						local entry = item.text
						local displayText = TruncateToWords(entry, 18)

						listOpts[tostring(count) .. 'label'] = {
							type = 'description',
							width = 'double',
							fontSize = 'medium',
							order = count * 3 + 10,
							name = displayText,
						}

						listOpts[tostring(count) .. 'delete'] = {
							type = 'execute',
							name = L['Delete'],
							width = 'half',
							order = (count * 3) + 11,
							func = function()
								if StopTalkingDBGlobal.global then
									if isBlacklist then
										StopTalkingDBGlobal.history[itemId] = nil
									else
										StopTalkingDBGlobal.whitelist[itemId] = nil
									end
								else
									if isBlacklist then
										StopTalkingDB.history[itemId] = nil
									else
										StopTalkingDB.whitelist[itemId] = nil
									end
								end
								buildStopTalkingList(listType, mode)
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

		OptionTable.args.stopTalking = {
			type = 'group',
			name = L['Stop Talking'],
			order = 2,
			args = {
				global = {
					name = L['Remember voice lines across all characters'],
					type = 'toggle',
					order = 0.5,
					width = 'full',
					get = function()
						return StopTalkingDBGlobal.global
					end,
					set = function(_, val)
						StopTalkingDBGlobal.global = val
						buildStopTalkingList('history', 'Blacklist')
						buildStopTalkingList('whitelist', 'Whitelist')
					end,
				},
				persist = {
					name = L['Keep track of voice lines forever'],
					type = 'toggle',
					order = 1,
					width = 'full',
					get = function()
						return StopTalkingDB.persist
					end,
					set = function(_, val)
						StopTalkingDB.persist = val
					end,
				},
				stopAll = {
					name = L['Stop ALL voice lines'],
					desc = L['Immediately close all talking head voice lines, ignoring blacklist/whitelist settings'],
					type = 'toggle',
					order = 1.5,
					width = 'full',
					get = function()
						return StopTalkingDB.stopAll
					end,
					set = function(_, val)
						StopTalkingDB.stopAll = val
					end,
				},
				chatOutput = {
					name = L['Display heard voice lines in the chat.'],
					type = 'toggle',
					order = 2,
					width = 'full',
					get = function()
						return StopTalkingDB.chatOutput
					end,
					set = function(_, val)
						StopTalkingDB.chatOutput = val
					end,
				},
				cleanDatabase = {
					name = L['Clean Database'],
					type = 'execute',
					order = 3,
					width = 'full',
					func = function()
						module:CleanupStopTalkingDatabase()
						buildStopTalkingList('history', 'Blacklist')
						buildStopTalkingList('whitelist', 'Whitelist')
					end,
				},
				Blacklist = {
					type = 'group',
					name = L['Blacklisted voice lines'],
					order = 30,
					args = {
						list = {
							order = 3,
							type = 'group',
							inline = true,
							name = L['Voice lines'],
							args = {},
						},
					},
				},
				Whitelist = {
					type = 'group',
					name = L['Whitelisted voice lines'],
					order = 40,
					args = {
						list = {
							order = 3,
							type = 'group',
							inline = true,
							name = L['Voice lines'],
							args = {},
						},
					},
				},
			},
		}

		-- Build the lists
		buildStopTalkingList('history', 'Blacklist')
		buildStopTalkingList('whitelist', 'Whitelist')
	end

	SUI.Options:AddOptions(OptionTable, 'UICleanup')
end
