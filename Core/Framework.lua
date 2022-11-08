---@class SUI : AceAddon, AceEvent-3.0, AceConsole-3.0, AceSerializer-3.0
---@field MoveIt MoveIt
local SUI = LibStub('AceAddon-3.0'):NewAddon('SpartanUI', 'AceEvent-3.0', 'AceConsole-3.0', 'AceSerializer-3.0')
SUI:SetDefaultModuleLibraries('AceEvent-3.0', 'AceTimer-3.0')
_G.SUI = SUI
local type, pairs, unpack = type, pairs, unpack
local _G = _G
SUI.L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true) ---@type SUIL
SUI.AutoOpenErrors = true
SUI.Version = GetAddOnMetadata('SpartanUI', 'Version') or 0
SUI.BuildNum = GetAddOnMetadata('SpartanUI', 'X-Build') or 0
SUI.Bartender4Version = (GetAddOnMetadata('Bartender4', 'Version') or 0)
SUI.IsDF = select(4, GetBuildInfo()) >= 100000 ---@type boolean
SUI.IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) ---@type boolean
SUI.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) ---@type boolean
SUI.IsTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC) ---@type boolean
SUI.IsWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC) -- ---@type boolean
SUI.GitHash = '@project-abbreviated-hash@' -- The ZIP packager will replace this with the Git hash.
local wowVersion = 'Retail'
if SUI.IsClassic then
	wowVersion = 'Classic'
end
if SUI.IsTBC then
	wowVersion = 'TBC'
end
if SUI.IsWrath then
	wowVersion = 'Wrath'
end
--@alpha@
SUI.releaseType = 'ALPHA ' .. SUI.BuildNum
--@end-alpha@
--@do-not-package@
SUI.releaseType = 'DEV Build'
SUI.Version = ''
--@end-do-not-package@

---------------  Add Libraries ---------------

---@class SUI.Lib
---@field AceC AceConfig-3.0
---@field AceDB AceDB-3.0
---@field StdUi StdUi
---@field LSM LibSharedMedia-3.0
SUI.Lib = {}

---@param name string
---@param libaray table|function
---@param silent? boolean
SUI.AddLib = function(name, libaray, silent)
	if not name then
		return
	end

	-- in this case: `major` is the lib table and `minor` is the minor version
	if type(libaray) == 'table' then
		SUI.Lib[name] = libaray
	else -- in this case: `major` is the lib name and `minor` is the silent switch
		SUI.Lib[name] = LibStub(libaray, silent)
	end
end

SUI.AddLib('AceC', 'AceConfig-3.0')
SUI.AddLib('AceCD', 'AceConfigDialog-3.0')
SUI.AddLib('AceCR', 'AceConfigRegistry-3.0')
SUI.AddLib('AceDB', 'AceDB-3.0')
SUI.AddLib('AceDBO', 'AceDBOptions-3.0')
SUI.AddLib('Compress', 'LibCompress')
SUI.AddLib('Base64', 'LibBase64-1.0-SUI')
SUI.AddLib('StdUi', 'StdUi')
SUI.AddLib('LSM', 'LibSharedMedia-3.0')
SUI.AddLib('WagoAnalytics', 'WagoAnalytics', true)

-- Add Statusbar textures
SUI.Lib.LSM:Register('statusbar', 'Brushed aluminum', [[Interface\AddOns\SpartanUI\images\statusbars\BrushedAluminum]])
SUI.Lib.LSM:Register('statusbar', 'Leaves', [[Interface\AddOns\SpartanUI\images\statusbars\Leaves]])
SUI.Lib.LSM:Register('statusbar', 'Lightning', [[Interface\AddOns\SpartanUI\images\statusbars\Lightning]])
SUI.Lib.LSM:Register('statusbar', 'Metal', [[Interface\AddOns\SpartanUI\images\statusbars\metal]])
SUI.Lib.LSM:Register('statusbar', 'Recessed stone', [[Interface\AddOns\SpartanUI\images\statusbars\RecessedStone]])
SUI.Lib.LSM:Register('statusbar', 'Smoke', [[Interface\AddOns\SpartanUI\images\statusbars\Smoke]])
SUI.Lib.LSM:Register('statusbar', 'Smooth gradient', [[Interface\AddOns\SpartanUI\images\statusbars\SmoothGradient]])
SUI.Lib.LSM:Register('statusbar', 'SpartanUI Default', [[Interface\AddOns\SpartanUI\images\statusbars\Smoothv2]])
SUI.Lib.LSM:Register('statusbar', 'Blank', [[Interface\AddOns\SpartanUI\images\blank]])

-- Add Background textures
SUI.Lib.LSM:Register('background', 'Smoke', [[Interface\AddOns\SpartanUI\images\backgrounds\smoke]])
SUI.Lib.LSM:Register('background', 'Dragonflight', [[Interface\AddOns\SpartanUI\images\backgrounds\Dragonflight]])
SUI.Lib.LSM:Register('background', 'None', [[Interface\AddOns\SpartanUI\images\blank]])

--init StdUI Instance for the whole addon
SUI.StdUi = SUI.Lib.StdUi:NewInstance() ---@type StdUi

---------------  Options Init ---------------
---@type AceConfigOptionsTable
SUI.opt = {
	name = string.format('|cffffffffSpartan|cffe21f1fUI|r %s %s %s', wowVersion, SUI.Version, SUI.releaseType or ''),
	type = 'group',
	childGroups = 'tree',
	args = {
		General = {name = SUI.L['General'], type = 'group', order = 0, args = {}},
		Artwork = {name = SUI.L['Artwork'], type = 'group', order = 1, args = {}}
	}
}
---------------  Database  ---------------
local scale = .88
if SUI.IsClassic then
	scale = .79
end

