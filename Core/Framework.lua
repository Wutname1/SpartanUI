local _, SUI = ...
SUI = LibStub('AceAddon-3.0'):NewAddon(SUI, 'SpartanUI', 'AceEvent-3.0', 'AceConsole-3.0')
_G.SUI = SUI

local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('SpartanUI', true)
SUI.L = L

local _G = _G
local type, pairs = type, pairs

SUI.Version = GetAddOnMetadata('SpartanUI', 'Version')
SUI.BuildNum = GetAddOnMetadata('SpartanUI', 'X-Build')
if not SUI.BuildNum then
	SUI.BuildNum = 0
end
----------------------------------------------------------------------------------------------------
SUI.opt = {
	name = 'SpartanUI ' .. SUI.Version,
	type = 'group',
	childGroups = 'tree',
	args = {
		General = {name = L['General'], type = 'group', order = 0, args = {}},
		Artwork = {name = L['Artwork'], type = 'group', args = {}},
		PlayerFrames = {name = L['PlayerFrames'], type = 'group', args = {}},
		PartyFrames = {name = L['PartyFrames'], type = 'group', args = {}},
		RaidFrames = {name = L['RaidFrames'], type = 'group', args = {}}
	}
}

---------------		Database		-------------------------------

local FontItems = {Primary = {}, Core = {}, Party = {}, Player = {}, Raid = {}}
local FontItemsSize = {Primary = {}, Core = {}, Party = {}, Player = {}, Raid = {}}
local fontdefault = {Size = 0, Face = 'Roboto-Bold', Type = 'outline'}
local MovedDefault = {moved = false, point = '', relativeTo = nil, relativePoint = '', xOffset = 0, yOffset = 0}
local frameDefault1 = {
	movement = MovedDefault,
	AuraDisplay = true,
	display = true,
	Debuffs = 'all',
	buffs = 'all',
	style = 'large',
	moved = false,
	Anchors = {}
}
local frameDefault2 = {
	AuraDisplay = true,
	display = true,
	Debuffs = 'all',
	buffs = 'all',
	style = 'medium',
	moved = false,
	Anchors = {}
}
local StatusBarsDefaults = {
	display = 'disabled',
	ToolTip = 'hover',
	text = true,
	AutoColor = true,
	Color = {0, 0, 0, 1},
	FontSize = 10,
	GlowAnchor = 'RIGHT',
	GlowHeight = 20,
	texCords = {0, 1, 0, 1}
}
local StatusBarsStyleDefaults = {
	size = {256, 36},
	Grow = 'LEFT',
	bgTooltip = 'Interface\\Addons\\SpartanUI_Artwork\\Images\\status-tooltip',
	texCordsTooltip = {0.1796875, 0.8203125, 0.103515625, 0.8984375},
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
	GlowImage = 'Interface\\AddOns\\SpartanUI_Artwork\\Images\\status-glow',
	texCords = {0, 1, 0, 1}
}

