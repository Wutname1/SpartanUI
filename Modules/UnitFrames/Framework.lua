local _G, L, print = _G, SUI.L, SUI.print
---@class SUI
local SUI = SUI
---@class SUI_UnitFrames : AceAddon-3.0, AceEvent-3.0, AceTimer-3.0
local UF = SUI:NewModule('Component_UnitFrames', 'AceTimer-3.0', 'AceEvent-3.0')
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
UF.frames = {
	arena = {},
	boss = {},
	party = {},
	raid = {},
	containers = {}
}
UF.Elements = {}
UF.Artwork = {}
UF.TagList = {
	--Health
	['curhp'] = {category = 'Health', description = 'Displays the current HP without decimals'},
	['deficit:name'] = {category = 'Health', description = 'Displays the health as a deficit and the name at full health'},
	['perhp'] = {
		category = 'Health',
		description = 'Displays percentage HP without decimals or the % sign. You can display the percent sign by adjusting the tag to [perhp<$%].'
	},
	['maxhp'] = {category = 'Health', description = 'Displays max HP without decimals'},
	['missinghp'] = {
		category = 'Health',
		description = 'Displays the missing health of the unit in whole numbers, when not at full health'
	},
	['health:current-short'] = {
		category = 'Health',
		description = 'Displays current HP rounded to the nearest Thousand or Million'
	},
	['health:current-dynamic'] = {
		category = 'Health',
		description = 'Displays current HP Rounded to the nearest Million or with commas below 1 million'
	},
	['health:current-formatted'] = {category = 'Health', description = 'Displays current HP with commas'},
	['health:missing-formatted'] = {category = 'Health', description = 'Displays missing HP with commas'},
	['health:max-formatted'] = {category = 'Health', description = 'Displays max HP with commas'},
	--Power
	['perpp'] = {category = 'Power', description = "Displays the unit's percentage power without decimals "},
	['curpp'] = {category = 'Power', description = "Displays the unit's current power without decimals"},
	['maxpp'] = {
		category = 'Power',
		description = 'Displays the max amount of power of the unit in whole numbers without decimals'
	},
	['missingpp'] = {
		category = 'Power',
		description = 'Displays the missing power of the unit in whole numbers when not at full power'
	},
	['power:current-formatted'] = {category = 'Power', description = 'Displays current power with commas'},
	['power:missing-formatted'] = {category = 'Power', description = 'Displays missing power with commas'},
	['power:max-formatted'] = {category = 'Power', description = 'Displays max power with commas'},
	--Mana
	['curmana'] = {category = 'Mana', description = 'Displays the current mana without decimals'},
	['maxmana'] = {category = 'Mana', description = 'Displays the max amount of mana the unit can have'},
	--Status
	['status'] = {category = 'Status', description = 'Displays zzz, dead, ghost, offline'},
	['afkdnd'] = {category = 'Status', description = 'Displays AFK or DND if the unit is afk or in Do not Disturb'},
	['dead'] = {category = 'Status', description = 'Displays <DEAD> if the unit is dead'},
	['offline'] = {category = 'Status', description = "Displays 'OFFLINE' if the unit is disconnected"},
	['resting'] = {category = 'Status', description = "Displays 'zzz' if the unit is resting"},
	--Classification
	['classification'] = {
		category = 'Classification',
		description = "Displays the unit's classification (e.g. 'ELITE' and 'RARE')"
	},
	['plus'] = {
		category = 'Classification',
		description = "Displays the character '+' if the unit is an elite or rare-elite"
	},
	['rare'] = {category = 'Classification', description = "Displays 'Rare' when the unit is a rare or rareelite"},
	['shortclassification'] = {
		category = 'Classification',
		description = "Displays the unit's classification in short form (e.g. '+' for ELITE and 'R' for RARE)"
	},
	--Classpower
	['cpoints'] = {
		category = 'Classpower',
		description = 'Displays amount of combo points the player has (only for player, shows nothing on 0)'
	},
	--Colors
	['difficulty'] = {
		category = 'Colors',
		description = 'Changes color of the next tag based on how difficult the unit is compared to the players level'
	},
	['powercolor'] = {category = 'Colors', description = 'Colors the power text based upon its type'},
	['SUI_ColorClass'] = {category = 'Colors', description = 'Changes the text color based on the class'},
	--PvP
	['faction'] = {category = 'PvP', description = "Displays 'Alliance' or 'Horde'"},
	['pvp'] = {category = 'PvP', description = "Displays 'PvP' if the unit is pvp flagged"},
	--Party and Raid
	['group'] = {category = 'Party and Raid', description = "Displays the group number the unit is in ('1' - '8')"},
	['leader'] = {category = 'Party and Raid', description = "Displays 'L' if the unit is the group/raid leader"},
	['leaderlong'] = {category = 'Party and Raid', description = "Displays 'Leader' if the unit is the group/raid leader"},
	--Level
	['level'] = {category = 'Level', description = 'Displays the level of the unit'},
	['smartlevel'] = {category = 'Level', description = "Only display the unit's level if it is not the same as yours"},
	--Names
	['name'] = {category = 'Names', description = 'Displays the full name of the unit without any letter limitation'}
}
if SUI.IsRetail then
	UF.TagList['affix'] = {category = 'Miscellaneous', description = 'Displays low level critter mobs'}
	UF.TagList['specialization'] = {
		category = 'Miscellaneous',
		description = 'Displays your current specialization as text'
	}
	UF.TagList['arcanecharges'] = {category = 'Classpower', description = 'Displays the arcane charges (Mage)'}
	UF.TagList['arenaspec'] = {category = 'PvP', description = 'Displays the area spec of an unit'}
	UF.TagList['chi'] = {category = 'Classpower', description = 'Displays the chi points (Monk)'}
	UF.TagList['faction'] = {category = 'PvP', description = "Displays 'Alliance' or 'Horde'"}
	UF.TagList['holypower'] = {category = 'Classpower', description = 'Displays the holy power (Paladin)'}
	UF.TagList['runes'] = {category = 'Classpower', description = 'Displays the runes (Death Knight)'}
	UF.TagList['soulshards'] = {category = 'Classpower', description = 'Displays the soulshards (Warlock)'}
	UF.TagList['threat'] = {
		category = 'Threat',
		description = 'Displays the current threat situation (Aggro is secure tanking, -- is losing threat and ++ is gaining threat)'
	}
	UF.TagList['title'] = {category = 'Names', description = 'Displays player title'}
	UF.TagList['threatcolor'] = {
		category = 'Colors',
		description = "Changes the text color, depending on the unit's threat situation"
	}