local DBdefault = {
	Version = '0',
	SetupDone = false,
	scale = scale,
	alpha = 1,
	ActionBars = {
		Allalpha = 100,
		Allenable = true,
		popup1 = {anim = true, alpha = 100, enable = true},
		popup2 = {anim = true, alpha = 100, enable = true},
		bar1 = {alpha = 100, enable = true},
		bar2 = {alpha = 100, enable = true},
		bar3 = {alpha = 100, enable = true},
		bar4 = {alpha = 100, enable = true},
		bar5 = {alpha = 100, enable = true},
		bar6 = {alpha = 100, enable = true}
	},
	BuffSettings = {
		disableblizz = true,
		enabled = true,
		Manualoffset = false,
		offset = 0
	},
	DisabledModules = {},
	font = {
		NumberSeperator = ',',
		Path = '',
		Modules = {
			['**'] = {
				Size = 0,
				Face = 'Roboto Bold',
				Type = 'outline'
			}
		}
	},
	MiniMap = {},
	Offset = {
		Top = 0,
		TopAuto = true,
		Bottom = 0,
		BottomAuto = true,
		Horizontal = {
			Bottom = 0,
			Top = 0
		}
	},
	SetupWizard = {
		FirstLaunch = true
	},
	Styles = {
		['**'] = {
			Frames = {},
			Artwork = {
				barBG = {
					['**'] = {
						enabled = true,
						alpha = 1
					},
					['1'] = {},
					['2'] = {},
					['3'] = {},
					['4'] = {},
					['5'] = {},
					['6'] = {},
					['7'] = {},
					['8'] = {},
					['9'] = {},
					['10'] = {},
					Stance = {},
					MenuBar = {}
				}
			},
			StatusBars = {
				['**'] = {
					size = {256, 36},
					bgTooltip = 'Interface\\Addons\\SpartanUI\\Images\\status-tooltip',
					texCordsTooltip = {0.103515625, 0.8984375, 0.1796875, 0.8203125},
					TooltipSize = {300, 100},
					TooltipTextSize = {230, 60},
					TooltipTextWidth = 300,
					tooltipAnchor = 'TOP',
					FontSize = 9,
					TextColor = {1, 1, 1, 1},
					MaxWidth = 0,
					GlowAnchor = 'RIGHT',
					GlowPoint = {x = 0, y = 0},
					GlowHeight = 20,
					GlowImage = 'Interface\\AddOns\\SpartanUI\\Images\\status-glow',
					texCords = {0, 1, 0, 1}
				},
				Left = {
					Grow = 'LEFT',
					Position = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOM,-100,0'
				},
				Right = {
					Grow = 'RIGHT',
					Position = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOM,100,0'
				}
			},
			Movers = {},
			BlizzMovers = {
				['VehicleSeatIndicator'] = 'RIGHT,SpartanUI,RIGHT,-10,-30',
				['ObjectiveTracker'] = 'TOPRIGHT,SpartanUI,TOPRIGHT,-30,-100',
				['TalkingHead'] = 'TOP,SpartanUI,TOP,0,-18',
				['AltPowerBar'] = 'TOP,SpartanUI,TOP,0,-18',
				['WidgetPowerBarContainer'] = 'BOTTOM,SpartanUI,BOTTOM,0,215',
				['ZoneAbility'] = 'CENTER,SpartanUI,CENTER,0,-172',
				['ExtraAction'] = 'CENTER,SpartanUI,CENTER,0,-172',
				['AlertFrame'] = 'BOTTOM,SpartanUI,BOTTOM,0,215',
				['VehicleLeaveButton'] = 'BOTTOM,SpartanUI,BOTTOM,0,180'
			},
			Color = {
				Art = false,
				PlayerFrames = false,
				PartyFrames = false,
				RaidFrames = false
			}
		},
		Arcane = {
			StatusBars = {
				['**'] = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\StatusBar',
					alpha = 0.9,
					size = {370, 20},
					TooltipSize = {350, 100},
					TooltipTextSize = {330, 80},
					texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
					MaxWidth = 48
				},
				Left = {
					GlowPoint = {x = -16},
					MaxWidth = 48
				},
				Right = {
					GlowPoint = {x = 16}
				}
			},
			Frames = {
				player = {
					elements = {
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						},
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'Arcane'
							},
							bg = {
								enabled = true,
								graphic = 'Arcane'
							},
							bottom = {
								enabled = true,
								graphic = 'Arcane'
							}
						}
					}
				},
				target = {
					elements = {
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						},
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'Arcane'
							},
							bg = {
								enabled = true,
								graphic = 'Arcane'
							},
							bottom = {
								enabled = true,
								graphic = 'Arcane'
							}
						}
					}
				}
			},
			Color = {
				Art = {
					0.4784313725490196,
					0.9137254901960784,
					1,
					0.9
				}
			},
			SlidingTrays = {
				left = {
					enabled = true,
					collapsed = false
				},
				right = {
					enabled = true,
					collapsed = false
				}
			}
		},
		ArcaneRed = {
			Frames = {
				player = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'ArcaneRed'
							},
							bg = {
								enabled = true,
								graphic = 'ArcaneRed'
							},
							bottom = {
								enabled = true,
								graphic = 'ArcaneRed'
							}
						},
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						}
					}
				},
				target = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'ArcaneRed'
							},
							bg = {
								enabled = true,
								graphic = 'ArcaneRed'
							},
							bottom = {
								enabled = true,
								graphic = 'ArcaneRed'
							}
						},
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						}
					}
				}
			}
		},
		Classic = {
			Frames = {
				player = {
					width = 153,
					scale = 0.91,
					elements = {
						Buffs = {
							rows = 4,
							growthy = 'UP',
							position = {
								y = 8,
								relativeTo = 'Name',
								relativePoint = 'TOPLEFT',
								anchor = 'BOTTOMLEFT',
								x = -23
							}
						},
						Debuffs = {
							rows = 4,
							growthy = 'UP',
							position = {
								y = 8,
								relativeTo = 'Name',
								anchor = 'BOTTOMRIGHT',
								relativePoint = 'TOPRIGHT'
							}
						},
						Castbar = {
							height = 15
						},
						Health = {
							offset = 2,
							height = 16,
							text = {
								['2'] = {
									enabled = true,
									text = '[perhp]%',
									position = {
										anchor = 'LEFT',
										x = -35,
										y = 0
									}
								}
							}
						},
						Power = {
							offset = 2,
							height = 14,
							text = {
								['2'] = {
									enabled = true,
									text = '[perpp]%',
									position = {
										anchor = 'LEFT',
										x = -35,
										y = 0
									}
								}
							},
							position = {
								y = -3
							}
						},
						Portrait = {
							position = 'right'
						},
						RestingIndicator = {
							position = {
								anchor = 'TOPRIGHT',
								x = 102,
								y = 10
							}
						},
						ClassIcon = {
							size = 18,
							position = {
								anchor = 'TOPRIGHT',
								x = 20,
								y = 16
							}
						},
						PvPIndicator = {
							position = {
								anchor = 'BOTTOMRIGHT',
								x = 80,
								y = 0
							}
						},
						RaidRoleIndicator = {
							position = {
								anchor = 'BOTTOMRIGHT',
								x = 22,
								y = 0
							}
						},
						SpartanArt = {
							full = {
								enabled = true,
								graphic = 'Classic'
							}
						},
						CombatIndicator = {
							enabled = true,
							position = {
								anchor = 'TOPRIGHT',
								x = 102,
								y = 10
							}
						}
					}
				},
				target = {
					width = 153,
					scale = 0.91,
					elements = {
						Buffs = {
							rows = 4,
							growthy = 'UP',
							position = {
								y = 8,
								relativeTo = 'Name',
								relativePoint = 'TOPLEFT',
								anchor = 'BOTTOMLEFT',
								x = -23
							}
						},
						Debuffs = {
							rows = 4,
							growthy = 'UP',
							position = {
								y = 8,
								relativeTo = 'Name',
								anchor = 'BOTTOMRIGHT',
								relativePoint = 'TOPRIGHT'
							}
						},
						Health = {
							offset = 2,
							height = 16,
							text = {
								['2'] = {
									enabled = true,
									text = '[perhp]%',
									position = {
										anchor = 'RIGHT',
										x = 40
									}
								}
							}
						},
						Power = {
							offset = 2,
							height = 16,
							text = {
								['2'] = {
									enabled = true,
									text = '[perpp]%',
									position = {
										anchor = 'RIGHT',
										x = 40
									}
								}
							},
							position = {
								y = -3
							}
						},
						Castbar = {
							height = 15
						},
						ClassIcon = {
							size = 18,
							position = {
								anchor = 'TOPLEFT',
								x = -22,
								y = 16
							}
						},
						PvPIndicator = {
							position = {
								anchor = 'BOTTOMLEFT',
								x = -80,
								y = 0
							}
						},
						RaidRoleIndicator = {
							position = {
								anchor = 'BOTTOMLEFT',
								x = -22,
								y = 0
							}
						},
						SpartanArt = {
							full = {
								enabled = true,
								graphic = 'Classic'
							}
						}
					}
				},
				pet = {
					elements = {
						Buffs = {
							enabled = false,
							position = {
								y = 22
							}
						},
						Debuffs = {
							rows = 4,
							growthy = 'UP',
							position = {
								y = 8,
								relativeTo = 'Name',
								anchor = 'BOTTOMRIGHT',
								relativePoint = 'TOPRIGHT'
							}
						},
						Health = {
							offset = 2,
							height = 16,
							text = {
								['2'] = {
									enabled = true,
									text = '[perhp]%',
									position = {
										anchor = 'LEFT',
										x = -35,
										y = 0
									}
								}
							}
						},
						Power = {
							offset = 2,
							height = 14,
							text = {
								['2'] = {
									enabled = true,
									text = '[perpp]%',
									position = {
										anchor = 'LEFT',
										x = -35,
										y = 0
									}
								}
							}
						},
						Castbar = {
							height = 15
						},
						Name = {
							position = {
								y = 17
							}
						},
						SpartanArt = {
							full = {
								enabled = true,
								graphic = 'Classic'
							}
						}
					}
				},
				targettarget = {
					elements = {
						Buffs = {
							enabled = false
						},
						Debuffs = {
							enabled = false
						},
						Health = {
							offset = 2,
							height = 14,
							text = {
								['2'] = {
									enabled = true,
									text = '[perhp]%',
									position = {
										anchor = 'RIGHT',
										x = 40
									}
								}
							}
						},
						Power = {
							offset = 1,
							height = 14,
							text = {
								['2'] = {
									enabled = true,
									text = '[perpp]%',
									position = {
										anchor = 'RIGHT',
										x = 40
									}
								}
							}
						},
						Castbar = {
							height = 14
						},
						SpartanArt = {
							full = {
								enabled = true,
								graphic = 'Classic'
							}
						}
					}
				}
			},
			StatusBars = {
				['**'] = {
					size = {370, 32},
					TooltipSize = {400, 100},
					TooltipTextSize = {380, 90},
					bgTooltip = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\BarBG',
					texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
				},
				Left = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\status-plate-exp',
					texCords = {0.150390625, 0.96875, 0, 1},
					MaxWidth = 15
				},
				Right = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\status-plate-rep',
					Grow = 'RIGHT',
					Position = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOM,79,0',
					texCords = {0, 0.849609375, 0, 1},
					GlowPoint = {x = 20},
					MaxWidth = 50
				}
			},
			BlizzMovers = {
				['VehicleLeaveButton'] = 'BOTTOM,SpartanUI,BOTTOM,0,195'
			}
		},
		Transparent = {
			Frames = {
				player = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'Transparent'
							},
							bg = {
								enabled = true,
								graphic = 'Transparent'
							}
						},
						Portrait = {
							position = 'right'
						}
					}
				},
				target = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'Transparent'
							},
							bg = {
								enabled = true,
								graphic = 'Transparent'
							}
						}
					}
				}
			},
			StatusBars = {
				['**'] = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\status-plate-rep',
					size = {400, 10},
					TooltipSize = {400, 100},
					TooltipTextSize = {380, 90},
					texCords = {0.150390625, 1, 0, 1},
					texCordsTooltip = {0.107421875, 0.892578125, 0.1875, 0.765625}
				}
			},
			Color = {
				Art = {0, .8, .9, .7},
				PlayerFrames = {0, .8, .9, .7},
				PartyFrames = {0, .8, .9, .7},
				RaidFrames = {0, .8, .9, .7}
			}
		},
		Minimal = {
			Color = {
				0.6156862745098039,
				0.1215686274509804,
				0.1215686274509804,
				0.9
			},
			HideCenterGraphic = false
		},
		Fel = {
			Artwork = {},
			Frames = {
				player = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'Fel'
							},
							bg = {
								enabled = true,
								graphic = 'Fel'
							},
							bottom = {
								enabled = true,
								graphic = 'Fel'
							}
						},
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						}
					}
				},
				target = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'Fel'
							},
							bg = {
								enabled = true,
								graphic = 'Fel'
							},
							bottom = {
								enabled = true,
								graphic = 'Fel'
							}
						},
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						}
					}
				}
			},
			StatusBars = {
				['**'] = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\status-plate-exp',
					size = {370, 20},
					TooltipSize = {400, 100},
					TooltipTextSize = {380, 90},
					texCords = {0.150390625, 1, 0, 1},
					bgTooltip = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Fel-Box',
					texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
				},
				Left = {
					GlowPoint = {x = -10},
					MaxWidth = 32
				},
				Right = {
					GlowPoint = {x = 10},
					MaxWidth = 35
				}
			}
		},
		Digital = {
			Artwork = {},
			StatusBars = {
				['**'] = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\status-plate-exp',
					size = {370, 20},
					TooltipSize = {400, 100},
					TooltipTextSize = {380, 90},
					texCords = {0.150390625, 1, 0, 1},
					bgTooltip = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\BarBG',
					texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
				},
				Left = {
					GlowPoint = {x = -10},
					MaxWidth = 32
				},
				Right = {
					Grow = 'RIGHT',
					GlowPoint = {x = 10},
					MaxWidth = 35
				}
			},
			Frames = {
				player = {
					elements = {
						SpartanArt = {
							bg = {
								enabled = true,
								graphic = 'Digital'
							}
						}
					}
				},
				target = {
					elements = {
						SpartanArt = {
							bg = {
								enabled = true,
								graphic = 'Digital'
							}
						}
					}
				}
			}
		},
		War = {
			Artwork = {},
			StatusBars = {
				['**'] = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
					alpha = 0.9,
					size = {370, 20},
					TooltipSize = {350, 100},
					TooltipTextSize = {330, 80},
					texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
					MaxWidth = 48
				},
				Left = {
					GlowPoint = {x = -16},
					MaxWidth = 48
				},
				Right = {
					GlowPoint = {x = 16}
				}
			},
			Frames = {
				player = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'War'
							},
							bg = {
								enabled = true,
								graphic = 'War'
							},
							bottom = {
								enabled = true,
								graphic = 'War'
							}
						},
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						},
						Buffs = {
							position = {
								relativeTo = 'Name',
								y = -15
							}
						},
						Debuffs = {
							position = {
								relativeTo = 'Name',
								y = -15
							}
						}
					}
				},
				target = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'War'
							},
							bg = {
								enabled = true,
								graphic = 'War'
							},
							bottom = {
								enabled = true,
								graphic = 'War'
							}
						},
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						},
						Buffs = {
							position = {
								relativeTo = 'Name',
								y = -5
							}
						},
						Debuffs = {
							position = {
								relativeTo = 'Name',
								y = -5
							}
						}
					}
				}
			},
			SlidingTrays = {
				left = {
					enabled = true,
					collapsed = false
				},
				right = {
					enabled = true,
					collapsed = false
				}
			}
		},
		Tribal = {
			Artwork = {},
			StatusBars = {
				['**'] = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Tribal\\Images\\StatusBar',
					alpha = .9,
					size = {370, 20},
					TooltipSize = {350, 100},
					TooltipTextSize = {330, 80},
					texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
					MaxWidth = 48
				},
				Left = {
					GlowPoint = {x = -16},
					MaxWidth = 48
				},
				Right = {
					GlowPoint = {x = 16}
				}
			},
			Frames = {
				player = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'Tribal'
							},
							bg = {
								enabled = true,
								graphic = 'Tribal'
							},
							bottom = {
								enabled = true,
								graphic = 'Tribal'
							}
						},
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						}
					}
				},
				target = {
					elements = {
						SpartanArt = {
							top = {
								enabled = true,
								graphic = 'Tribal'
							},
							bg = {
								enabled = true,
								graphic = 'Tribal'
							},
							bottom = {
								enabled = true,
								graphic = 'Tribal'
							}
						},
						Name = {
							enabled = true,
							SetJustifyH = 'LEFT',
							position = {
								anchor = 'BOTTOM',
								x = 0,
								y = -16
							}
						}
					}
				}
			},
			SlidingTrays = {
				left = {
					enabled = true,
					collapsed = false
				},
				right = {
					enabled = true,
					collapsed = false
				}
			}
		}
	},
	StatusBars = {
		['**'] = {
			display = 'disabled',
			ToolTip = 'hover',
			text = true,
			AutoColor = true,
			Color = {0, 0, 0, 1},
			FontSize = 10,
			GlowAnchor = 'RIGHT',
			GlowHeight = 20,
			texCords = {0, 1, 0, 1},
			CustomColor2 = {
				r = 0,
				g = 0,
				b = 0,
				a = 1
			},
			CustomColor = {
				r = 0,
				g = 0,
				b = 0,
				a = 1
			}
		},
		[1] = {
			display = 'xp'
		},
		[2] = {
			display = 'honor'
		}
	},
	Artwork = {
		Style = 'War',
		FirstLoad = true,
		SetupDone = false,
		VehicleUI = true,
		Viewport = {
			enabled = false,
			offset = {top = 0, bottom = 0, left = 0, right = 0}
		},
		SlidingTrays = {
			['**'] = {
				collapsed = false
			}
		}
	}
}
SUI.DBdefault = DBdefault
local GlobalDefaults = {
	ErrorHandler = {
		SUIErrorIcon = {}
	}
}

