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
				name = L['Indicators'],
				type = 'group',
				order = 40,
				childGroups = 'tree',
				args = {}
			},
			text = {
				name = L['Text'],
				type = 'group',
				order = 50,
				childGroups = 'tree',
				args = {
					execute = {
						name = L['Text tag list'],
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
		name = L['General'],
		desc = L['General display settings'],
		type = 'group',
		-- childGroups = 'inline',
		order = 10,
		args = {
			General = {
				name = L['General'],
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
						name = L['Fade out of range'],
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
				name = L['Portrait'],
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
						name = L['Portrait type'],
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
						name = L['Rotation'],
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
						name = L['Camera Distance Scale'],
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
						name = L['Position'],
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
		name = L['Artwork'],
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
					name = L['Enabled'],
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
					name = L['Current Style'],
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
					name = L['Style'],
					type = 'group',
					order = 3,
					inline = true,
					args = {}
				},
				settings = {
					name = L['Settings'],
					type = 'group',
					inline = true,
					order = 500,
					args = {
						alpha = {
							name = L['Custom alpha'],
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
		name = L['Bars'],
		type = 'group',
		order = 30,
		childGroups = 'tree',
		args = {
			Castbar = {
				name = L['Castbar'],
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
						name = L['Interrupt flash speed'],
						type = 'range',
						width = 'double',
						min = .01,
						max = 1,
						step = .01,
						order = 11
					},
					interruptable = {
						name = L['Show interrupt or spell steal'],
						type = 'toggle',
						width = 'double',
						order = 20
					},
					latency = {
						name = L['Show latency'],
						type = 'toggle',
						order = 21
					},
					Icon = {
						name = L['Spell icon'],
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
								name = L['Enable'],
								type = 'toggle',
								order = 1
							},
							size = {
								name = L['Size'],
								type = 'range',
								min = 0,
								max = 100,
								step = .1,
								order = 5
							},
							position = {
								name = L['Position'],
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
										name = L['X Axis'],
										type = 'range',
										order = 1,
										min = -100,
										max = 100,
										step = 1
									},
									y = {
										name = L['Y Axis'],
										type = 'range',
										order = 2,
										min = -100,
										max = 100,
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
				}
			},
			Health = {
				name = L['Health'],
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
						name = L['Health prediction'],
						type = 'toggle',
						order = 5
					},
					DispelHighlight = {
						name = L['Dispel highlight'],
						type = 'toggle',
						order = 5
					},
					coloring = {
						name = L['Color health bar by:'],
						desc = L['The below options are in order of wich they apply'],
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
								name = L['Tapped'],
								desc = "Color's the bar if the unit isn't tapped by the player",
								type = 'toggle',
								order = 1
							},
							colorDisconnected = {
								name = L['Disconnected'],
								desc = L['Color the bar if the player is offline'],
								type = 'toggle',
								order = 2
							},
							colorClass = {
								name = L['Class'],
								desc = L['Color the bar based on unit class'],
								type = 'toggle',
								order = 3
							},
							colorReaction = {
								name = L['Reaction'],
								desc = "color the bar based on the player's reaction towards the player.",
								type = 'toggle',
								order = 4
							},
							colorSmooth = {
								name = L['Smooth'],
								desc = "color the bar with a smooth gradient based on the player's current health percentage",
								type = 'toggle',
								order = 5
							}
						}
					}
				}
			},
			Power = {
				name = L['Power'],
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
			name = L['Height'],
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
			name = L['Background'],
			type = 'group',
			inline = true,
			order = 200,
			args = {
				enabled = {
					name = L['Enable'],
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
					name = L['Color'],
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
				name = L['Enable power prediction'],
				desc = L['Used to represent cost of spells on top of the Power bar'],
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
			name = L['Additional power'],
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
					name = L['Height'],
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
	if frameName == 'pet' and (SUI.IsClassic or SUI.IsBCC) then
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
							name = L['Scale'],
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
							name = L['Alpha'],
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
					name = L['Position'],
					type = 'group',
					order = 50,
					inline = true,
					args = {
						x = {
							name = L['X Axis'],
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
							name = L['Y Axis'],
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
							name = L['Anchor point'],
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
			name = L['Range'],
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
					name = L['In range alpha'],
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
					name = L['Out of range alpha'],
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
		name = L['Text element'] .. ' ' .. count,
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
				name = L['Text'],
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
				name = L['Size'],
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
				name = L['Position'],
				type = 'group',
				order = 50,
				inline = true,
				args = {
					x = {
						name = L['X Axis'],
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
						name = L['Y Axis'],
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
						name = L['Anchor point'],
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
		name = L['Castbar'],
		type = 'group',
		order = 1,
		args = {}
	}
	SUI.opt.args.UnitFrames.args[frameName].args['text'].args['Health'] = {
		name = L['Health'],
		type = 'group',
		order = 2,
		args = {}
	}
	SUI.opt.args.UnitFrames.args[frameName].args['text'].args['Power'] = {
		name = L['Power'],
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
							name = L['Text'],
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
							name = L['Size'],
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
							name = L['Horizontal alignment'],
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
							name = L['Vertical alignment'],
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
					name = L['Position'],
					type = 'group',
					order = 50,
					inline = true,
					args = {
						x = {
							name = L['X Axis'],
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
							name = L['Y Axis'],
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
							name = L['Anchor point'],
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
		name = L['Buffs & Debuffs'],
		desc = L['Buff & Debuff display settings'],
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
					name = L['Display settings'],
					type = 'group',
					order = 100,
					inline = true,
					get = function(info)
						return module.CurrentSettings[frameName].auras[buffType][info[#info]]
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
							name = L['Rows'],
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
							name = L['Buff anchor point'],
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
							name = L['Growth x'],
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
							name = L['Growth y'],
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
							name = L['Y Axis'],
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
							name = L['Anchor point'],
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
					type = 'group',
					order = 500,
					get = function(info)
						return module.CurrentSettings[frameName].auras[buffType].filters[info[#info]]
					end,
					set = function(info, value)
						--Update memory
						module.CurrentSettings[frameName].auras[buffType].filters[info[#info]] = value
						--Update the DB
						module.DB.UserSettings[module.DB.Style][frameName].auras[buffType].filters[info[#info]] = value
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

local function AddGroupOptions(frameName)
	SUI.opt.args.UnitFrames.args[frameName].args['general'].args['Display'] = {
		name = L['Display'],
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
			},
			bar1 = {name = L['Layout Configuration'], type = 'header', order = 20},
			maxColumns = {
				name = L['Max Columns'],
				type = 'range',
				order = 21,
				width = 'full',
				step = 1,
				min = 1,
				max = 40
			},
			yOffset = {
				name = L['Vertical offset'],
				type = 'range',
				order = 23,
				width = 'full',
				step = 1,
				min = -200,
				max = 200
			},
			xOffset = {
				name = L['Horizonal offset'],
				type = 'range',
				order = 23,
				width = 'full',
				step = 1,
				min = -200,
				max = 200
			},
			unitsPerColumn = {
				name = L['Units Per Column'],
				type = 'range',
				order = 22,
				width = 'full',
				step = 1,
				min = 1,
				max = 40
			},
			columnSpacing = {
				name = L['Column Spacing'],
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
			name = L['Sort order'],
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
		name = L['Unit frames'],
		type = 'group',
		args = {
			BaseStyle = {
				name = L['Base frame style'],
				type = 'group',
				inline = true,
				order = 30,
				args = {
					reset = {
						name = L['Reset to base style (Revert customizations)'],
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
				name = L['Enabled frames'],
				type = 'group',
				inline = true,
				order = 90,
				args = {}
			}
		}
	}
	SUI.opt.args.Help.args.TextTags = {
		name = L['Text tags'],
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
	SUI.opt.args.Help.args.SUIModuleHelp.args.ResetUnitFrames.name = L['Reset unitframe customizations']
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

function module:ScaleFrames(scale)
	if SUI:IsModuleDisabled('MoveIt') then
		return
	end
	local MoveIt = SUI:GetModule('Component_MoveIt')
	for _, v in ipairs(frameList) do
		if module.frames[v] and module.frames[v].mover then
			local newScale = module.frames[v].mover.defaultScale * (scale + .08) -- Add .08 to use .92 (the default scale) as 1.
			module.frames[v]:scale(newScale)
		end
	end
end
----------------------------------------------------------------------------------------------------

local function PlayerOptions()
	SUI.opt.args['PlayerFrames'].args['frameDisplay'] = {
		name = L['Disable Frames'],
		type = 'group',
		desc = L['Enable and Disable Specific frames'],
		args = {
			player = {
				name = L['Display player'],
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
				name = L['Display Pets'],
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
				name = L["Show Party's Target"],
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
				name = L['Display Target of Target'],
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
				name = L['Display focus target'],
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
