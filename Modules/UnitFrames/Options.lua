local _G, SUI, L, print = _G, SUI, SUI.L, SUI.print
local module = SUI:GetModule('Component_UnitFrames')
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
local limitedAnchorPoints = {
	['TOPLEFT'] = 'TOP LEFT',
	['TOPRIGHT'] = 'TOP RIGHT',
	['BOTTOMLEFT'] = 'BOTTOM LEFT',
	['BOTTOMRIGHT'] = 'BOTTOM RIGHT'
}

local frameList = {
	'player',
	'target',
	'targettarget',
	'boss',
	'bosstarget',
	'pet',
	'pettarget',
	'focus',
	'focustarget',
	'party',
	'partypet',
	'partytarget',
	'raid',
	'arena'
}

if SUI.IsClassic then
	frameList = {
		'player',
		'target',
		'targettarget',
		'pet',
		'pettarget',
		'party',
		'partypet',
		'partytarget',
		'raid'
	}
end

----------------------------------------------------------------------------------------------------

local function CreateOptionSet(frameName, order)
	SUI.opt.args.UnitFrames.args[frameName] = {
		name = frameName,
		type = 'group',
		order = order,
		childGroups = 'tab',
		disabled = function(args)
			return not module.CurrentSettings[frameName].enabled
		end,
		args = {
			indicators = {
				name = 'Indicators',
				type = 'group',
				order = 40,
				childGroups = 'tree',
				args = {}
			},
			text = {
				name = 'Text',
				type = 'group',
				order = 50,
				childGroups = 'tree',
				args = {
					execute = {
						name = 'Text tag list',
						type = 'execute',
						func = function(info)
							SUI.Lib.AceCD:SelectGroup('SpartanUI', 'Help', 'TextTags')
						end
					}
				}
			}
		}
	}
end

local function AddGeneralOptions(frameName)
	SUI.opt.args.UnitFrames.args[frameName].args['general'] = {
		name = 'General',
		desc = 'General display settings',
		type = 'group',
		-- childGroups = 'inline',
		order = 10,
		args = {
			General = {
				name = 'General',
				type = 'group',
				order = 1,
				inline = true,
				args = {
					width = {
						name = 'Frame width',
						type = 'range',
						width = 'full',
						order = 2,
						min = 1,
						max = 300,
						step = .1,
						get = function(info)
							return module.CurrentSettings[frameName].width
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].width = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].width = val
							--Update the screen
							module.frames[frameName]:UpdateSize()
						end
					},
					range = {
						name = 'Fade out of range',
						width = 'double',
						type = 'toggle',
						get = function(info)
							return module.CurrentSettings[frameName].elements.Range.enabled
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Range.enabled = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements.Range.enabled = val
							--Update the screen
							if module.frames[frameName].Range then
								if val then
									module.frames[frameName]:EnableElement('Range')
									module.frames[frameName].Range:ForceUpdate()
								else
									module.frames[frameName]:DisableElement('Range')
								end
							else
								module.frames[frameName]:UpdateAll()
							end
						end
					}
				}
			},
			portrait = {
				name = 'Portrait',
				type = 'group',
				order = 3,
				inline = true,
				args = {
					enabled = {
						name = L['Enabled'],
						type = 'toggle',
						order = 10,
						get = function(info)
							return module.CurrentSettings[frameName].elements.Portrait.enabled
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Portrait.enabled = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements.Portrait.enabled = val
							--Update the screen
							if module.frames[frameName].Portrait then
								if val then
									module.frames[frameName]:EnableElement('Portrait')
									module.frames[frameName].Portrait:ForceUpdate()
								else
									module.frames[frameName]:DisableElement('Portrait')
								end
							else
								module.frames[frameName]:UpdateAll()
							end
						end
					},
					type = {
						name = 'Portrait type',
						type = 'select',
						order = 20,
						values = {
							['3D'] = '3D',
							['2D'] = '2D'
						},
						get = function(info)
							return module.CurrentSettings[frameName].elements.Portrait.type
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Portrait.type = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements.Portrait.type = val
							--Update the screen
							module.frames[frameName]:ElementUpdate('Portrait')
						end
					},
					rotation = {
						name = 'Rotation',
						type = 'range',
						min = -1,
						max = 1,
						step = .01,
						order = 21,
						get = function(info)
							return module.CurrentSettings[frameName].elements.Portrait.rotation
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Portrait.rotation = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements.Portrait.rotation = val
							--Update the screen
							module.frames[frameName]:ElementUpdate('Portrait')
						end
					},
					camDistanceScale = {
						name = 'Camera Distance Scale',
						type = 'range',
						min = .01,
						max = 5,
						step = .1,
						order = 22,
						get = function(info)
							return module.CurrentSettings[frameName].elements.Portrait.camDistanceScale
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Portrait.camDistanceScale = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements.Portrait.camDistanceScale = val
							--Update the screen
							module.frames[frameName]:ElementUpdate('Portrait')
						end
					},
					position = {
						name = 'Position',
						type = 'select',
						order = 30,
						values = {
							['left'] = L['Left'],
							['right'] = L['Right']
						},
						get = function(info)
							return module.CurrentSettings[frameName].elements.Portrait.position
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Portrait.position = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements.Portrait.position = val
							--Update the screen
							module.frames[frameName]:ElementUpdate('Portrait')
						end
					}
				}
			}
		}
	}
end