---@class SUIDBObject
local DBdefaults = {global = GlobalDefaults, profile = DBdefault}
---@class SUIDB : SUIDBObject, AceDBObject-3.0
---@field RegisterCallback function
SUI.SpartanUIDB = SUI.Lib.AceDB:New('SpartanUIDB', DBdefaults)
--If user has not played in a long time reset the database.
local ver = SUI.SpartanUIDB.profile.Version
if (ver ~= '0' and ver < '6.0.0') then
	SUI.SpartanUIDB:ResetDB()
end

-- New SUI.DB Access
SUI.DBG = SUI.SpartanUIDB.global
SUI.DB = SUI.SpartanUIDB.profile

if SUI.DB.DisabledComponents then
	SUI:CopyData(SUI.DB.DisabledModules, SUI.DB.DisabledComponents)
	SUI.DB.DisabledComponents = nil
end

local function reloaduiWindow()
	local StdUi = SUI.StdUi
	local popup = StdUi:Window(nil, 400, 140)
	popup:SetPoint('TOP', UIParent, 'TOP', 0, -20)
	popup:SetFrameStrata('DIALOG')
	popup:Hide()

	popup.Title = StdUi:Texture(popup, 156, 45, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	popup.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	StdUi:GlueTop(popup.Title, popup)
	popup.Title:SetAlpha(.8)

	-- Create Popup Items
	popup.ReloadMsg = StdUi:Label(popup, 'A reload of your UI is required.', 20)
	popup.btnClose = StdUi:HighlightButton(popup, 50, 20, 'CLOSE')
	popup.btnReload = StdUi:Button(popup, 180, 20, 'RELOAD UI')

	-- Position
	StdUi:GlueTop(popup.ReloadMsg, popup, 0, -50)
	popup.btnReload:SetPoint('BOTTOM', popup, 'BOTTOM', 0, 4)
	popup.btnClose:SetPoint('BOTTOMRIGHT', popup, 'BOTTOMRIGHT', -4, 4)

	-- Actions
	popup.btnClose:SetScript(
		'OnClick',
		function()
			-- Perform the Page's Custom Next action
			popup:Hide()
		end
	)
	popup.btnReload:SetScript(
		'OnClick',
		function()
			-- Perform the Page's Custom Next action
			ReloadUI()
		end
	)

	SUI.reloaduiWindow = popup
end

function SUI:OnInitialize()
	SUI.SpartanUIDB = SUI.Lib.AceDB:New('SpartanUIDB', DBdefaults)

	-- New SUI.DB Access
	SUI.DBG = SUI.SpartanUIDB.global
	SUI.DB = SUI.SpartanUIDB.profile

	SUI.AutoOpenErrors = (SUI.DBG.ErrorHandler.AutoOpenErrors or false)
	if _G.SUIErrorDisplay then
		_G.SUIErrorDisplay:UpdateDisplay()
		_G.SUIErrorDisplay:updatemapIcon()
	end

	--Check for any SUI.DB changes
	if SUI.DB.SetupDone and (SUI.Version ~= SUI.DB.Version) and SUI.DB.Version ~= '0' then
		SUI:DBUpgrades()
	end

	if SUI.DB.SUIProper then
		SUI.print('---------------', true)
		SUI:Print('SpartanUI has detected an unsupported SUI5 profile is being used. Please reset your profile via /suihelp')
		SUI.print('---------------', true)
		---@type Frame | BackdropTemplate
		local SUI5Indicator = CreateFrame('Button', 'SUI5Profile', UIParent, BackdropTemplateMixin and 'BackdropTemplate')
		SUI5Indicator:SetFrameStrata('DIALOG')
		SUI5Indicator:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', 0, 0)
		SUI5Indicator:SetSize(20, 20)
		SUI5Indicator:SetBackdrop(
			{
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
				edgeFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
				edgeSize = 1
			}
		)
		SUI5Indicator:SetBackdropColor(1, 0, 0, .5)
		SUI5Indicator:SetBackdropBorderColor(0.00, 0.00, 0.00, 1)
		SUI5Indicator:HookScript(
			'OnEnter',
			function()
				SUI.print('---------------', true)
				SUI:Print('SpartanUI has detected an unsupported SUI5 profile is being used. Please reset your profile via /suihelp')
				SUI.print('---------------', true)
			end,
			'LE_SCRIPT_BINDING_TYPE_EXTRINSIC'
		)
	end

	-- Add Profiles to Options
	SUI.opt.args['Profiles'] = SUI.Lib.AceDBO:GetOptionsTable(SUI.SpartanUIDB)
	SUI.opt.args['Profiles'].order = 999

	-- Add dual-spec support
	local LibDualSpec = LibStub('LibDualSpec-1.0', true)
	if SUI.IsRetail and LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.SpartanUIDB, 'SpartanUI')
		LibDualSpec:EnhanceOptions(SUI.opt.args['Profiles'], self.SpartanUIDB)
	end

	-- Spec Setup
	SUI.SpartanUIDB.RegisterCallback(SUI, 'OnNewProfile', 'InitializeProfile')
	SUI.SpartanUIDB.RegisterCallback(SUI, 'OnProfileChanged', 'UpdateModuleConfigs')
	SUI.SpartanUIDB.RegisterCallback(SUI, 'OnProfileCopied', 'UpdateModuleConfigs')
	SUI.SpartanUIDB.RegisterCallback(SUI, 'OnProfileReset', 'UpdateModuleConfigs')

	--First Time Setup Actions
	if not SUI.DB.SetupDone then
		if LARGE_NUMBER_SEPERATOR == '.' then
			SUI.DB.font.NumberSeperator = '.'
		elseif LARGE_NUMBER_SEPERATOR == '' then
			SUI.DB.font.NumberSeperator = ''
		end
	end

	-- Setup ReloadUI Window
	reloaduiWindow()

	local ResetDBWarning = false
	local function resetdb()
		if ResetDBWarning then
			SUI.SpartanUIDB:ResetDB()
		else
			ResetDBWarning = true
			SUI:Print('|cffff0000Warning')
			SUI:Print(SUI.L['This will reset the SpartanUI Database. If you wish to continue perform the chat command again.'])
		end
	end

	local function resetfulldb()
		if ResetDBWarning then
			if Bartender4 then
				Bartender4.db:ResetDB()
			end
			SUI.SpartanUIDB:ResetDB()
		else
			ResetDBWarning = true
			SUI:Print('|cffff0000Warning')
			SUI:Print(SUI.L['This will reset the full SpartanUI & Bartender4 database. If you wish to continue perform the chat command again.'])
		end
	end

	local function resetbartender()
		SUI.opt.args['General'].args['Bartender'].args['ResetActionBars']:func()
	end

	local function Version()
		SUI:Print(SUI.L['Version'] .. ' ' .. GetAddOnMetadata('SpartanUI', 'Version'))
		SUI:Print(string.format('%s build %s', wowVersion, SUI.BuildNum))
		if SUI.Bartender4Version ~= 0 then
			SUI:Print(SUI.L['Bartender4 version'] .. ' ' .. SUI.Bartender4Version)
		end
	end

	SUI:AddChatCommand('version', Version, 'Displays version information to the chat')
	SUI:AddChatCommand('resetdb', resetdb, 'Reset SpartanUI settings')
	SUI:AddChatCommand('resetbartender', resetbartender, 'Reset all bartender4 settings')
	SUI:AddChatCommand('resetfulldb', resetfulldb, 'Reset bartender4 & SpartanUI settings (This is similar to deleting your WTF folder but will only effect this character)')
	if _G.SUIErrorDisplay then
		local function ErrHandler(arg)
			if arg == 'reset' then
				_G.SUIErrorDisplay:Reset()
			else
				_G.SUIErrorDisplay:OpenErrWindow()
			end
		end

		SUI:AddChatCommand(
			'errors',
			ErrHandler,
			'Display SUI Error handler',
			{
				reset = 'Clear all saved errors'
			}
		)
	end
