local SUI, L = SUI, SUI.L
---@class SUI.Module.QuestTools
local module = SUI:GetModule('QuestTools')
----------------------------------------------------------------------------------------------------

local DB
local GlobalDB

local OptionTable = {
	type = 'group',
	name = L['Quest Tools'],
	childGroups = 'tab',
	get = function(info)
		return DB[info[#info]]
	end,
	set = function(info, val)
		DB[info[#info]] = val
	end,
	disabled = function()
		return SUI:IsModuleDisabled(module)
	end,
}

local buildItemList

function module:BuildOptions()
	DB = module:GetDB()
	GlobalDB = module:GetGlobalDB()

	buildItemList = function(listType, mode)
		if not mode then
			mode = 'Blacklist'
		end
		local spellsOpt = OptionTable.args[mode].args[listType].args.list.args
		table.wipe(spellsOpt)

		for itemId, entry in pairs(module[mode].Get(listType)) do
			local label

			if type(entry) == 'number' then
				-- If the entry is a number, assume it's a quest ID
				local title = C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(entry)
				if title then
					label = 'ID: ' .. entry .. ' (' .. title .. ')'
				else
					label = '|cFFFF0000ID: ' .. entry .. ' (Title not found)'
				end
			else
				-- If the entry is not a number, use it directly
				label = entry
			end

			spellsOpt[itemId .. 'label'] = {
				type = 'description',
				width = 'double',
				fontSize = 'medium',
				order = itemId,
				name = label,
			}
			spellsOpt[tostring(itemId)] = {
				type = 'execute',
				name = L['Delete'],
				width = 'half',
				order = itemId + 0.05,
				func = function(info)
					module[mode].Remove(itemId, listType)
					buildItemList(listType, mode)
				end,
			}
		end
	end

	-- Store reference for RefreshBlacklistUI
	module.buildItemList = buildItemList

	OptionTable.args = {
		DoCampainQuests = {
			name = L['Accept/Complete Campaign Quests'],
			type = 'toggle',
			width = 'double',
			order = 1,
		},
		ChatText = {
			name = L['Output quest text in chat'],
			type = 'toggle',
			width = 'double',
			order = 2,
		},
		QuestAccepting = {
			name = L['Quest accepting'],
			type = 'group',
			inline = true,
			order = 10,
			width = 'full',
			get = function(info)
				return DB[info[#info]]
			end,
			set = function(info, val)
				DB[info[#info]] = val
			end,
			args = {
				AcceptGeneralQuests = {
					name = L['Accept quests'],
					type = 'toggle',
					order = 10,
				},
				trivial = {
					name = L['Accept trivial quests'],
					type = 'toggle',
					order = 20,
				},
				AcceptRepeatable = {
					name = L['Accept repeatable'],
					type = 'toggle',
					order = 30,
				},
				AutoGossip = {
					name = L['Auto gossip'],
					type = 'toggle',
					order = 15,
				},
				AutoGossipSafeMode = {
					name = L['Auto gossip safe mode'],
					desc = 'If the option is not in the whitelist or does not have the (Quest) tag, it will not be automatically selected.',
					type = 'toggle',
					order = 16,
				},
				hideBodyguardGossip = {
					name = L['Hide bodyguard gossip'],
					desc = L['Automatically close gossip window when talking to garrison bodyguards. Hold Shift to override.'],
					type = 'toggle',
					order = 17,
				},
			},
		},
		QuestTurnIn = {
			name = L['Quest turn in'],
			type = 'group',
			inline = true,
			order = 20,
			width = 'full',
			get = function(info)
				return DB[info[#info]]
			end,
			set = function(info, val)
				DB[info[#info]] = val
			end,
			args = {
				TurnInEnabled = {
					name = L['Turn in completed quests'],
					type = 'toggle',
					order = 10,
				},
				lootreward = {
					name = L['Auto select quest reward'],
					type = 'toggle',
					order = 30,
				},
				autoequip = {
					name = L['Auto equip upgrade quest rewards'],
					desc = L['Based on iLVL'],
					type = 'toggle',
					order = 30,
				},
			},
		},
		useGlobalDB = {
			name = L['Use a shared Blacklist & Whitelist for all characters.'],
			type = 'toggle',
			width = 'full',
			order = 30,
		},
		Blacklist = {
			type = 'group',
			name = 'Blacklist',
			order = 40,
			args = {
				QuestIDs = {
					type = 'group',
					name = 'Quest ID',
					order = 40,
					args = {
						desc = {
							name = 'Blacklisted quests will never be auto accepted',
							type = 'description',
							order = 1,
						},
						desc2 = {
							name = 'Quests can be blacklisted by holding CTRL while talking to a NPC or by adding the quest ID to the list below',
							type = 'description',
							order = 1.1,
						},
						create = {
							name = 'Add Quest ID',
							type = 'input',
							order = 2,
							width = 'full',
							set = function(info, input)
								module.Blacklist.Add(input, 'QuestIDs', false, #info - 1)
								buildItemList(info[#info - 1])
							end,
						},
						list = {
							order = 3,
							type = 'group',
							inline = true,
							name = 'Quest list',
							args = {},
						},
					},
				},
				Wildcard = {
					type = 'group',
					name = 'Wildcard',
					order = 41,
					args = {
						desc = {
							name = 'Any quest or gossip selection when talking to a NPC containing the text below will not be auto selected',
							type = 'description',
							order = 1,
						},
						create = {
							name = 'Add text to block',
							type = 'input',
							order = 2,
							width = 'full',
							set = function(info, input)
								module.Blacklist.Add(input, 'Wildcard', false, #info - 1)
								buildItemList(info[#info - 1])
							end,
						},
						list = {
							order = 3,
							type = 'group',
							inline = true,
							name = 'Quest list',
							args = {},
						},
					},
				},
				Gossip = {
					type = 'group',
					name = 'Gossip options',
					order = 42,
					args = {
						desc = {
							name = 'Blacklisted gossip options will never be auto selected',
							type = 'description',
							order = 1,
						},
						create = {
							name = 'Add gossip text',
							type = 'input',
							order = 2,
							width = 'full',
							set = function(info, input)
								module.Blacklist.Add(input, 'Gossip', false, #info - 1)
								buildItemList(info[#info - 1])
							end,
						},
						list = {
							order = 3,
							type = 'group',
							inline = true,
							name = 'Quest list',
							args = {},
						},
					},
				},
			},
		},
		Whitelist = {
			type = 'group',
			name = 'Whitelist',
			order = 50,
			args = {
				Gossip = {
					type = 'group',
					name = 'Gossip',
					order = 42,
					args = {
						desc = {
							name = 'Whitelisted gossip options will be auto selected',
							type = 'description',
							order = 1,
						},
						create = {
							name = 'Add gossip text',
							type = 'input',
							order = 2,
							width = 'full',
							set = function(info, input)
								module.Whitelist.Add(input, 'Gossip', false, #info - 1)
								buildItemList(info[#info - 1], 'Whitelist')
							end,
						},
						list = {
							order = 3,
							type = 'group',
							inline = true,
							name = 'Quest list',
							args = {},
						},
					},
				},
			},
		},
	}

	buildItemList('QuestIDs')
	buildItemList('Wildcard')
	buildItemList('Gossip')
	buildItemList('Gossip', 'Whitelist')
	SUI.Options:AddOptions(OptionTable, 'QuestTools')
end
