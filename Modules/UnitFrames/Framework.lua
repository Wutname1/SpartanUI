---@class SUI
local SUI = SUI
local _G, L, print = _G, SUI.L, SUI.print
---@class SUI_UnitFrames : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0
local UF = SUI:NewModule('Component_UnitFrames')
local MoveIt = SUI:GetModule('Component_MoveIt')
SUI.UF = UF
UF.DisplayName = L['Unit frames']
UF.description = 'CORE: SUI Unitframes'
UF.Core = true
UF.CurrentSettings = {}
UF.FramePos = {
	default = {
		['player'] = 'BOTTOMRIGHT,UIParent,BOTTOM,-60,250',
		['pet'] = 'RIGHT,SUI_UF_player,BOTTOMLEFT,-60,0',
		['pettarget'] = 'RIGHT,SUI_UF_pet,LEFT,0,-5',
		['target'] = 'LEFT,SUI_UF_player,RIGHT,150,0',
		['targettarget'] = 'LEFT,SUI_UF_target,BOTTOMRIGHT,4,0',
		['focus'] = 'BOTTOMLEFT,SUI_UF_target,TOP,0,30',
		['focustarget'] = 'BOTTOMLEFT,SUI_UF_focus,BOTTOMRIGHT,5,0',
		['boss'] = 'RIGHT,UIParent,RIGHT,-9,162',
		['party'] = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
		['partypet'] = 'BOTTOMRIGHT,frame,BOTTOMLEFT,-2,0',
		['partytarget'] = 'LEFT,frame,RIGHT,2,0',
		['raid'] = 'TOPLEFT,UIParent,TOPLEFT,20,-40',
		['arena'] = 'RIGHT,UIParent,RIGHT,-366,191'
	}
}
local Frames = {
	arena = {},
	boss = {},
	party = {},
	raid = {},
	containers = {},
	builders = {}
}
UF.Artwork = {}

---@param frameName string
---@param builder function
---@param defaultConfig? UFrameSettings
function Frames.Add(frameName, builder, defaultConfig)
	Frames.builders[frameName] = builder
end

---@param frame table
function Frames.Build(frame)
	if Frames.builders[frame.unitOnCreate] then
		Frames.builders[frame.unitOnCreate](frame)
	else
		Frames.builders['player'](frame)
	end
end

UF.Frames = Frames

function Frames.Config(frameName)
end

local Elements = {}

---@class SUIUFElement
---@field Build function
---@field Update? function
---@field OptionsTable? function
---@field UpdateSize? function+

---@class SUIUFElementList
---@field T table<string, SUIUFElement>
Elements.List = {}

---@class ElementConfig
---@field NoBulkUpdate boolean

---@param ElementName string
---@param Build function
---@param Update? function
---@param OptionsTable? function
---@param ElementSettings? ElementSettings
function Elements:Register(ElementName, Build, Update, OptionsTable, ElementSettings)
	UF.Elements.List[ElementName] = {
		Build = Build,
		Update = Update,
		OptionsTable = OptionsTable,
		ElementSettings = ElementSettings
	}
end

---@param frame table
---@param ElementName string
---@param DB? table
function Elements:Build(frame, ElementName, DB)
	if UF.Elements.List[ElementName] then
		if not frame.elementList then
			frame.elementList = {}
		end
		table.insert(frame.elementList, ElementName)
		UF.Elements.List[ElementName].Build(frame, DB or UF.CurrentSettings[frame.unitOnCreate].elements[ElementName] or {})
	end
end

---@param frame table
---@param ElementName string
---@param DB? table
---@return boolean --False if the element did not provide an updater
function Elements:Update(frame, ElementName, DB)
	if UF.Elements.List[ElementName] and UF.Elements.List[ElementName].Update then
		UF.Elements.List[ElementName].Update(frame, DB or UF.CurrentSettings[frame.unitOnCreate].elements[ElementName] or {})
		return true
	else
		return false
	end