local function AddArtworkOptions(frameName)
	local ArtPositions = {['full'] = 'Full frame skin', ['top'] = 'Top', ['bg'] = 'Background', ['bottom'] = 'Bottom'}
	local function ArtworkOptionUpdate(pos, option, val)
		--Update memory
		module.CurrentSettings[frameName].artwork[pos][option] = val
		--Update the DB
		module.DB.UserSettings[module.DB.Style][frameName].artwork[pos][option] = val
		--Update the screen
		module.frames[frameName]:ElementUpdate('SpartanArt')
	end
	SUI.opt.args.UnitFrames.args[frameName].args['artwork'] = {
		name = 'Artwork',
		type = 'group',
		order = 20,
		args = {}
	}
	local i = 1
	for position, DisplayName in pairs(ArtPositions) do
		SUI.opt.args.UnitFrames.args[frameName].args.artwork.args[position] = {
			name = DisplayName,
			type = 'group',
			order = i,
			disabled = true,
			args = {
				enabled = {
					name = 'Enabled',
					type = 'toggle',
					order = 1,
					get = function(info)
						return module.CurrentSettings[frameName].artwork[position].enabled
					end,
					set = function(info, val)
						ArtworkOptionUpdate(position, 'enabled', val)
					end
				},
				StyleDropdown = {
					name = 'Current Style',
					type = 'select',
					order = 2,
					values = {[''] = 'None'},
					get = function(info)
						return module.CurrentSettings[frameName].artwork[position].graphic
					end,
					set = function(info, val)
						ArtworkOptionUpdate(position, 'graphic', val)
					end
				},
				style = {
					name = 'Style',
					type = 'group',
					order = 3,
					inline = true,
					args = {}
				},
				settings = {
					name = 'Settings',
					type = 'group',
					inline = true,
					order = 500,
					args = {
						alpha = {
							name = 'Custom alpha',
							desc = "This setting will override your art's default settings. Set to 0 to disable custom Alpha.",
							type = 'range',
							width = 'double',
							min = 0,
							max = 1,
							step = .01,
							get = function(info)
								return module.CurrentSettings[frameName].artwork[position].alpha
							end,
							set = function(info, val)
								if val == 0 then
									val = false
								end

								ArtworkOptionUpdate(position, 'alpha', val)
							end
						}
					}
				}
			}
		}
		i = i + 1
	end

	for Name, data in pairs(module.Artwork) do
		for position, _ in pairs(ArtPositions) do
			if data[position] then
				local options = SUI.opt.args.UnitFrames.args[frameName].args.artwork.args[position].args
				local dataObj = data[position]
				if dataObj.perUnit and data[frameName] then
					dataObj = data[frameName]
				end

				if dataObj then
					--Enable art option
					SUI.opt.args.UnitFrames.args[frameName].args.artwork.args[position].disabled = false
					--Add to dropdown
					options.StyleDropdown.values[Name] = (data.name or Name)
					--Create example
					options.style.args[Name] = {
						name = (data.name or Name),
						width = 'normal',
						type = 'description',
						image = function()
							if type(dataObj.path) == 'function' then
								local path = dataObj.path(nil, position)
								if path then
									return path, (dataObj.exampleWidth or 160), (dataObj.exampleHeight or 40)
								end
							else
								return dataObj.path, (dataObj.exampleWidth or 160), (dataObj.exampleHeight or 40)
							end
						end,
						imageCoords = function()
							if type(dataObj.TexCoord) == 'function' then
								local cords = dataObj.TexCoord(nil, position)
								if cords then
									return cords
								end
							else
								return dataObj.TexCoord
							end
						end
					}
				end
			end
		end
	end
end

