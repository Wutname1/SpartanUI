local _, SUI = ...
SUI = LibStub('AceAddon-3.0'):NewAddon(SUI, 'SpartanUI', 'AceEvent-3.0', 'AceConsole-3.0', 'AceSerializer-3.0')
_G.SUI = SUI
local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)
local _G = _G
local type, pairs = type, pairs
SUI.L = L
SUI.Version = GetAddOnMetadata('SpartanUI', 'Version') or 0
SUI.BuildNum = GetAddOnMetadata('SpartanUI', 'X-Build') or 0
SUI.Bartender4Version = (GetAddOnMetadata('Bartender4', 'Version') or 0)
SUI.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
SUI.IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
SUI.GitHash = '@project-abbreviated-hash@' -- The ZIP packager will replace this with the Git hash.
local wowVersion = 'Retail'
if SUI.IsClassic then
	wowVersion = 'Classic'
end
--@alpha@
SUI.releaseType = 'ALPHA build ' .. SUI.BuildNum
--@end-alpha@
--@do-not-package@
SUI.releaseType = 'DEV Build'
SUI.Version = ''
--@end-do-not-package@

---------------  Add Libraries ---------------

SUI.Lib = {}
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
SUI.AddLib('Compress', 'LibCompress')
SUI.AddLib('Base64', 'LibBase64-1.0')
SUI.AddLib('StdUi', 'StdUi')

--init StdUI Instance for the whole addon
SUI.StdUi = SUI.Lib.StdUi:NewInstance()

