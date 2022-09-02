local _G, SUI, L = _G, SUI, SUI.L
local UF = SUI.UF ---@class SUI_UnitFrames
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
	['BOTTOMRIGHT'] = 'BOTTOM RIGHT'
}

local TagList = {
	--Health
	['curhp'] = {category = 'Health', description = 'Displays the current HP without decimals'},
	['deficit:name'] = {category = 'Health', description = 'Displays the health as a deficit and the name at full health'},
	['perhp'] = {
		category = 'Health',
		description = 'Displays percentage HP without decimals or the % sign. You can display the percent sign by adjusting the tag to [perhp<$%].'
	},
	['maxhp'] = {category = 'Health', description = 'Displays max HP without decimals'},
	['missinghp'] = {
		category = 'Health',
		description = 'Displays the missing health of the unit in whole numbers, when not at full health'
	},
	['health:current-short'] = {
		category = 'Health',
		description = 'Displays current HP rounded to the nearest Thousand or Million'
	},
	['health:current-dynamic'] = {
		category = 'Health',
		description = 'Displays current HP Rounded to the nearest Million or with commas below 1 million'
	},
	['health:current-formatted'] = {category = 'Health', description = 'Displays current HP with commas'},
	['health:missing-formatted'] = {category = 'Health', description = 'Displays missing HP with commas'},
	['health:max-formatted'] = {category = 'Health', description = 'Displays max HP with commas'},
	--Power
	['perpp'] = {category = 'Power', description = "Displays the unit's percentage power without decimals "},
	['curpp'] = {category = 'Power', description = "Displays the unit's current power without decimals"},
	['maxpp'] = {
		category = 'Power',
		description = 'Displays the max amount of power of the unit in whole numbers without decimals'
	},
	['missingpp'] = {
		category = 'Power',
		description = 'Displays the missing power of the unit in whole numbers when not at full power'
	},
	['power:current-formatted'] = {category = 'Power', description = 'Displays current power with commas'},
	['power:missing-formatted'] = {category = 'Power', description = 'Displays missing power with commas'},
	['power:max-formatted'] = {category = 'Power', description = 'Displays max power with commas'},
	--Mana
	['curmana'] = {category = 'Mana', description = 'Displays the current mana without decimals'},
	['maxmana'] = {category = 'Mana', description = 'Displays the max amount of mana the unit can have'},
	--Status
	['status'] = {category = 'Status', description = 'Displays zzz, dead, ghost, offline'},
	['afkdnd'] = {category = 'Status', description = 'Displays AFK or DND if the unit is afk or in Do not Disturb'},
	['dead'] = {category = 'Status', description = 'Displays <DEAD> if the unit is dead'},
	['offline'] = {category = 'Status', description = "Displays 'OFFLINE' if the unit is disconnected"},
	['resting'] = {category = 'Status', description = "Displays 'zzz' if the unit is resting"},
	--Classification
	['classification'] = {
		category = 'Classification',
		description = "Displays the unit's classification (e.g. 'ELITE' and 'RARE')"
	},
	['plus'] = {
		category = 'Classification',
		description = "Displays the character '+' if the unit is an elite or rare-elite"
	},
	['rare'] = {category = 'Classification', description = "Displays 'Rare' when the unit is a rare or rareelite"},
	['shortclassification'] = {
		category = 'Classification',
		description = "Displays the unit's classification in short form (e.g. '+' for ELITE and 'R' for RARE)"
	},
	--Classpower
	['cpoints'] = {
		category = 'Classpower',
		description = 'Displays amount of combo points the player has (only for player, shows nothing on 0)'
	},
	--Colors
	['difficulty'] = {
		category = 'Colors',
		description = 'Changes color of the next tag based on how difficult the unit is compared to the players level'
	},
	['powercolor'] = {category = 'Colors', description = 'Colors the power text based upon its type'},
	['SUI_ColorClass'] = {category = 'Colors', description = 'Changes the text color based on the class'},
	--PvP
	['faction'] = {category = 'PvP', description = "Displays 'Alliance' or 'Horde'"},
	['pvp'] = {category = 'PvP', description = "Displays 'PvP' if the unit is pvp flagged"},
	--Party and Raid
	['group'] = {category = 'Party and Raid', description = "Displays the group number the unit is in ('1' - '8')"},
	['leader'] = {category = 'Party and Raid', description = "Displays 'L' if the unit is the group/raid leader"},
	['leaderlong'] = {category = 'Party and Raid', description = "Displays 'Leader' if the unit is the group/raid leader"},
	--Level
	['level'] = {category = 'Level', description = 'Displays the level of the unit'},
	['smartlevel'] = {category = 'Level', description = "Only display the unit's level if it is not the same as yours"},
	--Names
	['name'] = {category = 'Names', description = 'Displays the full name of the unit without any letter limitation'}
}
if SUI.IsRetail then
	TagList['affix'] = {category = 'Miscellaneous', description = 'Displays low level critter mobs'}
	TagList['specialization'] = {
		category = 'Miscellaneous',
		description = 'Displays your current specialization as text'
	}
	TagList['arcanecharges'] = {category = 'Classpower', description = 'Displays the arcane charges (Mage)'}
	TagList['arenaspec'] = {category = 'PvP', description = 'Displays the area spec of an unit'}
	TagList['chi'] = {category = 'Classpower', description = 'Displays the chi points (Monk)'}
	TagList['faction'] = {category = 'PvP', description = "Displays 'Alliance' or 'Horde'"}
	TagList['holypower'] = {category = 'Classpower', description = 'Displays the holy power (Paladin)'}
	TagList['runes'] = {category = 'Classpower', description = 'Displays the runes (Death Knight)'}
	TagList['soulshards'] = {category = 'Classpower', description = 'Displays the soulshards (Warlock)'}
	TagList['threat'] = {
		category = 'Threat',
		description = 'Displays the current threat situation (Aggro is secure tanking, -- is losing threat and ++ is gaining threat)'
	}
	TagList['title'] = {category = 'Names', description = 'Displays player title'}
	TagList['threatcolor'] = {
		category = 'Colors',
		description = "Changes the text color, depending on the unit's threat situation"
	}