local function AddBarOptions(frameName)
	SUI.opt.args.UnitFrames.args[frameName].args.bars = {
		name = 'Bars',
		type = 'group',
		order = 30,
		childGroups = 'tree',
		args = {
			Castbar = {
				name = 'Castbar',
				type = 'group',
				order = 1,
				get = function(info)
					return module.CurrentSettings[frameName].elements.Castbar[info[#info]] or false
				end,
				set = function(info, val)
					--Update memory
					module.CurrentSettings[frameName].elements.Castbar[info[#info]] = val
					--Update the DB
					module.DB.UserSettings[module.DB.Style][frameName].elements.Castbar[info[#info]] = val
					--Update the screen
					module.frames[frameName]:UpdateAll()
				end,
				args = {
					FlashOnInterruptible = {
						name = L['Flash on interruptible cast'],
						type = 'toggle',
						width = 'double',
						order = 10
					},
					InterruptSpeed = {
						name = 'Interrupt flash speed',
						type = 'range',
						width = 'double',
						min = .01,
						max = 1,
						step = .01,
						order = 11
					},
					interruptable = {
						name = 'Show interrupt or spell steal',
						type = 'toggle',
						width = 'double',
						order = 20
					},
					latency = {
						name = 'Show latency',
						type = 'toggle',
						order = 21
					},
					Icon = {
						name = 'Spell icon',
						type = 'group',
						inline = true,
						order = 100,
						get = function(info)
							return module.CurrentSettings[frameName].elements.Castbar.Icon[info[#info]]
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Castbar.Icon[info[#info]] = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements.Castbar.Icon[info[#info]] = val
							--Update the screen
							module.frames[frameName]:UpdateAll()
						end,
						args = {
							enabled = {
								name = 'Enable',
								type = 'toggle',
								order = 1
							},
							size = {
								name = 'Size',
								type = 'range',
								min = 0,
								max = 100,
								step = .1,
								order = 5
							},
							position = {
								name = 'Position',
								type = 'group',
								order = 50,
								inline = true,
								get = function(info)
									return module.CurrentSettings[frameName].elements.Castbar.Icon.position[info[#info]]
								end,
								set = function(info, val)
									--Update memory
									module.CurrentSettings[frameName].elements.Castbar.Icon.position[info[#info]] = val
									--Update the DB
									module.DB.UserSettings[module.DB.Style][frameName].elements.Castbar.Icon.position[info[#info]] = val
									--Update Screen
									module.frames[frameName]:UpdateAll()
								end,
								args = {
									x = {
										name = 'X Axis',
										type = 'range',
										order = 1,
										min = -100,
										max = 100,
										step = 1
									},
									y = {
										name = 'Y Axis',
										type = 'range',
										order = 2,
										min = -100,
										max = 100,
										step = 1
									},
									anchor = {
										name = 'Anchor point',
										type = 'select',
										order = 3,
										values = anchorPoints
									}
								}
							}
						}
					}
				}
			},
			Health = {
				name = 'Health',
				type = 'group',
				order = 2,
				get = function(info)
					return module.CurrentSettings[frameName].elements[info[#info]]
				end,
				set = function(info, val)
					--Update the screen
					module.frames[frameName][info[#info]] = val
					--Update memory
					module.CurrentSettings[frameName].elements[info[#info]] = val
					--Update the DB
					module.DB.UserSettings[module.DB.Style][frameName].elements[info[#info]] = val
					--Update the screen
					module.frames[frameName]:UpdateAll()
				end,
				args = {
					healthprediction = {
						name = 'Health prediction',
						type = 'toggle',
						order = 5
					},
					DispelHighlight = {
						name = 'Dispel highlight',
						type = 'toggle',
						order = 5
					},
					coloring = {
						name = 'Color health bar by:',
						desc = 'The below options are in order of wich they apply',
						order = 10,
						inline = true,
						type = 'group',
						get = function(info)
							return module.CurrentSettings[frameName].elements.Health[info[#info]]
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Health[info[#info]] = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements.Health[info[#info]] = val
							--Update the screen
							module.frames[frameName]:UpdateAll()
						end,
						args = {
							colorTapping = {
								name = 'Tapped',
								desc = "Color's the bar if the unit isn't tapped by the player",
								type = 'toggle',
								order = 1
							},
							colorDisconnected = {
								name = 'Disconnected',
								desc = 'Color the bar if the player is offline',
								type = 'toggle',
								order = 2
							},
							colorClass = {
								name = 'Class',
								desc = 'Color the bar based on unit class',
								type = 'toggle',
								order = 3
							},
							colorReaction = {
								name = 'Reaction',
								desc = "color the bar based on the player's reaction towards the player.",
								type = 'toggle',
								order = 4
							},
							colorSmooth = {
								name = 'Smooth',
								desc = "color the bar with a smooth gradient based on the player's current health percentage",
								type = 'toggle',
								order = 5
							}
						}
					}
				}
			},
			Power = {
				name = 'Power',
				type = 'group',
				order = 3,
				childGroups = 'inline',
				args = {}
			}
		}
	}

	local bars = {'Castbar', 'Health', 'Power'}
	for _, key in ipairs(bars) do
		SUI.opt.args.UnitFrames.args[frameName].args.bars.args[key].args.enabled = {
			name = L['Enabled'],
			type = 'toggle',
			width = 'full',
			order = 1,
			get = function(info)
				return module.CurrentSettings[frameName].elements[key].enabled
			end,
			set = function(info, val)
				--Update memory
				module.CurrentSettings[frameName].elements[key].enabled = val
				--Update the DB
				module.DB.UserSettings[module.DB.Style][frameName].elements[key].enabled = val
				--Update the screen
				module.frames[frameName]:UpdateAll()
			end
		}
		SUI.opt.args.UnitFrames.args[frameName].args.bars.args[key].args.height = {
			name = 'Height',
			type = 'range',
			width = 'full',
			order = 2,
			min = 2,
			max = 100,
			step = 1,
			get = function(info)
				return module.CurrentSettings[frameName].elements[key].height
			end,
			set = function(info, val)
				--Update memory
				module.CurrentSettings[frameName].elements[key].height = val
				--Update the DB
				module.DB.UserSettings[module.DB.Style][frameName].elements[key].height = val
				--Update the screen
				module.frames[frameName]:UpdateSize()
			end
		}

		SUI.opt.args.UnitFrames.args[frameName].args.bars.args[key].args.Background = {
			name = 'Background',
			type = 'group',
			inline = true,
			order = 200,
			args = {
				enabled = {
					name = 'Enable',
					type = 'toggle',
					order = 1,
					get = function(info)
						return module.CurrentSettings[frameName].elements[key].bg.enabled
					end,
					set = function(info, val)
						--Update memory
						module.CurrentSettings[frameName].elements[key].bg.enabled = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].elements[key].bg.enabled = val
						--Update the screen
						module.frames[frameName]:UpdateAll()
					end
				},
				color = {
					name = 'Color',
					type = 'color',
					order = 2,
					hasAlpha = true,
					get = function(info)
						local val = module.CurrentSettings[frameName].elements[key].bg.color
						if not val then
							return {1, 1, 1, 1}
						end
						return unpack(val)
					end,
					set = function(info, r, b, g, a)
						local val = {r, b, g, a}
						--Update memory
						module.CurrentSettings[frameName].elements[key].bg.color = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].elements[key].bg.color = val
						--Update the screen
						module.frames[frameName]:UpdateAll()
					end
				}
			}
		}
	end

	if frameName == 'player' then
		if SUI.IsRetail then
			SUI.opt.args.UnitFrames.args.player.args.bars.args['Power'].args['PowerPrediction'] = {
				name = 'Enable power prediction',
				desc = 'Used to represent cost of spells on top of the Power bar',
				type = 'toggle',
				width = 'double',
				order = 10,
				get = function(info)
					return module.CurrentSettings.player.elements.Power.PowerPrediction
				end,
				set = function(info, val)
					--Update the screen
					if val then
						module.frames.player:EnableElement('PowerPrediction')
					else
						module.frames.player:DisableElement('PowerPrediction')
					end
					--Update memory
					module.CurrentSettings.player.elements.Power.PowerPrediction = val
					--Update the DB
					module.DB.UserSettings[module.DB.Style].player.elements.Power.PowerPrediction = val
				end
			}
		end

		SUI.opt.args.UnitFrames.args.player.args.bars.args['AdditionalPower'] = {
			name = 'Additional power',
			desc = "player's additional power, such as Mana for Balance druids.",
			order = 20,
			type = 'group',
			childGroups = 'inline',
			args = {
				enabled = {
					name = L['Enabled'],
					type = 'toggle',
					width = 'full',
					order = 1,
					get = function(info)
						return module.CurrentSettings.player.elements.AdditionalPower.enabled
					end,
					set = function(info, val)
						--Update the screen
						if val then
							module.frames.player:EnableElement('AdditionalPower')
						else
							module.frames.player:DisableElement('AdditionalPower')
						end
						--Update memory
						module.CurrentSettings.player.elements.AdditionalPower.enabled = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style].player.elements.AdditionalPower.enabled = val
					end
				},
				height = {
					name = 'Height',
					type = 'range',
					width = 'full',
					order = 2,
					min = 2,
					max = 100,
					step = 1,
					get = function(info)
						return module.CurrentSettings.player.elements.AdditionalPower.height
					end,
					set = function(info, val)
						--Update memory
						module.CurrentSettings.player.elements.AdditionalPower.height = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style].player.elements.AdditionalPower.height = val
						--Update the screen
						module.frames.player:UpdateSize()
					end
				}
			}
		}
	end

	local friendly = {'player', 'party', 'raid', 'target', 'focus', 'targettarget', 'focustarget'}
	if not SUI:isInTable(friendly, frameName) then
		SUI.opt.args.UnitFrames.args[frameName].args.bars.args['Health'].args['DispelHighlight'].hidden = true
	end

	if frameName == 'player' or frameName == 'party' or frameName == 'raid' then
		SUI.opt.args.UnitFrames.args[frameName].args.bars.args['Castbar'].args['interruptable'].hidden = true
	end
end

local function AddIndicatorOptions(frameName)
	local PlayerOnly = {
		['CombatIndicator'] = 'Combat',
		['RestingIndicator'] = 'Resting',
		['Runes'] = 'Runes',
		['Stagger'] = 'Stagger',
		['Totems'] = 'Totems'
	}
	local FriendlyOnly = {
		['AssistantIndicator'] = RAID_ASSISTANT,
		['GroupRoleIndicator'] = 'Group role',
		['LeaderIndicator'] = 'Leader',
		['PhaseIndicator'] = 'Phase',
		['PvPIndicator'] = 'PvP',
		['RaidRoleIndicator'] = 'Main tank or assist',
		['ReadyCheckIndicator'] = 'Ready check icon',
		['ResurrectIndicator'] = 'Resurrect',
		['SummonIndicator'] = 'Summon'
	}
	local targetOnly = {
		['QuestMobIndicator'] = 'Quest'
	}
	local AllIndicators = {
		['SUI_ClassIcon'] = 'Class icon',
		['RaidTargetIndicator'] = RAID_TARGET_ICON,
		['ThreatIndicator'] = 'Threat'
	}

	-- Text indicators TODO
	-- ['StatusText'] = STATUS_TEXT,

	-- Check frameName for what tables above need to be applied
	if frameName == 'player' then
		AllIndicators = SUI:MergeData(AllIndicators, PlayerOnly)
	end
	if frameName == 'pet' and SUI.IsClassic then
		local petIndicator = {
			['PetHappiness'] = 'Pet happiness'
		}
		AllIndicators = SUI:MergeData(AllIndicators, petIndicator)
	end
	if frameName == 'target' then
		AllIndicators = SUI:MergeData(AllIndicators, targetOnly)
	end
	if module:IsFriendlyFrame(frameName) then
		AllIndicators = SUI:MergeData(AllIndicators, FriendlyOnly)
	end

	for key, name in pairs(AllIndicators) do
		SUI.opt.args.UnitFrames.args[frameName].args.indicators.args[key] = {
			name = name,
			type = 'group',
			args = {
				enable = {
					name = L['Enabled'],
					type = 'toggle',
					order = 10,
					get = function(info)
						return module.CurrentSettings[frameName].elements[key].enabled
					end,
					set = function(info, val)
						--Update memory
						module.CurrentSettings[frameName].elements[key].enabled = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].elements[key].enabled = val
						--Update the screen
						if val then
							module.frames[frameName]:EnableElement(key)
							module.frames[frameName][key]:ForceUpdate()
						else
							module.frames[frameName]:DisableElement(key)
							module.frames[frameName][key]:Hide()
						end
					end
				},
				display = {
					name = 'Display',
					type = 'group',
					order = 20,
					inline = true,
					args = {
						size = {
							name = 'Size',
							type = 'range',
							min = 0,
							max = 100,
							step = .1,
							order = 1,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].size
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].size = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].size = val
								--Update Screen
								module.frames[frameName]:ElementUpdate(key)
							end
						},
						scale = {
							name = 'Scale',
							type = 'range',
							min = .1,
							max = 3,
							step = .01,
							order = 2,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].scale
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].scale = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].scale = val
								--Update Screen
								module.frames[frameName]:ElementUpdate(key)
							end
						},
						alpha = {
							name = 'Alpha',
							type = 'range',
							min = 0,
							max = 1,
							step = .01,
							order = 3,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].alpha
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].alpha = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].alpha = val
								--Update Screen
								module.frames[frameName]:ElementUpdate(key)
							end
						}
					}
				},
				position = {
					name = 'Position',
					type = 'group',
					order = 50,
					inline = true,
					args = {
						x = {
							name = 'X Axis',
							type = 'range',
							order = 1,
							min = -200,
							max = 200,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].position.x
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.x = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].position.x = val
								--Update Screen
								module.frames[frameName]:ElementUpdate(key)
							end
						},
						y = {
							name = 'Y Axis',
							type = 'range',
							order = 2,
							min = -200,
							max = 200,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].position.y
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.y = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].position.y = val
								--Update Screen
								module.frames[frameName]:ElementUpdate(key)
							end
						},
						anchor = {
							name = 'Anchor point',
							type = 'select',
							order = 3,
							values = anchorPoints,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].position.anchor
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.anchor = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].position.anchor = val
								--Update Screen
								module.frames[frameName]:ElementUpdate(key)
							end
						}
					}
				}
			}
		}
	end
	if SUI.opt.args.UnitFrames.args[frameName].args.indicators.args.PvPIndicator then
		-- Badge
		local i = 1
		for k, v in pairs({['Badge'] = 'BadgeBackup', ['Shadow'] = 'ShadowBackup'}) do
			SUI.opt.args.UnitFrames.args[frameName].args.indicators.args.PvPIndicator.args[k] = {
				name = (k == 'Badge' and 'Show honor badge') or 'Shadow',
				type = 'toggle',
				order = 70 + i,
				get = function(info)
					return module.CurrentSettings[frameName].elements.PvPIndicator[k]
				end,
				set = function(info, val)
					--Update memory
					module.CurrentSettings[frameName].elements.PvPIndicator[k] = val
					--Update the DB
					module.DB.UserSettings[module.DB.Style][frameName].elements.PvPIndicator[k] = val
					--Update the screen
					if val then
						module.frames[frameName].PvPIndicator[k] = module.frames[frameName].PvPIndicator[v]
					else
						module.frames[frameName].PvPIndicator[k]:Hide()
						module.frames[frameName].PvPIndicator[k] = nil
					end
					module.frames[frameName].PvPIndicator:ForceUpdate('OnUpdate')
				end
			}
			i = i + 1
		end
	end

	-- Non player items like
	if frameName ~= 'player' then
		SUI.opt.args.UnitFrames.args[frameName].args.indicators.args.Range = {
			name = 'Range',
			type = 'group',
			args = {
				enable = {
					name = L['Enabled'],
					type = 'toggle',
					order = 10,
					get = function(info)
						return module.CurrentSettings[frameName].elements.Range.enabled
					end,
					set = function(info, val)
						--Update memory
						module.CurrentSettings[frameName].elements.Range.enabled = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].elements.Range.enabled = val
						--Update the screen
						if val then
							module.frames[frameName]:EnableElement(key)
						else
							module.frames[frameName]:DisableElement(key)
						end
						module.frames[frameName].Range:ForceUpdate()
					end
				},
				insideAlpha = {
					name = 'In range alpha',
					type = 'range',
					min = 0,
					max = 1,
					step = .1,
					get = function(info)
						return module.CurrentSettings[frameName].elements.Range.insideAlpha
					end,
					set = function(info, val)
						--Update memory
						module.CurrentSettings[frameName].elements.Range.insideAlpha = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].elements.Range.insideAlpha = val
						--Update the screen
						module.frames[frameName].Range.insideAlpha = val
					end
				},
				outsideAlpha = {
					name = 'Out of range alpha',
					type = 'range',
					min = 0,
					max = 1,
					step = .1,
					get = function(info)
						return module.CurrentSettings[frameName].elements.Range.outsideAlpha
					end,
					set = function(info, val)
						--Update memory
						module.CurrentSettings[frameName].elements.Range.outsideAlpha = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].elements.Range.outsideAlpha = val
						--Update the screen
						module.frames[frameName].Range.outsideAlpha = val
					end
				}
			}
		}
	end

	-- Hide a few generated options from specific frame
	if frameName == 'player' then
		SUI.opt.args.UnitFrames.args[frameName].args['indicators'].args['ThreatIndicator'].hidden = true
	elseif frameName == 'boss' then
		SUI.opt.args.UnitFrames.args[frameName].args['indicators'].args['SUI_ClassIcon'].hidden = true
	end
end

local function AddDynamicText(frameName, element, count)
	SUI.opt.args.UnitFrames.args[frameName].args['text'].args[element].args[count] = {
		name = 'Text element ' .. count,
		type = 'group',
		inline = true,
		order = (10 + count),
		args = {
			enabled = {
				name = L['Enabled'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return module.CurrentSettings[frameName].elements[element].text[count].enabled
				end,
				set = function(info, val)
					--Update memory
					module.CurrentSettings[frameName].elements[element].text[count].enabled = val
					--Update the DB
					module.DB.UserSettings[module.DB.Style][frameName].elements[element].text[count].enabled = val
					--Update the screen
					if val then
						module.frames[frameName][element].TextElements[count]:Show()
					else
						module.frames[frameName][element].TextElements[count]:Hide()
					end
				end
			},
			text = {
				name = 'Text',
				type = 'input',
				width = 'full',
				order = 2,
				get = function(info)
					return module.CurrentSettings[frameName].elements[element].text[count].text
				end,
				set = function(info, val)
					--Update memory
					module.CurrentSettings[frameName].elements[element].text[count].text = val
					--Update the DB
					module.DB.UserSettings[module.DB.Style][frameName].elements[element].text[count].text = val
					--Update the screen
					module.frames[frameName]:Tag(module.frames[frameName][element].TextElements[count], val)
					module.frames[frameName]:UpdateTags()
				end
			},
			size = {
				name = 'Size',
				type = 'range',
				width = 'full',
				min = 1,
				max = 30,
				step = 1,
				order = 1.5,
				get = function(info)
					return module.CurrentSettings[frameName].elements[element].text[count].size
				end,
				set = function(info, val)
					--Update memory
					module.CurrentSettings[frameName].elements[element].text[count].size = val
					--Update the DB
					module.DB.UserSettings[module.DB.Style][frameName].elements[element].text[count].size = val
					--Update the screen
					SUI:UpdateDefaultSize(module.frames[frameName][element].TextElements[count], val, 'UnitFrames')
				end
			},
			position = {
				name = 'Position',
				type = 'group',
				order = 50,
				inline = true,
				args = {
					x = {
						name = 'X Axis',
						type = 'range',
						order = 1,
						min = -200,
						max = 200,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].elements[element].text[count].position.x
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements[element].text[count].position.x = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements[element].text[count].position.x = val
							--Update the screen
							local position = module.CurrentSettings[frameName].elements[element].text[count].position
							module.frames[frameName][element].TextElements[count]:ClearAllPoints()
							module.frames[frameName][element].TextElements[count]:SetPoint(
								position.anchor,
								module.frames[frameName],
								position.anchor,
								position.x,
								position.y
							)
						end
					},
					y = {
						name = 'Y Axis',
						type = 'range',
						order = 2,
						min = -200,
						max = 200,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].elements[element].text[count].position.y
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements[element].text[count].position.y = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements[element].text[count].position.y = val
							--Update the screen
							local position = module.CurrentSettings[frameName].elements[element].text[count].position
							module.frames[frameName][element].TextElements[count]:ClearAllPoints()
							module.frames[frameName][element].TextElements[count]:SetPoint(
								position.anchor,
								module.frames[frameName],
								position.anchor,
								position.x,
								position.y
							)
						end
					},
					anchor = {
						name = 'Anchor point',
						type = 'select',
						order = 3,
						values = anchorPoints,
						get = function(info)
							return module.CurrentSettings[frameName].elements[element].text[count].position.anchor
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements[element].text[count].position.anchor = val
							--Update the DB
							module.DB.UserSettings[module.DB.Style][frameName].elements[element].text[count].position.anchor = val
							--Update the screen
							local position = module.CurrentSettings[frameName].elements[element].text[count].position
							module.frames[frameName][element].TextElements[count]:ClearAllPoints()
							module.frames[frameName][element].TextElements[count]:SetPoint(
								position.anchor,
								module.frames[frameName],
								position.anchor,
								position.x,
								position.y
							)
						end
					}
				}
			}
		}
	}
end

local function AddTextOptions(frameName)
	SUI.opt.args.UnitFrames.args[frameName].args['text'].args['Castbar'] = {
		name = 'Castbar',
		type = 'group',
		order = 1,
		args = {}
	}
	SUI.opt.args.UnitFrames.args[frameName].args['text'].args['Health'] = {
		name = 'Health',
		type = 'group',
		order = 2,
		args = {}
	}
	SUI.opt.args.UnitFrames.args[frameName].args['text'].args['Power'] = {
		name = 'Power',
		type = 'group',
		order = 3,
		args = {}
	}

	for i in pairs(module.CurrentSettings[frameName].elements.Castbar.text) do
		AddDynamicText(frameName, 'Castbar', i)
	end
	SUI.opt.args.UnitFrames.args[frameName].args['text'].args['Castbar'].args['1'].args['text'].disabled = true
	SUI.opt.args.UnitFrames.args[frameName].args['text'].args['Castbar'].args['2'].args['text'].disabled = true

	for i in pairs(module.CurrentSettings[frameName].elements.Health.text) do
		AddDynamicText(frameName, 'Health', i)
	end

	for i in pairs(module.CurrentSettings[frameName].elements.Power.text) do
		AddDynamicText(frameName, 'Power', i)
	end

	local StringElements = {
		['SUI_RaidGroup'] = 'Raid group',
		['Name'] = 'Name',
		['StatusText'] = 'Player status'
	}

	for key, name in pairs(StringElements) do
		SUI.opt.args.UnitFrames.args[frameName].args['text'].args[key] = {
			name = name,
			type = 'group',
			order = 1,
			args = {
				enabled = {
					name = L['Enabled'],
					type = 'toggle',
					order = 1,
					get = function(info)
						return module.CurrentSettings[frameName].elements[key].enabled
					end,
					set = function(info, val)
						--Update memory
						module.CurrentSettings[frameName].elements[key].enabled = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].elements[key].enabled = val
						--Update the screen
						if val then
							module.frames[frameName][key]:Show()
						else
							module.frames[frameName][key]:Hide()
						end
					end
				},
				Text = {
					name = '',
					type = 'group',
					inline = true,
					order = 10,
					args = {
						text = {
							name = 'Text',
							type = 'input',
							width = 'full',
							order = 1,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].text
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].text = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].text = val
								--Update the screen
								module.frames[frameName]:Tag(module.frames[frameName][key], val)
								module.frames[frameName]:UpdateTags()
							end
						},
						size = {
							name = 'Size',
							type = 'range',
							width = 'full',
							min = 1,
							max = 30,
							step = 1,
							order = 1.5,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].size
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].size = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].size = val
								--Update the screen
								SUI:UpdateDefaultSize(module.frames[frameName][key], val, 'UnitFrames')
							end
						},
						JustifyH = {
							name = 'Horizontal alignment',
							type = 'select',
							order = 2,
							values = {
								['LEFT'] = 'Left',
								['CENTER'] = 'Center',
								['RIGHT'] = 'Right'
							},
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].SetJustifyH
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].SetJustifyH = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].SetJustifyH = val
								--Update the screen
								module.frames[frameName][key]:SetJustifyH(val)
							end
						},
						JustifyV = {
							name = 'Vertical alignment',
							type = 'select',
							order = 3,
							values = {
								['TOP'] = 'Top',
								['MIDDLE'] = 'Middle',
								['BOTTOM'] = 'Bottom'
							},
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].SetJustifyV
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].SetJustifyV = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].SetJustifyV = val
								--Update the screen
								module.frames[frameName][key]:SetJustifyV(val)
							end
						}
					}
				},
				position = {
					name = 'Position',
					type = 'group',
					order = 50,
					inline = true,
					args = {
						x = {
							name = 'X Axis',
							type = 'range',
							order = 1,
							min = -200,
							max = 200,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].position.x
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.x = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].position.x = val
								--Update the screen
								module.frames[frameName]:ElementUpdate(key)
							end
						},
						y = {
							name = 'Y Axis',
							type = 'range',
							order = 2,
							min = -200,
							max = 200,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].position.y
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.y = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].position.y = val
								--Update the screen
								module.frames[frameName]:ElementUpdate(key)
							end
						},
						anchor = {
							name = 'Anchor point',
							type = 'select',
							order = 3,
							values = anchorPoints,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].position.anchor
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.anchor = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].elements[key].position.anchor = val
								--Update the screen
								module.frames[frameName]:ElementUpdate(key)
							end
						}
					}
				}
			}
		}
	end