local DBdefault = {
	SUIProper = {
		Version = SUI.Version,
		SetupDone = false,
		HVer = '',
		yoffset = 0,
		xOffset = 0,
		yoffsetAuto = true,
		scale = .92,
		alpha = 1,
		viewport = true,
		EnabledComponents = {},
		Styles = {
			['**'] = {
				Artwork = false,
				PlayerFrames = false,
				PartyFrames = false,
				RaidFrames = false,
				Movable = {
					Minimap = true,
					PlayerFrames = true,
					PartyFrames = true,
					RaidFrames = true
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
					size = {width = 140, height = 140}
				},
				StatusBars = {
					XP = false,
					REP = false,
					AP = false
				},
				MovedBars = {},
				TooltipLoc = false,
				BuffLoc = false
			},
			Classic = {
				Artwork = true,
				PlayerFrames = true,
				PartyFrames = true,
				RaidFrames = true,
				BartenderProfile = 'SpartanUI - Classic',
				BartenderSettings = {
					-- actual settings being inserted into our custom profile
					ActionBars = {
						actionbars = {
							-- following settings are bare minimum, so that anything not defined is retained between resets
							{
								enabled = true,
								buttons = 12,
								rows = 1,
								padding = 3,
								skin = {Zoom = true},
								position = {
									point = 'LEFT',
									parent = 'SUI_ActionBarPlate',
									x = 0,
									y = 36,
									scale = 0.85,
									growHorizontal = 'RIGHT'
								}
							}, -- 1
							{
								enabled = true,
								buttons = 12,
								rows = 1,
								padding = 3,
								skin = {Zoom = true},
								position = {
									point = 'LEFT',
									parent = 'SUI_ActionBarPlate',
									x = 0,
									y = -4,
									scale = 0.85,
									growHorizontal = 'RIGHT'
								}
							}, -- 2
							{
								enabled = true,
								buttons = 12,
								rows = 1,
								padding = 3,
								skin = {Zoom = true},
								position = {
									point = 'RIGHT',
									parent = 'SUI_ActionBarPlate',
									x = -402,
									y = 36,
									scale = 0.85,
									growHorizontal = 'RIGHT'
								}
							}, -- 3
							{
								enabled = true,
								buttons = 12,
								rows = 1,
								padding = 3,
								skin = {Zoom = true},
								position = {
									point = 'RIGHT',
									parent = 'SUI_ActionBarPlate',
									x = -402,
									y = -4,
									scale = 0.85,
									growHorizontal = 'RIGHT'
								}
							}, -- 4
							{
								enabled = true,
								buttons = 12,
								rows = 3,
								padding = 4,
								skin = {Zoom = true},
								position = {
									point = 'LEFT',
									parent = 'SUI_ActionBarPlate',
									x = -135,
									y = 36,
									scale = 0.80,
									growHorizontal = 'RIGHT'
								}
							}, -- 5
							{
								enabled = true,
								buttons = 12,
								rows = 3,
								padding = 4,
								skin = {Zoom = true},
								position = {
									point = 'RIGHT',
									parent = 'SUI_ActionBarPlate',
									x = 3,
									y = 36,
									scale = 0.80,
									growHorizontal = 'RIGHT'
								}
							}, -- 6
							{
								enabled = false,
								buttons = 12,
								rows = 1,
								padding = 3,
								skin = {Zoom = true},
								position = {parent = 'SUI_ActionBarPlate', scale = 0.85, growHorizontal = 'RIGHT'}
							}, -- 7
							{
								enabled = false,
								buttons = 12,
								rows = 1,
								padding = 3,
								skin = {Zoom = true},
								position = {parent = 'SUI_ActionBarPlate', scale = 0.85, growHorizontal = 'RIGHT'}
							}, -- 8
							{
								enabled = false,
								buttons = 12,
								rows = 1,
								padding = 3,
								skin = {Zoom = true},
								position = {parent = 'SUI_ActionBarPlate', scale = 0.85, growHorizontal = 'RIGHT'}
							}, -- 9
							{
								enabled = false,
								buttons = 12,
								rows = 1,
								padding = 3,
								skin = {Zoom = true},
								position = {parent = 'SUI_ActionBarPlate', scale = 0.85, growHorizontal = 'RIGHT'}
							} -- 10
						}
					},
					BagBar = {
						enabled = true,
						padding = 0,
						position = {
							point = 'TOPRIGHT',
							parent = 'SUI_ActionBarPlate',
							x = -6,
							y = -2,
							scale = 0.70,
							growHorizontal = 'LEFT'
						},
						rows = 1,
						onebag = false,
						keyring = true
					},
					MicroMenu = {
						enabled = true,
						padding = -3,
						position = {
							point = 'TOPLEFT',
							parent = 'SUI_ActionBarPlate',
							x = 603,
							y = 0,
							scale = 0.80,
							growHorizontal = 'RIGHT'
						}
					},
					PetBar = {
						enabled = true,
						padding = 1,
						position = {
							point = 'TOPLEFT',
							parent = 'SUI_ActionBarPlate',
							x = 5,
							y = -6,
							scale = 0.70,
							growHorizontal = 'RIGHT'
						},
						rows = 1,
						skin = {Zoom = true}
					},
					StanceBar = {
						enabled = true,
						padding = 1,
						position = {
							point = 'TOPRIGHT',
							parent = 'SUI_ActionBarPlate',
							x = -605,
							y = -2,
							scale = 0.85,
							growHorizontal = 'LEFT'
						},
						rows = 1
					},
					MultiCast = {
						enabled = true,
						position = {point = 'TOPRIGHT', parent = 'SUI_ActionBarPlate', x = -777, y = -4, scale = 0.75}
					},
					Vehicle = {
						enabled = false,
						padding = 3,
						position = {point = 'CENTER', parent = 'SUI_ActionBarPlate', x = -15, y = 213, scale = 0.85}
					},
					ExtraActionBar = {enabled = true, position = {point = 'CENTER', parent = 'SUI_ActionBarPlate', x = -32, y = 240}},
					BlizzardArt = {enabled = false},
					XPBar = {enabled = false},
					RepBar = {enabled = false},
					APBar = {enabled = false},
					blizzardVehicle = true
				},
				Frames = {
					player = {
						Buffs = {Mode = 'icons'},
						Debuffs = {Mode = 'icons'}
					},
					target = {
						Buffs = {Mode = 'icons'},
						Debuffs = {Mode = 'bars'}
					}
				},
				Movable = {
					Minimap = false,
					PlayerFrames = true,
					PartyFrames = true,
					RaidFrames = true
				},
				Minimap = {
					shape = 'circle',
					size = {width = 140, height = 140}
				},
				StatusBars = {
					XP = true,
					REP = true,
					AP = true
				},
				TooltipLoc = true
			}
		},
		ChatSettings = {
			enabled = true
		},
		BuffSettings = {
			disableblizz = true,
			enabled = true,
			Manualoffset = false,
			offset = 0
		},
		PopUP = {
			popup1enable = true,
			popup2enable = true,
			popup1alpha = 100,
			popup2alpha = 100,
			popup1anim = true,
			popup2anim = true
		},
		StatusBars = {
			left = 'xp',
			right = 'rep',
			XPBar = {
				text = true,
				ToolTip = 'click',
				GainedColor = 'Blue',
				GainedRed = 0,
				GainedBlue = 1,
				GainedGreen = .5,
				GainedBrightness = .7,
				RestedColor = 'Light_Blue',
				RestedRed = 0,
				RestedBlue = 1,
				RestedGreen = .5,
				RestedBrightness = .7,
				RestedMatchColor = false
			},
			RepBar = {
				text = false,
				ToolTip = 'click',
				GainedColor = 'AUTO',
				GainedRed = 0,
				GainedBlue = 0,
				GainedGreen = 1,
				GainedBrightness = .6,
				AutoDefined = true
			},
			APBar = {
				text = true,
				ToolTip = 'hover'
			},
			AzeriteBar = {
				text = true,
				ToolTip = 'hover'
			},
			HonorBar = {
				text = true
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
			Shape = 'square',
			BlizzStyle = 'mouseover',
			OtherStyle = 'mouseover',
			Moved = false,
			Position = nil,
			-- frames = {},
			-- IgnoredFrames = {},
			SUIMapChangesActive = false
		},
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
		font = {
			NumberSeperator = ',',
			Path = '',
			Primary = fontdefault,
			Core = fontdefault,
			Player = fontdefault,
			Party = fontdefault,
			Raid = fontdefault
		},
		Components = {}
	},
	Modules = {
		StatusBars = {
			default = StatusBarsStyleDefaults,
			[1] = StatusBarsDefaults,
			[2] = StatusBarsDefaults,
			[3] = StatusBarsDefaults,
			[4] = StatusBarsDefaults,
			[5] = StatusBarsDefaults,
			XPBar = {
				GainedColor = 'Blue',
				RestedColor = 'Light_Blue'
			},
			RepBar = {
				GainedColor = 'AUTO',
				AutoDefined = true
			},
			APBar = {
				GainedColor = 'Orange'
			},
			AzeriteBar = {
				GainedColor = 'Orange'
			},
			HonorBar = {
				GainedColor = 'Red'
			}
		},
		Artwork = {
			Style = '',
			FirstLoad = true,
			VehicleUI = true,
			Viewport = {
				enabled = true,
				offset = {top = 0, bottom = 2.3, left = 0, right = 0}
			}
		},
		SpinCam = {
			enable = true,
			speed = 8
		},
		FilmEffects = {
			enable = false,
			animationInterval = 0,
			anim = '',
			vignette = nil
		},
		PartyFrames = {
			Style = 'Classic',
			Portrait3D = true,
			threat = true,
			preset = 'dps',
			FrameStyle = 'large',
			showAuras = true,
			partyLock = true,
			showClass = true,
			partyMoved = false,
			castbar = true,
			castbartext = true,
			showPartyInRaid = false,
			showParty = true,
			showPlayer = true,
			showSolo = false,
			Portrait = true,
			scale = 1,
			Auras = {
				NumBuffs = 0,
				NumDebuffs = 10,
				size = 16,
				spacing = 1,
				showType = true
			},
			Anchors = {
				point = 'TOPLEFT',
				relativeTo = 'UIParent',
				relativePoint = 'TOPLEFT',
				xOfs = 10,
				yOfs = -20
			},
			bars = {health = {textstyle = 'dynamic', textmode = 1}, mana = {textstyle = 'dynamic', textmode = 1}},
			display = {pet = true, target = true, mana = true}
		},
		PlayerFrames = {
			Style = 'Classic',
			Portrait3D = true,
			showClass = true,
			focusMoved = false,
			PetPortrait = true,
			global = frameDefault1,
			player = frameDefault1,
			target = frameDefault1,
			targettarget = frameDefault2,
			pet = frameDefault2,
			focus = frameDefault2,
			focustarget = frameDefault2,
			boss = frameDefault2,
			arena = frameDefault2,
			bars = {
				health = {textstyle = 'dynamic', textmode = 1},
				mana = {textstyle = 'longfor', textmode = 1},
				player = {color = 'dynamic'},
				target = {color = 'reaction'},
				targettarget = {color = 'dynamic', style = 'large'},
				pet = {color = 'happiness'},
				focus = {color = 'dynamic'},
				focustarget = {color = 'dynamic'}
			},
			Castbar = {
				player = 1,
				target = 1,
				targettarget = 1,
				pet = 1,
				focus = 1,
				text = {player = 1, target = 1, targettarget = 1, pet = 1, focus = 1}
			},
			BossFrame = {movement = MovedDefault, display = true, scale = 1},
			ArenaFrame = {movement = MovedDefault, display = true, scale = 1},
			ClassBar = {scale = 1, movement = MovedDefault},
			TotemFrame = {movement = MovedDefault},
			AltManaBar = {movement = MovedDefault}
		},
		RaidFrames = {
			Style = 'Classic',
			HideBlizzFrames = true,
			threat = true,
			mode = 'ASSIGNEDROLE',
			preset = 'dps',
			FrameStyle = 'small',
			showAuras = true,
			showClass = true,
			moved = false,
			showRaid = true,
			maxColumns = 4,
			unitsPerColumn = 10,
			columnSpacing = 5,
			scale = 1,
			Anchors = {
				point = 'TOPLEFT',
				relativeTo = 'UIParent',
				relativePoint = 'TOPLEFT',
				xOfs = 10,
				yOfs = -20
			},
			bars = {
				health = {textstyle = 'dynamic', textmode = 1},
				mana = {textstyle = 'dynamic', textmode = 1}
			},
			debuffs = {display = true},
			Auras = {size = 10, spacing = 1, showType = true}
		}
	}
}
DBdefault.Modules.StatusBars[1].display = 'xp'
DBdefault.Modules.StatusBars[2].display = 'honor'

local DBdefaults = {char = DBdefault, profile = DBdefault}
-- local SUI.DBGs = {Version = SUI.Version}

function SUI:ResetConfig()
	SUI.DB:ResetProfile(false, true)
	ReloadUI()
end

function SUI:FirstTimeSetup()
	local PageData, SetupWindow
	--Hide Bartender4 Minimap icon.
	if Bartender4 then
		Bartender4.db.profile.minimapIcon.hide = true
		local LDBIcon = LibStub('LibDBIcon-1.0', true)
		LDBIcon['Hide'](LDBIcon, 'Bartender4')
	end
	--Setup page
	SUI.DB.SetupDone = false
	PageData = {
		SubTitle = 'Welcome',
		Desc1 = 'Thank you for installing SpartanUI.',
		Desc2 = 'If you would like to copy the configuration from another character you may do so below.',
		Display = function()
			--Container
			SUI_Win.Core = CreateFrame('Frame', nil)
			SUI_Win.Core:SetParent(SUI_Win.content)
			SUI_Win.Core:SetAllPoints(SUI_Win.content)

			local gui = LibStub('AceGUI-3.0')

			--Profiles
			local control = gui:Create('Dropdown')
			control:SetLabel('Exsisting profiles')
			local tmpprofiles = {}
			local profiles = {}
			-- copy existing profiles into the table
			local currentProfile = SUI.DB:GetCurrentProfile()
			for _, v in pairs(SUI.DB:GetProfiles(tmpprofiles)) do
				if not (nocurrent and v == currentProfile) then
					profiles[v] = v
				end
			end
			control:SetList(profiles)
			control:SetPoint('TOP', SUI_Win.Core, 'TOP', 0, -30)
			control.frame:SetParent(SUI_Win.Core)
			control.frame:Show()
			SUI_Win.Core.Profiles = control
		end,
		Next = function()
			SUI.DB.SetupDone = true

			SUI_Win.Core:Hide()
			SUI_Win.Core = nil
		end,
		-- RequireReload = true,
		-- Priority = 1,
		-- Skipable = true,
		-- NoReloadOnSkip = true,
		Skip = function()
			SUI.DB.SetupDone = true
		end
	}

	-- Uncomment this when the time is right.
	-- SetupWindow = spartan:GetModule("SetupWindow")
	-- SetupWindow:AddPage(PageData)
	-- SetupWindow:DisplayPage()
end

function SUI:FontSetupWizard()
	local PageData, SetupWindow

	local fontlist = {
		'RobotoBold',
		'Roboto',
		'Cognosis',
		'NotoSans',
		'FrizQuadrata',
		'ArialNarrow'
	}
	local fontnames = {
		['RobotoBold'] = 'Roboto-Bold',
		['Roboto'] = 'Roboto',
		['Cognosis'] = 'SpartanUI',
		['NotoSans'] = 'SUI4',
		['FrizQuadrata'] = 'FrizQuadrata',
		['ArialNarrow'] = 'ArialNarrow'
	}

	PageData = {
		SubTitle = 'Font Style',
		Display = function()
			SUI_Win.FontFace = CreateFrame('Frame', nil)
			SUI_Win.FontFace:SetParent(SUI_Win.content)
			SUI_Win.FontFace:SetAllPoints(SUI_Win.content)

			local RadioButtons = function(self)
				for _, v in ipairs(fontlist) do
					fontface = SUI_Win.FontFace[v].radio:SetValue(false)
				end

				self.radio:SetValue(true)
			end

			local gui = LibStub('AceGUI-3.0')
			local control, radio

			--RobotoBold
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Setup-Fonts', 0, 0.421875, 0, 0.3125)
			control:SetImageSize(180, 60)
			control:SetPoint('TOPLEFT', SUI_Win.FontFace, 'TOPLEFT', 55, -55)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Roboto Bold')
			radio:SetUserData('value', 'Roboto-Bold')
			radio:SetUserData('text', 'Roboto-Bold')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.RobotoBold = control

			--Roboto
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Setup-Fonts', 0, 0.421875, 0.34375, 0.65625)
			control:SetImageSize(180, 60)
			control:SetPoint('LEFT', SUI_Win.FontFace.RobotoBold.frame, 'RIGHT', 80, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Roboto')
			radio:SetUserData('value', 'Roboto')
			radio:SetUserData('text', 'Roboto')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.Roboto = control

			--Cognosis
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Setup-Fonts', 0, 0.421875, 0.6875, 1)
			control:SetImageSize(180, 60)
			control:SetPoint('LEFT', SUI_Win.FontFace.Roboto.frame, 'RIGHT', 80, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Cognosis')
			radio:SetUserData('value', 'SpartanUI')
			radio:SetUserData('text', 'SpartanUI')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.Cognosis = control

			--NotoSans
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Setup-Fonts', 0.578125, 1, 0, 0.3125)
			control:SetImageSize(180, 60)
			control:SetPoint('TOP', SUI_Win.FontFace.RobotoBold.radio.frame, 'BOTTOM', 0, -20)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('NotoSans')
			radio:SetUserData('value', 'SUI4')
			radio:SetUserData('text', 'SUI4')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.NotoSans = control

			--FrizQuadrata
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Setup-Fonts', 0.578125, 1, 0.34375, 0.65625)
			control:SetImageSize(180, 60)
			control:SetPoint('LEFT', SUI_Win.FontFace.NotoSans.frame, 'RIGHT', 80, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Friz Quadrata')
			radio:SetUserData('value', 'FrizQuadrata')
			radio:SetUserData('text', 'FrizQuadrata')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.FrizQuadrata = control

			--ArialNarrow
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Setup-Fonts', 0.578125, 1, 0.6875, 1)
			control:SetImageSize(180, 60)
			control:SetPoint('LEFT', SUI_Win.FontFace.FrizQuadrata.frame, 'RIGHT', 80, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.FontFace)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Arial Narrow')
			radio:SetUserData('value', 'ArialNarrow')
			radio:SetUserData('text', 'ArialNarrow')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(120)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.FontFace.ArialNarrow = control

			SUI_Win.FontFace.RobotoBold.radio:SetValue(true)
		end,
		Next = function()
			local fontface

			for _, v in ipairs(fontlist) do
				if SUI_Win.FontFace[v].radio:GetValue() then
					fontface = fontnames[v]
				end
			end

			if fontface then
				SUI.DB.font.Primary.Face = fontface
				SUI.DB.font.Core.Face = fontface
				SUI.DB.font.Player.Face = fontface
				SUI.DB.font.Party.Face = fontface
				SUI.DB.font.Raid.Face = fontface
			end
			SUI_Win.FontFace:Hide()
			SUI_Win.FontFace = nil
			SUI.DB.SetupDone = true
		end,
		Skip = function()
			SUI_Win.FontFace:Hide()
			SUI_Win.FontFace = nil
			SUI.DB.SetupDone = true
		end
	}

	SetupWindow = SUI:GetModule('SetupWindow')
	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
	-- This will be moved once we put the setup page in place.
	-- we are setting this to true now so we dont have issues in the future with setup appearing on exsisting users
end

function SUI:OnInitialize()
	SUI.SpartanUIDB = LibStub('AceDB-3.0'):New('SpartanUIDB', DBdefaults)
	--If we have not played in a long time reset the database, make sure it is all good.
	local ver = SUI.SpartanUIDB.profile.SUIProper.Version
	if (ver ~= nil and ver < '4.0.0') then
		SUI.SpartanUIDB:ResetDB()
	end
	if not SUI.CurseVersion then
		SUI.CurseVersion = ''
	end

	-- New SUI.DB Access
	SUI.DBG = SUI.SpartanUIDB.global
	SUI.DB = SUI.SpartanUIDB.profile.SUIProper
	SUI.DBMod = SUI.SpartanUIDB.profile.Modules

	--Check for any SUI.DB changes
	if SUI.DB.SetupDone then
		SUI:DBUpgrades()
	end

	-- Legacy, need to phase these globals out it was messy
	-- SUI.DB = SUI.SpartanUIDB.profile.SUIProper
	-- SUI.DBMod = SUI.SpartanUIDB.profile.Modules
	SUI.opt.args['Profiles'] = LibStub('AceDBOptions-3.0'):GetOptionsTable(SUI.SpartanUIDB)

	-- Add dual-spec support
	local LibDualSpec = LibStub('LibDualSpec-1.0')
	LibDualSpec:EnhanceDatabase(self.SpartanUIDB, 'SpartanUI')
	LibDualSpec:EnhanceOptions(SUI.opt.args['Profiles'], self.SpartanUIDB)
	SUI.opt.args['Profiles'].order = 999

	-- Spec Setup
	SUI.SpartanUIDB.RegisterCallback(SUI, 'OnNewProfile', 'InitializeProfile')
	SUI.SpartanUIDB.RegisterCallback(SUI, 'OnProfileChanged', 'UpdateModuleConfigs')
	SUI.SpartanUIDB.RegisterCallback(SUI, 'OnProfileCopied', 'UpdateModuleConfigs')
	SUI.SpartanUIDB.RegisterCallback(SUI, 'OnProfileReset', 'UpdateModuleConfigs')

	--Bartender4
	if SUI.DBG.Bartender4 == nil then
		SUI.DBG.Bartender4 = {}
	end
	if SUI.DBG.BartenderChangesActive then
		SUI.DBG.BartenderChangesActive = false
	end
	if Bartender4 then
		--Update to the current profile
		SUI.DB.BT4Profile = Bartender4.db:GetCurrentProfile()
		Bartender4.db.RegisterCallback(SUI, 'OnProfileChanged', 'BT4RefreshConfig')
		Bartender4.db.RegisterCallback(SUI, 'OnProfileCopied', 'BT4RefreshConfig')
		Bartender4.db.RegisterCallback(SUI, 'OnProfileReset', 'BT4RefreshConfig')
	end

	SUI:FontSetup()

	--First Time Setup Actions
	if not SUI.DB.SetupDone then
		if _G.LARGE_NUMBER_SEPERATOR == '.' then
			SUI.DB.font.NumberSeperator = '.'
		elseif _G.LARGE_NUMBER_SEPERATOR == '' then
			SUI.DB.font.NumberSeperator = ''
		end

		SUI:FirstTimeSetup()
	end
end

function SUI:DBUpgrades()
	if SUI.DBMod.Artwork.Style == '' and SUI.DBMod.Artwork.SetupDone then
		SUI.DBMod.Artwork.Style = 'Classic'
	end
end

function SUI:InitializeProfile()
	SUI.DB:RegisterDefaults(SUI.DBdefaults)

	SUI.DBG = SUI.SpartanUIDB.global
	SUI.DB = SUI.SpartanUIDB.profile.SUIProper
	SUI.DBMod = SUI.SpartanUIDB.profile.Modules

	SUI:reloadui()
end

---------------		Misc Backend		-------------------------------

function SUI:BT4ProfileAttach(msg)
	PageData = {
		title = 'SpartanUI',
		Desc1 = msg,
		-- Desc2 = Desc2,
		width = 400,
		height = 150,
		Display = function()
			SUI_Win:ClearAllPoints()
			SUI_Win:SetPoint('TOP', 0, -20)
			SUI_Win:SetSize(400, 150)
			SUI_Win.Status:Hide()

			SUI_Win.Skip:SetText('DO NOT ATTACH')
			SUI_Win.Skip:SetSize(110, 25)
			SUI_Win.Skip:ClearAllPoints()
			SUI_Win.Skip:SetPoint('BOTTOMRIGHT', SUI_Win, 'BOTTOM', -15, 15)

			SUI_Win.Next:SetText('ATTACH')
			SUI_Win.Next:ClearAllPoints()
			SUI_Win.Next:SetPoint('BOTTOMLEFT', SUI_Win, 'BOTTOM', 15, 15)
		end,
		Next = function()
			SUI.DBG.Bartender4[SUI.DB.BT4Profile] = {
				Style = SUI.DBMod.Artwork.Style
			}
			-- Catch if Movedbars is not initalized
			if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars then
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
			end
			--Setup profile
			SUI:GetModule('Artwork_Core'):SetupProfile(Bartender4.db:GetCurrentProfile())
			ReloadUI()
		end,
		Skip = function()
			-- ReloadUI()
		end
	}
	local SetupWindow = SUI:GetModule('SetupWindow')
	SetupWindow:DisplayPage(PageData)
end

function SUI:BT4RefreshConfig()
	if SUI.DBG.BartenderChangesActive or SUI.DBMod.Artwork.FirstLoad then
		return
	end
	-- if SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile == Bartender4.db:GetCurrentProfile() then return end -- Catch False positive)
	SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile = Bartender4.db:GetCurrentProfile()
	SUI.DB.BT4Profile = Bartender4.db:GetCurrentProfile()

	if SUI.DBG.Bartender4 == nil then
		SUI.DBG.Bartender4 = {}
	end

	if SUI.DBG.Bartender4[SUI.DB.BT4Profile] then
		-- We know this profile.
		if SUI.DBG.Bartender4[SUI.DB.BT4Profile].Style == SUI.DBMod.Artwork.Style then
			--Profile is for this style, prompt to ReloadUI; usually un needed can uncomment if needed latter
			-- SUI:reloadui("Your bartender profile has changed, a reload may be required for the bars to appear properly.")
			-- Catch if Movedbars is not initalized
			if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars then
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
			end
		else
			--Ask if we should change to the correct profile or if we should change the profile to be for this style
			SUI:BT4ProfileAttach(
				"This bartender profile is currently attached to the style '" ..
					SUI.DBG.Bartender4[SUI.DB.BT4Profile].Style ..
						"' you are currently using " ..
							SUI.DBMod.Artwork.Style .. ' would you like to reassign the profile to this art skin? '
			)
		end
	else
		-- We do not know this profile, ask if we should attach it to this style.
		SUI:BT4ProfileAttach(
			'This bartender profile is currently NOT attached to any style you are currently using the ' ..
				SUI.DBMod.Artwork.Style .. ' style would you like to assign the profile to this art skin? '
		)
	end

	SUI:Print('Bartender4 Profile changed to: ' .. Bartender4.db:GetCurrentProfile())
end

function SUI:UpdateModuleConfigs()
	-- SUI.SpartanUIDB:RegisterDefaults(SUI.DBdefaults)

	-- SUI.DB = SUI.SpartanUIDB.profile.SUIProper
	-- SUI.DBMod = SUI.SpartanUIDB.profile.Modules

	if Bartender4 then
		if SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile then
			Bartender4.db:SetProfile(SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile)
		elseif SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile then
			Bartender4.db:SetProfile(SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile)
		else
			Bartender4.db:SetProfile(SUI.DB.BT4Profile)
		end
	end

	SUI:reloadui()
end

function SUI:reloadui(Desc2)
	-- SUI.DB.OpenOptions = true;
	PageData = {
		title = 'SpartanUI',
		Desc1 = 'A reload of your UI is required.',
		Desc2 = Desc2,
		width = 400,
		height = 150,
		WipePage = true,
		Display = function()
			SUI_Win:ClearAllPoints()
			SUI_Win:SetPoint('TOP', 0, -20)
			SUI_Win:SetSize(400, 150)
			SUI_Win.Status:Hide()
			SUI_Win.Next:SetText('RELOADUI')
			SUI_Win.Next:ClearAllPoints()
			SUI_Win.Next:SetPoint('BOTTOM', 0, 30)
		end,
		Next = function()
			ReloadUI()
		end
	}
	local SetupWindow = SUI:GetModule('SetupWindow')
	SetupWindow:DisplayPage(PageData)
end

function SUI:OnEnable()
	if not SUI.DB.SetupDone then
		SUI:FontSetupWizard()
	end
	AceConfig:RegisterOptionsTable(
		'SpartanUIBliz',
		{
			name = 'SpartanUI',
			type = 'group',
			args = {
				n1 = {
					type = 'description',
					fontSize = 'medium',
					order = 1,
					width = 'full',
					name = 'Options have moved into their own window as this menu was getting a bit crowded.'
				},
				n3 = {
					type = 'description',
					fontSize = 'medium',
					order = 3,
					width = 'full',
					name = 'Options can be accessed by the button below or by typing /sui or /spartanui'
				},
				Close = {
					name = 'Launch Options',
					width = 'full',
					type = 'execute',
					order = 50,
					func = function()
						InterfaceOptionsFrame:Hide()
						AceConfigDialog:SetDefaultSize('SpartanUI', 850, 600)
						AceConfigDialog:Open('SpartanUI')
					end
				}
			}
		}
	)
	AceConfigDialog:AddToBlizOptions('SpartanUIBliz', 'SpartanUI')

	AceConfig:RegisterOptionsTable('SpartanUI', SUI.opt)
	if not SUI:GetModule('Artwork_Core', true) then
		SUI.opt.args['Artwork'].disabled = true
	end
	if not SUI:GetModule('PartyFrames', true) then
		SUI.opt.args['PartyFrames'].disabled = true
	end
	if not SUI:GetModule('PlayerFrames', true) then
		SUI.opt.args['PlayerFrames'].disabled = true
	end
	if not SUI:GetModule('RaidFrames', true) then
		SUI.opt.args['RaidFrames'].disabled = true
	end

	self:RegisterChatCommand('sui', 'ChatCommand')
	self:RegisterChatCommand('suihelp', 'suihelp')
	self:RegisterChatCommand('spartanui', 'ChatCommand')

	--Reopen options screen if flagged to do so after a reloadui
	local LaunchOpt = CreateFrame('Frame')
	LaunchOpt:SetScript(
		'OnEvent',
		function(self, ...)
			if SUI.DB.OpenOptions then
				SUI:ChatCommand()
				SUI.DB.OpenOptions = false
			end
		end
	)
	LaunchOpt:RegisterEvent('PLAYER_ENTERING_WORLD')
end

function SUI:suihelp(input)
	AceConfigDialog:SetDefaultSize('SpartanUI', 850, 600)
	AceConfigDialog:Open('SpartanUI', 'General', 'Help')
end

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
				'This will reset the full SpartanUI & Bartender4 Database. If you wish to continue perform the chat command again.'
			)
		end
	elseif input == 'resetdb' then
		if ResetDBWarning then
			SUI.SpartanUIDB:ResetDB()
		else
			ResetDBWarning = true
			SUI:Print('|cffff0000Warning')
			SUI:Print('This will reset the SpartanUI Database. If you wish to continue perform the chat command again.')
		end
	elseif input == 'help' then
		SUI:suihelp()
	elseif input == 'version' then
		SUI:Print('SpartanUI ' .. L['Version'] .. ' ' .. GetAddOnMetadata('SpartanUI', 'Version'))
		SUI:Print('SpartanUI Build Number ' .. L['Version'] .. ' ' .. GetAddOnMetadata('SpartanUI', 'X-Build'))
	else
		AceConfigDialog:SetDefaultSize('SpartanUI', 850, 600)
		AceConfigDialog:Open('SpartanUI')
	end
end

function SUI:Err(mod, err)
	SUI:Print('|cffff0000Error detected')
	SUI:Print("An error has been captured in the Component '" .. mod .. "'")
	SUI:Print('Details: ' .. err)
	SUI:Print('Please submit a bug at |cff3370FFhttp://bugs.spartanui.net/')
end

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

---------------		Math and Comparison FUNCTIONS		-------------------------------

function SUI:isPartialMatch(frameName, tab)
	local result = false

	for _, v in ipairs(tab) do
		startpos, endpos = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true
		end
	end

	return result
end

function SUI:isInTable(tab, frameName)
	-- local Count = 0
	-- for Index, Value in pairs( tab ) do
	-- Count = Count + 1
	-- end
	-- print (Count)
	if tab == nil or frameName == nil then
		return false
	end
	for _, v in ipairs(tab) do
		if v ~= nil and frameName ~= nil then
			if (strlower(v) == strlower(frameName)) then
				return true
			end
		end
	end
	return false
end

function SUI:round(num) -- rounds a number to 2 decimal places
	if num then
		return floor((num * 10 ^ 2) + 0.5) / (10 ^ 2)
	end
end

function SUI:comma_value(n)
	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)', '%1' .. SUI.DB.font.NumberSeperator):reverse()) .. right
end

---------------		FONT FUNCTIONS		---------------------------------------------

function SUI:FontSetup()
	local OutlineSizes = {22, 18, 16, 13, 12, 11, 10, 9, 8}
	local Sizes = {10}
	for _, v in ipairs(OutlineSizes) do
		local filename = _G['SUI_FontOutline' .. v]:GetFont()
		if filename ~= SUI:GetFontFace('Primary') then
			_G['SUI_FontOutline' .. v] = _G['SUI_FontOutline' .. v]:SetFont(SUI:GetFontFace('Primary'), v)
		end
	end

	for _, v in ipairs(Sizes) do
		local filename = _G['SUI_Font' .. v]:GetFont()
		if filename ~= SUI:GetFontFace('Primary') then
			_G['SUI_Font' .. v] = _G['SUI_Font' .. v]:SetFont(SUI:GetFontFace('Primary'), v)
		end
	end
end

function SUI:GetFontFace(Module)
	if Module then
		if SUI.DB.font[Module].Face == 'SpartanUI' then
			return 'Interface\\AddOns\\SpartanUI\\media\\font-cognosis.ttf'
		elseif SUI.DB.font[Module].Face == 'SUI4' then
			return 'Interface\\AddOns\\SpartanUI\\media\\NotoSans-Bold.ttf'
		elseif SUI.DB.font[Module].Face == 'Roboto' then
			return 'Interface\\AddOns\\SpartanUI\\media\\Roboto-Medium.ttf'
		elseif SUI.DB.font[Module].Face == 'Roboto-Bold' then
			return 'Interface\\AddOns\\SpartanUI\\media\\Roboto-Bold.ttf'
		elseif SUI.DB.font[Module].Face == 'FrizQuadrata' then
			return 'Fonts\\FRIZQT__.TTF'
		elseif SUI.DB.font[Module].Face == 'Arial' then
			return 'Fonts\\ARIAL.TTF'
		elseif SUI.DB.font[Module].Face == 'ArialNarrow' then
			return 'Fonts\\ARIALN.TTF'
		elseif SUI.DB.font[Module].Face == 'Skurri' then
			return 'Fonts\\skurri.TTF'
		elseif SUI.DB.font[Module].Face == 'Morpheus' then
			return 'Fonts\\MORPHEUS.TTF'
		elseif SUI.DB.font[Module].Face == 'Custom' and SUI.DB.font.Path ~= '' then
			return SUI.DB.font.Path
		end
	end

	return 'Interface\\AddOns\\SpartanUI\\media\\NotoSans-Bold.ttf'
end

function SUI:FormatFont(element, size, Module)
	--Adaptive Modules
	if not Module then
		Module = 'Primary'
	end
	if SUI.DB.font[Module] == nil then
		SUI.DB.font[Module] = fontdefault
	end
	--Set Font Outline
	local flags, sizeFinal = ''
	if SUI.DB.font[Module].Type == 'monochrome' then
		flags = flags .. 'monochrome '
	end

	-- Outline was deemed to thick, it is not a slight drop shadow done below
	--if SUI.DB.font[Module].Type == "outline" then flags = flags.."outline " end

	if SUI.DB.font[Module].Type == 'thickoutline' then
		flags = flags .. 'thickoutline '
	end
	--Set Size
	sizeFinal = size + SUI.DB.font[Module].Size
	--Create Font
	element:SetFont(SUI:GetFontFace(Module), sizeFinal, flags)

	if SUI.DB.font[Module].Type == 'outline' then
		element:SetShadowColor(0, 0, 0, .9)
		element:SetShadowOffset(1, -1)
	end
	--Add Item to the Array
	local count = 0
	for _ in pairs(FontItems[Module]) do
		count = count + 1
	end
	FontItems[Module][count + 1] = element
	FontItemsSize[Module][count + 1] = size
end

function SUI:FontRefresh(Module)
	for a, b in pairs(FontItems[Module]) do
		--Set Font Outline
		local flags, size = ''
		if SUI.DB.font[Module].Type == 'monochrome' then
			flags = flags .. 'monochrome '
		end
		if SUI.DB.font[Module].Type == 'outline' then
			flags = flags .. 'outline '
		end
		if SUI.DB.font[Module].Type == 'thickoutline' then
			flags = flags .. 'thickoutline '
		end
		--Set Size
		size = FontItemsSize[Module][a] + SUI.DB.font[Module].Size
		--Update Font
		b:SetFont(SUI:GetFontFace(Module), size, flags)
	end
end