end

---@param ElementName string
---@return ElementSettings --False if the element did not provide a Size updater
function Elements:GetConfig(ElementName)
	if UF.Elements.List[ElementName] and UF.Elements.List[ElementName].ElementSettings then
		return UF.Elements.List[ElementName].ElementSettings
	else
		return {config = {NoBulkUpdate = false}}
	end
end

---@param unitName string
---@param ElementName string
---@param OptionSet AceConfigOptionsTable
---@param DB? table
---@return boolean --False if the element did not provide options customizer
function Elements:Options(unitName, ElementName, OptionSet, DB)
	if UF.Elements.List[ElementName] and UF.Elements.List[ElementName].OptionsTable then
		UF.Elements.List[ElementName].OptionsTable(
			unitName,
			OptionSet or {},
			DB or UF.CurrentSettings[unitName].elements[ElementName] or {}
		)
		return true
	else
		return false
	end
end
UF.Elements = Elements

function UF:IsFriendlyFrame(frameName)
	local FriendlyFrame = {
		'player',
		'pet',
		'party',
		'partypet',
		'target',
		'targettarget'
	}
	if SUI:IsInTable(FriendlyFrame, frameName) or frameName:match('party') or frameName:match('raid') then
		return true
	end
	return false
end

function UF:PositionFrame(b)
	local positionData = UF.FramePos.default
	-- If artwork is enabled load the art's position data if supplied
	if SUI:IsModuleEnabled('Artwork') and UF.FramePos[SUI.DB.Artwork.Style] then
		positionData = SUI:MergeData(UF.FramePos[SUI.DB.Artwork.Style], UF.FramePos.default)
	end

	if b then
		local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[b])

		if UF.Frames[b].position then
			UF.Frames[b]:position(point, anchor, secondaryPoint, x, y, false, true)
		else
			UF.Frames[b]:ClearAllPoints()
			UF.Frames[b]:SetPoint(point, anchor, secondaryPoint, x, y)
		end
	else
		local frameList = {
			'player',
			'target',
			'targettarget',
			'pet',
			'pettarget',
			'focus',
			'focustarget',
			'boss',
			'party',
			'raid',
			'arena'
		}

		for _, frame in ipairs(frameList) do
			local frameName = 'SUI_UF_' .. frame
			if _G[frameName] then
				local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[frame])

				if _G[frameName].position then
					_G[frameName]:position(point, anchor, secondaryPoint, x, y, false, true)
				else
					_G[frameName]:ClearAllPoints()
					_G[frameName]:SetPoint(point, anchor, secondaryPoint, x, y)
				end
			end
		end
	end
end

function UF:ResetSettings()
	--Reset the DB
	UF.DB.UserSettings[UF.DB.Style] = nil
	-- Trigger update
	UF:Update()
end

local function LoadDB()
	-- Load Default Settings
	UF.CurrentSettings = SUI:MergeData({}, UF.Settings)

	-- Import theme settings
	if SUI.DB.Styles[UF.DB.Style] and SUI.DB.Styles[UF.DB.Style].Frames then
		UF.CurrentSettings = SUI:MergeData(UF.CurrentSettings, SUI.DB.Styles[UF.DB.Style].Frames, true)
	elseif UF.Artwork[UF.DB.Style] then
		local skin = UF.Artwork[UF.DB.Style].skin
		UF.CurrentSettings = SUI:MergeData(UF.CurrentSettings, SUI.DB.Styles[skin].Frames, true)
	end

	-- Import player customizations
	UF.CurrentSettings = SUI:MergeData(UF.CurrentSettings, UF.DB.UserSettings[UF.DB.Style], true)
end

