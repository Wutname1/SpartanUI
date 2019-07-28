local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:GetModule('Module_UnitFrames')
----------------------------------------------------------------------------------------------------
local anchorPoints = {
	['TOPLEFT'] = 'TOPLEFT',
	['TOP'] = 'TOP',
	['TOPRIGHT'] = 'TOPRIGHT',
	['RIGHT'] = 'RIGHT',
	['CENTER'] = 'CENTER',
	['LEFT'] = 'LEFT',
	['BOTTOMLEFT'] = 'BOTTOMLEFT',
	['BOTTOM'] = 'BOTTOM',
	['BOTTOMRIGHT'] = 'BOTTOMRIGHT'
}
local elementList = {
	'Portrait',
	'Health',
	'HealthPrediction',
	'Power',
	'Castbar',
	'Name',
	'LeaderIndicator',
	'RestingIndicator',
	'GroupRoleIndicator',
	'CombatIndicator',
	'RaidTargetIndicator',
	'SUI_ClassIcon',
	'ReadyCheckIndicator',
	'PvPIndicator',
	'StatusText',
	'Runes',
	'Stagger',
	'Totems',
	'AssistantIndicator',
	'RaidRoleIndicator',
	'ResurrectIndicator',
	'SummonIndicator',
	'QuestIndicator',
	'Range',
	'phaseindicator',
	'ThreatIndicator',
	'SUI_RaidGroup'
}
local IndicatorList = {
	'LeaderIndicator',
	'RestingIndicator',
	'GroupRoleIndicator',
	'CombatIndicator',
	'RaidTargetIndicator',
	'SUI_ClassIcon',
	'ReadyCheckIndicator',
	'PvPIndicator',
	'AssistantIndicator',
	'RaidRoleIndicator',
	'ResurrectIndicator',
	'SummonIndicator',
	'QuestIndicator',
	'phaseindicator',
	'ThreatIndicator',
	'SUI_RaidGroup'
}
----------------------------------------------------------------------------------------------------

local function CreateOptionSet(frameName, order)
	SUI.opt.args['UnitFrames'].args[frameName] = {
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
	SUI.opt.args['UnitFrames'].args[frameName].args['general'] = {
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
							module.frames[frameName].UpdateSize()
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
							if val then
								module.frames[frameName]:EnableElement('Range')
								module.frames[frameName].Range:ForceUpdate()
							else
								module.frames[frameName]:DisableElement('Range')
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
							--Update the screen
							if val then
								module.frames[frameName]:EnableElement('Portrait')
								module.frames[frameName].Portrait:ForceUpdate()
							else
								module.frames[frameName]:DisableElement('Portrait')
							end
							--Update memory
							module.CurrentSettings[frameName].elements.Portrait.enabled = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Portrait.enabled = val
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
							--Update the screen
							-- module.frames[frameName]:DisableElement('Portrait')
							module.frames[frameName].Portrait3D:Hide()
							module.frames[frameName].Portrait2D:Hide()
							if val == '3D' then
								module.frames[frameName].Portrait = module.frames[frameName].Portrait3D
								module.frames[frameName].Portrait3D:Show()
							else
								module.frames[frameName].Portrait = module.frames[frameName].Portrait2D
								module.frames[frameName].Portrait2D:Show()
							end
							-- module.frames[frameName]:EnableElement('Portrait')
							module.frames[frameName]:UpdateAllElements('OnUpdate')
							--Update memory
							module.CurrentSettings[frameName].elements.Portrait.type = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Portrait.type = val
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
							--Update the screen
							module.frames[frameName].Portrait3D:ClearAllPoints()
							module.frames[frameName].Portrait2D:ClearAllPoints()
							if val == 'left' then
								module.frames[frameName].Portrait3D:SetPoint('RIGHT', module.frames[frameName], 'LEFT')
								module.frames[frameName].Portrait2D:SetPoint('RIGHT', module.frames[frameName], 'LEFT')
							else
								module.frames[frameName].Portrait3D:SetPoint('LEFT', module.frames[frameName], 'RIGHT')
								module.frames[frameName].Portrait2D:SetPoint('LEFT', module.frames[frameName], 'RIGHT')
							end
							--Update memory
							module.CurrentSettings[frameName].elements.Portrait.position = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Portrait.position = val
						end
					}
				}
			}
		}
	}
end

local function AddArtworkOptions(frameName)
	SUI.opt.args['UnitFrames'].args[frameName].args['artwork'] = {
		name = 'Artwork',
		type = 'group',
		order = 20,
		args = {
			top = {
				name = 'Top',
				type = 'group',
				order = 1,
				inline = true,
				args = {
					War = {
						name = 'War',
						order = 1.1,
						type = 'description',
						width = 'normal',
						image = function()
							return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_War', 120, 40
						end,
						imageCoords = function()
							return {0, .5, 0, 0.203125}
						end
					},
					Fel = {
						name = 'War',
						order = 1.2,
						width = 'normal',
						type = 'description',
						image = function()
							return 'Interface\\Scenarios\\LegionInvasion', 120, 40
						end,
						imageCoords = function()
							return {0.140625, 0.615234375, 0, 0.14453125}
						end
					},
					enabled = {
						name = 'Enabled',
						type = 'toggle',
						order = 2,
						get = function(info)
							return module.CurrentSettings[frameName].artwork.top.enabled
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].artwork.top.enabled = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].artwork.top.enabled = val
						end
					},
					x = {
						name = 'X Axis',
						type = 'range',
						min = -100,
						max = 100,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].artwork.top.x
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].artwork.top.x = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].artwork.top.x = val
						end
					},
					y = {
						name = 'Y Axis',
						type = 'range',
						min = -100,
						max = 100,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].artwork.top.y
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].artwork.top.y = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].artwork.top.y = val
						end
					},
					StyleDropdown = {
						name = 'Current Style',
						type = 'select',
						order = 3,
						values = {
							['war'] = 'War',
							['fel'] = 'Fel'
						},
						get = function(info)
							return module.CurrentSettings[frameName].artwork.top.graphic
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].artwork.top.graphic = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].artwork.top.graphic = val
						end
					}
				}
			}
		}
	}