end

function SUI:DBUpgrades()
	if SUI.DB.Artwork.Style == '' and SUI.DB.Artwork.SetupDone then
		SUI.DB.Artwork.Style = 'Classic'
	end

	SUI.DB.Version = SUI.Version
end

function SUI:InitializeProfile()
	SUI.SpartanUIDB:RegisterDefaults(DBdefaults)

	SUI:reloadui()
end
-- chat setup --

function SUI.Print(self, ...)
	local tmp = {}
	local n = 1
	tmp[1] = '|cffffffffSpartan|cffe21f1fUI|r:'
	for i = 1, select('#', ...) do
		n = n + 1
		tmp[n] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage(table.concat(tmp, ' ', 1, n))
end

function SUI.print(msg, doNotLabel)
	if doNotLabel then
		print(msg)
	else
		SUI:Print(msg)
	end
end

function SUI:Error(err, mod)
	if mod then
		SUI:Print("|cffff0000Error|c occured in the Module '" .. mod .. "'")
	else
		SUI:Print('|cffff0000Error occured')
	end
	SUI:Print('Details: ' .. (err or 'None provided'))
	SUI:Print('Please submit a bug at |cff3370FFhttp://bugs.spartanui.net/')
end

---------  Create SpartanUI Container  ---------
do
	-- Create Plate
	local plate = CreateFrame('Frame', 'SpartanUI', UIParent)
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetPoint('BOTTOMLEFT')
	plate:SetPoint('TOPRIGHT')

	-- Create Bottom Anchor
	local BottomAnchor = CreateFrame('Frame', 'SUI_BottomAnchor', SpartanUI)
	BottomAnchor:SetFrameStrata('BACKGROUND')
	BottomAnchor:SetFrameLevel(1)
	BottomAnchor:SetPoint('BOTTOM')
	BottomAnchor:SetSize(1000, 140)

	-- Create Top Anchor
	local TopAnchor = CreateFrame('Frame', 'SUI_TopAnchor', SpartanUI)
	TopAnchor:SetFrameStrata('BACKGROUND')
	TopAnchor:SetFrameLevel(1)
	TopAnchor:SetPoint('TOP')
	TopAnchor:SetSize(1000, 5)

	plate.TopAnchor = TopAnchor
	plate.BottomAnchor = BottomAnchor
