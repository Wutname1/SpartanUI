local SUI = SUI
local L = SUI.L
local PlayerFrames = SUI.PlayerFrames
----------------------------------------------------------------------------------------------------

function PlayerFrames:OnInitialize()
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