end

local function AddBarOptions(frameName)
	SUI.opt.args['UnitFrames'].args[frameName].args['bars'] = {
		name = 'Bars',
		type = 'group',
		order = 30,
		childGroups = 'tree',
		args = {
			Castbar = {
				name = 'Castbar',
				type = 'group',
				order = 1,
				childGroups = 'inline',
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
							if val then
								self.Castbar.SafeZone:Show()
							else
								self.Castbar.SafeZone:Hide()
							end
						end
					},
					latency = {
						name = 'Show latency',
						type = 'toggle',
						order = 10,
						get = function(info)
							return module.CurrentSettings[frameName].elements.Castbar.latency
						end,
						set = function(info, val)
							--Update memory
							module.CurrentSettings[frameName].elements.Castbar.latency = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Castbar.latency = val
							--Update the screen
							if val then
								self.Castbar.Shield:Show()
							else
								self.Castbar.Shield:Hide()
							end
						end
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
						desc = "color the bar with a smooth gradient based on the player's current health percentage",
						type = 'toggle',
						order = 5,
						get = function(info)
							return module.CurrentSettings[frameName].elements.Health.colorSmooth
						end,
						set = function(info, val)
							--Update the screen
							module.frames[frameName].Health.colorSmooth = val
							--Update memory
							module.CurrentSettings[frameName].elements.Health.colorSmooth = val
							--Update the DB
							SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorSmooth = val
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
									--Update the screen
									module.frames[frameName].Health.colorTapping = val
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorTapping = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorTapping = val
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
									--Update the screen
									module.frames[frameName].Health.colorDisconnected = val
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorDisconnected = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorDisconnected =
										val
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
									--Update the screen
									module.frames[frameName].Health.colorClass = val
									module.frames[frameName].Health:ForceUpdate()
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorClass = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorClass = val
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
									--Update the screen
									module.frames[frameName].Health.colorReaction = val
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorReaction = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorReaction = val
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
									--Update the screen
									module.frames[frameName].Health.colorSmooth = val
									--Update memory
									module.CurrentSettings[frameName].elements.Health.colorSmooth = val
									--Update the DB
									SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Health.colorSmooth = val
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
	for i, key in ipairs(bars) do
		SUI.opt.args['UnitFrames'].args[frameName].args['bars'].args[key].args['enabled'] = {
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
					module.frames[frameName]:EnableElement(key)
				else
					module.frames[frameName]:DisableElement(key)
				end
				module.frames[frameName].UpdateSize()
			end
		}
		SUI.opt.args['UnitFrames'].args[frameName].args['bars'].args[key].args['height'] = {
			name = 'Height',
			type = 'range',
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
				module.frames[frameName].UpdateSize()
			end
		}
	end

	if frameName == 'player' then
		SUI.opt.args['UnitFrames'].args[frameName].args['bars'].args['Power'].args['PowerPrediction'] = {
			name = 'Enable power prediction',
			desc = 'Used to represent cost of spells on top of the Power bar',
			type = 'toggle',
			order = 10,
			get = function(info)
				return module.CurrentSettings[frameName].elements.Power.PowerPrediction
			end,
			set = function(info, val)
				--Update the screen
				if val then
					module.frames[frameName]:EnableElement('PowerPrediction')
				else
					module.frames[frameName]:DisableElement('PowerPrediction')
				end
				--Update memory
				module.CurrentSettings[frameName].elements.Power.PowerPrediction = val
				--Update the DB
				SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.Power.PowerPrediction = val
			end
		}
		SUI.opt.args['UnitFrames'].args[frameName].args['bars'].args['additionalpower'] = {
			name = 'Additional power',
			desc = "player's additional power, such as Mana for Balance druids.",
			order = 20,
			type = 'group',
			childGroups = 'inline',
			args = {
				enabled = {
					name = L['Enabled'],
					type = 'toggle',
					order = 1,
					get = function(info)
						return module.CurrentSettings[frameName].elements.additionalpower.enabled
					end,
					set = function(info, val)
						--Update the screen
						if val then
							module.frames[frameName]:EnableElement('AdditionalPower')
						else
							module.frames[frameName]:DisableElement('AdditionalPower')
						end
						--Update memory
						module.CurrentSettings[frameName].elements.additionalpower.enabled = val
						--Update the DB
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.additionalpower.enabled = val
					end
				},
				height = {
					name = 'Height',
					type = 'range',
					order = 2,
					min = 2,
					max = 100,
					step = 1,
					get = function(info)
						return module.CurrentSettings[frameName].elements.additionalpower.height
					end,
					set = function(info, val)
						--Update memory
						module.CurrentSettings[frameName].elements.additionalpower.height = val
						--Update the DB
						SUI.DB.Unitframes.PlayerCustomizations[SUI.DB.Unitframes.Style][frameName].elements.additionalpower.height = val
						--Update the screen
						module.frames[frameName].UpdateSize()
					end
				}
			}
		}
	end

	if module:IsFriendlyFrame(frameName) then
		SUI.opt.args['UnitFrames'].args[frameName].args['bars'].args['Castbar'].args['Interruptable'].hidden = true
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
		['phaseindicator'] = 'Phase',
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
								module.frames[frameName][key]:SetSize(val, val)
							end
						},
						scale = {
							name = 'Scale',
							type = 'range',
							min = 0,
							max = 30,
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

	-- Hide a few generated options from specific frame
	if frameName == 'player' then
		SUI.opt.args['UnitFrames'].args[frameName].args['indicators'].args['ThreatIndicator'].hidden = true
	elseif frameName == 'boss' then
		SUI.opt.args['UnitFrames'].args[frameName].args['indicators'].args['SUI_ClassIcon'].hidden = true
	end
end

local function AddDynamicText(frameName, element, count)
	SUI.opt.args['UnitFrames'].args[frameName].args['text'].args[element].args[count] = {
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
	SUI.opt.args['UnitFrames'].args[frameName].args['text'].args['Castbar'] = {
		name = 'Castbar',
		type = 'group',
		order = 1,
		args = {}
	}
	SUI.opt.args['UnitFrames'].args[frameName].args['text'].args['Health'] = {
		name = 'Health',
		type = 'group',
		order = 2,
		args = {}
	}
	SUI.opt.args['UnitFrames'].args[frameName].args['text'].args['Power'] = {
		name = 'Power',
		type = 'group',
		order = 3,
		args = {}
	}

	for i in pairs(module.CurrentSettings[frameName].elements.Castbar.text) do
		AddDynamicText(frameName, 'Castbar', i)
	end
	SUI.opt.args['UnitFrames'].args[frameName].args['text'].args['Castbar'].args['1'].args['text'].disabled = true
	SUI.opt.args['UnitFrames'].args[frameName].args['text'].args['Castbar'].args['2'].args['text'].disabled = true

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
		SUI.opt.args['UnitFrames'].args[frameName].args['text'].args[key] = {
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
								module.frames[frameName][key]:UpdatePosition(key)
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
								module.frames[frameName][key]:UpdatePosition(key)
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
								module.frames[frameName][key]:UpdatePosition(key)
							end
						}
					}
				}
			}
		}
	end
