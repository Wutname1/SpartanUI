local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_Classic')
----------------------------------------------------------------------------------------------------
if SUI.DB.Styles.Classic.BuffLoc == nil then
	SUI.DB.Styles.Classic.BuffLoc = true
end
local InitRan = false

function module:OnInitialize()
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Classic = {
		['BT4Bar1'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-358,81',
		['BT4Bar2'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-359,32',
		--
		['BT4Bar3'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,359,80',
		['BT4Bar4'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,359,33',
		--
		['BT4Bar5'] = 'BOTTOMRIGHT,SUI_ActionBarAnchor,BOTTOMLEFT,-2,3',
		['BT4Bar6'] = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOMRIGHT,4,3',
		--
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_ActionBarAnchor,TOP,0,130',
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_ActionBarAnchor,TOP,0,130',
		--
		['BT4BarStanceBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-224,138',
		['BT4BarPetBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-564,165',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,297,133',
		['BT4BarBagBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,628,168'
	}
	BarHandler.BarScale.BT4.Classic = {
		['BT4Bar1'] = 0.78,
		['BT4Bar2'] = 0.78,
		['BT4Bar3'] = 0.78,
		['BT4Bar4'] = 0.78,
		['BT4Bar5'] = 0.75,
		['BT4Bar6'] = 0.75,
		['BT4BarBagBar'] = 0.6,
		['BT4BarStanceBar'] = 0.7,
		-- ['BT4BarPetBar'] = 0.7,
		['BT4BarMicroMenu'] = 0.7
	}

	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.Classic = {
		full = {perUnit = true},
		player = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\base_1_full',
			TexCoord = {0.2, 0.80859375, 0.8046875, 0.1953125}
		},
		target = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\base_1_full',
			TexCoord = {0.80859375, 0.2, 0.1953125, 0.8046875}
		},
		targettarget = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\base_3_single',
			TexCoord = {.68, 0, 0, 0.6640625}
		}
	}
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style == 'Classic') then
		module:SetupMenus()
		module:InitFramework()
		module:InitActionBars()
		module:EnableFramework()
		module:EnableActionBars()
		module:EnableMinimap()
	else
		module:Disable()
	end
end

function module:SetupMenus()
	SUI.opt.args['Artwork'].args['ActionBar'] = {
		name = 'ActionBar Settings',
		type = 'group',
		desc = L['ActionBarConfDesc'],
		args = {
			header1 = {name = '', type = 'header', order = 1.1},
			Allenable = {
				name = L['AllBarEnable'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return SUI.DB.ActionBars.Allenable
				end,
				set = function(info, val)
					SUI.DB.ActionBars.Allenable = val
					for i = 1, 6 do
						SUI.DB.ActionBars['bar' .. i].enable = val
					end
				end
			},
			Allalpha = {
				name = L['AllBarAlpha'],
				type = 'range',
				order = 2.1,
				width = 'double',
				min = 0,
				max = 100,
				step = 1,
				get = function(info)
					return SUI.DB.ActionBars.Allalpha
				end,
				set = function(info, val)
					for i = 1, 6 do
						SUI.DB.ActionBars['bar' .. i].alpha, DB.ActionBars.Allalpha = val, val
					end
				end
			},
			Bar1 = {
				name = 'Bar 1',
				type = 'group',
				inline = true,
				args = {
					bar1alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar1.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar1.enable == true then
								SUI.DB.ActionBars.bar1.alpha = val
							end
						end
					},
					bar1enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar1.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar1.enable = val
						end
					}
				}
			},
			Bar2 = {
				name = 'Bar 2',
				type = 'group',
				inline = true,
				args = {
					bar2alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar2.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar2.enable == true then
								SUI.DB.ActionBars.bar2.alpha = val
							end
						end
					},
					bar2enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar2.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar2.enable = val
						end
					}
				}
			},
			Bar3 = {
				name = 'Bar 3',
				type = 'group',
				inline = true,
				args = {
					bar3alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar3.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar3.enable == true then
								SUI.DB.ActionBars.bar3.alpha = val
							end
						end
					},
					bar3enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar3.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar3.enable = val
						end
					}
				}
			},
			Bar4 = {
				name = 'Bar 4',
				type = 'group',
				inline = true,
				args = {
					bar4alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar4.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar4.enable == true then
								SUI.DB.ActionBars.bar4.alpha = val
							end
						end
					},
					bar4enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar4.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar4.enable = val
						end
					}
				}
			},
			Bar5 = {
				name = 'Bar 5',
				type = 'group',
				inline = true,
				args = {
					bar5alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar5.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar5.enable == true then
								SUI.DB.ActionBars.bar5.alpha = val
							end
						end
					},
					bar5enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar5.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar5.enable = val
						end
					}
				}
			},
			Bar6 = {
				name = 'Bar 6',
				type = 'group',
				inline = true,
				args = {
					bar6alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar6.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar6.enable == true then
								SUI.DB.ActionBars.bar6.alpha = val
							end
						end
					},
					bar6enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar6.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar6.enable = val
						end
					}
				}
			}
		}
	}
	SUI.opt.args['Artwork'].args['popup'] = {
		name = L['PopupAnimConf'],
		type = 'group',
		desc = L['PopupAnimConfDesc'],
		args = {
			popup1anim = {
				name = L['LPopupAnimate'],
				type = 'toggle',
				order = 1,
				width = 'full',
				get = function(info)
					return SUI.DB.ActionBars.popup1.anim
				end,
				set = function(info, val)
					SUI.DB.ActionBars.popup1.anim = val
				end
			},
			popup1alpha = {
				name = L['LPopupAlpha'],
				type = 'range',
				order = 2,
				min = 0,
				max = 100,
				step = 1,
				get = function(info)
					return SUI.DB.ActionBars.popup1.alpha
				end,
				set = function(info, val)
					if SUI.DB.ActionBars.popup1.enable == true then
						SUI.DB.ActionBars.popup1.alpha = val
					end
				end
			},
			popup1enable = {
				name = L['LPopupEnable'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DB.ActionBars.popup1.enable
				end,
				set = function(info, val)
					SUI.DB.ActionBars.popup1.enable = val
				end
			},
			popup2anim = {
				name = L['RPopupAnimate'],
				type = 'toggle',
				order = 4,
				width = 'full',
				get = function(info)
					return SUI.DB.ActionBars.popup2.anim
				end,
				set = function(info, val)
					SUI.DB.ActionBars.popup2.anim = val
				end
			},
			popup2alpha = {
				name = L['RPopupAlpha'],
				type = 'range',
				order = 5,
				min = 0,
				max = 100,
				step = 1,
				get = function(info)
					return SUI.DB.ActionBars.popup2.alpha
				end,
				set = function(info, val)
					if SUI.DB.ActionBars.popup2.enable == true then
						SUI.DB.ActionBars.popup2.alpha = val
					end
				end
			},
			popup2enable = {
				name = L['RPopupEnable'],
				type = 'toggle',
				order = 6,
				get = function(info)
					return SUI.DB.ActionBars.popup2.enable
				end,
				set = function(info, val)
					SUI.DB.ActionBars.popup2.enable = val
				end
			}
		}
	}
	SUI.opt.args['Artwork'].args['Artwork'] = {
		name = L['ArtworkOpt'],
		type = 'group',
		order = 10,
		args = {
			Color = {
				name = L['ArtColor'],
				type = 'color',
				hasAlpha = true,
				order = .5,
				get = function(info)
					if not SUI.DB.Styles.Classic.Color.Art then
						return {1, 1, 1, 1}
					end
					return unpack(SUI.DB.Styles.Classic.Color.Art)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Classic.Color.Art = {r, b, g, a}
					module:SetColor()
				end
			},
			ColorEnabled = {
				name = 'Color enabled',
				type = 'toggle',
				order = .6,
				get = function(info)
					if SUI.DB.Styles.Classic.Color.Art then
						return true
					else
						return false
					end
				end,
				set = function(info, val)
					if val then
						SUI.DB.Styles.Classic.Color.Art = {1, 1, 1, 1}
						module:SetColor()
					else
						SUI.DB.Styles.Classic.Color.Art = false
						module:SetColor()
					end
				end
			},
			alpha = {
				name = L['Transparency'],
				type = 'range',
				order = 1,
				width = 'full',
				min = 0,
				max = 100,
				step = 1,
				desc = L['TransparencyDesc'],
				get = function(info)
					return (SUI.DB.alpha * 100)
				end,
				set = function(info, val)
					SUI.DB.alpha = (val / 100)
					module:updateSpartanAlpha()
					module:AddNotice()
				end
			},
			TransparencyNotice = {
				name = L['TransparencyNotice'],
				order = 1.1,
				type = 'description',
				fontSize = 'small',
				hidden = true
			},
			xOffset = {
				name = L['MoveSideways'],
				type = 'range',
				width = 'full',
				order = 2,
				desc = L['MoveSidewaysDesc'],
				min = -200,
				max = 200,
				step = .1,
				get = function(info)
					return SUI.DB.Offset.Horizontal / 6.25
				end,
				set = function(info, val)
					SUI.DB.Offset.Horizontal = val * 6.25
					module:updateSpartanXOffset()
				end
			},
			offset = {
				name = L['ConfOffset'],
				type = 'range',
				width = 'normal',
				order = 3,
				desc = L['ConfOffsetDesc'],
				min = 0,
				max = 200,
				step = .1,
				get = function(info)
					return SUI.DB.yoffset
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
					else
						if SUI.DB.yoffsetAuto then
							SUI:Print(L['confOffsetAuto'])
						else
							val = tonumber(val)
							SUI.DB.yoffset = val
						end
					end
				end
			},
			offsetauto = {
				name = L['AutoOffset'],
				type = 'toggle',
				desc = L['AutoOffsetDesc'],
				order = 3.1,
				get = function(info)
					return SUI.DB.yoffsetAuto
				end,
				set = function(info, val)
					SUI.DB.yoffsetAuto = val
				end
			}
		}
	}

	if (SUI.DB.alpha ~= 1) then
		module:AddNotice()
	end
end

function module:AddNotice()
	if (SUI.DB.alpha == 1) then
		SUI.opt.args['Artwork'].args['Artwork'].args['TransparencyNotice'].hidden = true
	else
		SUI.opt.args['Artwork'].args['Artwork'].args['TransparencyNotice'].hidden = false
	end
end

function module:OnDisable()
	SUI_Art_Classic:Hide()
	UnregisterStateDriver(SUI_Art_Classic, 'visibility')
end