end

----------------------------------------------------------------------------------------------------
-- 1.  Styles are initalized and calls AddStyleSettings to pass the styles config into the unitframes module
-- 2.  A table is created with all of the settings from all the styles
-- 3.  UnitFrames OnEnable is called
-- 4.  Frames are spawned
--
-- DB is used for Player Customization. It uses the format:
-- DB.STYLE.FRAME
--
-- Styles DB Format
-- Style = {
--		id = 'MYSTYLE', -- One word, used in backend.
-- 		name = 'My Style', -- Human Readable
--		artskin = 'Artwork Skin Name',
--		FrameOptions = { Settings defined here override anything set in the default FrameOptions }
--	}
--
----------------------------------------------------------------------------------------------------
---@param ElementName string
---@param Build function
---@param Update? function
---@param OptionsTable? function
---@param UpdateSize? function
function UF:RegisterElement(ElementName, Build, Update, OptionsTable, UpdateSize)
	UF.Elements[ElementName] = {
		Build = Build,
		Update = Update,
		UpdateSize = UpdateSize,
		OptionsTable = OptionsTable
	}
end

function UF:BuldElement(frame, ElementName)
	if UF.Elements[ElementName] then
		UF.Elements[ElementName].Build(frame, UF.CurrentSettings[frame.unitOnCreate].elements[ElementName])
	end
end