end

local function AddBuffOptions(frameName)
	local values = {
		['bars'] = L['Bars'],
		['icons'] = L['Icons'],
		['both'] = L['Both'],
		['disabled'] = L['Disabled']
	}

	SUI.opt.args['UnitFrames'].args[frameName].args['auras'] = {
		name = 'Buffs & Debuffs',
		desc = 'Buff & Debuff display settings',
		type = 'group',
		order = 100,
		args = {
			Notice = {type = 'description', order = .5, fontSize = 'medium', name = L['possiblereloadneeded']},
			Buffs = {
				name = 'Buffs',
				type = 'group',
				inline = true,
				order = 1,
				args = {
					Display = {
						name = L['Display mode'],
						type = 'select',
						order = 15,
						values = values,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Buffs.Mode
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Buffs.Mode = val
							SUI:reloadui()
						end
					},
					Number = {
						name = L['Number to show'],
						type = 'range',
						order = 20,
						min = 1,
						max = 30,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Buffs.Number
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Buffs.Number = val
							if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
								PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
							end
						end
					},
					size = {
						name = L['Size'],
						type = 'range',
						order = 30,
						min = 1,
						max = 30,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Buffs.size
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Buffs.size = val
							if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
								PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
							end
						end
					},
					spacing = {
						name = L['Spacing'],
						type = 'range',
						order = 40,
						min = 1,
						max = 30,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Buffs.spacing
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Buffs.spacing = val
							if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
								PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
							end
						end
					},
					showType = {
						name = L['Show type'],
						type = 'toggle',
						order = 50,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Buffs.showType
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Buffs.showType = val
							if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
								PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
							end
						end
					},
					onlyShowPlayer = {
						name = L['Only show players'],
						type = 'toggle',
						order = 60,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Buffs.onlyShowPlayer
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Buffs.onlyShowPlayer = val
							if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then
								PlayerFrames[unit].Buffs:PostUpdate(unit, 'Buffs')
							end
						end
					}
				}
			},
			Debuffs = {
				name = 'Debuffs',
				type = 'group',
				inline = true,
				order = 2,
				args = {
					Display = {
						name = L['Display mode'],
						type = 'select',
						order = 15,
						values = values,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Debuffs.Mode
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Debuffs.Mode = val
							SUI:reloadui()
						end
					},
					Number = {
						name = L['Number to show'],
						type = 'range',
						order = 20,
						min = 1,
						max = 30,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Debuffs.Number
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Debuffs.Number = val
							if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
								PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
							end
						end
					},
					size = {
						name = L['Size'],
						type = 'range',
						order = 30,
						min = 1,
						max = 30,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Debuffs.size
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Debuffs.size = val
							if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
								PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
							end
						end
					},
					spacing = {
						name = L['Spacing'],
						type = 'range',
						order = 40,
						min = 1,
						max = 30,
						step = 1,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Debuffs.spacing
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Debuffs.spacing = val
							if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
								PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
							end
						end
					},
					showType = {
						name = L['Show type'],
						type = 'toggle',
						order = 50,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Debuffs.showType
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Debuffs.showType = val
							if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
								PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
							end
						end
					},
					onlyShowPlayer = {
						name = L['Only show players'],
						type = 'toggle',
						order = 60,
						get = function(info)
							return module.CurrentSettings[frameName].auras.Debuffs.onlyShowPlayer
						end,
						set = function(info, val)
							module.CurrentSettings[frameName].auras.Debuffs.onlyShowPlayer = val
							if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then
								PlayerFrames[unit].Debuffs:PostUpdate(unit, 'Debuffs')
							end
						end
					}
				}
			}
		}
	}
