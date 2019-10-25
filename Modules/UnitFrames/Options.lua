local _G, SUI, L = _G, SUI, SUI.L
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
		'boss',
		'bosstarget',
		'pet',
		'pettarget',
		'party',
		'partypet',
		'partytarget',
		'raid',
		'arena'
	}
end

----------------------------------------------------------------------------------------------------

local function CreateOptionSet(frameName, order)
	SUI.opt.args.UnitFrames.args[frameName] = {
		name = frameName,
		type = 'group',
		order = order,
		childGroups = 'tab',
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
				args = {}
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
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].width = val
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
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Range.enabled = val
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
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Portrait.enabled = val
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
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Portrait.type = val
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
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Portrait.rotation = val
							--Update the screen
							module.frames[frameName]:ElementUpdate('Portrait')
						end
					},
					camDistanceScale = {
						name = 'Camera Distance Scale',
						type = 'range',
						min = -1,
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
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Portrait.camDistanceScale =
								val
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
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Portrait.position = val
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
	local ArtPositions = {['top'] = 'Top', ['bg'] = 'Background', ['bottom'] = 'Bottom'}
	local function ArtworkOptionUpdate(pos, option, val)
		--Update memory
		module.CurrentSettings[frameName].artwork[pos][option] = val
		--Update the DB
		SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].artwork[pos][option] = val
		--Update the screen
		module.frames[frameName]:UpdateArtwork()
	end
	SUI.opt.args.UnitFrames.args[frameName].args['artwork'] = {
		name = 'Artwork',
		type = 'group',
		order = 20,
		args = {}
	}
	local i = 1
	for position, DisplayName in ipairs(ArtPositions) do
		SUI.opt.args.UnitFrames.args[frameName].args.artwork.args[position] = {
			name = DisplayName,
			type = 'group',
			order = i,
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
				}
			}
		}
		i = i + 1
	end

	for Name, data in pairs(module.Artwork) do
		-- if data.full then
		-- 	if data.full.perUnit and not data[frameName] then
		-- 		return
		-- 	end
		-- end
		for position, _ in ipairs(ArtPositions) do
			if data[position] then
				SUI.opt.args.UnitFrames.args[frameName].args.artwork.args[position].args.style.args[Name] = {
					name = (data.name or Name),
					width = 'normal',
					type = 'description',
					image = function()
						return data[position].path, (data[position].x or 160), (data[position].y or 40)
					end,
					imageCoords = function()
						return data[position].TexCoord
					end
				}
			end
		end
	end
end

