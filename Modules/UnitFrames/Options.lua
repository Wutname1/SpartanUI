local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:GetModule('Module_UnitFrames')
----------------------------------------------------------------------------------------------------

local function CreateOptionSet(frameName, order)
	SUI.opt.args['UnitFrames'].args[frameName] = {
		name = frameName,
		type = 'group',
		order = order,
		childGroups = 'tab',
		args = {
			bars = {
				name = 'Bars',
				type = 'group',
				order = 20,
				childGroups = 'tree',
				args = {}
			},
			elements = {
				name = 'Elements',
				type = 'group',
				order = 30,
				childGroups = 'tree',
				args = {}
			},
			text = {
				name = 'Text',
				type = 'group',
				order = 30,
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
		order = 10,
		args = {
			portrait = {
				name = 'Portrait',
				type = 'group',
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
			},
			artwork = {
				name = 'Artwork',
				type = 'group',
				inline = true,
				args = {}
			}
		}
	}
end

local function AddBuffOptions(frameName)
	local values = {['bars'] = L['Bars'], ['icons'] = L['Icons'], ['both'] = L['Both'], ['disabled'] = L['Disabled']}

	SUI.opt.args['UnitFrames'].args[frameName].args['auras'] = {
		name = 'Buffs & Debuffs',
		desc = 'Buff & Debuff display settings',
		type = 'group',
		order = 40,
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

function module:InitializeOptions()
	SUI.opt.args['UnitFrames'] = {
		name = 'Unit frames',
		type = 'group',
		args = {}
	}
	for i, key in ipairs(module.frameList) do
		CreateOptionSet(key, i)
		AddGeneralOptions(key)
		AddBuffOptions(key)
	end
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
