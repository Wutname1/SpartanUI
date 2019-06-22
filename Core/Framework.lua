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
SUI.Version = GetAddOnMetadata('SpartanUI', 'Version')
SUI.BuildNum = GetAddOnMetadata('SpartanUI', 'X-Build')
SUI.IsClassic = select(4, GetBuildInfo()) < 20000

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

local DBdefault = {
	SUIProper = {
		Version = '0',
		Bartender4Version = 0,
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
		MiniMap = {
			northTag = false,
			ManualAllowUse = false,
			ManualAllowPrompt = '',
			AutoDetectAllowUse = true,
			MapButtons = true,
			MouseIsOver = false,
			MapZoomButtons = true,
			DisplayMapCords = true,
			DisplayZoneName = true,
			Shape = 'square',
			BlizzStyle = 'mouseover',
			OtherStyle = 'mouseover',
			Moved = false,
			lockminimap = true,
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
			Modules = {
				['**'] = {
					Size = 0,
					Face = 'Roboto-Bold',
					Type = 'outline'
				}
			}
		},
		Components = {}
	},
	Modules = {
		StatusBars = {
			default = {
				size = {256, 36},
				Grow = 'LEFT',
				bgTooltip = 'Interface\\Addons\\SpartanUI_Artwork\\Images\\status-tooltip',
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
				GlowImage = 'Interface\\AddOns\\SpartanUI_Artwork\\Images\\status-glow',
				texCords = {0, 1, 0, 1}
			},
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
			Style = '',
			TopOffset = 0,
			TopOffsetAuto = true,
			BottomOffset = 0,
			BottomOffsetAuto = true,
			FirstLoad = true,
			VehicleUI = true,
			Viewport = {
				enabled = true,
				offset = {top = 0, bottom = 2.3, left = 0, right = 0}
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

local DBdefaults = {char = DBdefault, profile = DBdefault}
-- local SUI.DBGs = {Version = SUI.Version}

function SUI:ResetConfig()
	SUI.DB:ResetProfile(false, true)
	ReloadUI()
end

function SUI:OnInitialize()
	SUI.SpartanUIDB = LibStub('AceDB-3.0'):New('SpartanUIDB', DBdefaults)
	--If we have not played in a long time reset the database, make sure it is all good.
	local ver = SUI.SpartanUIDB.profile.SUIProper.Version
	if (ver ~= '0' and ver < '4.0.0') then
		SUI.SpartanUIDB:ResetDB()
	end

	-- New SUI.DB Access
	SUI.DBG = SUI.SpartanUIDB.global
	SUI.DB = SUI.SpartanUIDB.profile.SUIProper
	SUI.DBMod = SUI.SpartanUIDB.profile.Modules

	--Check for any SUI.DB changes
	if SUI.DB.SetupDone and (SUI.Version ~= SUI.DB.Version) then
		SUI:DBUpgrades()
	end

	-- Add Addon-Wide Bar textures
	SUI.BarTextures = {
		smooth = 'Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga'
	}

	-- Add Profiles to Options
	SUI.opt.args['Profiles'] = LibStub('AceDBOptions-3.0'):GetOptionsTable(SUI.SpartanUIDB)

	-- Add dual-spec support
	local LibDualSpec = LibStub('LibDualSpec-1.0', true)
	if not SUI.IsClassic and LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.SpartanUIDB, 'SpartanUI')
		LibDualSpec:EnhanceOptions(SUI.opt.args['Profiles'], self.SpartanUIDB)
		SUI.opt.args['Profiles'].order = 999
	end

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
end

function SUI:DBUpgrades()
	if SUI.DBMod.Artwork.Style == '' and SUI.DBMod.Artwork.SetupDone then
		SUI.DBMod.Artwork.Style = 'Classic'
	end

	-- 5.0.0 Upgrades
	if SUI.DB.Version < '5.0.0' then
		SUI.DB.font.SetupDone = true
		SUI.DBMod.Objectives.SetupDone = true
		SUI.DB.SetupWizard.FirstLaunch = false
		SUI.DB.AutoTurnIn.FirstLaunch = false
		SUI.DB.AutoSell.FirstLaunch = false
		SUI.DB.SetupWizard.FirstLaunch = false
	end

	SUI.DB.Version = SUI.Version
end

function SUI:InitializeProfile()
	SUI.DB:RegisterDefaults(SUI.DBdefaults)

	SUI.DBG = SUI.SpartanUIDB.global
	SUI.DB = SUI.SpartanUIDB.profile.SUIProper
	SUI.DBMod = SUI.SpartanUIDB.profile.Modules

	SUI:reloadui()
end

---------------		Misc Backend		-------------------------------

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
	local SetupWindow = SUI:GetModule('SUIWindow')
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
	local SetupWindow = SUI:GetModule('SUIWindow')
	SetupWindow:DisplayPage(PageData)
end

function SUI:OnEnable()
	if not SUI.DB.SetupDone then
	end
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
	self:RegisterChatCommand('suimove', 'SUIMove')

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
	if (not select(4, GetAddOnInfo('Bartender4')) and not SUI.DB.BT4Warned) then
		local cnt = 1
		local BT4Warning = CreateFrame('Frame')
		BT4Warning:SetScript('OnEvent', function()
			if cnt <= 10 then
				StdUi:Dialog(L['Warning'], L['Bartender4 not detected! Please download and install Bartender4.'] ..' Warning ' .. cnt .. ' of 10')
			else
				SUI.DB.BT4Warned = true
			end
			cnt = cnt + 1
		end)
		BT4Warning:RegisterEvent('PLAYER_LOGIN')
		BT4Warning:RegisterEvent('PLAYER_ENTERING_WORLD')
		BT4Warning:RegisterEvent('ZONE_CHANGED')
		BT4Warning:RegisterEvent('ZONE_CHANGED_INDOORS')
		BT4Warning:RegisterEvent('ZONE_CHANGED_NEW_AREA')
		
	end
end

function SUI:suihelp(input)
	AceConfigDialog:SetDefaultSize('SpartanUI', 850, 600)
	AceConfigDialog:Open('SpartanUI', 'Help')
end

function SUI:SUIMove(input)
	SUI:Print(
		'Sorry, /suimove has been removed due to conflicts with other systems. It will be back and better than before in a SUI 5.x build. In the meantime you can move frames and the minimap by holding alt and dragging.'
	)
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
		SUI:Print(L['Build'] .. ' ' .. GetAddOnMetadata('SpartanUI', 'X-Build'))
		SUI:Print(L['Bartender4 version'] .. ' ' .. SUI.DB.Bartender4Version)
	else
		if SUIChatCommands[input] then
			SUIChatCommands[input]()
		elseif string.find(input, ' ') then
			for i in string.gmatch(input, "%S+") do
				local arg, _ = string.gsub(input, i .. ' ', '')
				if SUIChatCommands[i] then
					SUIChatCommands[i](arg)
				end
			 end
		else
			AceConfigDialog:SetDefaultSize('SpartanUI', 850, 600)
			AceConfigDialog:Open('SpartanUI')
		end
	end
end

function SUI:AddChatCommand(arg, func)
	SUIChatCommands[arg] = func
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
