local _, SUI = ...
SUI = LibStub('AceAddon-3.0'):NewAddon(SUI, 'SpartanUI', 'AceEvent-3.0', 'AceConsole-3.0')
local StdUi = LibStub('StdUi'):NewInstance()
_G.SUI = SUI

local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)
SUI.L = L

local _G = _G
local type, pairs = type, pairs
local SUIChatCommands = {}
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
--@beta@
SUI.releaseType = 'BETA'
--@end-beta@
--@alpha@
SUI.releaseType = '6.0 ALPHA build ' .. SUI.BuildNum
SUI.Version = ''
--@end-alpha@
--@do-not-package@
SUI.releaseType = '6.x.x DEV build'
SUI.Version = ''
--@end-do-not-package@
--@alpha@
-- TODO REMOVE FOR 6.0 RELEASE
SUI.Version = '5.9.91'
--@end-alpha@

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
	scale = .92,
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
		MaxILVL = 180,
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
	BarTextures = {
		smooth = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'
	},
	BuffSettings = {
		disableblizz = true,
		enabled = true,
		Manualoffset = false,
		offset = 0
	},
	Components = {},
	ChatSettings = {
		enabled = true
	},
	EnabledComponents = {},
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
		Horizontal = 0
	},
	SetupWizard = {
		FirstLaunch = true
	},
	Styles = {
		['**'] = {
			Artwork = {},
			PlayerFrames = {},
			PartyFrames = {},
			RaidFrames = {},
			Movable = {
				Minimap = true,
				PlayerFrames = true,
				PartyFrames = true,
				RaidFrames = true
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
					Position = 'BOTTOMRIGHT,SUI_ActionBarAnchor,BOTTOM,-100,0'
				},
				Right = {
					Grow = 'RIGHT',
					Position = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOM,100,0'
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
				shape = 'circle',
				size = {140, 140},
				ZoneText = {Location = 'BOTTOM'},
				UnderVehicleUI = true,
				BG = {
					enabled = true,
					BlendMode = 'ADD',
					alpha = 1
				},
				coords = {
					scale = 1,
					position = 'TOP,Minimap,BOTTOM,0,-4',
					TextColor = {1, .82, 0, 1},
					ShadowColor = {0, 0, 0, 1}
				}
			},
			Movers = {},
			BlizzMovers = {
				['TalkingHead'] = 'TOP,SpartanUI,TOP,0,-18',
				['AltPowerBar'] = 'TOP,SpartanUI,TOP,0,-18',
				['AlertFrame'] = 'BOTTOM,SpartanUI,BOTTOM,0,215',
				['VehicleLeaveButton'] = 'LEFT,SUI_UF_player,RIGHT,20,0'
			}
		},
		Classic = {
			Artwork = {},
			Frames = {
				player = {
					Buffs = {Mode = 'icons'},
					Debuffs = {Mode = 'icons'}
				},
				target = {
					Buffs = {Mode = 'icons'},
					Debuffs = {Mode = 'bars'}
				},
				pet = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}},
				targettarget = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}},
				focus = {Buffs = {Mode = 'icons'}, Debuffs = {Mode = 'icons'}}
			},
			Movable = {
				Minimap = false,
				PlayerFrames = true,
				PartyFrames = true,
				RaidFrames = true
			},
			Minimap = {
				size = {156, 156},
				coords = {TextColor = {1, .82, 0, 1}},
				coords = {
					position = 'TOP,MinimapZoneText,BOTTOM,0,-4'
				},
				position = 'CENTER,SUI_Art_Classic,CENTER,0,54'
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
					texCords = {0, 0.849609375, 0, 1},
					GlowPoint = {x = 20},
					MaxWidth = 50
				}
			},
			Color = {
				Art = false,
				PlayerFrames = false,
				PartyFrames = false,
				RaidFrames = false
			},
			BlizzMovers = {
				['VehicleLeaveButton'] = 'BOTTOM,SUI_Art_Classic,TOP,0,80'
			}
		},
		Transparent = {
			Minimap = {
				shape = 'square',
				size = {130, 130},
				ZoneText = {Location = 'TOP'},
				position = 'CENTER,SUI_Art_Transparent,CENTER,0,-5',
				coords = {
					Location = 'TOP'
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
				shape = 'square'
			},
			Color = {
				0.6156862745098039,
				0.1215686274509804,
				0.1215686274509804,
				0.9
			},
			PartyFramesSize = 'large',
			HideCenterGraphic = false
		},
		Fel = {
			Artwork = {
				Allenable = true,
				Allalpha = 100,
				bar1 = {enable = true, alpha = 100},
				bar2 = {enable = true, alpha = 100},
				bar3 = {enable = true, alpha = 100},
				bar4 = {enable = true, alpha = 100},
				Stance = {enable = true, alpha = 100},
				MenuBar = {enable = true, alpha = 100}
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
			Artwork = {
				Allenable = true,
				Allalpha = 100,
				bar1 = {enable = true, alpha = 100},
				bar2 = {enable = true, alpha = 100},
				bar3 = {enable = true, alpha = 100},
				bar4 = {enable = true, alpha = 100},
				Stance = {enable = true, alpha = 100},
				MenuBar = {enable = true, alpha = 100}
			},
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
				position = 'CENTER,SUI_Art_Digital,CENTER,0,54',
				engulfed = true
			}
		},
		War = {
			Artwork = {
				Allenable = true,
				Allalpha = 100,
				bar1 = {enable = true, alpha = 100},
				bar2 = {enable = true, alpha = 100},
				bar3 = {enable = true, alpha = 100},
				bar4 = {enable = true, alpha = 100},
				Stance = {enable = true, alpha = 100},
				MenuBar = {enable = true, alpha = 100}
			},
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
			PartyFrames = {
				FrameStyle = 'medium'
			},
			RaidFrames = {
				FrameStyle = 'small'
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
					top = {
						enabled = false,
						x = 0,
						y = 0,
						graphic = ''
					},
					bg = {
						enabled = false,
						x = 0,
						y = 0,
						graphic = ''
					},
					bottom = {
						enabled = false,
						x = 0,
						y = 0,
						graphic = ''
					}
				},
				auras = {
					Buffs = {
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
							anchor = 'TOPLEFT',
							x = 0,
							y = 20
						}
					},
					Debuffs = {
						enabled = true,
						number = 10,
						size = 20,
						spacing = 1,
						showType = true,
						ShowBoss = true,
						onlyShowPlayer = false,
						initialAnchor = 'BOTTOMRIGHT',
						growthx = 'LEFT',
						growthy = 'UP',
						rows = 3,
						position = {
							anchor = 'TOPRIGHT',
							x = 0,
							y = 20
						}
					},
					Bars = {
						enabled = false,
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
							anchor = 'TOP',
							x = 0,
							y = 20
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
					Runes = {},
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
					QuestIndicator = {},
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
				yOffset = -10,
				elements = {
					Castbar = {
						enabled = true
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
					QuestIndicator = {
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
						QuestIndicator = {},
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
	SpinCam = {
		enable = true,
		speed = 8
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
			QuestIndicator = {},
			Health = {
				height = 5,
				colorTapping = true,
				colorReaction = true,
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
	},
	Chatbox = {
		URLCopy = true,
		SendHistory = true,
		ColorClass = true,
		LinkHover = true,
		webLinks = true,
		TimeStamp = {
			enabled = true,
			format = '%X'
		},
		player = {
			color = true,
			level = true
		},
		ChatCopy = {
			enabled = true,
			tip = true
		}
	}
}

-- local DBdefaults = {char = DBdefault, profile = DBdefault}
local DBdefaults = {profile = DBdefault}

function SUI:ResetConfig()
	SUI.DB:ResetProfile(false, true)
	ReloadUI()
end

SUI.SpartanUIDB = LibStub('AceDB-3.0'):New('SpartanUIDB', DBdefaults)
--If user has not played in a long time reset the database.
local ver = SUI.SpartanUIDB.profile.Version
if (ver ~= '0' and ver < '5.0.0') then
	SUI.SpartanUIDB:ResetDB()
end

-- New SUI.DB Access
SUI.DBG = SUI.SpartanUIDB.global
SUI.DB = SUI.SpartanUIDB.profile

local function reloaduiWindow()
	local StdUi = LibStub('StdUi'):NewInstance()
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

	-- Initalize setup of Fonts
	SUI:FontSetup()

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
	if SUI.DB.Artwork.Style == '' and SUI.DB.Artwork.SetupDone then
		SUI.DB.Artwork.Style = 'Classic'
	end

	-- 6.0.0 Upgrades
	if SUI.DB.Version < '5.9.9' and not SUI.DB.Migrated then
		if not select(4, GetAddOnInfo('SpartanUI_Artwork')) then
			SUI.DB.EnabledComponents.Artwork = false
		end
		if not select(4, GetAddOnInfo('SpartanUI_FilmEffects')) then
			SUI.DB.EnabledComponents.FilmEffects = false
		end
		if not select(4, GetAddOnInfo('SpartanUI_SpinCam')) then
			SUI.DB.EnabledComponents.SpinCam = false
		end

		-- Only disable the new Unitframes if all 3 unitframe addons are disabled
		if
			not select(4, GetAddOnInfo('SpartanUI_PartyFrames')) and not select(4, GetAddOnInfo('SpartanUI_PlayerFrames')) and
				not select(4, GetAddOnInfo('SpartanUI_RaidFrames'))
		 then
			SUI.DB.EnabledComponents.UnitFrames = false
		end

		-- Make sure everything is disabled
		DisableAddOn('SpartanUI_Artwork')
		DisableAddOn('SpartanUI_SpinCam')
		DisableAddOn('SpartanUI_FilmEffects')
		DisableAddOn('SpartanUI_PartyFrames')
		DisableAddOn('SpartanUI_PlayerFrames')
		DisableAddOn('SpartanUI_RaidFrames')
		DisableAddOn('SpartanUI_Style_Fel')
		DisableAddOn('SpartanUI_Style_Minimal')
		DisableAddOn('SpartanUI_Style_Transparent')
		DisableAddOn('SpartanUI_Style_War')
		SUI.DB.Migrated = true
	end

	if SUI.DB.Version < '5.9.91' then
		SUI.SpartanUIDB:ResetProfile()
		ReloadUI()
	end

	SUI.DB.Version = SUI.Version
end

function SUI:InitializeProfile()
	SUI.SpartanUIDB:RegisterDefaults(SUI.DBdefaults)

	SUI:reloadui()
end

---------------  Layout  ---------------
do
	-- Create Plate
	local plate = CreateFrame('Frame', 'SpartanUI', UIParent)
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetPoint('BOTTOMLEFT')
	plate:SetPoint('TOPRIGHT')
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

function SUI:reloadui(Desc2)
	SUI.reloaduiWindow:Show()
end

function SUI:OnEnable()
	AceConfig:RegisterOptionsTable(
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
						AceConfigDialog:SetDefaultSize('SpartanUI', 850, 600)
						AceConfigDialog:Open('SpartanUI')
					end
				}
			}
		}
	)
	AceConfig:RegisterOptionsTable('SpartanUI', SUI.opt)

	AceConfigDialog:AddToBlizOptions('SpartanUIBliz', 'SpartanUI')
	AceConfigDialog:SetDefaultSize('SpartanUI', 1000, 700)

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

function SUI:suihelp(input)
	AceConfigDialog:Open('SpartanUI', 'Help')
end

---------------  Chat Command  ---------------

local ResetDBWarning = false
function SUI:ChatCommand(input)
	if input == 'resetfulldb' then
		if ResetDBWarning then
			Bartender4.db:ResetDB()
			SUI.SpartanUIDB:ResetDB()
		else
			ResetDBWarning = true
			SUI:Print('|cffff0000Warning')
			SUI:Print(
				L[
					'This will reset the full SpartanUI & Bartender4 database. If you wish to continue perform the chat command again.'
				]
			)
		end
	elseif input == 'resetbartender' then
		SUI.opt.args['General'].args['Bartender'].args['ResetActionBars']:func()
	elseif input == 'resetdb' then
		if ResetDBWarning then
			SUI.SpartanUIDB:ResetDB()
		else
			ResetDBWarning = true
			SUI:Print('|cffff0000Warning')
			SUI:Print(L['This will reset the SpartanUI Database. If you wish to continue perform the chat command again.'])
		end
	elseif input == 'setup' then
		SUI:GetModule('SetupWizard'):SetupWizard()
	elseif input == 'help' then
		SUI:suihelp()
	elseif input == 'version' then
		SUI:Print(L['Version'] .. ' ' .. GetAddOnMetadata('SpartanUI', 'Version'))
		SUI:Print(string.format('%s build %s', wowVersion, SUI.BuildNum))
		if SUI.Bartender4Version ~= 0 then
			SUI:Print(L['Bartender4 version'] .. ' ' .. SUI.Bartender4Version)
		end
	else
		if SUIChatCommands[input] then
			SUIChatCommands[input]()
		elseif string.find(input, ' ') then
			for i in string.gmatch(input, '%S+') do
				local arg, _ = string.gsub(input, i .. ' ', '')
				if SUIChatCommands[i] then
					SUIChatCommands[i](arg)
				end
			end
		else
			AceConfigDialog:Open('SpartanUI')
		end
	end
end

function SUI:AddChatCommand(arg, func)
	SUIChatCommands[arg] = func
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

function SUI:tableLength(T)
	assert(type(T) == 'table', 'bad parameter #1: must be table')

	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end

function SUI:round(num) -- rounds a number to 2 decimal places
	if num then
		return floor((num * 10 ^ 2) + 0.5) / (10 ^ 2)
	end
end
