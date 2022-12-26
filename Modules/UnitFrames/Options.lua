local _G, SUI, L = _G, SUI, SUI.L
local UF = SUI.UF ---@class SUI.UF
----------------------------------------------------------------------------------------------------
local anchorPoints = {
	['TOPLEFT'] = 'TOP LEFT',
	['TOP'] = 'TOP',
	['TOPRIGHT'] = 'TOP RIGHT',
	['RIGHT'] = 'RIGHT',
	['CENTER'] = 'CENTER',
	['LEFT'] = 'LEFT',
	['BOTTOMLEFT'] = 'BOTTOM LEFT',
	['BOTTOM'] = 'BOTTOM',
	['BOTTOMRIGHT'] = 'BOTTOM RIGHT',
}

---@param optTable AceConfigOptionsTable
local function SUIHealth(optTable)
	local mode = 'Health'
	if optTable.name == 'SUIPower' then mode = 'Power' end

	local prefix = ''
	local suffix = ''
	local options = {
		displayDead = false,
		hideDead = false,
		hideZero = false,
		hideMax = false,
		short = false,
		percentage = false,
		dynamic = false,
		formatted = true,
		current = true,
		max = false,
		missing = false,
	}
	local tagText = 'current'
	local tagTextMode = 'formatted'

	optTable.type = 'group'
	optTable.inline = true
	optTable.order = 0.1
	optTable.args = {
		description = {
			name = 'This is a custom dynamic text tag that you can use to display information about the ' .. mode .. ' of the unit. You can use the following options to customize the text.',
			type = 'description',
			order = 0,
		},
		output = {
			name = optTable.name or '',
			type = 'input',
			order = 1,
			width = 'full',
			get = function(info)
				local opt = ''
				for k, v in pairs(options) do
					if v and k ~= 'formatted' and k ~= 'current' then
						if opt == '' then
							opt = opt .. k
						else
							opt = opt .. ',' .. k
						end
					end
				end

				--Setup the misc stuff
				if opt ~= '' then opt = '(' .. opt .. ')' end
				local finalPrefix = ''
				local finalSuffix = ''
				if prefix ~= '' then finalPrefix = prefix .. '$>' end
				if suffix ~= '' then finalSuffix = '<$' .. suffix end

				return '[' .. finalPrefix .. optTable.name .. finalSuffix .. opt .. ']'
			end,
		},
		prefix = {
			name = 'Prefix',
			type = 'input',
			order = 2,
			get = function(info)
				return prefix
			end,
			set = function(info, value)
				prefix = value
			end,
		},
		suffix = {
			name = 'Suffix',
			type = 'input',
			order = 3,
			get = function(info)
				return suffix
			end,
			set = function(info, value)
				suffix = value
			end,
		},
		tagText = {
			name = mode .. ' text to show',
			type = 'select',
			style = 'radio',
			order = 4,
			get = function(info)
				return tagText
			end,
			set = function(info, value)
				options.missing = false
				options.current = false
				options.max = false

				tagText = value
				options[value] = true
			end,
			values = {
				['missing'] = 'Missing ' .. mode,
				['current'] = 'Current ' .. mode,
				['max'] = 'Max ' .. mode,
			},
		},
		tagTextMode = {
			name = 'How to show selected text',
			desc = '- Formatted will add commas to the value\n- Short will round the number to the thousands or millions\n- Dynamic will change based on the total health pool\n- Percentage will show the percentage of health remaining and includes a % sign',
			type = 'select',
			style = 'radio',
			order = 5,
			get = function(info)
				return tagTextMode
			end,
			set = function(info, value)
				options.dynamic = false
				options.short = false
				options.percentage = false
				options.formatted = false

				tagTextMode = value
				options[value] = true
			end,
			values = {
				['formatted'] = 'Formatted',
				['short'] = 'Short',
				['dynamic'] = 'Dynamic',
				['percentage'] = 'Percentage',
			},
		},
		options = {
			type = 'group',
			name = 'Options',
			desc = 'Options for the tag, you may select as many as you like',
			order = 6,
			get = function(info)
				return options[info[#info]]
			end,
			set = function(info, value)
				options[info[#info]] = value
			end,
			args = {
				displayDead = {
					type = 'toggle',
					name = 'Display Dead',
					desc = "Display 'DEAD' when the unit is dead",
					order = 1,
				},
				hideDead = {
					type = 'toggle',
					name = 'Hide Dead',
					desc = 'Show nothing when the unit is dead',
					order = 2,
				},
				hideMax = {
					type = 'toggle',
					name = 'Hide Max',
					desc = 'Show nothing when the unit is at full health',
					order = 3,
				},
				hideZero = {
					type = 'toggle',
					name = 'Hide Zero',
					desc = 'Show nothing when the specified health data is at 0',
					order = 4,
				},
				line = {
					type = 'description',
					name = '',
					order = 5,
				},
			},
		},
	}
end

local TagList = {
	--Health
	['SUIHealth'] = { category = 'Health', description = 'SUIHealth', func = SUIHealth },
	['curhp'] = { category = 'Health', description = 'Displays the current HP without decimals' },
	['deficit:name'] = { category = 'Health', description = 'Displays the health as a deficit and the name at full health' },
	['perhp'] = {
		category = 'Health',
		description = 'Displays percentage HP without decimals or the % sign. You can display the percent sign by adjusting the tag to [perhp<$%].',
	},
	['maxhp'] = { category = 'Health', description = 'Displays max HP without decimals' },
	['missinghp'] = {
		category = 'Health',
		description = 'Displays the missing health of the unit in whole numbers, when not at full health',
	},
	--Power
	['SUIPower'] = { category = 'Power', description = 'SUIPower', func = SUIHealth },
	['perpp'] = { category = 'Power', description = "Displays the unit's percentage power without decimals " },
	['curpp'] = { category = 'Power', description = "Displays the unit's current power without decimals" },
	['maxpp'] = {
		category = 'Power',
		description = 'Displays the max amount of power of the unit in whole numbers without decimals',
	},
	['missingpp'] = {
		category = 'Power',
		description = 'Displays the missing power of the unit in whole numbers when not at full power',
	},
	--Mana
	['curmana'] = { category = 'Mana', description = 'Displays the current mana without decimals' },
	['maxmana'] = { category = 'Mana', description = 'Displays the max amount of mana the unit can have' },
	--Status
	['status'] = { category = 'Status', description = 'Displays zzz, dead, ghost, offline' },
	['afkdnd'] = { category = 'Status', description = 'Displays AFK or DND if the unit is afk or in Do not Disturb' },
	['dead'] = { category = 'Status', description = 'Displays <DEAD> if the unit is dead' },
	['offline'] = { category = 'Status', description = "Displays 'OFFLINE' if the unit is disconnected" },
	['resting'] = { category = 'Status', description = "Displays 'zzz' if the unit is resting" },
	--Classification
	['classification'] = {
		category = 'Classification',
		description = "Displays the unit's classification (e.g. 'ELITE' and 'RARE')",
	},
	['plus'] = {
		category = 'Classification',
		description = "Displays the character '+' if the unit is an elite or rare-elite",
	},
	['rare'] = { category = 'Classification', description = "Displays 'Rare' when the unit is a rare or rareelite" },
	['shortclassification'] = {
		category = 'Classification',
		description = "Displays the unit's classification in short form (e.g. '+' for ELITE and 'R' for RARE)",
	},
	--Classpower
	['cpoints'] = {
		category = 'Classpower',
		description = 'Displays amount of combo points the player has (only for player, shows nothing on 0)',
	},
	['arcanecharges'] = { category = 'Classpower', description = 'Displays the arcane charges (Mage)' },
	['chi'] = { category = 'Classpower', description = 'Displays the chi points (Monk)' },
	['holypower'] = { category = 'Classpower', description = 'Displays the holy power (Paladin)' },
	['runes'] = { category = 'Classpower', description = 'Displays the runes (Death Knight)' },
	['soulshards'] = { category = 'Classpower', description = 'Displays the soulshards (Warlock)' },
	--Colors
	['difficulty'] = {
		category = 'Colors',
		description = 'Changes color of the next tag based on how difficult the unit is compared to the players level',
	},
	['powercolor'] = { category = 'Colors', description = 'Colors the power text based upon its type' },
	['SUI_ColorClass'] = { category = 'Colors', description = 'Changes the text color based on the class' },
	--PvP
	['faction'] = { category = 'PvP', description = "Displays 'Alliance' or 'Horde'" },
	['pvp'] = { category = 'PvP', description = "Displays 'PvP' if the unit is pvp flagged" },
	['arenaspec'] = { category = 'PvP', description = 'Displays the area spec of an unit' },
	--Party and Raid
	['group'] = { category = 'Party and Raid', description = "Displays the group number the unit is in ('1' - '8')" },
	['leader'] = { category = 'Party and Raid', description = "Displays 'L' if the unit is the group/raid leader" },
	['leaderlong'] = { category = 'Party and Raid', description = "Displays 'Leader' if the unit is the group/raid leader" },
	--Level
	['level'] = { category = 'Level', description = 'Displays the level of the unit' },
	['smartlevel'] = { category = 'Level', description = "Only display the unit's level if it is not the same as yours" },
	--Names
	['name'] = { category = 'Names', description = 'Displays the full name of the unit without any letter limitation' },
	['affix'] = { category = 'Miscellaneous', description = 'Displays low level critter mobs' },
	['specialization'] = {
		category = 'Miscellaneous',
		description = 'Displays your current specialization as text',
	},
	['threat'] = {
		category = 'Threat',
		description = 'Displays the current threat situation (Aggro is secure tanking, -- is losing threat and ++ is gaining threat)',
	},
	['title'] = { category = 'Names', description = 'Displays player title' },
	['threatcolor'] = {
		category = 'Colors',
		description = "Changes the text color, depending on the unit's threat situation",
	},
}
local Options = {}
----------------------------------------------------------------------------------------------------

---Creates the base options screen for a frame name
---@param frameName UnitFrameName
---@return AceConfigOptionsTable
function Options:CreateFrameOptionSet(frameName, get, set)
	local OptionSet = {
		name = frameName,
		type = 'group',
		childGroups = 'tab',
		disabled = function()
			return (UF.CurrentSettings[frameName] and not UF.CurrentSettings[frameName].enabled) or false
		end,
		get = get,
		set = set,
		args = {
			ShowFrame = {
				name = 'Show Frame',
				type = 'execute',
				order = 1,
				width = 'full',
				disabled = (frameName == 'raid' or frameName == 'boss' or frameName == 'arena'),
				func = function()
					UF.Unit:ToggleForceShow(frameName)
				end,
			},
			General = {
				name = L['General'],
				desc = L['General display settings'],
				type = 'group',
				order = 10,
				args = {},
			},
			StatusBar = {
				name = L['Bars'],
				type = 'group',
				order = 20,
				childGroups = 'tree',
				args = {},
			},
			Indicator = {
				name = L['Indicators'],
				type = 'group',
				order = 30,
				childGroups = 'tree',
				args = {},
			},
			-- Text = {
			-- 	name = L['Text'],
			-- 	type = 'group',
			-- 	order = 40,
			-- 	childGroups = 'tree',
			-- 	args = {
			-- 		execute = {
			-- 			name = L['Text tag list'],
			-- 			type = 'execute',
			-- 			func = function(info)
			-- 				SUI.Lib.AceCD:SelectGroup('SpartanUI', 'Help', 'UnitFrames')
			-- 			end
			-- 		}
			-- 	}
			-- },
			Auras = {
				name = L['Buffs & Debuffs'],
				desc = L['Buff & Debuff display settings'],
				type = 'group',
				childGroups = 'tree',
				order = 50,
				args = {},
			},
		},
	} ---@type AceConfigOptionsTable

	return OptionSet
end

---@param OptionSet AceConfigOptionsTable
function Options:AddGeneral(OptionSet)
	OptionSet.args.General.args = {
		General = {
			name = '',
			type = 'group',
			order = 1,
			inline = true,
			args = {
				width = {
					name = L['Frame width'],
					type = 'range',
					width = 'full',
					order = 2,
					min = 1,
					max = 300,
					step = 0.1,
				},
			},
		},
	}
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
function Options:AddAuraLayout(frameName, OptionSet)
	OptionSet.args.Layout = {
		name = L['Layout Configuration'],
		type = 'group',
		order = 100,
		inline = true,
		args = {
			number = {
				name = L['Number to show'],
				type = 'range',
				order = 20,
				min = 1,
				max = 30,
				step = 1,
			},
			showType = {
				name = L['Show type'],
				type = 'toggle',
				order = 30,
			},
			selfScale = {
				order = 2,
				type = 'range',
				name = L['Scaled aura size'],
				desc = L['Scale for auras that you casted or can Spellsteal, any number above 100% is bigger than default, any number below 100% is smaller than default.'],
				min = 0,
				max = 3,
				step = 0.10,
				isPercent = true,
			},
			spacing = {
				name = L['Spacing'],
				type = 'range',
				order = 41,
				min = 1,
				max = 30,
				step = 1,
			},
			rows = {
				name = L['Rows'],
				type = 'range',
				order = 50,
				min = 1,
				max = 30,
				step = 1,
			},
			growthx = {
				name = L['Growth x'],
				type = 'select',
				order = 71,
				values = {
					['RIGHT'] = 'RIGHT',
					['LEFT'] = 'LEFT',
				},
			},
			growthy = {
				name = L['Growth y'],
				type = 'select',
				order = 72,
				values = {
					['UP'] = 'UP',
					['DOWN'] = 'DOWN',
				},
			},
		},
	}
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
---@param create function
function Options:AddAuraWhitelistBlacklist(frameName, OptionSet, create)
	OptionSet.args.whitelist = {
		name = L['Whitelist'],
		desc = L['Whitelisted auras will always be shown'],
		type = 'group',
		order = 4,
		args = {
			desc = {
				name = L['Whitelisted auras will always be shown'],
				type = 'description',
				order = 1,
			},
			create = {
				name = L['Add spell name or ID'],
				type = 'input',
				order = 2,
				width = 'full',
				set = create,
			},
			spells = {
				order = 3,
				type = 'group',
				inline = true,
				name = L['Auras list'],
				args = {},
			},
		},
	}
	OptionSet.args.blacklist = {
		name = L['Blacklist'],
		desc = L['Blacklisted auras will never be shown'],
		type = 'group',
		order = 5,
		args = {
			desc = {
				name = L['Blacklisted auras will never be shown'],
				type = 'description',
				order = 1,
			},
			create = {
				name = L['Add spell name or ID'],
				type = 'input',
				order = 2,
				width = 'full',
				set = create,
			},
			spells = {
				order = 3,
				type = 'group',
				inline = true,
				name = L['Auras list'],
				args = {},
			},
		},
	}
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
---@param set function
---@param get function
function Options:AddAuraFilters(frameName, OptionSet, set, get)
	OptionSet.args.Filters = {
		name = L['Basic filters'],
		type = 'group',
		order = 1,
		get = get,
		set = set,
		args = {
			duration = {
				name = L['Duration'],
				type = 'group',
				order = 1,
				inline = true,
				args = {
					enabled = {
						name = L['Duration rules enabled'],
						type = 'toggle',
						order = 1,
					},
					mode = {
						name = L['Duration mode'],
						type = 'select',
						order = 2,
						values = {
							['exclude'] = 'Exclusionary',
							['include'] = 'Inclusionary',
						},
					},
					minTime = {
						name = L['Minimum Duration'],
						desc = L["Don't display auras that are shorter than this duration (in seconds). Set to zero to disable."],
						type = 'range',
						order = 2,
						min = 0,
						max = 600,
						step = 1,
					},
					maxTime = {
						name = L['Maximum Duration'],
						desc = L["Don't display auras that are longer than this duration (in seconds). Set to zero to disable."],
						type = 'range',
						order = 3,
						min = 0,
						max = 3600,
						step = 1,
					},
				},
			},
			rules = {
				name = L['Basic states'],
				type = 'multiselect',
				order = 3,
				values = {
					IsDispellableByMe = L['Dispellable by me'],
					isBossAura = L['Casted by boss'],
					isHarmful = L['Harmful'],
					isHelpful = L['Helpful'],
					isMount = L['Mount'],
					showPlayers = L['Player casted'],
					isRaid = L['Raid'],
					isStealable = L['Stealable'],
				},
			},
		},
	}
end

---@param frameName UnitFrameName
---@param ElementOptSet AceConfigOptionsTable
function Options:TextBasicDisplay(frameName, ElementOptSet)
	ElementOptSet.args.Text = {
		name = '',
		type = 'group',
		inline = true,
		order = 10,
		args = {
			text = {
				name = L['Text'],
				type = 'input',
				width = 'full',
				order = 1,
			},
			taglist = {
				name = L['Text tag list'],
				type = 'execute',
				func = function(info)
					SUI.Lib.AceCD:SelectGroup('SpartanUI', 'Help', 'UnitFrames')
				end,
			},
			textSize = {
				name = L['Size'],
				type = 'range',
				width = 'full',
				min = 1,
				max = 30,
				step = 1,
				order = 1.5,
			},
			SetJustifyH = {
				name = L['Horizontal alignment'],
				type = 'select',
				order = 2,
				values = {
					['LEFT'] = 'Left',
					['CENTER'] = 'Center',
					['RIGHT'] = 'Right',
				},
			},
			SetJustifyV = {
				name = L['Vertical alignment'],
				type = 'select',
				order = 3,
				values = {
					['TOP'] = 'Top',
					['MIDDLE'] = 'Middle',
					['BOTTOM'] = 'Bottom',
				},
			},
		},
	}
end

---@param frameName UnitFrameName
---@param ElementOptSet AceConfigOptionsTable
---@param elementName SUI.UF.Elements.list
function Options:StatusBarDefaults(frameName, ElementOptSet, elementName)
	ElementOptSet.args.texture = {
		type = 'select',
		dialogControl = 'LSM30_Statusbar',
		order = 2,
		width = 'double',
		name = 'Bar Texture',
		values = AceGUIWidgetLSMlists.statusbar,
	}
	ElementOptSet.args.height = {
		name = L['Height'],
		type = 'range',
		width = 'double',
		order = 5,
		min = 2,
		max = 100,
		step = 1,
	}
	ElementOptSet.args.Background = {
		name = L['Background'],
		type = 'group',
		inline = true,
		order = 20,
		get = function(info)
			local dbData = UF.CurrentSettings[frameName].elements[elementName].bg[info[#info]]
			if info.type == 'color' then
				return unpack(dbData, 1, 4)
			else
				return dbData
			end
		end,
		set = function(info, val, ...)
			if info.type == 'color' then
				--Update memory
				UF.CurrentSettings[frameName].elements[elementName].bg[info[#info]] = { val, ... }
				--Update the DB
				UF.DB.UserSettings[UF.DB.Style][frameName].elements[elementName].bg[info[#info]] = { val, ... }
			else
				--Update memory
				UF.CurrentSettings[frameName].elements[elementName].bg[info[#info]] = val
				--Update the DB
				UF.DB.UserSettings[UF.DB.Style][frameName].elements[elementName].bg[info[#info]] = val
			end
			--Update the screen
			UF.Unit[frameName]:UpdateAll()
		end,
		args = {
			enabled = {
				name = L['Enable'],
				type = 'toggle',
				order = 1,
			},
			color = {
				name = L['Color'],
				type = 'color',
				order = 2,
				hasAlpha = true,
			},
		},
	}
end

---@param ElementOptSet AceConfigOptionsTable
function Options:IndicatorAddDisplay(ElementOptSet)
	ElementOptSet.args.display = {
		name = L['Display'],
		type = 'group',
		order = 20,
		inline = true,
		args = {
			size = {
				name = L['Size'],
				type = 'range',
				min = 0,
				max = 100,
				step = 0.1,
				order = 1,
			},
			scale = {
				name = L['Scale'],
				type = 'range',
				min = 0.1,
				max = 3,
				step = 0.01,
				order = 2,
			},
			alpha = {
				name = L['Alpha'],
				type = 'range',
				min = 0,
				max = 1,
				step = 0.01,
				order = 3,
			},
		},
	}
end

---@param anchors table
---@param ElementOptSet AceConfigOptionsTable
---@param get function
---@param set function
function Options:AddPositioning(anchors, ElementOptSet, get, set)
	local AnchorablePoints = {
		['Frame'] = 'Unit Frame',
	}
	SUI:CopyData(AnchorablePoints, anchors)

	ElementOptSet.args.position = {
		name = L['Position'],
		type = 'group',
		order = 50,
		inline = true,
		get = get,
		set = set,
		args = {
			x = {
				name = L['X Axis'],
				type = 'range',
				order = 1,
				min = -200,
				max = 200,
				step = 1,
			},
			y = {
				name = L['Y Axis'],
				type = 'range',
				order = 2,
				min = -200,
				max = 200,
				step = 1,
			},
			anchor = {
				name = L['Anchor point'],
				type = 'select',
				order = 3,
				values = anchorPoints,
			},
			relativeTo = {
				name = 'Relative To',
				type = 'select',
				order = 3,
				values = AnchorablePoints,
			},
			relativePoint = {
				name = 'Relative Point',
				type = 'select',
				order = 3,
				values = anchorPoints,
			},
		},
	}
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
---@param element SUI.UF.Elements.list
function Options:AddDynamicText(frameName, OptionSet, element)
	OptionSet.args.Text = {
		name = L['Text'],
		type = 'group',
		order = 1,
		args = {
			execute = {
				name = L['Text tag list'],
				type = 'execute',
				order = 0.1,
				func = function(info)
					SUI.Lib.AceCD:SelectGroup('SpartanUI', 'Help', 'UnitFrames')
				end,
			},
		},
	}

	for count in pairs(UF.CurrentSettings[frameName].elements[element].text) do
		OptionSet.args.Text.args[count] = {
			name = L['Text element'] .. ' ' .. count,
			type = 'group',
			inline = true,
			order = (10 + count),
			get = function(info)
				return UF.CurrentSettings[frameName].elements[element].text[count][info[#info]]
			end,
			args = {
				enabled = {
					name = L['Enabled'],
					type = 'toggle',
					order = 1,
					set = function(info, val)
						--Update memory
						UF.CurrentSettings[frameName].elements[element].text[count].enabled = val
						--Update the DB
						UF.DB.UserSettings[UF.DB.Style][frameName].elements[element].text[count].enabled = val
						--Update the screen
						if val then
							UF.Unit[frameName][element].TextElements[count]:Show()
						else
							UF.Unit[frameName][element].TextElements[count]:Hide()
						end
					end,
				},
				text = {
					name = L['Text'],
					type = 'input',
					width = 'full',
					order = 2,
					set = function(info, val)
						--Update memory
						UF.CurrentSettings[frameName].elements[element].text[count].text = val
						--Update the DB
						UF.DB.UserSettings[UF.DB.Style][frameName].elements[element].text[count].text = val
						--Update the screen
						if UF.Unit[frameName][element] then
							UF.Unit[frameName]:Tag(UF.Unit[frameName][element].TextElements[count], val)
							UF.Unit[frameName]:UpdateTags()
						end
					end,
				},
				size = {
					name = L['Size'],
					type = 'range',
					width = 'full',
					min = 1,
					max = 30,
					step = 1,
					order = 1.5,
					set = function(info, val)
						--Update memory
						UF.CurrentSettings[frameName].elements[element].text[count].size = val
						--Update the DB
						UF.DB.UserSettings[UF.DB.Style][frameName].elements[element].text[count].size = val
						--Update the screen
						SUI.Font:UpdateDefaultSize(UF.Unit[frameName][element].TextElements[count], val, 'UnitFrames')
					end,
				},
				position = {
					name = L['Position'],
					type = 'group',
					order = 50,
					inline = true,
					get = function(info)
						return UF.CurrentSettings[frameName].elements[element].text[count].position[info[#info]]
					end,
					set = function(info, val)
						--Update memory
						UF.CurrentSettings[frameName].elements[element].text[count].position[info[#info]] = val
						--Update the DB
						UF.DB.UserSettings[UF.DB.Style][frameName].elements[element].text[count].position[info[#info]] = val
						--Update the screen
						local position = UF.CurrentSettings[frameName].elements[element].text[count].position
						UF.Unit[frameName][element].TextElements[count]:ClearAllPoints()
						UF.Unit[frameName][element].TextElements[count]:SetPoint(position.anchor, UF.Unit[frameName], position.anchor, position.x, position.y)
					end,
					args = {
						x = {
							name = L['X Axis'],
							type = 'range',
							order = 1,
							min = -200,
							max = 200,
							step = 1,
						},
						y = {
							name = L['Y Axis'],
							type = 'range',
							order = 2,
							min = -200,
							max = 200,
							step = 1,
						},
						anchor = {
							name = L['Anchor point'],
							type = 'select',
							order = 3,
							values = anchorPoints,
						},
					},
				},
			},
		}
	end
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
function Options:AddGroupDisplay(frameName, OptionSet)
	OptionSet.args.General.args.Display = {
		name = L['Display'],
		type = 'group',
		order = 0.1,
		set = function(info, val)
			local setting = info[#info]
			--Update memory
			UF.CurrentSettings[frameName][setting] = val
			--Update the DB
			UF.DB.UserSettings[UF.DB.Style][frameName][setting] = val
			--Update the screen
			UF.Unit:Get(frameName).header:SetAttribute(setting, val)
		end,
		args = {
			showRaid = {
				name = L['Show Raid Frames'],
				type = 'toggle',
				order = 1,
			},
			showParty = {
				name = L['Show while in party'],
				type = 'toggle',
				order = 2,
			},
			showPlayer = {
				name = L['Show player'],
				type = 'toggle',
				order = 2,
			},
			showSolo = {
				name = L['Show solo'],
				type = 'toggle',
				order = 2,
			},
		},
	}
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
function Options:AddGroupLayout(frameName, OptionSet)
	OptionSet.args.General.args.Layout = {
		name = L['Layout Configuration'],
		type = 'group',
		order = 0.2,
		set = function(info, val)
			local setting = info[#info]
			--Update memory
			UF.CurrentSettings[frameName][setting] = val
			--Update the DB
			UF.DB.UserSettings[UF.DB.Style][frameName][setting] = val
			--Update the screen
			UF.Unit:Get(frameName).header:SetAttribute(setting, val)
		end,
		args = {
			maxColumns = {
				name = L['Max Columns'],
				type = 'range',
				order = 1,
				width = 'full',
				step = 1,
				min = 1,
				max = 40,
			},
			unitsPerColumn = {
				name = L['Units Per Column'],
				type = 'range',
				order = 2,
				width = 'full',
				step = 1,
				min = 1,
				max = 40,
			},
			columnSpacing = {
				name = L['Column Spacing'],
				type = 'range',
				order = 3,
				width = 'full',
				step = 1,
				min = -200,
				max = 200,
			},
			bar1 = { name = 'Offsets', type = 'header', order = 20 },
			yOffset = {
				name = L['Vertical offset'],
				type = 'range',
				order = 21,
				width = 'full',
				step = 1,
				min = -200,
				max = 200,
			},
			xOffset = {
				name = L['Horizonal offset'],
				type = 'range',
				order = 22,
				width = 'full',
				step = 1,
				min = -200,
				max = 200,
			},
		},
	}
end

function Options:Initialize()
	---Build Help screen

	---@type AceConfigOptionsTable
	local HelpScreen = {
		name = L['Text tags'],
		type = 'group',
		childGroups = 'tab',
		args = {
			Health = {
				name = L['Health'],
				type = 'group',
				order = 0.1,
				args = {},
			},
			Power = {
				name = L['Power'],
				type = 'group',
				order = 0.2,
				args = {},
			},
			Names = {
				name = 'Names',
				type = 'group',
				order = 0.3,
				args = {},
			},
		},
	}
	for k, v in pairs(TagList) do
		if v.category and not HelpScreen.args[v.category] then HelpScreen.args[v.category] = {
			name = v.category,
			type = 'group',
			args = {},
			set = function(info, val) end,
		} end

		HelpScreen.args[v.category].args[k] = {
			name = v.description or '',
			type = 'input',
			width = 'full',
			get = function(info)
				return '[' .. k .. ']'
			end,
		}
		if v.func then v.func(HelpScreen.args[v.category].args[k]) end
	end
	SUI.opt.args.Help.args.UnitFrames = HelpScreen

	-- Add options to Base Help group
	SUI.opt.args.Help.args.SUIModuleHelp.args.ResetUFSettings = {
		name = L['Reset unitframe customizations'],
		type = 'execute',
		width = 'double',
		order = 90,
		func = function()
			UF:ResetSettings()
		end,
	}

	-- Construct base Options object
	---@type AceConfigOptionsTable
	local UFOptions = {
		name = L['Unit frames'],
		type = 'group',
		order = 2,
		disabled = function()
			return SUI:IsModuleDisabled(SUI.UF)
		end,
		args = {
			ResetUFSettings = {
				name = L['Reset to base style (Revert customizations)'],
				type = 'execute',
				width = 'full',
				order = 1,
				func = function()
					UF:ResetSettings()
				end,
			},
			BaseStyle = {
				name = L['Base frame style'],
				type = 'group',
				inline = true,
				order = 30,
				args = {},
			},
			EnabledFrame = {
				name = L['Enabled frames'],
				type = 'group',
				inline = true,
				order = 90,
				args = {},
			},
		},
	}

	for frameName, _ in pairs(UF.Unit:GetFrameList()) do
		UFOptions.args.EnabledFrame.args[frameName] = {
			name = frameName,
			type = 'toggle',
			get = function(info)
				return UF.CurrentSettings[frameName].enabled
			end,
			set = function(info, val)
				--Update memory
				UF.CurrentSettings[frameName].enabled = val
				--Update the DB
				UF.DB.UserSettings[UF.DB.Style][frameName].enabled = val
				--Update the UI
				local frame = UF.Unit:Get(frameName)
				if frame then
					if val then
						frame:Enable()
					else
						frame:Disable()
					end
				end
			end,
		}
	end

	-- Build style Buttons
	for styleName, styleInfo in pairs(UF.Style:GetList()) do
		local data = styleInfo.settings ---@type SUI.UF.Style.Settings

		UFOptions.args.BaseStyle.args[styleName] = {
			name = data.displayName or styleName,
			type = 'execute',
			image = function()
				return data.setup.image or ('interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_' .. styleName), 120, 60
			end,
			imageCoords = function()
				return data.setup.imageCoords or { 0, 0.5, 0, 0.5 }
			end,
			func = function()
				UF:SetActiveStyle(styleName)
			end,
		}
	end

	-- -- Add built skins selection page to the styles section
	SUI.opt.args.General.args.style.args.Unitframes = UFOptions.args.BaseStyle

	-- Build frame options
	for frameName, _ in pairs(UF.Unit:GetBuiltFrameList()) do
		local FrameOptSet = Options:CreateFrameOptionSet(frameName, function(info)
			return UF.CurrentSettings[frameName][info[#info]] or false
		end, function(info, val)
			--Update memory
			UF.CurrentSettings[frameName][info[#info]] = val
			--Update the DB
			UF.DB.UserSettings[UF.DB.Style][frameName][info[#info]] = val
			--Update the screen
			UF.Unit[frameName]:UpdateAll()
		end)
		Options:AddGeneral(FrameOptSet)

		-- Add Element Options
		local builtFrame = UF.Unit:Get(frameName)

		for elementName, _ in pairs(builtFrame.elementList) do
			local elementConfig = builtFrame.config.elements[elementName].config

			local ElementSettings = UF.CurrentSettings[frameName].elements[elementName]
			local UserSetting = UF.DB.UserSettings[UF.DB.Style][frameName].elements[elementName]

			---@type AceConfigOptionsTable
			local ElementOptSet = {
				name = elementConfig.DisplayName and L[elementConfig.DisplayName] or elementName,
				desc = elementConfig.Description or '',
				type = 'group',
				order = 1,
				get = function(info)
					return ElementSettings[info[#info]] or false
				end,
				set = function(info, val)
					--Update memory
					ElementSettings[info[#info]] = val
					--Update the DB
					UserSetting[info[#info]] = val
					--Update the screen
					builtFrame:UpdateAll()
				end,
				args = {},
			}

			local PositionGet = function(info)
				return ElementSettings.position[info[#info]]
			end
			local PositionSet = function(info, val)
				if val == elementName then
					SUI:Print(L['Cannot set position to self'])
					return
				end
				--Update memory
				ElementSettings.position[info[#info]] = val
				--Update the DB
				UserSetting.position[info[#info]] = val
				--Update Screen
				UF.Unit[frameName]:ElementUpdate(elementName)
			end

			if elementConfig.type == 'General' then
			elseif elementConfig.type == 'StatusBar' then
				Options:StatusBarDefaults(frameName, ElementOptSet, elementName)
			elseif elementConfig.type == 'Indicator' then
				Options:IndicatorAddDisplay(ElementOptSet)
				Options:AddPositioning(builtFrame.elementList, ElementOptSet, PositionGet, PositionSet)
			elseif elementConfig.type == 'Text' then
				-- Options:IndicatorAddDisplay(ElementOptSet)
				Options:AddPositioning(builtFrame.elementList, ElementOptSet, PositionGet, PositionSet)
			elseif elementConfig.type == 'Auras' then
				Options:IndicatorAddDisplay(ElementOptSet)
				Options:AddPositioning(builtFrame.elementList, ElementOptSet, PositionGet, PositionSet)
				Options:AddAuraLayout(frameName, ElementOptSet)

				-- Basic Filtering Options
				local FilterGet = function(info, key)
					if info[#info - 1] == 'duration' then
						return ElementSettings.rules.duration[info[#info]] or false
					else
						return ElementSettings.rules[key] or false
					end
				end
				local FilterSet = function(info, key, val)
					if info[#info - 1] == 'duration' then
						if (info[#info] == 'minTime') and key > ElementSettings.rules.duration.maxTime then
							return
						elseif (info[#info] == 'maxTime') and key < ElementSettings.rules.duration.minTime then
							return
						end

						--Update memory
						ElementSettings.rules.duration[info[#info]] = key
						--Update the DB
						UserSetting.rules.duration[info[#info]] = key
					else
						--Update memory
						ElementSettings.rules[key] = (val or false)
						--Update the DB
						UserSetting.rules[key] = (val or nil)
					end
					--Update Screen
					UF.Unit[frameName]:ElementUpdate(elementName)
				end
				Options:AddAuraFilters(frameName, ElementOptSet, FilterSet, FilterGet)

				-- Whitelist and Blacklist Options
				local buildItemList

				local spellLabel = {
					type = 'description',
					width = 'double',
					fontSize = 'medium',
					order = function(info)
						return tonumber(string.match(info[#info], '(%d+)'))
					end,
					name = function(info)
						local id = tonumber(string.match(info[#info], '(%d+)'))
						local name = 'unknown'
						if id then
							-- local spellLink = GetSpellLink(id)
							local spellName, _, spellIcon = GetSpellInfo(id)
							name = string.format('|T%s:14:14:0:0|t %s (#%i)', spellIcon or 'Interface\\Icons\\Inv_misc_questionmark', spellName or L['Unknown'], id)
						end
						return name
					end,
				}

				local spellDelete = {
					type = 'execute',
					name = L['Delete'],
					width = 'half',
					order = function(info)
						return tonumber(string.match(info[#info], '(%d+)')) + 0.5
					end,
					func = function(info)
						local id = tonumber(info[#info])

						--Remove Setting
						ElementSettings.rules[info[#info - 2]][id] = nil
						UserSetting.rules[info[#info - 2]][id] = nil

						--Update Screen
						buildItemList(info[#info - 2])
						UF.Unit[frameName]:ElementUpdate(elementName)
					end,
				}

				buildItemList = function(mode)
					local spellsOpt = ElementOptSet.args[mode].args.spells.args
					table.wipe(spellsOpt)

					for spellID, _ in pairs(ElementSettings.rules[mode]) do
						spellsOpt[spellID .. 'label'] = spellLabel
						spellsOpt[tostring(spellID)] = spellDelete
					end
				end
				local additem = function(info, input)
					local spellId
					if type(input) == 'string' then
						--See if we got a spell link
						if input:find('|Hspell:%d+') then
							spellId = tonumber(input:match('|Hspell:(%d+)'))
						elseif input:find('%[(.-)%]') then
							spellId = select(7, GetSpellInfo(input:match('%[(.-)%]')))
						else
							spellId = select(7, GetSpellInfo(input))
						end
						if not spellId then
							SUI:Print('Invalid spell name or ID')
							return
						end
					end

					ElementSettings.rules[info[#info - 1]][spellId] = true
					UserSetting.rules[info[#info - 1]][spellId] = true

					UF.Unit[frameName]:ElementUpdate(elementName)
					buildItemList(info[#info - 1])
				end

				Options:AddAuraWhitelistBlacklist(frameName, ElementOptSet, additem)
				buildItemList('whitelist')
				buildItemList('blacklist')
			end

			--Call Elements Custom function
			UF.Elements:Options(frameName, elementName, ElementOptSet)

			if not ElementOptSet.args.enabled then
				--Add a disable check to all args
				for k, v in pairs(ElementOptSet.args) do
					v.disabled = function()
						return not ElementSettings.enabled
					end
				end

				ElementOptSet.args.enabled = {
					name = L['Enabled'],
					type = 'toggle',
					order = 1,
				}
			end
			-- Add element option to screen
			FrameOptSet.args[elementConfig.type].args[elementName] = ElementOptSet
		end

		UF.Unit:BuildOptions(frameName, FrameOptSet)

		UFOptions.args[frameName] = FrameOptSet
	end

	SUI.opt.args.UnitFrames = UFOptions
end

Options.CONST = { anchorPoints = anchorPoints }

UF.Options = Options