end

---------------  Math and Comparison  ---------------

--[[
	Takes a target table and injects data from the source
	override allows the source to be put into the target
	even if its already populated
]]
function SUI:MergeData(target, source, override)
	if source == nil then
		return target
	end

	if type(target) ~= 'table' then
		target = {}
	end
	for k, v in pairs(source) do
		if type(v) == 'table' then
			target[k] = self:MergeData(target[k], v, override)
		else
			if override then
				target[k] = v
			elseif target[k] == nil then
				target[k] = v
			end
		end
	end
	return target
end

---Copied from AceDB this allows tables to be copied and used as a in memory dynamic db using the '*' and '**' wildcards
---@param dest any the table that will be updated
---@param source any The data that will be used to populate the dest, unless the target info exsists in the dest then it will be left alone
---@return any will return the dest table, this is not needed as LUA updates the dest obj you passed but can be useful for easy re-assignment
function SUI:CopyData(dest, source)
	if source == nil then
		return dest
	end

	if type(dest) ~= 'table' then
		dest = {}
	end
	for k, v in pairs(source) do
		if k == '*' or k == '**' then
			if type(v) == 'table' then
				-- This is a metatable used for table defaults
				local mt = {
					-- This handles the lookup and creation of new subtables
					__index = function(t, k)
						if k == nil then
							return nil
						end
						local tbl = {}
						SUI:CopyData(tbl, v)
						rawset(t, k, tbl)
						return tbl
					end
				}
				setmetatable(dest, mt)
				-- handle already existing tables in the SV
				for dk, dv in pairs(dest) do
					if not rawget(source, dk) and type(dv) == 'table' then
						SUI:CopyData(dv, v)
					end
				end
			else
				-- Values are not tables, so this is just a simple return
				local mt = {
					__index = function(t, k)
						return k ~= nil and v or nil
					end
				}
				setmetatable(dest, mt)
			end
		elseif type(v) == 'table' then
			if not rawget(dest, k) then
				rawset(dest, k, {})
			end
			if type(dest[k]) == 'table' then
				SUI:CopyData(dest[k], v)
				if source['**'] then
					SUI:CopyData(dest[k], source['**'])
				end
			end
		else
			if rawget(dest, k) == nil then
				rawset(dest, k, v)
			end
		end
	end
	return dest