end
local Options = {}
----------------------------------------------------------------------------------------------------

---Creates the base options screen for a frame name
---@param frameName UnitFrameName
---@return AceConfigOptionsTable
local function CreateOptionSet(frameName)
	local OptionSet = {
		name = frameName,
		type = 'group',
		childGroups = 'tab',
		disabled = function()
			return not UF.CurrentSettings[frameName].enabled
		end,
		get = function(info)
			return UF.CurrentSettings[frameName][info[#info]] or false
		end,
		set = function(info, val)
			--Update memory
			UF.CurrentSettings[frameName][info[#info]] = val
			--Update the DB
			UF.DB.UserSettings[UF.DB.Style][frameName][info[#info]] = val
			--Update the screen
			UF.Unit[frameName]:UpdateAll()
		end,
		args = {
			ShowFrame = {
				name = 'Show Frame',
				type = 'execute',
				order = 1,
				width = 'full',
				-- disabled = (frameName == 'raid' or frameName == 'party' or frameName == 'boss' or frameName == 'arena'),
				func = function()
					UF.Unit:ToggleForceShow(frameName)
				end
			},
			General = {
				name = L['General'],
				desc = L['General display settings'],
				type = 'group',
				order = 10,
				args = {}
			},
			StatusBar = {
				name = L['Bars'],
				type = 'group',
				order = 20,
				childGroups = 'tree',
				args = {}
			},
			Indicator = {
				name = L['Indicators'],
				type = 'group',
				order = 30,
				childGroups = 'tree',
				args = {}
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
				args = {}
			}
		}
	} ---@type AceConfigOptionsTable

	return OptionSet
end

---@param OptionSet AceConfigOptionsTable
local function AddGeneral(OptionSet)
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
					step = .1
				}
			}
		}
	}
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
local function AddAuras(frameName, OptionSet)
	local anchorPoints = {
		['TOPLEFT'] = 'TOP LEFT',
		['TOP'] = 'TOP',
		['TOPRIGHT'] = 'TOP RIGHT',
		['RIGHT'] = 'RIGHT',
		['CENTER'] = 'CENTER',
		['LEFT'] = 'LEFT',
		['BOTTOMLEFT'] = 'BOTTOM LEFT',
		['BOTTOM'] = 'BOTTOM',
		['BOTTOMRIGHT'] = 'BOTTOM RIGHT'
	}
	local limitedAnchorPoints = {
		['TOPLEFT'] = 'TOP LEFT',
		['TOPRIGHT'] = 'TOP RIGHT',
		['BOTTOMLEFT'] = 'BOTTOM LEFT',
		['BOTTOMRIGHT'] = 'BOTTOM RIGHT'
	}
	local CurrentSettings = UF.CurrentSettings[frameName].elements.Auras

	local function SetOption(val, buffType, setting)
		--Update memory
		CurrentSettings[buffType][setting] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][frameName].elements.Auras[buffType][setting] = val
		--Update the screen
		UF.Unit[frameName]:UpdateAuras()
	end

	for _, buffType in pairs({'Buffs', 'Debuffs'}) do
		OptionSet.args.auras.args[buffType] = {
			name = L[buffType],
			type = 'group',
			-- inline = true,
			order = 1,
			args = {
				enabled = {
					name = L['Enabled'],
					type = 'toggle',
					order = 1,
					get = function(info)
						return CurrentSettings[buffType].enabled
					end,
					set = function(info, val)
						SetOption(val, buffType, 'enabled')
					end
				},
				Display = {
					name = L['Display settings'],
					type = 'group',
					order = 100,
					inline = true,
					get = function(info)
						return CurrentSettings[buffType][info[#info]]
					end,
					set = function(info, val)
						SetOption(val, buffType, info[#info])
					end,
					args = {
						number = {
							name = L['Number to show'],
							type = 'range',
							order = 20,
							min = 1,
							max = 30,
							step = 1
						},
						showType = {
							name = L['Show type'],
							type = 'toggle',
							order = 30
						},
						selfScale = {
							order = 2,
							type = 'range',
							name = L['Scaled aura size'],
							desc = L[
								'Scale for auras that you casted or can Spellsteal, any number above 100% is bigger than default, any number below 100% is smaller than default.'
							],
							min = 1,
							max = 3,
							step = 0.10,
							isPercent = true
						}
					}
				},
				Sizing = {
					name = L['Sizing & layout'],
					type = 'group',
					order = 200,
					inline = true,
					args = {
						size = {
							name = L['Size'],
							type = 'range',
							order = 40,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].size
							end,
							set = function(info, val)
								SetOption(val, buffType, 'size')
							end
						},
						spacing = {
							name = L['Spacing'],
							type = 'range',
							order = 41,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].spacing
							end,
							set = function(info, val)
								SetOption(val, buffType, 'spacing')
							end
						},
						rows = {
							name = L['Rows'],
							type = 'range',
							order = 50,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].rows
							end,
							set = function(info, val)
								SetOption(val, buffType, 'rows')
							end
						},
						initialAnchor = {
							name = L['Buff anchor point'],
							type = 'select',
							order = 70,
							values = limitedAnchorPoints,
							get = function(info)
								return CurrentSettings[buffType].initialAnchor
							end,
							set = function(info, val)
								SetOption(val, buffType, 'initialAnchor')
							end
						},
						growthx = {
							name = L['Growth x'],
							type = 'select',
							order = 71,
							values = {
								['RIGHT'] = 'RIGHT',
								['LEFT'] = 'LEFT'
							},
							get = function(info)
								return CurrentSettings[buffType].growthx
							end,
							set = function(info, val)
								SetOption(val, buffType, 'growthx')
							end
						},
						growthy = {
							name = L['Growth y'],
							type = 'select',
							order = 72,
							values = {
								['UP'] = 'UP',
								['DOWN'] = 'DOWN'
							},
							get = function(info)
								return CurrentSettings[buffType].growthy
							end,
							set = function(info, val)
								SetOption(val, buffType, 'growthy')
							end
						}
					}
				},
				position = {
					name = L['Position'],
					type = 'group',
					order = 400,
					inline = true,
					args = {
						x = {
							name = L['X Axis'],
							type = 'range',
							order = 1,
							min = -100,
							max = 100,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].position.x
							end,
							set = function(info, val)
								--Update memory
								CurrentSettings[buffType].position.x = val
								--Update the DB
								UF.DB.UserSettings[UF.DB.Style][frameName].elements.Auras[buffType].position.x = val
								--Update Screen
								UF.Unit[frameName]:UpdateAuras()
							end
						},
						y = {
							name = L['Y Axis'],
							type = 'range',
							order = 2,
							min = -100,
							max = 100,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].position.y
							end,
							set = function(info, val)
								--Update memory
								CurrentSettings[buffType].position.y = val
								--Update the DB
								UF.DB.UserSettings[UF.DB.Style][frameName].elements.Auras[buffType].position.y = val
								--Update Screen
								UF.Unit[frameName]:UpdateAuras()
							end
						},
						anchor = {
							name = L['Anchor point'],
							type = 'select',
							order = 3,
							values = anchorPoints,
							get = function(info)
								return CurrentSettings[buffType].position.anchor
							end,
							set = function(info, val)
								--Update memory
								CurrentSettings[buffType].position.anchor = val
								--Update the DB
								UF.DB.UserSettings[UF.DB.Style][frameName].elements.Auras[buffType].position.anchor = val
								--Update Screen
								UF.Unit[frameName]:UpdateAuras()
							end
						}
					}
				},
				filters = {
					name = L['Filters'],
					type = 'group',
					order = 500,
					get = function(info)
						return CurrentSettings[buffType].filters[info[#info]]
					end,
					set = function(info, value)
						--Update memory
						CurrentSettings[buffType].filters[info[#info]] = value
						--Update the DB
						UF.DB.UserSettings[UF.DB.Style][frameName].elements.Auras[buffType].filters[info[#info]] = value
						--Update Screen
						UF.Unit[frameName]:UpdateAuras()
					end,
					args = {
						minDuration = {
							order = 1,
							type = 'range',
							name = L['Minimum Duration'],
							desc = L["Don't display auras that are shorter than this duration (in seconds). Set to zero to disable."],
							min = 0,
							max = 7200,
							step = 1,
							width = 'full'
						},
						maxDuration = {
							order = 2,
							type = 'range',
							name = L['Maximum Duration'],
							desc = L["Don't display auras that are longer than this duration (in seconds). Set to zero to disable."],
							min = 0,
							max = 7200,
							step = 1,
							width = 'full'
						},
						showPlayers = {
							order = 3,
							type = 'toggle',
							name = L['Show your auras'],
							desc = L['Whether auras you casted should be shown'],
							width = 'full'
						},
						raid = {
							order = 4,
							type = 'toggle',
							name = function(info)
								return buffType == 'buffs' and L['Show castable on other auras'] or L['Show curable/removable auras']
							end,
							desc = function(info)
								return buffType == 'buffs' and L['Whether to show buffs that you cannot cast.'] or
									L['Whether to show any debuffs you can remove, cure or steal.']
							end,
							width = 'full'
						},
						boss = {
							order = 5,
							type = 'toggle',
							name = L['Show casted by boss'],
							desc = L['Whether to show any auras casted by the boss'],
							width = 'full'
						},
						misc = {
							order = 6,
							type = 'toggle',
							name = L['Show any other auras'],
							desc = L['Whether to show auras that do not fall into the above categories.'],
							width = 'full'
						},
						relevant = {
							order = 7,
							type = 'toggle',
							name = L['Smart Friendly/Hostile Filter'],
							desc = L[
								'Only apply the selected filters to buffs on friendly units and debuffs on hostile units, and otherwise show all auras.'
							],
							width = 'full'
						}
					}
				}
			}
		}
	end
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
local function AddBarOptions(frameName, OptionSet)
	if frameName == 'player' then
		SUI.opt.args.UnitFrames.args.player.args.bars.args.AdditionalPower = {
			name = L['Additional power'],
			desc = "player's additional power, such as Mana for Balance druids.",
			order = 20,
			type = 'group',
			childGroups = 'inline',
			args = {}
		}
	end

	local bars = {'Castbar', 'Health', 'Power', 'AdditionalPower'}
	for _, key in ipairs(bars) do
		local BarOpt = SUI.opt.args.UnitFrames.args[frameName].args.bars.args[key]
		if BarOpt then
			BarOpt.args.enabled = {
				name = L['Enabled'],
				type = 'toggle',
				width = 'full',
				order = 1,
				get = function(info)
					return UF.CurrentSettings[frameName].elements[key].enabled
				end,
				set = function(info, val)
					--Update memory
					UF.CurrentSettings[frameName].elements[key].enabled = val
					--Update the DB
					UF.DB.UserSettings[UF.DB.Style][frameName].elements[key].enabled = val
					--Update the screen
					UF.Unit[frameName]:UpdateAll()
				end
			}
			BarOpt.args.texture = {
				type = 'select',
				dialogControl = 'LSM30_Statusbar',
				order = 2,
				width = 'double',
				name = 'Bar Texture',
				values = AceGUIWidgetLSMlists.statusbar
			}

		-- UF.Elements:Options(frameName, key, BarOpt)
		end
	end

	local friendly = {'player', 'party', 'raid', 'target', 'focus', 'targettarget', 'focustarget'}
	if not SUI:IsInTable(friendly, frameName) then
		SUI.opt.args.UnitFrames.args[frameName].args.bars.args['Health'].args['DispelHighlight'].hidden = true
	end

	if frameName == 'player' or frameName == 'party' or frameName == 'raid' then
		SUI.opt.args.UnitFrames.args[frameName].args.bars.args['Castbar'].args['interruptable'].hidden = true
	end
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
				order = 1
			},
			taglist = {
				name = L['Text tag list'],
				type = 'execute',
				func = function(info)
					SUI.Lib.AceCD:SelectGroup('SpartanUI', 'Help', 'UnitFrames')
				end
			},
			textSize = {
				name = L['Size'],
				type = 'range',
				width = 'full',
				min = 1,
				max = 30,
				step = 1,
				order = 1.5
			},
			SetJustifyH = {
				name = L['Horizontal alignment'],
				type = 'select',
				order = 2,
				values = {
					['LEFT'] = 'Left',
					['CENTER'] = 'Center',
					['RIGHT'] = 'Right'
				}
			},
			SetJustifyV = {
				name = L['Vertical alignment'],
				type = 'select',
				order = 3,
				values = {
					['TOP'] = 'Top',
					['MIDDLE'] = 'Middle',
					['BOTTOM'] = 'Bottom'
				}
			}
		}
	}
end

---@param frameName UnitFrameName
---@param ElementOptSet AceConfigOptionsTable
---@param elementName UnitFrameElement
function Options:StatusBarDefaults(frameName, ElementOptSet, elementName)
	ElementOptSet.args.texture = {
		type = 'select',
		dialogControl = 'LSM30_Statusbar',
		order = 2,
		width = 'double',
		name = 'Bar Texture',
		values = AceGUIWidgetLSMlists.statusbar
	}
	ElementOptSet.args.height = {
		name = L['Height'],
		type = 'range',
		width = 'double',
		order = 5,
		min = 2,
		max = 100,
		step = 1
	}
	ElementOptSet.args.Background = {
		name = L['Background'],
		type = 'group',
		inline = true,
		order = 20,
		get = function(info)
			return UF.CurrentSettings[frameName].elements[elementName].bg[info[#info]]
		end,
		set = function(info, val)
			--Update memory
			UF.CurrentSettings[frameName].elements[elementName].bg[info[#info]] = val
			--Update the DB
			UF.DB.UserSettings[UF.DB.Style][frameName].elements[elementName].bg[info[#info]] = val
			--Update the screen
			UF.Unit[frameName]:UpdateAll()
		end,
		args = {
			enabled = {
				name = L['Enable'],
				type = 'toggle',
				order = 1
			},
			color = {
				name = L['Color'],
				type = 'color',
				order = 2,
				hasAlpha = true
			}
		}
	}
end

---@param frameName UnitFrameName
---@param ElementOptSet AceConfigOptionsTable
function Options:IndicatorAddDisplay(frameName, ElementOptSet)
	ElementOptSet.args.display = {
		name = '',
		type = 'group',
		order = 20,
		inline = true,
		args = {
			header = {
				type = 'header',
				name = L['Display'],
				order = .1
			},
			size = {
				name = L['Size'],
				type = 'range',
				min = 0,
				max = 100,
				step = .1,
				order = 1
			},
			scale = {
				name = L['Scale'],
				type = 'range',
				min = .1,
				max = 3,
				step = .01,
				order = 2
			},
			alpha = {
				name = L['Alpha'],
				type = 'range',
				min = 0,
				max = 1,
				step = .01,
				order = 3
			}
		}
	}
end

---@param frameName UnitFrameName
---@param ElementOptSet AceConfigOptionsTable
---@param get function
---@param set function
function Options:AddPositioning(frameName, ElementOptSet, get, set)
	local builtFrame = UF.Unit:Get(frameName)
	local AnchorablePoints = {
		['Frame'] = 'Unit Frame'
	}
	SUI:CopyData(AnchorablePoints, builtFrame.elementList)

	ElementOptSet.args.position = {
		name = '',
		type = 'group',
		order = 50,
		inline = true,
		get = get,
		set = set,
		args = {
			header = {
				type = 'header',
				name = L['Position'],
				order = .1
			},
			x = {
				name = L['X Axis'],
				type = 'range',
				order = 1,
				min = -200,
				max = 200,
				step = 1
			},
			y = {
				name = L['Y Axis'],
				type = 'range',
				order = 2,
				min = -200,
				max = 200,
				step = 1
			},
			anchor = {
				name = L['Anchor point'],
				type = 'select',
				order = 3,
				values = anchorPoints
			},
			relativeTo = {
				name = 'Relative To',
				type = 'select',
				order = 3,
				values = AnchorablePoints
			},
			relativePoint = {
				name = 'Relative Point',
				type = 'select',
				order = 3,
				values = anchorPoints
			}
		}
	}
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
---@param element UnitFrameElement
function Options:AddDynamicText(frameName, OptionSet, element)
	OptionSet.args.Text = {
		name = L['Text'],
		type = 'group',
		order = 1,
		args = {
			execute = {
				name = L['Text tag list'],
				type = 'execute',
				order = .1,
				func = function(info)
					SUI.Lib.AceCD:SelectGroup('SpartanUI', 'Help', 'UnitFrames')
				end
			}
		}
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
					end
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
						UF.Unit[frameName]:Tag(UF.Unit[frameName][element].TextElements[count], val)
						UF.Unit[frameName]:UpdateTags()
					end
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
						SUI:UpdateDefaultSize(UF.Unit[frameName][element].TextElements[count], val, 'UnitFrames')
					end
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
						if not UF.DB.UserSettings[UF.DB.Style][frameName].elements[element].text[count].position then
							UF.DB.UserSettings[UF.DB.Style][frameName].elements[element].text[count].position = {}
						end
						UF.DB.UserSettings[UF.DB.Style][frameName].elements[element].text[count].position[info[#info]] = val
						--Update the screen
						local position = UF.CurrentSettings[frameName].elements[element].text[count].position
						UF.Unit[frameName][element].TextElements[count]:ClearAllPoints()
						UF.Unit[frameName][element].TextElements[count]:SetPoint(
							position.anchor,
							UF.Unit[frameName],
							position.anchor,
							position.x,
							position.y
						)
					end,
					args = {
						x = {
							name = L['X Axis'],
							type = 'range',
							order = 1,
							min = -200,
							max = 200,
							step = 1
						},
						y = {
							name = L['Y Axis'],
							type = 'range',
							order = 2,
							min = -200,
							max = 200,
							step = 1
						},
						anchor = {
							name = L['Anchor point'],
							type = 'select',
							order = 3,
							values = anchorPoints
						}
					}
				}
			}
		}
	end
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
function Options:AddGroupDisplay(frameName, OptionSet)
	OptionSet.args.General.args.Display = {
		name = L['Display'],
		type = 'group',
		order = .1,
		set = function(info, val)
			local setting = info[#info]
			--Update memory
			UF.CurrentSettings[frameName][setting] = val
			--Update the DB
			UF.DB.UserSettings[UF.DB.Style][frameName][setting] = val
			--Update the screen
			UF.Unit[frameName]:SetAttribute(setting, val)
		end,
		args = {
			showRaid = {
				name = L['Show Raid Frames'],
				type = 'toggle',
				order = 1
			},
			showParty = {
				name = L['Show while in party'],
				type = 'toggle',
				order = 2
			},
			showPlayer = {
				name = L['Show player'],
				type = 'toggle',
				order = 2
			},
			showSolo = {
				name = L['Show solo'],
				type = 'toggle',
				order = 2
			}
		}
	}
end

---@param frameName UnitFrameName
---@param OptionSet AceConfigOptionsTable
function Options:AddGroupLayout(frameName, OptionSet)
	OptionSet.args.General.args.Layout = {
		name = L['Layout Configuration'],
		type = 'group',
		order = .2,
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
				max = 40
			},
			unitsPerColumn = {
				name = L['Units Per Column'],
				type = 'range',
				order = 2,
				width = 'full',
				step = 1,
				min = 1,
				max = 40
			},
			columnSpacing = {
				name = L['Column Spacing'],
				type = 'range',
				order = 3,
				width = 'full',
				step = 1,
				min = -200,
				max = 200
			},
			bar1 = {name = 'Offsets', type = 'header', order = 20},
			yOffset = {
				name = L['Vertical offset'],
				type = 'range',
				order = 21,
				width = 'full',
				step = 1,
				min = -200,
				max = 200
			},
			xOffset = {
				name = L['Horizonal offset'],
				type = 'range',
				order = 22,
				width = 'full',
				step = 1,
				min = -200,
				max = 200
			}
		}
	}
end

function Options:Initialize()
	---Build Help screen

	---@type AceConfigOptionsTable
	local HelpScreen = {
		name = L['Text tags'],
		type = 'group',
		childGroups = 'tab',
		args = {}
	}
	for k, v in pairs(TagList) do
		if v.category and not HelpScreen.args[v.category] then
			HelpScreen.args[v.category] = {
				name = v.category,
				type = 'group',
				args = {}
			}
		end
		HelpScreen.args[v.category].args[k] = {
			name = v.description,
			-- desc = 'desc',
			type = 'input',
			-- multiline = 'false',
			width = 'full',
			get = function(info)
				return '[' .. k .. ']'
			end,
			set = function(info, val)
			end
		}
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
		end
	}

	-- Construct base Options object
	---@type AceConfigOptionsTable
	local UFOptions = {
		name = L['Unit frames'],
		type = 'group',
		args = {
			ResetUFSettings = {
				name = L['Reset to base style (Revert customizations)'],
				type = 'execute',
				width = 'full',
				order = 1,
				func = function()
					UF:ResetSettings()
				end
			},
			BaseStyle = {
				name = L['Base frame style'],
				type = 'group',
				inline = true,
				order = 30,
				args = {}
			},
			EnabledFrame = {
				name = L['Enabled frames'],
				type = 'group',
				inline = true,
				order = 90,
				args = {}
			}
		}
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
			end
		}
	end

	-- Build style Buttons
	for styleName, styleInfo in pairs(UF.Style:GetList()) do
		local data = styleInfo.settings ---@type UFStyleSettings

		UFOptions.args.BaseStyle.args[styleName] = {
			name = data.displayName or styleName,
			type = 'execute',
			image = function()
				return data.setup.image or ('interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_' .. styleName), 120, 60
			end,
			imageCoords = function()
				return data.setup.imageCoords or {0, .5, 0, .5}
			end,
			func = function()
				UF:SetActiveStyle(styleName)
			end
		}
	end

	-- -- Add built skins selection page to the styles section
	SUI.opt.args.General.args.style.args.Unitframes = UFOptions.args.BaseStyle

	-- Build frame options
	for frameName, FrameConfig in pairs(UF.Unit:GetFrameList()) do
		local FrameOptSet = CreateOptionSet(frameName)
		AddGeneral(FrameOptSet)

		-- Add Element Options
		local builtFrame = UF.Unit:Get(frameName)

		for elementName, _ in pairs(builtFrame.elementList) do
			local elementConfig = builtFrame.config.elements[elementName].config

			local ElementOptSet = {
				name = elementConfig.DisplayName and L[elementConfig.DisplayName] or elementName,
				-- description = elementConfig.Description or '',
				type = 'group',
				order = 1,
				get = function(info)
					return UF.CurrentSettings[frameName].elements[elementName][info[#info]] or false
				end,
				set = function(info, val)
					--Update memory
					UF.CurrentSettings[frameName].elements[elementName][info[#info]] = val
					--Update the DB
					UF.DB.UserSettings[UF.DB.Style][frameName].elements[elementName][info[#info]] = val
					--Update the screen
					builtFrame:UpdateAll()
				end,
				args = {}
			}

			local PositionGet = function(info)
				return UF.CurrentSettings[frameName].elements[elementName].position[info[#info]]
			end
			local PositionSet = function(info, val)
				--Update memory
				UF.CurrentSettings[frameName].elements[elementName].position[info[#info]] = val
				--Update the DB
				UF.DB.UserSettings[UF.DB.Style][frameName].elements[elementName].position[info[#info]] = val
				--Update Screen
				UF.Unit[frameName]:ElementUpdate(elementName)
			end

			if elementConfig.type == 'General' then
			elseif elementConfig.type == 'StatusBar' then
				Options:StatusBarDefaults(frameName, ElementOptSet, elementName)
			elseif elementConfig.type == 'Indicator' then
				Options:IndicatorAddDisplay(frameName, ElementOptSet)
				Options:AddPositioning(frameName, ElementOptSet, PositionGet, PositionSet)
			elseif elementConfig.type == 'Text' then
				-- Options:IndicatorAddDisplay(frameName, ElementOptSet)
				Options:AddPositioning(frameName, ElementOptSet, PositionGet, PositionSet)
			elseif elementConfig.type == 'Auras' then
				Options:IndicatorAddDisplay(frameName, ElementOptSet)
				Options:AddPositioning(frameName, ElementOptSet, PositionGet, PositionSet)
			end

			--Call Elements Custom function
			UF.Elements:Options(frameName, elementName, ElementOptSet)

			if not ElementOptSet.args.enabled then
				ElementOptSet.args.enabled = {
					name = L['Enabled'],
					type = 'toggle',
					order = 1
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

Options.CONST = {anchorPoints = anchorPoints}

UF.Options = Options