function UF:OnInitialize()
	if SUI:IsModuleDisabled('UnitFrames') then
		return
	end

	-- Setup Database
	local defaults = {
		global = {
			['**'] = {
				enabled = true,
				width = 180,
				scale = 1,
				moved = false,
				visibility = {
					alphaDelay = 1,
					hideDelay = 3,
					showAlways = false,
					showInCombat = true,
					showWithTarget = false,
					showInRaid = false,
					showInParty = false
				},
				position = {
					point = 'BOTTOM',
					relativeTo = 'Frame',
					relativePoint = 'BOTTOM',
					xOfs = 0,
					yOfs = 0
				},
				elements = {
					['**'] = {
						enabled = false,
						bgTexture = false,
						points = false,
						alpha = 1,
						width = 20,
						height = 20,
						size = false,
						scale = 1,
						FrameStrata = nil,
						FrameLevel = nil,
						texture = nil,
						bg = {
							enabled = false,
							color = {0, 0, 0, .2}
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
							relativeTo = 'Frame',
							relativePoint = nil,
							x = 0,
							y = 0
						}
					},
					AssistantIndicator = {
						enabled = true,
						size = 12,
						position = {
							anchor = 'TOP',
							x = 0,
							y = 6
						}
					},
					AuraBars = {
						height = 14,
						width = false,
						sparkEnabled = true,
						spacing = 2,
						initialAnchor = 'BOTTOMLEFT',
						growth = 'UP',
						maxBars = 32,
						texture = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2',
						fgalpha = 1,
						bgalpha = 1,
						spellNameSize = 10,
						spellTimeSize = 10,
						gap = 1,
						scaleTime = false,
						icon = true,
						position = {
							anchor = 'BOTTOM',
							relativePoint = 'TOP',
							x = 7,
							y = 20
						},
						filters = {
							showPlayers = true
						}
					},
					Buffs = {
						number = 10,
						auraSize = 20,
						spacing = 1,
						showType = true,
						width = false,
						initialAnchor = 'BOTTOMLEFT',
						growthx = 'RIGHT',
						growthy = 'DOWN',
						rows = 2,
						position = {
							anchor = 'TOPLEFT',
							relativePoint = 'BOTTOMLEFT',
							y = -10
						},
						filters = {
							showPlayers = true,
							boss = true
						}
					},
					Debuffs = {
						number = 10,
						auraSize = 20,
						spacing = 1,
						width = false,
						ShowBoss = true,
						showType = true,
						initialAnchor = 'BOTTOMRIGHT',
						growthx = 'LEFT',
						growthy = 'UP',
						rows = 2,
						position = {
							anchor = 'TOPRIGHT',
							relativePoint = 'BOTTOMRIGHT',
							y = -10
						},
						filters = {
							showPlayers = true,
							boss = true
						}
					},
					DispelHighlight = {
						enabled = true,
						position = {
							anchor = nil
						}
					},
					Castbar = {
						enabled = false,
						height = 10,
						width = false,
						FrameStrata = 'BACKGROUND',
						interruptable = true,
						FlashOnInterruptible = true,
						latency = false,
						InterruptSpeed = .1,
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
						},
						position = {
							anchor = 'TOP'
						}
					},
					ClassPower = {
						enabled = true,
						width = 16,
						height = 5,
						position = {
							anchor = 'TOPLEFT',
							relativeTo = 'Name',
							relativePoint = 'BOTTOMLEFT',
							y = -5
						}
					},
					ClassIcon = {
						VisibleOn = 'PlayerControlled',
						size = 20,
						position = {
							anchor = 'BOTTOMLEFT',
							x = -12,
							y = 0
						}
					},
					CombatIndicator = {},
					GroupRoleIndicator = {
						enabled = true,
						size = 18,
						alpha = .75,
						ShowTank = true,
						ShowHealer = true,
						ShowDPS = true,
						position = {
							anchor = 'TOPRIGHT',
							x = 0,
							y = 10
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
					Health = {
						enabled = true,
						height = 40,
						width = false,
						FrameStrata = 'BACKGROUND',
						colorReaction = true,
						colorSmooth = false,
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
								text = '[health:current-formatted] / [health:max-formatted]',
								position = {
									anchor = 'CENTER',
									x = 0,
									y = 0
								}
							}
						},
						position = {
							anchor = 'TOP'
						}
					},
					HealthPrediction = {
						enabled = true
					},
					PhaseIndicator = {
						enabled = true,
						size = 20,
						position = {
							anchor = 'TOP',
							x = 0,
							y = 0
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
					Power = {
						enabled = true,
						height = 10,
						width = false,
						FrameStrata = 'BACKGROUND',
						bg = {
							enabled = true,
							color = {1, 1, 1, .2}
						},
						text = {
							['1'] = {
								enabled = false,
								text = '[power:current-formatted] / [power:max-formatted]'
							},
							['2'] = {
								enabled = false,
								text = '[perpp]%'
							}
						},
						position = {
							anchor = 'TOP',
							relativeTo = 'Health',
							relativePoint = 'BOTTOM',
							y = -1
						}
					},
					AdditionalPower = {
						enabled = true,
						height = 5,
						width = false,
						position = {
							anchor = 'TOP',
							relativeTo = 'Power',
							relativePoint = 'BOTTOM',
							y = -1
						}
					},
					ThreatIndicator = {},
					Name = {
						enabled = true,
						width = false,
						height = 12,
						textSize = 12,
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
					RestingIndicator = {
						size = 20
					},
					ResurrectIndicator = {
						enabled = true,
						size = 20
					},
					RaidTargetIndicator = {
						enabled = true,
						size = 20,
						position = {
							anchor = 'BOTTOMRIGHT',
							x = 5,
							y = -10
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
						size = 20,
						position = {
							anchor = 'TOPLEFT',
							x = -10
						}
					},
					StatusText = {
						textSize = 22,
						width = 70,
						height = 25,
						text = '[afkdnd]',
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
					RaidRoleIndicator = {
						enabled = true
					},
					SpartanArt = {
						enabled = true,
						['**'] = {
							enabled = false,
							x = 0,
							y = 0,
							alpha = 1,
							graphic = ''
						},
						full = {},
						top = {},
						bg = {},
						bottom = {}
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
					SUI_RaidGroup = {
						textSize = 13,
						text = '[group]',
						SetJustifyH = 'CENTER',
						SetJustifyV = 'MIDDLE',
						position = {
							anchor = 'BOTTOMRIGHT',
							x = 0,
							y = 10
						}
					},
					RareElite = {
						enabled = true,
						alpha = .4,
						points = {
							['1'] = {
								anchor = 'TOPLEFT',
								relativeTo = 'Frame',
								x = 0,
								y = 0
							},
							['2'] = {
								anchor = 'BOTTOMRIGHT',
								relativeTo = 'Frame',
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
				yOffset = -25,
				elements = {
					Name = {text = '[SUI_ColorClass][name] [arenaspec]'},
					Power = {
						height = 5
					},
					Castbar = {
						enabled = true,
						height = 15
					},
					Health = {
						position = {
							anchor = 'TOP',
							relativeTo = 'Castbar',
							relativePoint = 'BOTTOM'
						}
					},
					ThreatIndicator = {
						enabled = true,
						points = 'Name'
					},
					ClassIcon = {
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
				elements = {
					Castbar = {
						enabled = true
					},
					Health = {
						position = {
							anchor = 'TOP',
							relativeTo = 'Castbar',
							relativePoint = 'BOTTOM'
						}
					}
				}
			},
			bosstarget = {},
			focus = {
				enabled = true,
				width = 100,
				elements = {
					Debuffs = {
						enabled = true,
						onlyShowPlayer = true
					},
					Castbar = {
						enabled = true
					},
					Health = {
						position = {
							anchor = 'TOP',
							relativeTo = 'Castbar',
							relativePoint = 'BOTTOM'
						}
					}
				}
			},
			focustarget = {
				enabled = true,
				width = 90,
				elements = {
					Castbar = {
						enabled = true
					},
					Health = {
						position = {
							anchor = 'TOP',
							relativeTo = 'Castbar',
							relativePoint = 'BOTTOM'
						}
					}
				}
			},
			player = {
				enabled = true,
				visibility = {
					showAlways = true
				},
				anchor = {
					point = 'BOTTOMRIGHT',
					relativePoint = 'BOTTOM',
					xOfs = -60,
					yOfs = 250
				},
				elements = {
					AuraBars = {
						enabled = true
					},
					Buffs = {
						enabled = true,
						position = {
							anchor = 'TOPLEFT'
						}
					},
					Debuffs = {
						enabled = true,
						position = {
							anchor = 'TOPRIGHT'
						}
					},
					Portrait = {
						enabled = true
					},
					Castbar = {
						enabled = true
					},
					Health = {
						position = {
							anchor = 'TOP',
							relativeTo = 'Castbar',
							relativePoint = 'BOTTOM'
						}
					},
					CombatIndicator = {
						enabled = true,
						position = {
							anchor = 'TOPRIGHT',
							x = 10,
							y = 10
						}
					},
					ClassIcon = {
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
					},
					SUI_RaidGroup = {enabled = true}
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
				enabled = true,
				width = 120,
				showParty = true,
				showPlayer = true,
				showRaid = false,
				showSolo = false,
				xOffset = 0,
				yOffset = -20,
				maxColumns = 1,
				unitsPerColumn = 5,
				columnSpacing = 2,
				elements = {
					Buffs = {
						enabled = true,
						onlyShowPlayer = true,
						size = 15,
						initialAnchor = 'BOTTOMLEFT',
						growthx = 'LEFT',
						position = {
							anchor = 'BOTTOMLEFT',
							x = -15,
							y = 47
						}
					},
					Debuffs = {
						enabled = true,
						size = 15,
						initialAnchor = 'BOTTOMRIGHT',
						growthx = 'RIGHT',
						position = {
							anchor = 'BOTTOMRIGHT',
							x = 15,
							y = 47
						}
					},
					Castbar = {
						enabled = true
					},
					ThreatIndicator = {
						enabled = true,
						points = 'Name'
					},
					Health = {
						position = {
							anchor = 'TOP',
							relativeTo = 'Castbar',
							relativePoint = 'BOTTOM'
						}
					},
					ResurrectIndicator = {
						enabled = true
					},
					SummonIndicator = {
						enabled = true
					},
					GroupRoleIndicator = {
						enabled = true,
						position = {
							anchor = 'TOPRIGHT',
							x = 0,
							y = 0
						}
					},
					AssistantIndicator = {
						enabled = true
					},
					RaidTargetIndicator = {
						enabled = true,
						size = 15,
						position = {
							anchor = 'RIGHT',
							x = 5,
							y = 0
						}
					},
					ClassIcon = {
						enabled = false,
						size = 15,
						position = {
							anchor = 'TOPLEFT',
							x = 0,
							y = 0
						}
					},
					name = {
						position = {
							y = 12
						}
					},
					Power = {
						height = 5
					}
				}
			},
			partypet = {},
			partytarget = {},
			raid = {
				enabled = true,
				width = 95,
				showParty = false,
				showPlayer = true,
				showRaid = true,
				showSolo = false,
				mode = 'NAME',
				xOffset = 2,
				yOffset = 0,
				maxColumns = 4,
				unitsPerColumn = 10,
				columnSpacing = 2,
				visibility = {
					showAlways = false,
					showInRaid = true,
					showInParty = false
				},
				elements = {
					Buffs = {
						enabled = true,
						onlyShowPlayer = true,
						size = 10
					},
					Debuffs = {
						enabled = true,
						rows = 1,
						size = 10
					},
					Health = {
						height = 30
					},
					Power = {
						height = 3,
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
						enabled = true,
						size = 10,
						alpha = .75,
						position = {
							anchor = 'BOTTOMLEFT',
							x = 0,
							y = 0
						}
					},
					ThreatIndicator = {
						enabled = true,
						points = 'Name'
					},
					Name = {
						enabled = true,
						height = 10,
						textSize = 10,
						text = '[SUI_ColorClass][name]',
						position = {
							y = 0
						}
					},
					SUI_RaidGroup = {
						textSize = 9,
						text = '[group]',
						SetJustifyH = 'CENTER',
						SetJustifyV = 'MIDDLE',
						position = {
							anchor = 'BOTTOMRIGHT',
							x = 0,
							y = 5
						}
					},
					GroupRoleIndicator = {
						enabled = true,
						size = 15,
						alpha = .75,
						position = {
							anchor = 'TOPRIGHT',
							x = -1,
							y = 1
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
				elements = {
					AuraBars = {
						enabled = true
					},
					Buffs = {
						enabled = true,
						position = {
							anchor = 'TOPLEFT'
						}
					},
					Debuffs = {
						enabled = true,
						position = {
							anchor = 'TOPRIGHT'
						}
					},
					ThreatIndicator = {
						enabled = true,
						points = 'Name'
					},
					Portrait = {
						enabled = true
					},
					Castbar = {
						enabled = true
					},
					Health = {
						position = {
							anchor = 'TOP',
							relativeTo = 'Castbar',
							relativePoint = 'BOTTOM'
						}
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
					ClassIcon = {
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
				elements = {
					auras = {
						Debuffs = {
							size = 10
						}
					},
					ThreatIndicator = {
						enabled = true,
						points = 'Name'
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
		profile = {
			Style = 'War',
			UserSettings = {
				['**'] = {['**'] = {['**'] = {['**'] = {['**'] = {['**'] = {}}}}}}
			}
		}
	}
	UF.Database = SUI.SpartanUIDB:RegisterNamespace('UnitFrames', defaults)
	UF.Settings = UF.Database.global
	UF.DB = UF.Database.profile

	for frameKey, frameData in pairs(UF.DB.UserSettings[UF.DB.Style]) do
		if frameData.artwork then
			frameData.elements.SpartanArt = frameData.artwork
			frameData.artwork = nil
		end
	end

	LoadDB()
end

function UF:OnEnable()
	if SUI:IsModuleDisabled('UnitFrames') then
		return
	end

	-- Create Party & Raid frame holder
	local GroupedFrames = {
		'party',
		'raid',
		'boss',
		'arena'
	}
	for _, key in ipairs(GroupedFrames) do
		local elements = UF.CurrentSettings[key].elements
		local FrameHeight = 0
		if elements.Castbar.enabled then
			FrameHeight = FrameHeight + elements.Castbar.height
		end
		if elements.Health.enabled then
			FrameHeight = FrameHeight + elements.Health.height
		end
		if elements.Power.enabled then
			FrameHeight = FrameHeight + elements.Power.height
		end
		local height = UF.CurrentSettings[key].unitsPerColumn * (FrameHeight + UF.CurrentSettings[key].yOffset)

		local width =
			UF.CurrentSettings[key].maxColumns * (UF.CurrentSettings[key].width + UF.CurrentSettings[key].columnSpacing)

		local frame = CreateFrame('Frame', 'SUI_UF_' .. key)
		frame:Hide()
		frame:SetSize(width, height)
		UF.Frames.containers[key] = frame
	end

	-- Build options
	UF:InitializeOptions()

	-- Spawn Frames
	UF:SpawnFrames()

	-- Put frames into their inital position
	UF:PositionFrame()

	-- Create movers
	local FramesList = {
		'pet',
		'target',
		'targettarget',
		'focus',
		'focustarget',
		'player'
	}
	for _, b in pairs(FramesList) do
		MoveIt:CreateMover(UF.Frames[b], b, nil, nil, 'Unit frames')
	end

	-- Create Party & Raid Mover
	MoveIt:CreateMover(UF.Frames.containers.party, 'Party', nil, nil, 'Unit frames')
	MoveIt:CreateMover(UF.Frames.containers.raid, 'Raid', nil, nil, 'Unit frames')
	MoveIt:CreateMover(UF.Frames.containers.boss, 'Boss', nil, nil, 'Unit frames')
	if SUI.IsRetail then
		MoveIt:CreateMover(UF.Frames.containers.arena, 'Arena', nil, nil, 'Unit frames')
	end
end

function UF:Update()
	-- Refresh Settings
	LoadDB()
	-- Update positions
	UF:PositionFrame()
	--Send Custom change event
	SUI.Event:SendEvent('UNITFRAME_STYLE_CHANGED')
	-- Update all display elements
	UF:UpdateAll()
end

function UF:SetActiveStyle(style)
	UF.DB.Style = style
	-- Refersh Settings
	UF:Update()

	--Analytics
	SUI.Analytics:Set(UF, 'Style', style)
end

function UF.PostCreateAura(element, button)
	local function UpdateAura(self, elapsed)
		if (self.expiration) then
			self.expiration = math.max(self.expiration - elapsed, 0)

			if (self.expiration > 0 and self.expiration < 60) then
				self.Duration:SetFormattedText('%d', self.expiration)
			else
				self.Duration:SetText()
			end
		end
	end

	if button.SetBackdrop then
		button:SetBackdrop(nil)
		button:SetBackdropColor(0, 0, 0)
	end
	button.cd:SetReverse(true)
	button.cd:SetHideCountdownNumbers(true)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
	-- button:SetScript('OnEnter', OnAuraEnter)

	-- We create a parent for aura strings so that they appear over the cooldown widget
	local StringParent = CreateFrame('Frame', nil, button)
	StringParent:SetFrameLevel(20)

	button.count:SetParent(StringParent)
	button.count:ClearAllPoints()
	button.count:SetPoint('BOTTOMRIGHT', button, 2, 1)
	button.count:SetFont(SUI:GetFontFace('UnitFrames'), select(2, button.count:GetFont()) - 3)

	local Duration = StringParent:CreateFontString(nil, 'OVERLAY')
	Duration:SetFont(SUI:GetFontFace('UnitFrames'), 11)
	Duration:SetPoint('TOPLEFT', button, 0, -1)
	button.Duration = Duration

	button:HookScript('OnUpdate', UpdateAura)
end

function UF.PostUpdateAura(element, unit, button, index)
	local _, _, _, _, duration, expiration, owner, canStealOrPurge = UnitAura(unit, index, button.filter)
	if (duration and duration > 0) then
		button.expiration = expiration - GetTime()
	else
		button.expiration = math.huge
	end

	if button.SetBackdrop then
		if (unit == 'target' and canStealOrPurge) then
			button:SetBackdropColor(0, 1 / 2, 1 / 2)
		elseif (owner ~= 'player') then
			button:SetBackdropColor(0, 0, 0)
		end
	end
end

function UF.InverseAnchor(anchor)
	if anchor == 'TOPLEFT' then
		return 'BOTTOMLEFT'
	elseif anchor == 'TOPRIGHT' then
		return 'BOTTOMRIGHT'
	elseif anchor == 'BOTTOMLEFT' then
		return 'TOPLEFT'
	elseif anchor == 'BOTTOMRIGHT' then
		return 'TOPRIGHT'
	elseif anchor == 'BOTTOM' then
		return 'TOP'
	elseif anchor == 'TOP' then
		return 'BOTTOM'
	elseif anchor == 'LEFT' then
		return 'RIGHT'
	elseif anchor == 'RIGHT' then
		return 'LEFT'
	end
end