end

function SUI:isPartialMatch(frameName, tab)
	local result = false

	for _, v in ipairs(tab) do
		local startpos, _ = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true
		end
	end

	return result
end

--[[
	Takes a target table and searches for the specified phrase
]]
function SUI:IsInTable(searchTable, searchPhrase, all)
	if searchTable == nil or searchPhrase == nil then
		SUI:Error('Invalid isInTable call', 'Core')
		return false
	end

	assert(type(searchTable) == 'table', "Invalid argument 'searchTable' in SUI:isInTable.")

	-- If All is specified then we are dealing with a 2 string table search both keys
	if all ~= nil then
		for k, v in ipairs(searchTable) do
			if v ~= nil and searchPhrase ~= nil then
				if (strlower(v) == strlower(searchPhrase)) then
					return true
				end
			end
			if k ~= nil and searchPhrase ~= nil then
				if (strlower(k) == strlower(searchPhrase)) then
					return true
				end
			end
		end
	else
		for _, v in ipairs(searchTable) do
			if v ~= nil and searchPhrase ~= nil then
				if (strlower(v) == strlower(searchPhrase)) then
					return true
				end
			end
		end
	end
	return false
end

function SUI:CopyTable(currentTable, defaultTable)
	if type(currentTable) ~= 'table' then
		currentTable = {}
	end

	if type(defaultTable) == 'table' then
		for option, value in pairs(defaultTable) do
			if type(value) == 'table' then
				value = self:CopyTable(currentTable[option], value)
			end

			currentTable[option] = value
		end
	end

	return currentTable