end

local function AddBuffOptions(frameName)
	SUI.opt.args.UnitFrames.args[frameName].args['auras'] = {
		name = 'Buffs & Debuffs',
		desc = 'Buff & Debuff display settings',
		type = 'group',
		childGroups = 'tree',
		order = 100,
		args = {}
	}

	local function SetOption(val, buffType, setting)
		--Update memory
		module.CurrentSettings[frameName].auras[buffType][setting] = val
		--Update the DB
		module.DB.UserSettings[module.DB.Style][frameName].auras[buffType][setting] = val
		--Update the screen
		module.frames[frameName]:UpdateAuras()
	end

	for _, buffType in pairs({'Buffs', 'Debuffs'}) do
		local function AddBuffFilter(value)
		end

		SUI.opt.args.UnitFrames.args[frameName].args.auras.args[buffType] = {
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
						return module.CurrentSettings[frameName].auras[buffType].enabled
					end,
					set = function(info, val)
						SetOption(val, buffType, 'enabled')
					end
				},
				Display = {
					name = 'Display settings',
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
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].number
							end,
							set = function(info, val)
								SetOption(val, buffType, 'number')
							end
						},
						showType = {
							name = L['Show type'],
							type = 'toggle',
							order = 30,
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].showType
							end,
							set = function(info, val)
								SetOption(val, buffType, 'showType')
							end
						},
						onlyShowPlayer = {
							name = L['Only show players'],
							type = 'toggle',
							order = 60,
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].onlyShowPlayer
							end,
							set = function(info, val)
								SetOption(val, buffType, 'onlyShowPlayer')
							end
						}
					}
				},
				Sizing = {
					name = 'Sizing & layout',
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
								return module.CurrentSettings[frameName].auras[buffType].size
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
								return module.CurrentSettings[frameName].auras[buffType].spacing
							end,
							set = function(info, val)
								SetOption(val, buffType, 'spacing')
							end
						},
						rows = {
							name = 'Rows',
							type = 'range',
							order = 50,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].rows
							end,
							set = function(info, val)
								SetOption(val, buffType, 'rows')
							end
						},
						initialAnchor = {
							name = 'Buff anchor point',
							type = 'select',
							order = 70,
							values = limitedAnchorPoints,
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].initialAnchor
							end,
							set = function(info, val)
								SetOption(val, buffType, 'initialAnchor')
							end
						},
						growthx = {
							name = 'Growth x',
							type = 'select',
							order = 71,
							values = {
								['RIGHT'] = 'RIGHT',
								['LEFT'] = 'LEFT'
							},
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].growthx
							end,
							set = function(info, val)
								SetOption(val, buffType, 'growthx')
							end
						},
						growthy = {
							name = 'Growth y',
							type = 'select',
							order = 72,
							values = {
								['UP'] = 'UP',
								['DOWN'] = 'DOWN'
							},
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].growthy
							end,
							set = function(info, val)
								SetOption(val, buffType, 'growthy')
							end
						}
					}
				},
				position = {
					name = 'Position',
					type = 'group',
					order = 400,
					inline = true,
					args = {
						x = {
							name = 'X Axis',
							type = 'range',
							order = 1,
							min = -100,
							max = 100,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].position.x
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].auras[buffType].position.x = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].auras[buffType].position.x = val
								--Update Screen
								module.frames[frameName]:UpdateAuras()
							end
						},
						y = {
							name = 'Y Axis',
							type = 'range',
							order = 2,
							min = -100,
							max = 100,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].position.y
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].auras[buffType].position.y = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].auras[buffType].position.y = val
								--Update Screen
								module.frames[frameName]:UpdateAuras()
							end
						},
						anchor = {
							name = 'Anchor point',
							type = 'select',
							order = 3,
							values = anchorPoints,
							get = function(info)
								return module.CurrentSettings[frameName].auras[buffType].position.anchor
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].auras[buffType].position.anchor = val
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].auras[buffType].position.anchor = val
								--Update Screen
								module.frames[frameName]:UpdateAuras()
							end
						}
					}
				},
				filters = {
					name = L['Filters'],
					inline = true,
					type = 'group',
					order = 500,
					get = function(info)
						return module.CurrentSettings[frameName].auras[buffType].filters[info[#info]]
					end,
					set = function(info, value)
						print(info)
						print(#info)
						module.CurrentSettings[frameName].auras[buffType].filters[info[#info]] = value
						--Update memory
						module.CurrentSettings[frameName].auras[buffType].filters[info[#info]] = val
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].auras[buffType].filters[info[#info]] = val
						--Update Screen
						module.frames[frameName]:UpdateAuras()
					end,
					args = {
						minDuration = {
							order = 1,
							type = 'range',
							name = L['Minimum Duration'],
							desc = L["Don't display auras that are shorter than this duration (in seconds). Set to zero to disable."],
							min = 0,
							max = 7200,
							step = 1
						},
						maxDuration = {
							order = 2,
							type = 'range',
							name = L['Maximum Duration'],
							desc = L["Don't display auras that are longer than this duration (in seconds). Set to zero to disable."],
							min = 0,
							max = 7200,
							step = 1
						},
						customFilters = {
							order = 3,
							name = L['Custom Filters'],
							desc = L["Go to 'Filters' section of the config."],
							type = 'execute',
							func = function()
								SUI.Lib.AceCD:SelectGroup('SpartanUI', 'BuffFilters')
							end
						},
						basicFilters = {
							order = 4,
							-- sortByValue = true,
							type = 'select',
							name = L['Add basic Filter'],
							desc = L[
								"These filters don't use a list of spells like Custom filters. They are dynamic and based on the WoW API."
							],
							values = function()
								local filters = {}
								local list = {
									-- Whitelists
									Boss = true,
									MyPet = true,
									OtherPet = true,
									Personal = true,
									nonPersonal = true,
									CastByUnit = true,
									notCastByUnit = true,
									Dispellable = true,
									notDispellable = true,
									CastByNPC = true,
									CastByPlayers = true,
									-- Blacklists
									blockNonPersonal = true,
									blockCastByPlayers = true,
									blockNoDuration = true,
									blockDispellable = true,
									blockNotDispellable = true
								}
								for filter in pairs(list) do
									filters[filter] = filter
								end
								return filters
							end,
							set = function(info, value)
								AddBuffFilter(value)
							end
						},
						resetPriority = {
							order = 6,
							name = L['Reset Priority'],
							desc = L['Reset filter priority to the default state.'],
							type = 'execute',
							func = function()
								--Update the DB
								module.DB.UserSettings[module.DB.Style][frameName].auras[buffType].priority = ''
								--Update Screen
								module.frames[frameName]:UpdateAuras()
							end
						},
						-- filterPriority = {
						-- 	order = 7,
						-- 	dragdrop = true,
						-- 	type = 'multiselect',
						-- 	name = L['Filter Priority'],
						-- 	dragOnLeave = function()
						-- 	end, --keep this here
						-- 	dragOnEnter = function(info)
						-- 		carryFilterTo = info.obj.value
						-- 	end,
						-- 	dragOnMouseDown = function(info)
						-- 		carryFilterFrom, carryFilterTo = info.obj.value, nil
						-- 	end,
						-- 	dragOnMouseUp = function(info)
						-- 		filterPriority(auraType, groupName, carryFilterTo, nil, carryFilterFrom) --add it in the new spot
						-- 		carryFilterFrom, carryFilterTo = nil, nil
						-- 	end,
						-- 	dragOnClick = function(info)
						-- 		filterPriority(auraType, groupName, carryFilterFrom, true)
						-- 	end,
						-- 	stateSwitchGetText = function(_, TEXT)
						-- 		local friend, enemy = strmatch(TEXT, '^Friendly:([^,]*)'), strmatch(TEXT, '^Enemy:([^,]*)')
						-- 		local text, blockB, blockS, blockT = friend or enemy or TEXT
						-- 		local SF, localized = E.global.unitframe.specialFilters[text], L[text]
						-- 		if SF and localized and text:match('^block') then
						-- 			blockB, blockS, blockT = localized:match('^%[(.-)](%s?)(.+)')
						-- 		end
						-- 		local filterText = (blockB and format('|cFF999999%s|r%s%s', blockB, blockS, blockT)) or localized or text
						-- 		return (friend and format('|cFF33FF33%s|r %s', _G.FRIEND, filterText)) or
						-- 			(enemy and format('|cFFFF3333%s|r %s', _G.ENEMY, filterText)) or
						-- 			filterText
						-- 	end,
						-- 	stateSwitchOnClick = function(info)
						-- 		filterPriority(auraType, groupName, carryFilterFrom, nil, nil, true)
						-- 	end,
						-- 	values = function()
						-- 		local str = E.db.unitframe.units[groupName][auraType].priority
						-- 		if str == '' then
						-- 			return nil
						-- 		end
						-- 		return {strsplit(',', str)}
						-- 	end,
						-- 	get = function(info, value)
						-- 		local str = E.db.unitframe.units[groupName][auraType].priority
						-- 		if str == '' then
						-- 			return nil
						-- 		end
						-- 		local tbl = {strsplit(',', str)}
						-- 		return tbl[value]
						-- 	end,
						-- 	set = function(info)
						-- 		E.db.unitframe.units[groupName][auraType][info[#info]] = nil -- this was being set when drag and drop was first added, setting it to nil to clear tester profiles of this variable
						-- 		updateFunc(UF, groupName, numUnits)
						-- 	end
						-- },
						spacer1 = {
							order = 8,
							type = 'description',
							fontSize = 'medium',
							name = L['Use drag and drop to rearrange filter priority or right click to remove a filter.'] ..
								'\n' ..
									L[
										'Use Shift+LeftClick to toggle between friendly or enemy or normal state. Normal state will apply the filter to all units.'
									]
						}
					}
				}
			}
		}
	end
end

local function AddGroupOptions(frameName)
	SUI.opt.args.UnitFrames.args[frameName].args['general'].args['Display'] = {
		name = 'Display',
		type = 'group',
		order = 5,
		inline = true,
		get = function(info)
			return module.CurrentSettings[frameName][info[#info]]
		end,
		set = function(info, val)
			local setting = info[#info]

			--Update memory
			module.CurrentSettings[frameName][setting] = val
			--Update the DB
			module.DB.UserSettings[module.DB.Style][frameName][setting] = val
			--Update the screen
			module.frames[frameName]:SetAttribute(setting, val)
		end,
		args = {
			showRaid = {
				name = L['ShowRFrames'],
				type = 'toggle',
				order = 1
			},
			showParty = {
				name = L['PartyDispParty'],
				type = 'toggle',
				order = 2
			},
			showPlayer = {
				name = 'Show player',
				type = 'toggle',
				order = 2
			},
			showSolo = {
				name = 'Show solo',
				type = 'toggle',
				order = 2
			},
			bar1 = {name = L['LayoutConf'], type = 'header', order = 20},
			maxColumns = {
				name = L['MaxCols'],
				type = 'range',
				order = 21,
				width = 'full',
				step = 1,
				min = 1,
				max = 40
			},
			yOffset = {
				name = 'Vertical offset',
				type = 'range',
				order = 23,
				width = 'full',
				step = 1,
				min = -200,
				max = 200
			},
			xOffset = {
				name = 'Horizonal offset',
				type = 'range',
				order = 23,
				width = 'full',
				step = 1,
				min = -200,
				max = 200
			},
			unitsPerColumn = {
				name = L['UnitPerCol'],
				type = 'range',
				order = 22,
				width = 'full',
				step = 1,
				min = 1,
				max = 40
			},
			columnSpacing = {
				name = L['ColSpacing'],
				type = 'range',
				order = 23,
				width = 'full',
				step = 1,
				min = -200,
				max = 200
			}
		}
	}
	if frameName == 'raid' then
		SUI.opt.args.UnitFrames.args[frameName].args.general.args.Display.args.SortOrder = {
			name = 'Sort order',
			type = 'select',
			order = 3,
			values = {['GROUP'] = 'Groups', ['NAME'] = 'Name', ['ASSIGNEDROLE'] = 'Roles'},
			get = function(info)
				return module.CurrentSettings[frameName].mode
			end,
			set = function(info, val)
				--Update memory
				module.CurrentSettings[frameName].mode = val
				--Update the DB
				module.DB.UserSettings[module.DB.Style][frameName].mode = val
				--Update the screen
				local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'
				if val == 'GROUP' then
					groupingOrder = '1,2,3,4,5,6,7,8'
				end
				module.frames.raid:SetAttribute('groupingOrder', groupingOrder)
			end
		}
	end
end

function module:InitializeOptions()
	SUI.opt.args['UnitFrames'] = {
		name = 'Unit frames',
		type = 'group',
		args = {
			BaseStyle = {
				name = 'Base frame style',
				type = 'group',
				inline = true,
				order = 30,
				args = {
					reset = {
						name = 'Reset to base style (Revert customizations)',
						type = 'execute',
						width = 'full',
						order = 900,
						func = function()
							module:ResetSettings()
						end
					}
				}
			},
			EnabledFrame = {
				name = 'Enabled frames',
				type = 'group',
				inline = true,
				order = 90,
				args = {}
			}
		}
	}
	SUI.opt.args.Help.args.TextTags = {
		name = 'Text tags',
		type = 'group',
		childGroups = 'tab',
		args = {}
	}
	for k, v in pairs(module.TagList) do
		if v.category and not SUI.opt.args.Help.args.TextTags.args[v.category] then
			SUI.opt.args.Help.args.TextTags.args[v.category] = {
				name = v.category,
				type = 'group',
				args = {}
			}
		end
		SUI.opt.args.Help.args.TextTags.args[v.category].args[k] = {
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

	SUI.opt.args.Help.args.SUIModuleHelp.args.ResetUnitFrames = SUI.opt.args.UnitFrames.args.BaseStyle.args.reset
	SUI.opt.args.Help.args.SUIModuleHelp.args.ResetUnitFrames.name = 'Reset unitframe customizations'
	SUI.opt.args.Help.args.SUIModuleHelp.args.ResetUnitFrames.width = 'double'

	for _, v in ipairs(frameList) do
		SUI.opt.args.UnitFrames.args.EnabledFrame.args[v] = {
			name = v,
			type = 'toggle',
			get = function(info)
				return module.CurrentSettings[v].enabled
			end,
			set = function(info, val)
				--Update memory
				module.CurrentSettings[v].enabled = val
				--Update the DB
				module.DB.UserSettings[module.DB.Style][v].enabled = val
				--Update the UI
				if module.frames[v] then
					if val then
						module.frames[v]:Enable()
					elseif module.frames[v] then
						module.frames[v]:Disable()
					end
				end
			end
		}
	end

	-- Build style Buttons
	for styleKey, data in pairs(module.Artwork) do
		local skin = data.skin or styleKey

		SUI.opt.args.UnitFrames.args.BaseStyle.args[skin] = {
			name = data.name or skin,
			type = 'execute',
			image = function()
				return data.image or ('interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_' .. skin), 120, 60
			end,
			imageCoords = function()
				return {0, .5, 0, .5}
			end,
			func = function()
				module:SetActiveStyle(skin)
			end
		}
	end
	SUI.opt.args.UnitFrames.args.BaseStyle.args.Minimal = {
		name = 'Minimal',
		type = 'execute',
		image = function()
			return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_Minimal', 120, 60
		end,
		imageCoords = function()
			return {0, .5, 0, .5}
		end,
		func = function()
			module:SetActiveStyle('Minimal')
		end
	}

	-- Add built skins selection page to the styles section
	SUI.opt.args.General.args.style.args.Unitframes = SUI.opt.args.UnitFrames.args.BaseStyle

	-- Build frame options
	for i, key in ipairs(frameList) do
		CreateOptionSet(key, i)
		AddGeneralOptions(key)
		AddBarOptions(key)
		AddIndicatorOptions(key)
		AddTextOptions(key)
		AddBuffOptions(key)
		AddArtworkOptions(key)
	end

	AddGroupOptions('raid')
	AddGroupOptions('party')
	if SUI.IsRetail then
		AddGroupOptions('boss')
		AddGroupOptions('arena')
	end

	SUI.opt.args.UnitFrames.args.player.args.general.args.General.args.range.hidden = true
end

----------------------------------------------------------------------------------------------------

local function PlayerOptions()
	SUI.opt.args['PlayerFrames'].args['frameDisplay'] = {
		name = 'Disable Frames',
		type = 'group',
		desc = 'Enable and Disable Specific frames',
		args = {
			player = {
				name = L['DispPlayer'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.PlayerFrames.player.display
				end,
				set = function(info, val)
					SUI.DB.PlayerFrames.player.display = val
					if SUI.DB.PlayerFrames.player.display then
						PlayerFrames.player:Enable()
					else
						PlayerFrames.player:Disable()
					end
				end
			},
			pet = {
				name = L['DispPet'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return SUI.DB.PlayerFrames.pet.display
				end,
				set = function(info, val)
					SUI.DB.PlayerFrames.pet.display = val
					if SUI.DB.PlayerFrames.pet.display then
						PlayerFrames.pet:Enable()
					else
						PlayerFrames.pet:Disable()
					end
				end
			},
			target = {
				name = L['DispTarget'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DB.PlayerFrames.target.display
				end,
				set = function(info, val)
					SUI.DB.PlayerFrames.target.display = val
					if SUI.DB.PlayerFrames.target.display then
						PlayerFrames.target:Enable()
					else
						PlayerFrames.target:Disable()
					end
				end
			},
			targettarget = {
				name = L['DispToT'],
				type = 'toggle',
				order = 4,
				get = function(info)
					return SUI.DB.PlayerFrames.targettarget.display
				end,
				set = function(info, val)
					SUI.DB.PlayerFrames.targettarget.display = val
					if SUI.DB.PlayerFrames.targettarget.display then
						PlayerFrames.targettarget:Enable()
					else
						PlayerFrames.targettarget:Disable()
					end
				end
			},
			focustarget = {
				name = L['DispFocusTar'],
				type = 'toggle',
				order = 5,
				get = function(info)
					return SUI.DB.PlayerFrames.focustarget.display
				end,
				set = function(info, val)
					SUI.DB.PlayerFrames.focustarget.display = val
					if SUI.DB.PlayerFrames.focustarget.display then
						PlayerFrames.focustarget:Enable()
					else
						PlayerFrames.focustarget:Disable()
					end
				end
			}
		}
	}
end

function module:UpdateText()
	for i = 1, 5 do
		if _G['SUI_PartyFrameHeaderUnitButton' .. i] then
			local unit = _G['SUI_PartyFrameHeaderUnitButton' .. i]
			if unit then
				unit:TextUpdate()
			end
		end
	end
end