end

local function AddRaidOptions()
	SUI.opt.args['UnitFrames'].args['raid'].args['general'].args['Display'] = {
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
					return module.CurrentSettings.raid.showRaid
				end,
				set = function(info, val)
					module.CurrentSettings.raid.showRaid = val
				end
			},
			toggleparty = {
				name = L['PartyDispParty'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return module.CurrentSettings.raid.showParty
				end,
				set = function(info, val)
					module.CurrentSettings.raid.showParty = val
				end
			},
			togglesolo = {
				name = L['PartyDispSolo'],
				type = 'toggle',
				order = 4,
				get = function(info)
					return module.CurrentSettings.raid.showSolo
				end,
				set = function(info, val)
					module.CurrentSettings.raid.showSolo = val
				end
			},
			mode = {
				name = L['LayMode'],
				type = 'select',
				order = 3,
				values = {['NAME'] = L['LayName'], ['GROUP'] = L['LayGrp'], ['ASSIGNEDROLE'] = L['LayRole']},
				get = function(info)
					return module.CurrentSettings.raid.mode
				end,
				set = function(info, val)
					module.CurrentSettings.raid.mode = val
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
					return module.CurrentSettings.raid.maxColumns
				end,
				set = function(info, val)
					module.CurrentSettings.raid.maxColumns = val
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
					return module.CurrentSettings.raid.unitsPerColumn
				end,
				set = function(info, val)
					module.CurrentSettings.raid.unitsPerColumn = val
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
					return module.CurrentSettings.raid.columnSpacing
				end,
				set = function(info, val)
					module.CurrentSettings.raid.columnSpacing = val
				end
			}
		}
	}
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
				order = 1,
				args = {
					Classic = {
						name = 'Classic',
						type = 'execute',
						image = function()
							return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_Classic', 120, 60
						end,
						imageCoords = function()
							return {0, .5, 0, .5}
						end,
						func = function()
							SUI.DB.Unitframes.Style = 'Classic'
						end
					},
					Arcane = {
						name = 'Arcane',
						type = 'execute',
						image = function()
							return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_Fel', 120, 60
						end,
						imageCoords = function()
							return {.1, .5, .1, .5}
						end,
						func = function()
							SUI.DB.Unitframes.Style = 'Arcane'
						end
					},
					War = {
						name = 'War',
						type = 'execute',
						image = function()
							return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_Fel', 120, 60
						end,
						imageCoords = function()
							return {.1, .5, .1, .5}
						end,
						func = function()
							SUI.DB.Unitframes.Style = 'War'
						end
					},
					Fel = {
						name = 'Fel',
						type = 'execute',
						image = function()
							return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_Fel', 120, 60
						end,
						imageCoords = function()
							return {.1, .5, .1, .5}
						end,
						func = function()
							SUI.DB.Unitframes.Style = 'Fel'
						end
					},
					Transparent = {
						name = 'Transparent',
						type = 'execute',
						image = function()
							return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_Transparent', 120, 60
						end,
						imageCoords = function()
							return {0, .5, 0, .5}
						end,
						func = function()
							SUI.DB.Unitframes.Style = 'Transparent'
						end
					},
					Minimal = {
						name = 'Minimal',
						type = 'execute',
						image = function()
							return 'interface\\addons\\SpartanUI\\images\\setup\\Style_Frames_Minimal', 120, 60
						end,
						imageCoords = function()
							return {0, .5, 0, .5}
						end,
						func = function()
							SUI.DB.Unitframes.Style = 'Minimal'
						end
					},
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
			}
		}
	}
	for i, key in ipairs(module.frameList) do
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

	AddRaidOptions()
	SUI.opt.args['UnitFrames'].args['player'].args['general'].args['General'].args['range'].hidden = true
end

----------------------------------------------------------------------------------------------------