end

function SUI:CopyDefaults(dest, src)
	-- this happens if some value in the SV overwrites our default value with a non-table
	--if type(dest) ~= "table" then return end
	for k, v in pairs(src) do
		if k == '*' or k == '**' then
			if type(v) == 'table' then
				-- This is a metatable used for table defaults
				local mt = {
					-- This handles the lookup and creation of new subtables
					__index = function(t, k)
						if k == nil then
							return nil
						end
						local tbl = {}
						SUI:CopyDefaults(tbl, v)
						rawset(t, k, tbl)
						return tbl
					end
				}
				setmetatable(dest, mt)
				-- handle already existing tables in the SV
				for dk, dv in pairs(dest) do
					if not rawget(src, dk) and type(dv) == 'table' then
						SUI:CopyDefaults(dv, v)
					end
				end
			else
				-- Values are not tables, so this is just a simple return
				local mt = {
					__index = function(t, k)
						return k ~= nil and v or nil
					end
				}
				setmetatable(dest, mt)
			end
		elseif type(v) == 'table' then
			if not rawget(dest, k) then
				rawset(dest, k, {})
			end
			if type(dest[k]) == 'table' then
				SUI:CopyDefaults(dest[k], v)
				if src['**'] then
					SUI:CopyDefaults(dest[k], src['**'])
				end
			end
		else
			if rawget(dest, k) == nil then
				rawset(dest, k, v)
			end
		end
	end
end

function SUI:RemoveEmptySubTables(tbl)
	if type(tbl) ~= 'table' then
		print("Bad argument #1 to 'RemoveEmptySubTables' (table expected)")
		return
	end

	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			if next(v) == nil then
				tbl[k] = nil
			else
				self:RemoveEmptySubTables(v)
			end
		end
	end
end

--Compare 2 tables and remove duplicate key/value pairs
--param cleanTable : table you want cleaned
--param checkTable : table you want to check against.
--return : a copy of cleanTable with duplicate key/value pairs removed
function SUI:RemoveTableDuplicates(cleanTable, checkTable, customVars)
	if type(cleanTable) ~= 'table' then
		print("Bad argument #1 to 'RemoveTableDuplicates' (table expected)")
		return {}
	end
	if type(checkTable) ~= 'table' then
		print("Bad argument #2 to 'RemoveTableDuplicates' (table expected)")
		return {}
	end

	local rtdCleaned = {}
	for option, value in pairs(cleanTable) do
		if not customVars or (customVars[option] or checkTable[option] ~= nil) then
			-- we only want to add settings which are existing in the default table, unless it's allowed by customVars
			if type(value) == 'table' and type(checkTable[option]) == 'table' then
				rtdCleaned[option] = self:RemoveTableDuplicates(value, checkTable[option], customVars)
			elseif cleanTable[option] ~= checkTable[option] then
				-- add unique data to our clean table
				rtdCleaned[option] = value
			end
		end
	end

	--Clean out empty sub-tables
	self:RemoveEmptySubTables(rtdCleaned)

	return rtdCleaned
end

--Compare 2 tables and remove blacklisted key/value pairs
--cleanTable - table you want cleaned
--blacklistTable - table you want to check against.
--return - a copy of cleanTable with blacklisted key/value pairs removed
function SUI:FilterTableFromBlacklist(cleanTable, blacklistTable)
	if type(cleanTable) ~= 'table' then
		print("Bad argument #1 to 'FilterTableFromBlacklist' (table expected)")
		return {}
	end
	if type(blacklistTable) ~= 'table' then
		print("Bad argument #2 to 'FilterTableFromBlacklist' (table expected)")
		return {}
	end

	local tfbCleaned = {}
	for option, value in pairs(cleanTable) do
		if type(value) == 'table' and blacklistTable[option] and type(blacklistTable[option]) == 'table' then
			tfbCleaned[option] = self:FilterTableFromBlacklist(value, blacklistTable[option])
		else
			-- Filter out blacklisted keys
			if (blacklistTable[option] ~= true) then
				tfbCleaned[option] = value
			end
		end
	end

	--Clean out empty sub-tables
	self:RemoveEmptySubTables(tfbCleaned)

	return tfbCleaned
end

function SUI:TableToLuaString(inTable)
	local function recurse(table, level, ret)
		for i, v in pairs(table) do
			ret = ret .. strrep('    ', level) .. '['
			if type(i) == 'string' then
				ret = ret .. '"' .. i .. '"'
			else
				ret = ret .. i
			end
			ret = ret .. '] = '

			if type(v) == 'number' then
				ret = ret .. v .. ',\n'
			elseif type(v) == 'string' then
				ret = ret .. '"' .. v:gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('"', '\\"'):gsub('\124', '\124\124') .. '",\n'
			elseif type(v) == 'boolean' then
				if v then
					ret = ret .. 'true,\n'
				else
					ret = ret .. 'false,\n'
				end
			elseif type(v) == 'table' then
				ret = ret .. '{\n'
				ret = recurse(v, level + 1, ret)
				ret = ret .. strrep('    ', level) .. '},\n'
			else
				ret = ret .. '"' .. tostring(v) .. '",\n'
			end
		end

		return ret
	end
	if type(inTable) ~= 'table' then
		print('Invalid argument #1 to SUI:TableToLuaString (table expected)')
		return
	end

	local ret = '{\n'
	if inTable then
		ret = recurse(inTable, 1, ret)
	end
	ret = ret .. '}'

	return ret
end

function SUI:round(num, pos)
	if num then
		local mult = 10 ^ (pos or 2)
		return floor(num * mult + 0.5) / mult
	-- return floor((num * 10 ^ 2) + 0.5) / (10 ^ 2)
	end