---------------  Options Init ---------------
SUI.opt = {
	name = string.format('SpartanUI %s %s %s', SUI.Version, SUI.releaseType or '', wowVersion),
	type = 'group',
	childGroups = 'tree',
	args = {
		General = {name = L['General'], type = 'group', order = 0, args = {}},
		Artwork = {name = L['Artwork'], type = 'group', order = 1, args = {}}
	}
}
---------------  Database  ---------------
local DBdefault = {
	Version = '0',
	SetupDone = false,
	scale = .88,
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
	AutoSell = {
		FirstLaunch = true,
		NotCrafting = true,
		NotConsumables = true,
		NotInGearset = true,
		MaxILVL = 100,
		Gray = true,
		White = false,
		Green = false,
		Blue = false,
		Purple = false,
		GearTokens = false,
		AutoRepair = false,
		UseGuildBankRepair = false
	},
	AutoTurnIn = {
		ChatText = true,
		FirstLaunch = true,
		debug = false,
		TurnInEnabled = true,
		AutoGossip = true,
		AutoGossipSafeMode = true,
		AcceptGeneralQuests = true,
		AcceptRepeatable = false,
		trivial = false,
		lootreward = false,
		autoequip = false,
		armor = {},
		weapon = {},
		stat = {},
		secondary = {},
		Blacklist = {}
	},
	BuffSettings = {
		disableblizz = true,
		enabled = true,
		Manualoffset = false,
		offset = 0
	},
	DisabledComponents = {},
	font = {
		NumberSeperator = ',',
		Path = '',
		Modules = {
			['**'] = {
				Size = 0,
				Face = 'Roboto-Bold',
				Type = 'outline'
			}
		}
	},
	MiniMap = {
		northTag = false,
		ManualAllowUse = false,
		ManualAllowPrompt = '',
		AutoDetectAllowUse = true,
		MapButtons = true,
		MouseIsOver = false,
		MapZoomButtons = true,
		MapTimeIndicator = false,
		DisplayMapCords = true,
		DisplayZoneName = true,
		Shape = 'square',
		BlizzStyle = 'mouseover',
		OtherStyle = 'mouseover',
		Moved = false,
		lockminimap = true,
		Position = nil,
		SUIMapChangesActive = false
	},
	MoveIt = {
		AltKey = false,
		tips = true,
		movers = {
			['**'] = {
				defaultPoint = false,
				MovedPoints = false
			}
		}
	},
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
			Frames = {
				player = {
					Buffs = {
						Display = true,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = false,
						Mode = 'both'
					},
					Debuffs = {
						Display = true,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = true,
						Mode = 'both'
					}
				},
				target = {
					Buffs = {
						Display = true,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = false,
						Mode = 'both'
					},
					Debuffs = {
						Display = true,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = true,
						Mode = 'bars'
					}
				},
				targettarget = {
					Buffs = {
						Display = false,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = false,
						Mode = 'disabled'
					},
					Debuffs = {
						Display = true,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = true,
						Mode = 'icons'
					}
				},
				pet = {
					Buffs = {
						Display = true,
						Number = 10,
						size = 15,
						spacing = 1,
						showType = true,
						onlyShowPlayer = false,
						Mode = 'icons'
					},
					Debuffs = {
						Display = true,
						Number = 10,
						size = 15,
						spacing = 1,
						showType = true,
						onlyShowPlayer = false,
						Mode = 'icons'
					}
				},
				focus = {
					Buffs = {
						Display = true,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = false,
						Mode = 'icons'
					},
					Debuffs = {
						Display = true,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = true,
						Mode = 'icons'
					}
				},
				focustarget = {
					Buffs = {
						Display = false,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = false,
						Mode = 'disabled'
					},
					Debuffs = {
						Display = false,
						Number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = true,
						Mode = 'disabled'
					}
				}
			},
			Minimap = {
				Movable = true,
				shape = 'circle',
				size = {140, 140},
				scaleWithArt = true,
				UnderVehicleUI = true,
				BG = {
					enabled = true,
					BlendMode = 'ADD',
					alpha = 1
				},
				ZoneText = {
					size = {100, 12},
					scale = 1,
					position = 'TOP,Minimap,BOTTOM,0,-4',
					TextColor = {1, .82, 0, 1},
					ShadowColor = {0, 0, 0, 1}
				},
				coords = {
					scale = 1,
					size = {80, 12},
					position = 'TOP,MinimapZoneText,BOTTOM,0,-4',
					TextColor = {1, .82, 0, 1},
					ShadowColor = {0, 0, 0, 1}
				}
			},
			Movers = {},
			BlizzMovers = {
				['TalkingHead'] = 'TOP,SpartanUI,TOP,0,-18',
				['AltPowerBar'] = 'TOP,SpartanUI,TOP,0,-18',
				['ZoneAbility'] = 'CENTER,SpartanUI,CENTER,0,-172',
				['ExtraAction'] = 'CENTER,SpartanUI,CENTER,0,-172',
				['AlertFrame'] = 'BOTTOM,SpartanUI,BOTTOM,0,215',
				['VehicleLeaveButton'] = 'LEFT,SUI_UF_player,RIGHT,20,0'
			},
			Color = {
				Art = false,
				PlayerFrames = false,
				PartyFrames = false,
				RaidFrames = false
			}
		},
		Arcane = {
			Artwork = {},
			StatusBars = {
				['**'] = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\StatusBar',
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
					artwork = {
						top = {
							enabled = true,
							graphic = 'ArcaneBlue'
						},
						bg = {
							enabled = true,
							graphic = 'ArcaneBlue'
						},
						bottom = {
							enabled = true,
							graphic = 'ArcaneBlue'
						}
					},
					elements = {
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
					artwork = {
						top = {
							enabled = true,
							graphic = 'ArcaneBlue'
						},
						bg = {
							enabled = true,
							graphic = 'ArcaneBlue'
						},
						bottom = {
							enabled = true,
							graphic = 'ArcaneBlue'
						}
					},
					elements = {
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
			Minimap = {
				size = {156, 156},
				BG = {
					texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\minimap'
				},
				coords = {
					position = 'TOP,MinimapZoneText,BOTTOM,0,-4'
				},
				position = 'CENTER,SUI_Art_Arcane_Left,RIGHT,0,20'
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
		Classic = {
			Frames = {
				player = {
					artwork = {
						full = {
							enabled = true,
							graphic = 'Classic'
						}
					},
					Buffs = {Mode = 'icons'},
					Debuffs = {Mode = 'icons'},
					elements = {
						Portrait = {
							position = 'right'
						}
					}
				},
				target = {
					artwork = {
						full = {
							enabled = true,
							graphic = 'Classic'
						}
					},
					Buffs = {Mode = 'icons'},
					Debuffs = {Mode = 'bars'}
				},
				pet = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}},
				targettarget = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}},
				focus = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}}
			},
			Minimap = {
				Movable = false,
				size = {156, 156},
				coords = {
					position = 'TOP,MinimapZoneText,BOTTOM,0,-4'
				},
				position = 'CENTER,SUI_Art_Classic_Center,CENTER,0,0'
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
				['VehicleLeaveButton'] = 'BOTTOM,SUI_Art_Classic,TOP,0,80'
			}
		},
		Transparent = {
			Frames = {
				player = {
					artwork = {
						top = {
							enabled = true,
							graphic = 'Transparent'
						},
						bg = {
							enabled = true,
							graphic = 'Transparent'
						}
					},
					Buffs = {Mode = 'icons'},
					Debuffs = {Mode = 'icons'}
				},
				target = {
					artwork = {
						top = {
							enabled = true,
							graphic = 'Transparent'
						},
						bg = {
							enabled = true,
							graphic = 'Transparent'
						}
					},
					Buffs = {Mode = 'icons'},
					Debuffs = {Mode = 'bars'}
				},
				pet = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}},
				targettarget = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}},
				focus = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}}
			},
			Minimap = {
				shape = 'square',
				size = {135, 135},
				position = 'CENTER,SUI_Art_Transparent,CENTER,0,-5',
				ZoneText = {
					size = {130, 12},
					position = 'BOTTOM,Minimap,TOP,0,2'
				},
				coords = {
					size = {80, 12},
					position = 'BOTTOM,Minimap,BOTTOM,0,2'
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
			Minimap = {
				UnderVehicleUI = false,
				scaleWithArt = false,
				position = 'TOPRIGHT,SUI_Art_Minimal_Base3,TOPRIGHT,-10,-10',
				shape = 'square'
			},
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
					artwork = {
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
					elements = {
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
					artwork = {
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
					elements = {
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
			},
			Minimap = {
				size = {156, 156},
				BG = {
					texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Minimap-Engulfed',
					size = {330, 330},
					position = 'CENTER,Minimap,CENTER,7,37'
				},
				coords = {
					position = 'TOP,MinimapZoneText,BOTTOM,0,-4',
					scale = 1.2
				},
				position = 'CENTER,SUI_Art_Fel,CENTER,0,54',
				engulfed = true
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
					artwork = {
						bg = {
							enabled = true,
							graphic = 'Digital'
						}
					}
				},
				target = {
					artwork = {
						bg = {
							enabled = true,
							graphic = 'Digital'
						}
					}
				}
			},
			Minimap = {
				size = {156, 156},
				BG = {
					texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\Minimap',
					position = {'TOPLEFT,Minimap,TOPLEFT,-38,41', 'BOTTOMRIGHT,Minimap,BOTTOMRIGHT,47,-44'}
				},
				coords = {
					position = 'TOP,MinimapZoneText,BOTTOM,0,-4',
					scale = 1.2
				},
				position = 'CENTER,SUI_Art_Digital,CENTER,0,54'
			}
		},
		War = {
			Artwork = {},
			StatusBars = {
				['**'] = {
					bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
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
					artwork = {
						top = {
							enabled = true,
							graphic = 'war'
						},
						bg = {
							enabled = true,
							graphic = 'war'
						},
						bottom = {
							enabled = true,
							graphic = 'war'
						}
					},
					elements = {
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
					artwork = {
						top = {
							enabled = true,
							graphic = 'war'
						},
						bg = {
							enabled = true,
							graphic = 'war'
						},
						bottom = {
							enabled = true,
							graphic = 'war'
						}
					},
					elements = {
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
			Minimap = {
				size = {156, 156},
				BG = {
					texture = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\minimap'
				},
				coords = {
					position = 'TOP,MinimapZoneText,BOTTOM,0,-4'
				},
				position = 'CENTER,SUI_Art_War_Left,RIGHT,0,20'
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
	Tooltips = {
		Styles = {
			metal = {
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\textures\\metal',
				tile = false
			},
			smooth = {
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2',
				tile = false
			},
			smoke = {
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\textures\\smoke',
				tile = false
			},
			none = {
				bgFile = 'Interface\\AddOns\\SpartanUI\\images\\blank.tga',
				tile = false
			}
		},
		ActiveStyle = 'smoke',
		VendorPrices = true,
		Override = {},
		ColorOverlay = true,
		Color = {0, 0, 0, 0.4},
		SuppressNoMatch = true
	},
	Unitframes = {
		Style = 'War',
		FrameOptions = {
			['**'] = {
				enabled = true,
				width = 180,
				moved = false,
				position = {
					point = 'BOTTOM',
					relativePoint = 'BOTTOM',
					xOfs = 0,
					yOfs = 0
				},
				artwork = {
					full = {
						enabled = false,
						x = 0,
						y = 0,
						alpha = 1,
						graphic = ''
					},
					top = {
						enabled = false,
						x = 0,
						y = 0,
						alpha = 1,
						graphic = ''
					},
					bg = {
						enabled = false,
						x = 0,
						y = 0,
						alpha = 1,
						graphic = ''
					},
					bottom = {
						enabled = false,
						x = 0,
						y = 0,
						alpha = 1,
						graphic = ''
					}
				},
				auras = {
					['**'] = {
						enabled = false,
						number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						onlyShowPlayer = false,
						initialAnchor = 'BOTTOMLEFT',
						growthx = 'RIGHT',
						growthy = 'UP',
						rows = 3,
						position = {
							anchor = 'TOPRIGHT',
							x = 0,
							y = 20
						},
						filters = {
							minDuration = 0,
							maxDuration = 600,
							priority = ''
						}
					},
					Buffs = {
						number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						initialAnchor = 'BOTTOMLEFT',
						growthx = 'RIGHT',
						growthy = 'UP',
						position = {
							anchor = 'TOPLEFT'
						},
						filters = {
							priority = 'Blacklist,blockNoDuration,Personal,TurtleBuffs,PlayerBuffs'
						}
					},
					Debuffs = {
						enabled = true,
						ShowBoss = true,
						initialAnchor = 'BOTTOMRIGHT',
						growthx = 'LEFT',
						growthy = 'UP'
					},
					Bars = {
						auraBarHeight = 15,
						auraBarWidth = false,
						auraBarTexture = Smoothv2,
						fgalpha = 1,
						bgalpha = 1,
						spellNameSize = 10,
						spellTimeSize = 10,
						gap = 1,
						spacing = 1,
						scaleTime = false,
						position = {
							anchor = 'TOP'
						}
					}
				},
				elements = {
					['**'] = {
						enabled = false,
						Scale = 1,
						bgTexture = false,
						points = false,
						alpha = 1,
						width = 20,
						height = 20,
						size = 20,
						scale = 1,
						bg = {
							enabled = false,
							color = false
						},
						text = {
							['**'] = {
								enabled = false,
								text = '',
								size = 10,
								SetJustifyH = 'CENTER',
								SetJustifyV = 'MIDDLE',
								position = {
									anchor = 'CENTER',
									x = 0,
									y = 0
								}
							},
							['1'] = {
								enabled = false,
								position = {}
							},
							['2'] = {
								enabled = false,
								position = {}
							}
						},
						position = {
							anchor = 'CENTER',
							x = 0,
							y = 0
						}
					},
					DispelHighlight = {
						enabled = true,
						position = {
							anchor = nil
						}
					},
					HappinessIndicator = {
						enabled = true,
						position = {
							anchor = 'LEFT',
							x = -10,
							y = -10
						}
					},
					Portrait = {
						type = '3D',
						scaleWithFrame = true,
						width = 50,
						height = 100,
						rotation = 0,
						camDistanceScale = 1,
						xOffset = 0,
						yOffset = 0,
						position = 'left'
					},
					Health = {
						enabled = true,
						height = 40,
						offset = 1,
						colorReaction = false,
						colorSmooth = true,
						colorClass = true,
						colorTapping = true,
						colorDisconnected = true,
						bg = {
							enabled = true,
							color = {1, 1, 1, .2}
						},
						text = {
							['1'] = {
								enabled = true,
								text = '[curhpformatted] / [maxhpformatted]',
								position = {
									anchor = 'CENTER',
									x = 0,
									y = 0
								}
							}
						}
					},
					HealthPrediction = {
						enabled = true
					},
					Power = {
						enabled = true,
						height = 10,
						offset = 1,
						bg = {
							enabled = true,
							color = {1, 1, 1, .2}
						},
						text = {
							['1'] = {
								enabled = false,
								text = '[curppformatted] / [maxppformatted]'
							},
							['2'] = {
								enabled = false,
								text = '[perpp]%'
							}
						}
					},
					AdditionalPower = {
						enabled = true,
						offset = 1,
						height = 5
					},
					Castbar = {
						enabled = false,
						height = 10,
						offset = 0,
						interruptable = true,
						latency = false,
						bg = {
							enabled = true,
							color = {1, 1, 1, .2}
						},
						Icon = {
							enabled = true,
							size = 12,
							position = {
								anchor = 'LEFT',
								x = 0,
								y = 0
							}
						},
						text = {
							['1'] = {
								enabled = true,
								text = '[Spell name]',
								position = {
									anchor = 'CENTER',
									x = 0,
									y = 0
								}
							},
							['2'] = {
								enabled = true,
								text = '[Spell timer]',
								size = 8,
								position = {
									anchor = 'RIGHT',
									x = 0,
									y = 0
								}
							}
						}
					},
					Name = {
						enabled = true,
						height = 12,
						size = 12,
						text = '[difficulty][smartlevel] [SUI_ColorClass][name]',
						SetJustifyH = 'CENTER',
						SetJustifyV = 'MIDDLE',
						position = {
							anchor = 'TOP',
							x = 0,
							y = 15
						}
					},
					LeaderIndicator = {
						enabled = true,
						size = 12,
						position = {
							anchor = 'TOP',
							x = 0,
							y = 6
						}
					},
					RestingIndicator = {},
					GroupRoleIndicator = {
						enabled = true,
						size = 18,
						alpha = .75,
						position = {
							anchor = 'TOPRIGHT',
							x = -10,
							y = 10
						}
					},
					CombatIndicator = {},
					RaidTargetIndicator = {
						enabled = true,
						size = 20,
						position = {
							anchor = 'BOTTOMRIGHT',
							x = 5,
							y = -10
						}
					},
					SUI_ClassIcon = {
						position = {
							anchor = 'BOTTOMLEFT',
							x = -12,
							y = 0
						}
					},
					ReadyCheckIndicator = {
						enabled = true,
						size = 35,
						position = {
							anchor = 'LEFT',
							x = 0,
							y = 0
						}
					},
					PvPIndicator = {
						Badge = false,
						Shadow = true,
						position = {
							anchor = 'TOPLEFT',
							x = -10
						}
					},
					StatusText = {
						size = 22,
						SetJustifyH = 'CENTER',
						SetJustifyV = 'MIDDLE',
						position = {
							anchor = 'CENTER',
							x = 0,
							y = 0
						}
					},
					Runes = {
						enabled = true
					},
					Stagger = {},
					Totems = {},
					AssistantIndicator = {
						enabled = true,
						size = 12,
						position = {
							anchor = 'TOP',
							x = 0,
							y = 6
						}
					},
					RaidRoleIndicator = {
						enabled = true
					},
					ResurrectIndicator = {
						enabled = true
					},
					SummonIndicator = {},
					QuestMobIndicator = {
						position = {
							anchor = 'RIGHT'
						}
					},
					Range = {
						enabled = true,
						insideAlpha = 1,
						outsideAlpha = .3
					},
					PhaseIndicator = {
						enabled = true,
						position = {
							anchor = 'TOP',
							x = 0,
							y = 0
						}
					},
					ThreatIndicator = {
						enabled = true
					},
					SUI_RaidGroup = {},
					RareElite = {
						enabled = true,
						alpha = .4,
						points = {
							['1'] = {
								anchor = 'TOPLEFT',
								x = 0,
								y = 0
							},
							['2'] = {
								anchor = 'BOTTOMRIGHT',
								x = 0,
								y = 0
							}
						}
					}
				}
			},
			arena = {
				enabled = true,
				maxColumns = 1,
				unitsPerColumn = 5,
				columnSpacing = 1,
				yOffset = -15,
				elements = {
					Name = {text = '[SUI_ColorClass][name] [arenaspec]'},
					Power = {
						height = 5
					},
					Castbar = {
						enabled = true,
						height = 15
					},
					SUI_ClassIcon = {
						enabled = true
					}
				}
			},
			boss = {
				enabled = true,
				width = 120,
				maxColumns = 1,
				unitsPerColumn = 5,
				columnSpacing = 0,
				yOffset = -10,
				auras = {
					Buffs = {
						enabled = true,
						size = 10
					}
				},
				elements = {
					Portrait = {
						enabled = true,
						type = '2D'
					},
					Castbar = {
						enabled = true
					}
				}
			},
			bosstarget = {},
			focus = {
				enabled = true,
				width = 100,
				auras = {
					Buffs = {
						enabled = true,
						onlyShowPlayer = true
					},
					Debuffs = {
						enabled = true,
						onlyShowPlayer = true
					}
				},
				elements = {
					Castbar = {
						enabled = true
					}
				}
			},
			focustarget = {
				enabled = true,
				width = 90,
				elements = {
					Castbar = {
						enabled = true
					}
				}
			},
			player = {
				enabled = true,
				anchor = {
					point = 'BOTTOMRIGHT',
					relativePoint = 'BOTTOM',
					xOfs = -60,
					yOfs = 250
				},
				auras = {
					Buffs = {
						enabled = true
					},
					Debuffs = {
						enabled = true
					},
					Bars = {
						enabled = true
					}
				},
				elements = {
					Portrait = {
						enabled = true
					},
					Castbar = {
						enabled = true
					},
					CombatIndicator = {
						enabled = true,
						position = {
							anchor = 'TOPRIGHT',
							x = 10,
							y = 10
						}
					},
					SUI_ClassIcon = {
						enabled = true
					},
					RestingIndicator = {
						enabled = true,
						position = {
							anchor = 'TOPLEFT',
							x = 0,
							y = 0
						}
					},
					Power = {
						text = {
							['1'] = {
								enabled = true
							}
						}
					},
					PvPIndicator = {
						enabled = true
					},
					AdditionalPower = {
						enabled = true
					}
				}
			},
			pet = {
				width = 100,
				elements = {
					Health = {
						height = 30
					},
					Power = {
						height = 5,
						text = {
							['1'] = {
								enabled = false
							}
						}
					},
					Name = {
						enabled = true,
						height = 10,
						size = 10,
						position = {
							y = 0
						}
					}
				}
			},
			pettarget = {},
			party = {
				width = 120,
				enabled = true,
				showSelf = true,
				showSolo = false,
				showParty = true,
				showRaid = false,
				xOffset = 0,
				yOffset = -10,
				maxColumns = 1,
				unitsPerColumn = 5,
				columnSpacing = 2,
				auras = {
					Buffs = {
						enabled = true,
						size = 10
					},
					Debuffs = {
						enabled = true,
						size = 16
					}
				},
				elements = {
					Castbar = {
						enabled = true
					},
					ResurrectIndicator = {
						enabled = true
					},
					SummonIndicator = {
						enabled = true
					},
					RaidRoleIndicator = {
						enabled = true
					},
					AssistantIndicator = {
						enabled = true
					},
					SUI_ClassIcon = {
						enabled = true
					}
				}
			},
			partypet = {},
			partytarget = {},
			raid = {
				enabled = true,
				width = 95,
				showParty = true,
				showSelf = true,
				showSolo = false,
				mode = 'NAME',
				xOffset = 2,
				yOffset = 2,
				maxColumns = 4,
				unitsPerColumn = 10,
				columnSpacing = 2,
				auras = {
					Buffs = {
						enabled = true,
						size = 10
					},
					Debuffs = {
						enabled = true,
						size = 10
					}
				},
				elements = {
					Health = {
						height = 30
					},
					Power = {
						height = 5,
						text = {
							['1'] = {
								enabled = false
							}
						}
					},
					ResurrectIndicator = {
						enabled = true
					},
					SummonIndicator = {
						enabled = true
					},
					RaidRoleIndicator = {
						enabled = true
					},
					Name = {
						enabled = true,
						height = 10,
						size = 10,
						position = {
							y = 0
						}
					}
				}
			},
			target = {
				enabled = true,
				anchor = {
					point = 'BOTTOMLEFT',
					relativePoint = 'BOTTOM',
					xOfs = 60,
					yOfs = 250
				},
				auras = {
					Buffs = {
						enabled = true
					},
					Debuffs = {
						enabled = true
					},
					Bars = {
						enabled = true
					}
				},
				elements = {
					Portrait = {
						enabled = true
					},
					Castbar = {
						enabled = true
					},
					QuestMobIndicator = {
						enabled = true
					},
					RaidRoleIndicator = {
						enabled = true
					},
					AssistantIndicator = {
						enabled = true
					},
					SUI_ClassIcon = {
						enabled = true
					},
					PvPIndicator = {
						enabled = true
					},
					Power = {
						text = {
							['1'] = {
								enabled = true
							}
						}
					}
				}
			},
			targettarget = {
				enabled = true,
				width = 100,
				auras = {
					Debuffs = {
						size = 10
					}
				},
				elements = {
					Castbar = {
						enabled = false
					},
					Health = {
						height = 30
					},
					Power = {
						height = 5
					}
				}
			}
		},
		PlayerCustomizations = {
			['**'] = {
				['**'] = {
					anchor = {},
					artwork = {
						full = {},
						top = {},
						bg = {},
						bottom = {}
					},
					auras = {
						Buffs = {
							position = {}
						},
						Debuffs = {
							position = {}
						},
						Bars = {
							position = {}
						}
					},
					elements = {
						['**'] = {
							bg = {}
						},
						Portrait = {},
						Health = {
							text = {
								['1'] = {
									position = {}
								},
								['2'] = {
									position = {}
								}
							}
						},
						DispelHighlight = {
							enabled = true
						},
						HealthPrediction = {},
						HappinessIndicator = {
							position = {}
						},
						Power = {
							position = {},
							text = {
								['1'] = {
									position = {}
								},
								['2'] = {
									position = {}
								}
							}
						},
						Castbar = {
							Icon = {
								position = {}
							},
							text = {
								['1'] = {
									position = {}
								},
								['2'] = {
									position = {}
								}
							}
						},
						Name = {
							position = {}
						},
						LeaderIndicator = {
							position = {}
						},
						RestingIndicator = {
							position = {}
						},
						GroupRoleIndicator = {
							position = {}
						},
						CombatIndicator = {
							position = {}
						},
						RaidTargetIndicator = {
							position = {}
						},
						SUI_ClassIcon = {
							position = {}
						},
						ReadyCheckIndicator = {
							position = {}
						},
						PvPIndicator = {
							position = {}
						},
						StatusText = {
							position = {}
						},
						AdditionalPower = {},
						Runes = {},
						Stagger = {},
						Totems = {},
						AssistantIndicator = {},
						RaidRoleIndicator = {},
						ResurrectIndicator = {},
						SummonIndicator = {},
						QuestMobIndicator = {},
						Range = {},
						phaseindicator = {},
						ThreatIndicator = {},
						SUI_RaidGroup = {}
					},
					font = {
						mana = {},
						health = {}
					}
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
	},
	TauntWatcher = {
		active = {
			always = false,
			inBG = false,
			inRaid = true,
			inParty = true,
			inArena = true,
			outdoors = false
		},
		failures = true,
		FirstLaunch = true,
		announceLocation = 'SELF',
		text = '%who taunted %what!'
	},
	FilmEffects = {
		enable = false,
		animationInterval = 0,
		anim = '',
		vignette = nil
	},
	NamePlates = {
		ShowThreat = true,
		ShowName = true,
		ShowLevel = true,
		ShowTarget = true,
		ShowRaidTargetIndicator = true,
		onlyShowPlayer = true,
		showStealableBuffs = false,
		Scale = 1,
		elements = {
			['**'] = {
				enabled = true,
				alpha = 1,
				size = 20,
				position = {
					anchor = 'CENTER',
					x = 0,
					y = 0
				}
			},
			RareElite = {},
			Background = {
				type = 'solid',
				colorMode = 'reaction',
				alpha = 0.35
			},
			Name = {
				SetJustifyH = 'CENTER'
			},
			QuestMobIndicator = {},
			Health = {
				height = 5,
				colorTapping = true,
				colorReaction = false,
				colorSmooth = true,
				colorClass = true
			},
			Power = {
				ShowPlayerPowerIcons = true,
				height = 3
			},
			Castbar = {
				height = 5,
				text = true,
				FlashOnInterruptible = true
			},
			SUI_ClassIcon = {
				enabled = false,
				size = 20,
				visibleOn = 'PlayerControlled',
				position = {
					anchor = 'TOP',
					x = 0,
					y = 40
				}
			},
			XPBar = {
				height = 5,
				Offset = -10
			}
		}
	}
}

local DBdefaults = {profile = DBdefault}
SUI.SpartanUIDB = LibStub('AceDB-3.0'):New('SpartanUIDB', DBdefaults)
--If user has not played in a long time reset the database.
local ver = SUI.SpartanUIDB.profile.Version
if (ver ~= '0' and ver < '6.0.0') then
	SUI.SpartanUIDB:ResetDB()
end

-- New SUI.DB Access
SUI.DBG = SUI.SpartanUIDB.global
SUI.DB = SUI.SpartanUIDB.profile

local function reloaduiWindow()
	local StdUi = LibStub('StdUi')
	local popup = StdUi:Window(nil, 400, 140)
	popup:SetPoint('TOP', 0, -20)
	popup:SetFrameStrata('DIALOG')
	popup:Hide()

	popup.Title = StdUi:Texture(popup, 156, 45, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	popup.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	popup.Title:SetPoint('TOP')
	popup.Title:SetAlpha(.8)

	-- Create Popup Items
	popup.ReloadMsg = StdUi:Label(popup, 'A reload of your UI is required.', 20)
	popup.ExtraMsg = StdUi:Label(popup, (Desc2 or ''), 20, nil, 400)
	popup.btnClose = StdUi:HighlightButton(popup, 50, 20, 'CLOSE')
	popup.btnReload = StdUi:Button(popup, 180, 20, 'RELOAD UI')

	-- Position
	StdUi:GlueTop(popup.ReloadMsg, popup, 0, -50)
	StdUi:GlueTop(popup.ExtraMsg, popup.ReloadMsg, 0, -20)
	popup.btnReload:SetPoint('BOTTOM', popup, 'BOTTOM', 0, 4)
	popup.btnClose:SetPoint('BOTTOMRIGHT', popup, 'BOTTOMRIGHT', -4, 4)

	-- Actions
	popup.btnClose:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Next action
			popup:Hide()
		end
	)
	popup.btnReload:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Next action
			ReloadUI()
		end
	)

	SUI.reloaduiWindow = popup
end

function SUI:OnInitialize()
	SUI.SpartanUIDB = LibStub('AceDB-3.0'):New('SpartanUIDB', DBdefaults)

	-- New SUI.DB Access
	SUI.DBG = SUI.SpartanUIDB.global
	SUI.DB = SUI.SpartanUIDB.profile

	--Check for any SUI.DB changes
	if SUI.DB.SetupDone and (SUI.Version ~= SUI.DB.Version) and SUI.DB.Version ~= '0' then
		SUI:DBUpgrades()
	end

	-- Add Profiles to Options
	SUI.opt.args['Profiles'] = LibStub('AceDBOptions-3.0'):GetOptionsTable(SUI.SpartanUIDB)
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
		if _G.LARGE_NUMBER_SEPERATOR == '.' then
			SUI.DB.font.NumberSeperator = '.'
		elseif _G.LARGE_NUMBER_SEPERATOR == '' then
			SUI.DB.font.NumberSeperator = ''
		end
	end

	-- Setup ReloadUI Window
	reloaduiWindow()
end

function SUI:DBUpgrades()
	if SUI.DB.SUIProper then
		SUI.SpartanUIDB:ResetDB()
		ReloadUI()
	end

	SUI.DB.Version = SUI.Version
end

function SUI:InitializeProfile()
	SUI.SpartanUIDB:RegisterDefaults(SUI.DBdefaults)

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
	SUI:Print('|cffff0000Error detected')
	if mod then
		SUI:Print("An error has occured in the Component '" .. mod .. "'")
	else
		SUI:Print('An error has occured')
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

function SUI:isPartialMatch(frameName, tab)
	local result = false

	for _, v in ipairs(tab) do
		local startpos, endpos = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true
		end
	end

	return result
end

--[[
	Takes a target table and searches for the specified phrase
]]
function SUI:isInTable(searchTable, searchPhrase, all)
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
		return
	end
	if type(checkTable) ~= 'table' then
		print("Bad argument #2 to 'RemoveTableDuplicates' (table expected)")
		return
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
		return
	end
	if type(blacklistTable) ~= 'table' then
		print("Bad argument #2 to 'FilterTableFromBlacklist' (table expected)")
		return
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

function SUI:round(num) -- rounds a number to 2 decimal places
	if num then
		return floor((num * 10 ^ 2) + 0.5) / (10 ^ 2)
	end
end

---------------  Misc Backend  ---------------

function SUI:GetiLVL(itemLink)
	if not itemLink then
		return 0
	end

	local scanningTooltip = CreateFrame('GameTooltip', 'AutoTurnInTooltip', nil, 'GameTooltipTemplate')
	local itemLevelPattern = _G.ITEM_LEVEL:gsub('%%d', '(%%d+)')
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

	return format(
		GOLD_AMOUNT_TEXTURE .. ' ' .. SILVER_AMOUNT_TEXTURE .. ' ' .. COPPER_AMOUNT_TEXTURE,
		gold,
		0,
		0,
		silver,
		0,
		0,
		copper,
		0,
		0
	)
end

function SUI:UpdateModuleConfigs()
	SUI:reloadui()
end

function SUI:reloadui()
	SUI.reloaduiWindow:Show()
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
					name = L['Options can be accessed by the button below or by typing /sui']
				},
				Close = {
					name = 'Launch Options',
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

	self:RegisterChatCommand('sui', 'ChatCommand')
	self:RegisterChatCommand('suihelp', 'suihelp')
	self:RegisterChatCommand('spartanui', 'ChatCommand')

	--Reopen options screen if flagged to do so after a reloadui
	SUI:RegisterEvent(
		'PLAYER_ENTERING_WORLD',
		function(self, ...)
			if SUI.DB.OpenOptions then
				SUI:ChatCommand()
				SUI.DB.OpenOptions = false
			end
		end
	)
end

function SUI:suihelp()
	SUI.Lib.AceCD:Open('SpartanUI', 'Help')
end