function PlayerOptions()
	SUI.opt.args['PlayerFrames'].args['FrameStyle'] = {
		name = L['FrameStyle'],
		type = 'group',
		desc = L['BarOptDesc'],
		args = {
			toggle3DPortrait = {
				name = L['Portrait3D'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DBMod.PlayerFrames.Portrait3D
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.Portrait3D = val
				end
			},
			showPetPortrait = {
				name = 'Show pet portrait',
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DBMod.PlayerFrames.PetPortrait
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.PetPortrait = val
				end
			},
			toggleclassname = {
				name = L['ClrNameClass'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return SUI.DBMod.PlayerFrames.showClass
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.showClass = val
				end
			},
			targettargetStyle = {
				name = L['ToTFrameStyle'],
				type = 'select',
				order = 3,
				values = {['large'] = L['LargeFrame'], ['medium'] = L['HidePicture'], ['small'] = L['NameHealthOnly']},
				get = function(info)
					return SUI.DBMod.PlayerFrames.targettarget.style
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.targettarget.style = val
				end
			},
			targettargetinfo = {name = L['ReloadRequired'], type = 'description', order = 4},
			bars = {
				name = L['BarOpt'],
				type = 'group',
				order = 1,
				desc = L['BarOptDesc'],
				args = {
					bar1 = {name = L['HBarClr'], type = 'header', order = 10},
					healthPlayerColor = {
						name = L['PlayerHClr'],
						type = 'select',
						order = 11,
						values = {['reaction'] = L['Green'], ['dynamic'] = L['TextStyle3']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.player.color
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.player.color = val
							PlayerFrames.player:ColorUpdate('player')
						end
					},
					healthTargetColor = {
						name = 'Target Health Color',
						type = 'select',
						order = 12,
						values = {['class'] = L['ClrByClass'], ['dynamic'] = L['TextStyle3'], ['reaction'] = L['ClrByReac']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.target.color
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.target.color = val
							PlayerFrames.player:ColorUpdate('target')
						end
					},
					healthToTColor = {
						name = 'Target of Target Health Color',
						type = 'select',
						order = 13,
						values = {['class'] = L['ClrByClass'], ['dynamic'] = L['TextStyle3'], ['reaction'] = L['ClrByReac']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.targettarget.color
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.targettarget.color = val
							PlayerFrames.player:ColorUpdate('targettarget')
						end
					},
					healthPetColor = {
						name = 'Pet Health Color',
						type = 'select',
						order = 14,
						values = {['class'] = L['ClrByClass'], ['dynamic'] = L['TextStyle3'], ['happiness'] = 'Happiness'},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.pet.color
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.pet.color = val
							PlayerFrames.player:ColorUpdate('pet')
						end
					},
					healthFocusColor = {
						name = 'Focus Health Color',
						type = 'select',
						order = 15,
						values = {['class'] = L['ClrByClass'], ['dynamic'] = L['TextStyle3'], ['reaction'] = L['ClrByReac']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.focus.color
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.focus.color = val
							PlayerFrames.player:ColorUpdate('focus')
						end
					},
					healthFocusTargetColor = {
						name = 'Focus Target Health Color',
						type = 'select',
						order = 16,
						values = {['class'] = L['ClrByClass'], ['dynamic'] = L['TextStyle3'], ['reaction'] = L['ClrByReac']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.focustarget.color
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.focustarget.color = val
							PlayerFrames.player:ColorUpdate('focustarget')
						end
					},
					bar2 = {name = L['TextStyle'], type = 'header', order = 20},
					healthtextstyle = {
						name = L['HTextStyle'],
						type = 'select',
						order = 21,
						desc = 'Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed',
						values = {['long'] = L['TextStyle1'], ['longfor'] = L['TextStyle2'], ['dynamic'] = L['TextStyle3']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.health.textstyle
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.health.textstyle = val
							for _, b in pairs(SUI.PlayerFrames) do
								SUI.PlayerFrames[b]:TextUpdate(b)
							end
						end
					},
					healthtextmode = {
						name = L['HTextMode'],
						type = 'select',
						order = 22,
						values = {
							[1] = L['HTextMode1'],
							[2] = L['HTextMode2'],
							[3] = L['HTextMode3'],
							[4] = L['HTextMode1'] .. ' (Percentage)'
						},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.health.textmode
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.health.textmode = val
							for _, b in pairs(SUI.PlayerFrames) do
								SUI.PlayerFrames[b]:TextUpdate(b)
							end
						end
					},
					manatextstyle = {
						name = L['MTextStyle'],
						type = 'select',
						order = 23,
						desc = 'Long: Displays all numbers.|nLong Formatted: Displays all numbers with commas.|nDynamic: Abbriviates and formats as needed',
						values = {['long'] = L['TextStyle1'], ['longfor'] = L['TextStyle2'], ['dynamic'] = L['TextStyle3']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.mana.textstyle
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.mana.textstyle = val
							for _, b in pairs(SUI.PlayerFrames) do
								SUI.PlayerFrames[b]:TextUpdate(b)
							end
						end
					},
					manatextmode = {
						name = L['MTextMode'],
						type = 'select',
						order = 24,
						values = {[1] = L['HTextMode1'], [2] = L['HTextMode2'], [3] = L['HTextMode3']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.bars.mana.textmode
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.bars.mana.textmode = val
							for _, b in pairs(Units) do
								addon[b]:TextUpdate(b)
							end
						end
					}
				}
			},
			ClassBarScale = {
				name = 'Class bar scale',
				type = 'range',
				order = 6,
				width = 'full',
				min = .01,
				max = 2,
				step = .01,
				get = function(info)
					return SUI.DBMod.PlayerFrames.ClassBar.scale
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.ClassBar.scale = val
					SUI:GetModule('PlayerFrames'):SetupExtras()
				end
			}
		}
	}
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

	SUI.opt.args['PlayerFrames'].args['castbar'] = {
		name = L['castbar'],
		type = 'group',
		desc = L['UnitCastSet'],
		args = {
			player = {
				name = L['PlayerStyle'],
				type = 'select',
				style = 'radio',
				values = {[0] = L['FillLR'], [1] = L['DepRL']},
				get = function(info)
					return SUI.DBMod.PlayerFrames.Castbar.player
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.Castbar.player = val
				end
			},
			target = {
				name = L['TargetStyle'],
				type = 'select',
				style = 'radio',
				values = {[0] = L['FillLR'], [1] = L['DepRL']},
				get = function(info)
					return SUI.DBMod.PlayerFrames.Castbar.target
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.Castbar.target = val
				end
			},
			targettarget = {
				name = L['ToTStyle'],
				type = 'select',
				style = 'radio',
				values = {[0] = L['FillLR'], [1] = L['DepRL']},
				get = function(info)
					return SUI.DBMod.PlayerFrames.Castbar.targettarget
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.Castbar.targettarget = val
				end
			},
			pet = {
				name = L['PetStyle'],
				type = 'select',
				style = 'radio',
				values = {[0] = L['FillLR'], [1] = L['DepRL']},
				get = function(info)
					return SUI.DBMod.PlayerFrames.Castbar.pet
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.Castbar.pet = val
				end
			},
			focus = {
				name = L['FocusStyle'],
				type = 'select',
				style = 'radio',
				values = {[0] = L['FillLR'], [1] = L['DepRL']},
				get = function(info)
					return SUI.DBMod.PlayerFrames.Castbar.focus
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.Castbar.focus = val
				end
			},
			text = {
				name = L['CastText'],
				desc = L['CastTextDesc'],
				type = 'group',
				args = {
					player = {
						name = L['TextStyle'],
						type = 'select',
						style = 'radio',
						values = {[0] = L['CountUp'], [1] = L['CountDown']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.Castbar.text.player
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.Castbar.text.player = val
						end
					},
					target = {
						name = L['TextStyle'],
						type = 'select',
						style = 'radio',
						values = {[0] = L['CountUp'], [1] = L['CountDown']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.Castbar.text.target
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.Castbar.text.target = val
						end
					},
					targettarget = {
						name = L['TextStyle'],
						type = 'select',
						style = 'radio',
						values = {[0] = L['CountUp'], [1] = L['CountDown']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.Castbar.text.targettarget
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.Castbar.text.targettarget = val
						end
					},
					pet = {
						name = L['TextStyle'],
						type = 'select',
						style = 'radio',
						values = {[0] = L['CountUp'], [1] = L['CountDown']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.Castbar.text.pet
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.Castbar.text.pet = val
						end
					},
					focus = {
						name = L['TextStyle'],
						type = 'select',
						style = 'radio',
						values = {[0] = L['CountUp'], [1] = L['CountDown']},
						get = function(info)
							return SUI.DBMod.PlayerFrames.Castbar.text.focus
						end,
						set = function(info, val)
							SUI.DBMod.PlayerFrames.Castbar.text.focus = val
						end
					}
				}
			}
		}
	}
	SUI.opt.args['PlayerFrames'].args['bossarena'] = {
		name = L['BossArenaFrames'],
		type = 'group',
		args = {
			bar0 = {name = L['BossFrames'], type = 'header', order = 0},
			boss = {
				name = L['ShowFrames'],
				type = 'toggle',
				order = 1,
				--disabled=true,
				get = function(info)
					return SUI.DBMod.PlayerFrames.BossFrame.display
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.BossFrame.display = val
				end
			},
			bossscale = {
				name = L['ScaleFrames'],
				type = 'range',
				order = 3,
				width = 'full',
				--disabled=true,
				min = .01,
				max = 2,
				step = .01,
				get = function(info)
					return SUI.DBMod.PlayerFrames.BossFrame.scale
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.BossFrame.scale = val
				end
			},
			bar2 = {name = L['ArenaFrames'], type = 'header', order = 20},
			arena = {
				name = L['ShowFrames'],
				type = 'toggle',
				order = 21,
				get = function(info)
					return SUI.DBMod.PlayerFrames.ArenaFrame.display
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.ArenaFrame.display = val
				end
			},
			arenascale = {
				name = L['ScaleFrames'],
				type = 'range',
				order = 23,
				width = 'full',
				min = .01,
				max = 2,
				step = .01,
				get = function(info)
					return SUI.DBMod.PlayerFrames.ArenaFrame.scale
				end,
				set = function(info, val)
					SUI.DBMod.PlayerFrames.ArenaFrame.scale = val
				end
			}
		}
	}

	SUI.opt.args['PlayerFrames'].args['resetSpecialBar'] = {
		name = L['resetSpecialBar'],
		type = 'execute',
		desc = L['resetSpecialBarDesc'],
		func = function()
			PlayerFrames:ResetAltBarPositions()
		end
	}
end

----------------------------------------------------------------------------------------------------

function RaidOptions()
	SUI.opt.args['RaidFrames'].args['DisplayOpts'] = {
		name = L['DisplayOpts'],
		type = 'group',
		order = 100,
		inline = true,
		args = {
			toggleraid = {
				name = L['ShowRFrames'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DBMod.RaidFrames.showRaid
				end,
				set = function(info, val)
					SUI.DBMod.RaidFrames.showRaid = val
					RaidFrames:UpdateRaid('FORCE_UPDATE')
				end
			},
			toggleparty = {
				name = L['PartyDispParty'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return SUI.DBMod.RaidFrames.showParty
				end,
				set = function(info, val)
					SUI.DBMod.RaidFrames.showParty = val
					RaidFrames:UpdateRaid('FORCE_UPDATE')
				end
			},
			togglesolo = {
				name = L['PartyDispSolo'],
				type = 'toggle',
				order = 4,
				get = function(info)
					return SUI.DBMod.RaidFrames.showSolo
				end,
				set = function(info, val)
					SUI.DBMod.RaidFrames.showSolo = val
					RaidFrames:UpdateRaid('FORCE_UPDATE')
				end
			},
			toggleclassname = {
				name = L['ClrNameClass'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DBMod.RaidFrames.showClass
				end,
				set = function(info, val)
					SUI.DBMod.RaidFrames.showClass = val
					RaidFrames:UpdateRaid('FORCE_UPDATE')
				end
			},
			scale = {
				name = L['ScaleSize'],
				type = 'range',
				order = 5,
				width = 'full',
				step = .01,
				min = .01,
				max = 2,
				get = function(info)
					return SUI.DBMod.RaidFrames.scale
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
					else
						SUI.DBMod.RaidFrames.scale = val
						RaidFrames:UpdateRaid('FORCE_UPDATE')
					end
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
					return SUI.DBMod.RaidFrames.maxColumns
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
					else
						SUI.DBMod.RaidFrames.maxColumns = val
						RaidFrames:UpdateRaid('FORCE_UPDATE')
					end
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
					return SUI.DBMod.RaidFrames.unitsPerColumn
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
					else
						SUI.DBMod.RaidFrames.unitsPerColumn = val
						RaidFrames:UpdateRaid('FORCE_UPDATE')
					end
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
					return SUI.DBMod.RaidFrames.columnSpacing
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
					else
						SUI.DBMod.RaidFrames.columnSpacing = val
						RaidFrames:UpdateRaid('FORCE_UPDATE')
					end
				end
			},
			desc1 = {name = L['LayoutConfDesc'], type = 'description', order = 29.9},
			bar3 = {name = L['TextStyle'], type = 'header', order = 30},
			healthtextstyle = {
				name = L['HTextStyle'],
				type = 'select',
				order = 31,
				desc = L['TextStyle1Desc'] .. '|n' .. L['TextStyle2Desc'] .. '|n' .. L['TextStyle3Desc'],
				values = {
					['long'] = L['TextStyle1'],
					['longfor'] = L['TextStyle2'],
					['dynamic'] = L['TextStyle3'],
					['disabled'] = L['Disabled']
				},
				get = function(info)
					return SUI.DBMod.RaidFrames.bars.health.textstyle
				end,
				set = function(info, val)
					SUI.DBMod.RaidFrames.bars.health.textstyle = val
					RaidFrames:UpdateText()
				end
			},
			healthtextmode = {
				name = L['HTextMode'],
				type = 'select',
				order = 32,
				values = {[1] = L['HTextMode1'], [2] = L['HTextMode2'], [3] = L['HTextMode3']},
				get = function(info)
					return SUI.DBMod.RaidFrames.bars.health.textmode
				end,
				set = function(info, val)
					SUI.DBMod.RaidFrames.bars.health.textmode = val
					RaidFrames:UpdateText()
				end
			}
		}
	}

	SUI.opt.args['RaidFrames'].args['mode'] = {
		name = L['LayMode'],
		type = 'select',
		order = 3,
		values = {['NAME'] = L['LayName'], ['GROUP'] = L['LayGrp'], ['ASSIGNEDROLE'] = L['LayRole']},
		get = function(info)
			return SUI.DBMod.RaidFrames.mode
		end,
		set = function(info, val)
			SUI.DBMod.RaidFrames.mode = val
			RaidFrames:UpdateRaid('FORCE_UPDATE')
		end
	}
	SUI.opt.args['RaidFrames'].args['raidLockReset'] = {
		name = L['ResetRaidPos'],
		type = 'execute',
		order = 11,
		func = function()
			if (InCombatLockdown()) then
				SUI:Print(ERR_NOT_IN_COMBAT)
			else
				SUI.DBMod.RaidFrames.moved = false
				RaidFrames:UpdateRaidPosition()
			end
		end
	}
	SUI.opt.args['RaidFrames'].args['HideBlizz'] = {
		name = L['HideBlizzFrames'],
		type = 'toggle',
		order = 4,
		get = function(info)
			return SUI.DBMod.RaidFrames.HideBlizzFrames
		end,
		set = function(info, val)
			SUI.DBMod.RaidFrames.HideBlizzFrames = val
		end
	}
end

----------------------------------------------------------------------------------------------------

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

function PartyOptions()
	SUI.opt.args['PartyFrames'].args['DisplayOpts'] = {
		name = L['DisplayOpts'],
		type = 'group',
		order = 100,
		inline = true,
		desc = L['DisplayOptsPartyDesc'],
		args = {
			bar1 = {name = L['WhenDisplayParty'], type = 'header', order = 0},
			toggleraid = {
				name = L['PartyDispRaid'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DBMod.PartyFrames.showPartyInRaid
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.showPartyInRaid = val
					PartyFrames:UpdateParty('FORCE_UPDATE')
				end
			},
			toggleparty = {
				name = L['PartyDispParty'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return SUI.DBMod.PartyFrames.showParty
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.showParty = val
					PartyFrames:UpdateParty('FORCE_UPDATE')
				end
			},
			toggleplayer = {
				name = L['PartyDispSelf'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DBMod.PartyFrames.showPlayer
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.showPlayer = val
					PartyFrames:UpdateParty('FORCE_UPDATE')
				end
			},
			togglesolo = {
				name = L['PartyDispSolo'],
				type = 'toggle',
				order = 4,
				get = function(info)
					return SUI.DBMod.PartyFrames.showSolo
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.showSolo = val
					PartyFrames:UpdateParty('FORCE_UPDATE')
				end
			},
			bar2 = {name = L['SubFrameDisp'], type = 'header', order = 10},
			DisplayPet = {
				name = L['DispPet'],
				type = 'toggle',
				order = 11,
				get = function(info)
					return SUI.DBMod.PartyFrames.display.pet
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.display.pet = val
				end
			},
			DisplayTarget = {
				name = L['DispTarget'],
				type = 'toggle',
				order = 12,
				get = function(info)
					return SUI.DBMod.PartyFrames.display.target
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.display.target = val
				end
			},
			bar3 = {name = L['TextStyle'], type = 'header', order = 20},
			healthtextstyle = {
				name = L['HTextStyle'],
				type = 'select',
				order = 21,
				desc = L['TextStyle1Desc'] .. '|n' .. L['TextStyle2Desc'] .. '|n' .. L['TextStyle3Desc'],
				values = {
					['Long'] = L['TextStyle1'],
					['longfor'] = L['TextStyle2'],
					['dynamic'] = L['TextStyle3'],
					['disabled'] = L['Disabled']
				},
				get = function(info)
					return SUI.DBMod.PartyFrames.bars.health.textstyle
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.bars.health.textstyle = val
					module:UpdateText()
				end
			},
			healthtextmode = {
				name = L['HTextMode'],
				type = 'select',
				order = 22,
				values = {[1] = L['HTextMode1'], [2] = L['HTextMode2'], [3] = L['HTextMode3']},
				get = function(info)
					return SUI.DBMod.PartyFrames.bars.health.textmode
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.bars.health.textmode = val
					module:UpdateText()
				end
			},
			manatextstyle = {
				name = L['MTextStyle'],
				type = 'select',
				order = 23,
				desc = L['TextStyle1Desc'] .. '|n' .. L['TextStyle2Desc'] .. '|n' .. L['TextStyle3Desc'],
				values = {
					['Long'] = L['TextStyle1'],
					['longfor'] = L['TextStyle2'],
					['dynamic'] = L['TextStyle3'],
					['disabled'] = L['Disabled']
				},
				get = function(info)
					return SUI.DBMod.PartyFrames.bars.mana.textstyle
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.bars.mana.textstyle = val
					module:UpdateText()
				end
			},
			manatextmode = {
				name = L['MTextMode'],
				type = 'select',
				order = 24,
				values = {[1] = L['HTextMode1'], [2] = L['HTextMode2'], [3] = L['HTextMode3']},
				get = function(info)
					return SUI.DBMod.PartyFrames.bars.mana.textmode
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.bars.mana.textmode = val
					module:UpdateText()
				end
			},
			toggleclasscolorname = {
				name = L['ClrNameClass'],
				type = 'toggle',
				order = 25,
				get = function(info)
					return SUI.DBMod.PartyFrames.showClass
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.showClass = val
					PartyFrames:UpdateParty('FORCE_UPDATE')
				end
			}
		}
	}
	SUI.opt.args['PartyFrames'].args['partyReset'] = {
		name = L['ResetPartyPos'],
		type = 'execute',
		order = 5,
		func = function()
			-- if (InCombatLockdown()) then
			-- SUI:Print(ERR_NOT_IN_COMBAT);
			-- else
			SUI.DBMod.PartyFrames.moved = false
			PartyFrames:UpdatePartyPosition()
			-- end
		end
	}
	SUI.opt.args['PartyFrames'].args['scale'] = {
		name = L['ScaleSize'],
		type = 'range',
		order = 11,
		width = 'full',
		step = .01,
		min = .01,
		max = 2,
		get = function(info)
			return SUI.DBMod.PartyFrames.scale
		end,
		set = function(info, val)
			if (InCombatLockdown()) then
				SUI:Print(ERR_NOT_IN_COMBAT)
			else
				SUI.DBMod.PartyFrames.scale = val
				PartyFrames:UpdateParty('FORCE_UPDATE')
			end
		end
	}
end