end

---------------  Misc Backend  ---------------

function SUI:IsAddonEnabled(addon)
	return GetAddOnEnableState(UnitName('player'), addon) == 2
end

function SUI:IsAddonDisabled(addon)
	return not self:IsAddonEnabled(addon)
end

function SUI:GetAceAddon(addon)
	return LibStub('AceAddon-3.0'):GetAddon(addon, true)
end

function SUI:GetiLVL(itemLink)
	if not itemLink then
		return 0
	end

	local scanningTooltip = CreateFrame('GameTooltip', 'AutoTurnInTooltip', nil, 'GameTooltipTemplate')
	local itemLevelPattern = ITEM_LEVEL:gsub('%%d', '(%%d+)')
	local itemQuality = select(3, GetItemInfo(itemLink))

	-- if a heirloom return a huge number so we dont replace it.
	if (itemQuality == 7) then
		return math.huge
	end

	-- Scan the tooltip
	-- Setup the scanning tooltip
	-- Why do this here and not in OnEnable? If the player is not questing there is no need for this to exsist.
	scanningTooltip:SetOwner(UIParent, 'ANCHOR_NONE')

	-- If the item is not in the cache populate it.
	-- if not ilevel then
	-- Load tooltip
	scanningTooltip:SetHyperlink(itemLink)

	-- Find the iLVL inthe tooltip
	for i = 2, scanningTooltip:NumLines() do
		local line = _G['AutoTurnInTooltipTextLeft' .. i]
		if line:GetText():match(itemLevelPattern) then
			return tonumber(line:GetText():match(itemLevelPattern))
		end
	end
	return 0
end

function SUI:GoldFormattedValue(rawValue)
	local gold = math.floor(rawValue / 10000)
	local silver = math.floor((rawValue % 10000) / 100)
	local copper = (rawValue % 10000) % 100

	return format(GOLD_AMOUNT_TEXTURE .. ' ' .. SILVER_AMOUNT_TEXTURE .. ' ' .. COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0)
end

function SUI:UpdateModuleConfigs()
	SUI:reloadui()
end

function SUI:reloadui()
	SUI.reloaduiWindow:Show()
end

function SUI:SplitString(str, delim)
	assert(type(delim) == 'string' and strlen(delim) > 0, 'bad delimiter')
	local splitTable = {}
	local start = 1

	-- find each instance of a string followed by the delimiter
	while true do
		local pos = strfind(str, delim, start, true)
		if not pos then
			break
		end

		tinsert(splitTable, strsub(str, start, pos - 1))
		start = pos + strlen(delim)
	end

	-- insert final one (after last delimiter)
	tinsert(splitTable, strsub(str, start))

	return unpack(splitTable)
end

function SUI:OnEnable()
	local AceC = SUI.Lib.AceC
	local AceCD = SUI.Lib.AceCD

	AceC:RegisterOptionsTable(
		'SpartanUIBliz',
		{
			name = 'SpartanUI',
			type = 'group',
			args = {
				n3 = {
					type = 'description',
					fontSize = 'medium',
					order = 3,
					width = 'full',
					name = SUI.L['Options can be accessed by the button below or by typing /sui']
				},
				Close = {
					name = SUI.L['Launch Options'],
					width = 'full',
					type = 'execute',
					order = 50,
					func = function()
						while CloseWindows() do
						end
						AceCD:SetDefaultSize('SpartanUI', 850, 600)
						AceCD:Open('SpartanUI')
					end
				}
			}
		}
	)
	AceC:RegisterOptionsTable('SpartanUI', SUI.opt)

	AceCD:AddToBlizOptions('SpartanUIBliz', 'SpartanUI')
	AceCD:SetDefaultSize('SpartanUI', 1000, 700)

	SUI:RegisterChatCommand('sui', 'ChatCommand')
	SUI:RegisterChatCommand(
		'suihelp',
		function()
			SUI.Lib.AceCD:Open('SpartanUI', 'Help')
		end
	)
	SUI:RegisterChatCommand('spartanui', 'ChatCommand')

	--Reopen options screen if flagged to do so after a reloadui
	SUI:RegisterEvent(
		'PLAYER_ENTERING_WORLD',
		function()
			if SUI.DB.OpenOptions then
				SUI:ChatCommand()
				SUI.DB.OpenOptions = false
			end
		end
	)

	--Add to Menu Frame
	local SUIMenuButton = CreateFrame('Button', 'GameMenuButtonSUI', GameMenuFrame, 'GameMenuButtonTemplate')
	SUIMenuButton:SetScript(
		'OnClick',
		function()
			SUI:GetModule('Handler_Options'):ToggleOptions()
			if not InCombatLockdown() then
				HideUIPanel(GameMenuFrame)
			end
		end
	)
	SUIMenuButton:SetPoint('TOP', GameMenuButtonAddons, 'BOTTOM', 0, -1)
	GameMenuFrame.SUI = SUIMenuButton
	hooksecurefunc(
		'GameMenuFrame_UpdateVisibleButtons',
		function()
			GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + (GameMenuButtonSUI:GetHeight() * 1.8))

			GameMenuButtonSUI:SetFormattedText('|cffffffffSpartan|cffe21f1fUI|r')

			local _, relTo, _, _, offY = GameMenuButtonLogout:GetPoint()
			if relTo ~= GameMenuButtonSUI then
				GameMenuButtonSUI:ClearAllPoints()
				GameMenuButtonSUI:SetPoint('TOPLEFT', relTo, 'BOTTOMLEFT', 0, -2)
				GameMenuButtonLogout:ClearAllPoints()
				GameMenuButtonLogout:SetPoint('TOPLEFT', GameMenuButtonSUI, 'BOTTOMLEFT', 0, offY)
			end
		end
	)
end

-- For Setting a unifid skin across all registered Skinable modules
function SUI:SetActiveStyle(skin)
	SUI:GetModule('Module_Artwork'):SetActiveStyle(skin)

	for name, submodule in SUI:IterateModules() do
		if submodule.SetActiveStyle then
			submodule:SetActiveStyle(skin)
		end
	end

	-- Ensure this is the First and last thing to occur, iincase the art style has any StyleUpdate's needed after doing the other updates
	SUI:GetModule('Module_Artwork'):SetActiveStyle(skin)
end