function UF:IsFriendlyFrame(frameName)
	local FriendlyFrame = {
		'player',
		'pet',
		'party',
		'partypet',
		'raid',
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

		if UF.frames[b].position then
			UF.frames[b]:position(point, anchor, secondaryPoint, x, y, false, true)
		else
			UF.frames[b]:ClearAllPoints()
			UF.frames[b]:SetPoint(point, anchor, secondaryPoint, x, y)
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
							showPlayers = true,
							boss = true
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
						mode = 'icons',
						position = {
							anchor = 'TOPLEFT',
							y = 0
						},
						filters = {
							raid = true
						}
					},
					Debuffs = {
						enabled = true,
						ShowBoss = true,
						initialAnchor = 'BOTTOMRIGHT',
						growthx = 'LEFT',
						growthy = 'UP',
						mode = 'icons',
						position = {
							anchor = 'BOTTOMRIGHT',
							y = 0
						}
					},
					Bars = {
						auraBarHeight = 15,
						auraBarWidth = false,
						auraBarTexture = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2',
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
								text = '[power:current-formatted] / [power:max-formatted]'
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
							x = 0,
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
					ClassIcon = {
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
					SUI_RaidGroup = {
						size = 13,
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
				auras = {
					Buffs = {
						enabled = true,
						size = 10
					}
				},
				elements = {
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
				visibility = {
					showAlways = true
				},
				anchor = {
					point = 'BOTTOMRIGHT',
					relativePoint = 'BOTTOM',
					xOfs = -60,
					yOfs = 250
				},
				auras = {
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
				auras = {
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
				auras = {
					Buffs = {
						enabled = true,
						onlyShowPlayer = true,
						size = 10
					},
					Debuffs = {
						enabled = true,
						rows = 1,
						size = 10
					}
				},
				elements = {
					Health = {
						height = 30
					},
					Power = {
						height = 3,
						offset = 0,
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
						position = {
							anchor = 'BOTTOMLEFT',
							x = 0,
							y = 0
						}
					},
					Name = {
						enabled = true,
						height = 10,
						size = 10,
						position = {
							y = 0
						}
					},
					SUI_RaidGroup = {
						size = 9,
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
						size = 14,
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
				auras = {
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
		profile = {
			Style = 'War',
			UserSettings = {
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
								position = {},
								filters = {}
							},
							Debuffs = {
								position = {},
								filters = {}
							},
							Bars = {
								position = {},
								filters = {}
							}
						},
						elements = {
							['**'] = {
								bg = {},
								position = {}
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
							DispelHighlight = {},
							HealthPrediction = {},
							HappinessIndicator = {},
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
							Name = {},
							LeaderIndicator = {},
							RestingIndicator = {},
							GroupRoleIndicator = {},
							CombatIndicator = {},
							RaidTargetIndicator = {},
							ClassIcon = {},
							ReadyCheckIndicator = {},
							PvPIndicator = {},
							StatusText = {},
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
		}
	}
	UF.Database = SUI.SpartanUIDB:RegisterNamespace('UnitFrames', defaults)
	UF.Settings = UF.Database.global
	UF.DB = UF.Database.profile

	-- Migrate old settings
	if SUI.DB.Unitframes then
		print('Unit Frame DB Migration')
		UF.DB.Style = SUI.DB.Artwork.Style -- default to this, setting to SUI.DB.Unitframes.Style results in blank frames on inital load
		if SUI.DB.Unitframes.PlayerCustomizations then
			UF.DB.UserSettings = SUI:MergeData(UF.DB.UserSettings, SUI.DB.Unitframes.PlayerCustomizations, true)
		end

		SUI.DB.Unitframes = nil
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
		UF.frames.containers[key] = frame
	end

	-- Build options
	UF:InitializeOptions()

	-- Spawn Frames
	UF:SpawnFrames()

	-- Put frames into their inital position
	UF:PositionFrame()

	-- Create movers
	local FramesList = {
		[1] = 'pet',
		[2] = 'target',
		[3] = 'targettarget',
		[4] = 'focus',
		[5] = 'focustarget',
		[6] = 'player'
	}
	for _, b in pairs(FramesList) do
		MoveIt:CreateMover(UF.frames[b], b, nil, nil, 'Unit frames')
	end

	-- Create Party & Raid Mover
	MoveIt:CreateMover(UF.frames.containers.party, 'Party', nil, nil, 'Unit frames')
	MoveIt:CreateMover(UF.frames.containers.raid, 'Raid', nil, nil, 'Unit frames')
	MoveIt:CreateMover(UF.frames.containers.boss, 'Boss', nil, nil, 'Unit frames')
	if SUI.IsRetail then
		MoveIt:CreateMover(UF.frames.containers.arena, 'Arena', nil, nil, 'Unit frames')
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