local function AddBarOptions(frameName)
	SUI.opt.args.UnitFrames.args[frameName].args['bars'] = {
		name = 'Bars',
		type = 'group',
		order = 30,
		childGroups = 'tree',
		args = {
			Castbar = {
				name = 'Castbar',
				type = 'group',
				order = 1,
				args = {
					Interruptable = {
						name = 'Show interrupt or spell steal',
						type = 'toggle',
						order = 10,
						get = function(info)
							return module.CurrentSettings[frameName].elements.Castbar.interruptable
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Castbar.interruptable = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Castbar.interruptable = val
							--Update the screen
							module.frames[frameName]:UpdateAll()
						end
					},
					latency = {
						name = 'Show latency',
						type = 'toggle',
						order = 11,
						get = function(info)
							return module.CurrentSettings[frameName].elements.Castbar.latency
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Castbar.latency = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Castbar.latency = val
							--Update the screen
							module.frames[frameName]:UpdateAll()
						end
					},
					Icon = {
						name = 'Spell icon',
						type = 'group',
						inline = true,
						order = 30,
						args = {
							enabled = {
								name = 'Enable',
								type = 'toggle',
								order = 1,
								get = function(info)
									return module.CurrentSettings[frameName].elements.Castbar.Icon.enabled
								end,
								set = function(info, val)
									--Update memory
									module.CurrentSettings[frameName].elements.Castbar.Icon.enabled = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Castbar.Icon.enabled = val
									--Update the screen
									module.frames[frameName]:UpdateAll()
								end
							},
							size = {
								name = 'Size',
								type = 'range',
								min = 0,
								max = 100,
								step = .1,
								order = 5,
								get = function(info)
									return module.CurrentSettings[frameName].elements.Castbar.Icon.size
								end,
								set = function(info, val)
									--Update memory
									module.CurrentSettings[frameName].elements.Castbar.Icon.size = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Castbar.Icon.size = val
									--Update Screen
									if module.frames[frameName].Castbar.Icon then
										module.frames[frameName].Castbar.Icon:SetSize(val, val)
									end
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
										min = -100,
										max = 100,
										step = 1,
										get = function(info)
											return module.CurrentSettings[frameName].elements.Castbar.Icon.position.x
										end,
										set = function(info, val)
											--Update memory
											module.CurrentSettings[frameName].elements.Castbar.Icon.position.x = val
											--Update the DB
											SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Castbar.Icon.position.x =
												val
											--Update Screen
											module.frames[frameName]:UpdateAll()
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
											return module.CurrentSettings[frameName].elements.Castbar.Icon.position.y
										end,
										set = function(info, val)
											--Update memory
											module.CurrentSettings[frameName].elements.Castbar.Icon.position.y = val
											--Update the DB
											SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Castbar.Icon.position.y =
												val
											--Update Screen
											module.frames[frameName]:UpdateAll()
										end
									},
									anchor = {
										name = 'Anchor point',
										type = 'select',
										order = 3,
										values = anchorPoints,
										get = function(info)
											return module.CurrentSettings[frameName].elements.Castbar.Icon.position.anchor
										end,
										set = function(info, val)
											--Update memory
											module.CurrentSettings[frameName].elements.Castbar.Icon.position.anchor = val
											--Update the DB
											SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Castbar.Icon.position.anchor =
												val
											--Update Screen
											module.frames[frameName]:UpdateAll()
										end
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
				args = {
					healthprediction = {
						name = 'Health prediction',
						type = 'toggle',
						order = 5,
						get = function(info)
							return module.CurrentSettings[frameName].elements.HealthPrediction
						end,
						set = function(info, val)
							--Update the screen
							module.frames[frameName].HealthPrediction = val
							--Update memory
							module.CurrentSettings[frameName].elements.HealthPrediction = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.HealthPrediction = val
						end
					},
					DispelHighlight = {
						name = 'Dispel highlight',
						type = 'toggle',
						order = 5,
						get = function(info)
							return module.CurrentSettings[frameName].elements.DispelHighlight
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.DispelHighlight = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.DispelHighlight = val
							--Update the screen
							module.frames[frameName]:UpdateAll()
						end
					},
					coloring = {
						name = 'Color health bar by:',
						desc = 'The below options are in order of wich they apply',
						order = 10,
						inline = true,
						type = 'group',
						args = {
							colorTapping = {
								name = 'Tapped',
								desc = "Color's the bar if the unit isn't tapped by the player",
								type = 'toggle',
								order = 1,
								get = function(info)
									return module.CurrentSettings[frameName].elements.Health.colorTapping
								end,
								set = function(info, val)
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorTapping = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorTapping = val
									--Update the screen
									module.frames[frameName]:UpdateAll()
								end
							},
							colorDisconnected = {
								name = 'Disconnected',
								desc = 'Color the bar if the player is offline',
								type = 'toggle',
								order = 2,
								get = function(info)
									return module.CurrentSettings[frameName].elements.Health.colorDisconnected
								end,
								set = function(info, val)
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorDisconnected = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorDisconnected =
										val
									--Update the screen
									module.frames[frameName]:UpdateAll()
								end
							},
							colorClass = {
								name = 'Class',
								desc = 'Color the bar based on unit class',
								type = 'toggle',
								order = 3,
								get = function(info)
									return module.CurrentSettings[frameName].elements.Health.colorClass
								end,
								set = function(info, val)
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorClass = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorClass = val
									--Update the screen
									module.frames[frameName]:UpdateAll()
								end
							},
							colorReaction = {
								name = 'Reaction',
								desc = "color the bar based on the player's reaction towards the player.",
								type = 'toggle',
								order = 4,
								get = function(info)
									return module.CurrentSettings[frameName].elements.Health.colorReaction
								end,
								set = function(info, val)
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorReaction = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorReaction = val
									--Update the screen
									module.frames[frameName]:UpdateAll()
								end
							},
							colorSmooth = {
								name = 'Smooth',
								desc = "color the bar with a smooth gradient based on the player's current health percentage",
								type = 'toggle',
								order = 5,
								get = function(info)
									return module.CurrentSettings[frameName].elements.Health.colorSmooth
								end,
								set = function(info, val)
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorSmooth = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorSmooth = val
									--Update the screen
									module.frames[frameName]:UpdateAll()
								end
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
		SUI.opt.args.UnitFrames.args[frameName].args['bars'].args[key].args['enabled'] = {
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
				SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].enabled = val
				--Update the screen
				module.frames[frameName]:UpdateAll()
			end
		}
		SUI.opt.args.UnitFrames.args[frameName].args['bars'].args[key].args['height'] = {
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
				SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].height = val
				--Update the screen
				module.frames[frameName]:UpdateSize()
			end
		}
	end

	if frameName == 'player' then
		if not SUI.IsClassic then
			SUI.opt.args.UnitFrames.args.player.args['bars'].args['Power'].args['PowerPrediction'] = {
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
					SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style].player.elements.Power.PowerPrediction = val
				end
			}
		end

		SUI.opt.args.UnitFrames.args.player.args['bars'].args['AdditionalPower'] = {
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
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style].player.elements.AdditionalPower.enabled = val
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
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style].player.elements.AdditionalPower.height = val
						--Update the screen
						module.frames.player:UpdateSize()
					end
				}
			}
		}
	end

	local friendly = {'player', 'party', 'raid', 'target', 'focus', 'targettarget', 'focustarget'}
	if not SUI:isInTable(friendly, frameName) then
		SUI.opt.args.UnitFrames.args[frameName].args['bars'].args['Health'].args['DispelHighlight'].hidden = true
	end

	if frameName == 'player' or frameName == 'party' or frameName == 'raid' then
		SUI.opt.args.UnitFrames.args[frameName].args['bars'].args['Castbar'].args['Interruptable'].hidden = true
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
		['QuestIndicator'] = 'Quest'
	}
	local AllIndicators = {
		['SUI_ClassIcon'] = 'Class icon',
		['RaidTargetIndicator'] = RAID_TARGET_ICON,
		['ThreatIndicator'] = 'Threat'
	}

	-- Text indicators
	-- ['StatusText'] = STATUS_TEXT,
	-- ['SUI_RaidGroup'] = 'Raid group'

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
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].enabled = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].size = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].scale = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].alpha = val
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
							min = -100,
							max = 100,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].position.x
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.x = val
								--Update the DB
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].position.x = val
								--Update Screen
								module.frames[frameName]:ElementUpdate(key)
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
								return module.CurrentSettings[frameName].elements[key].position.y
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.y = val
								--Update the DB
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].position.y = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].position.anchor = val
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
		SUI.opt.args.UnitFrames.args[frameName].args.indicators.args.PvPIndicator.args['Badge'] = {
			name = 'Show honor badge',
			type = 'toggle',
			get = function(info)
				return module.CurrentSettings[frameName].elements.PvPIndicator.badge
			end,
			set = function(info, val)
				--Update memory
				module.CurrentSettings[frameName].elements.PvPIndicator.badge = val
				--Update the DB
				SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.PvPIndicator.badge = val
				--Update the screen
				if val then
					module.frames[frameName].PvPIndicator.Badge = module.frames[frameName].PvPIndicator.BadgeBackup
				else
					module.frames[frameName].PvPIndicator.Badge:Hide()
					module.frames[frameName].PvPIndicator.Badge = nil
				end
				module.frames[frameName].PvPIndicator:ForceUpdate('OnUpdate')
			end
		}
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
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Range.enabled = val
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
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Range.insideAlpha = val
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
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Range.outsideAlpha = val
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
					SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[element].text[count].enabled =
						val
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
					SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[element].text[count].text = val
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
					SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[element].text[count].size = val
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
						min = -100,
						max = 100,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].elements[element].text[count].position.x
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements[element].text[count].position.x = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[element].text[count].position.x =
								val
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
						min = -100,
						max = 100,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].elements[element].text[count].position.y
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements[element].text[count].position.y = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[element].text[count].position.y =
								val
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
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[element].text[count].position.anchor =
								val
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
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].enabled = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].text = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].size = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].SetJustifyH = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].SetJustifyV = val
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
							min = -100,
							max = 100,
							step = 1,
							get = function(info)
								return module.CurrentSettings[frameName].elements[key].position.x
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.x = val
								--Update the DB
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].position.x = val
								--Update the screen
								module.frames[frameName]:ElementUpdate(key)
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
								return module.CurrentSettings[frameName].elements[key].position.y
							end,
							set = function(info, val)
								--Update memory
								module.CurrentSettings[frameName].elements[key].position.y = val
								--Update the DB
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].position.y = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements[key].position.anchor = val
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
		SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].auras[buffType][setting] = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].auras[buffType].position.x = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].auras[buffType].position.y = val
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
								SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].auras[buffType].position.anchor = val
								--Update Screen
								module.frames[frameName]:UpdateAuras()
							end
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
		args = {
			toggleraid = {
				name = L['ShowRFrames'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return module.CurrentSettings[frameName].showRaid
				end,
				set = function(info, val)
					module.CurrentSettings[frameName].showRaid = val
				end
			},
			toggleparty = {
				name = L['PartyDispParty'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return module.CurrentSettings[frameName].showParty
				end,
				set = function(info, val)
					module.CurrentSettings[frameName].showParty = val
				end
			},
			bar1 = {name = L['LayoutConf'], type = 'header', order = 20},
			maxColumns = {
				name = L['MaxCols'],
				type = 'range',
				order = 21,
				width = 'full',
				step = 1,
				min = 1,
				max = 40,
				get = function(info)
					return module.CurrentSettings[frameName].maxColumns
				end,
				set = function(info, val)
					module.CurrentSettings[frameName].maxColumns = val
				end
			},
			unitsPerColumn = {
				name = L['UnitPerCol'],
				type = 'range',
				order = 22,
				width = 'full',
				step = 1,
				min = 1,
				max = 40,
				get = function(info)
					return module.CurrentSettings[frameName].unitsPerColumn
				end,
				set = function(info, val)
					module.CurrentSettings[frameName].unitsPerColumn = val
				end
			},
			columnSpacing = {
				name = L['ColSpacing'],
				type = 'range',
				order = 23,
				width = 'full',
				step = 1,
				min = 0,
				max = 200,
				get = function(info)
					return module.CurrentSettings[frameName].columnSpacing
				end,
				set = function(info, val)
					module.CurrentSettings[frameName].columnSpacing = val
				end
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
				SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].mode = val
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
							--Reset the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style] = nil
							-- Refresh the memory
							module:LoadDB()

							-- Update the screen
							for _, frame in pairs(module.frames) do
								-- Check that its a frame
								if frame.UpdateAll then
									frame:UpdateAll()
								end
							end
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
	local Skins = {
		'Classic',
		'War',
		'Fel',
		'Digital',
		'Arcane',
		'Transparent',
		'Minimal'
	}

	for _, v in ipairs(frameList) do
		SUI.opt.args.UnitFrames.args.EnabledFrame.args[v] = {
			name = v,
			type = 'toggle',
			get = function(info)
				return module.CurrentSettings[v].enabled
			end,
			set = function(info, val)
				module.CurrentSettings[v].enabled = val
				SUI.opt.args.UnitFrames.args[v].disabled = (not val)

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
	for _, skin in pairs(Skins) do
		SUI.opt.args.UnitFrames.args.BaseStyle.args[skin] = {
			name = skin,
			type = 'execute',
			image = function()
				return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_' .. skin, 120, 60
			end,
			imageCoords = function()
				return {0, .5, 0, .5}
			end,
			func = function()
				SUI.DB.Unitframes.Style = skin
			end
		}
	end

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

		if key == 'player' or key == 'target' or key == 'party' or key == 'boss' then
			AddArtworkOptions(key)
		end
	end

	AddGroupOptions('raid')
	AddGroupOptions('party')
	AddGroupOptions('boss')
	AddGroupOptions('arena')

	SUI.opt.args.UnitFrames.args.player.args.general.args.General.args.range.hidden = true
end

----------------------------------------------------------------------------------------------------

function PlayerOptions()
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
					return SUI.DBMod.PlayerFrames.player.display
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.player.display = val
					if SUI.DBMod.PlayerFrames.player.display then
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
					return SUI.DBMod.PlayerFrames.pet.display
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.pet.display = val
					if SUI.DBMod.PlayerFrames.pet.display then
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
					return SUI.DBMod.PlayerFrames.target.display
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.target.display = val
					if SUI.DBMod.PlayerFrames.target.display then
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
					return SUI.DBMod.PlayerFrames.targettarget.display
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.targettarget.display = val
					if SUI.DBMod.PlayerFrames.targettarget.display then
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
					return SUI.DBMod.PlayerFrames.focustarget.display
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.focustarget.display = val
					if SUI.DBMod.PlayerFrames.focustarget.display then
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
