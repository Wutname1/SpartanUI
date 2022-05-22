local unpack, SUI, L, print, UF = unpack, SUI, SUI.L, SUI.print, SUI.UF
local module = SUI:NewModule('Component_Nameplates', 'AceTimer-3.0')
module.description = 'Basic nameplate module'
local Images = {
	Alliance = {
		bg = {
			Texture = 'Interface\\addons\\SpartanUI\\Images\\war\\UnitFrames',
			Coords = {0, 0.458984375, 0.74609375, 1} --left, right, top, bottom
		},
		flair = {
			Texture = 'Interface\\addons\\SpartanUI\\Images\\war\\UnitFrames',
			Coords = {0.03125, 0.427734375, 0, 0.421875}
		}
	},
	Horde = {
		bg = {
			Texture = 'Interface\\addons\\SpartanUI\\Images\\war\\UnitFrames',
			Coords = {0.572265625, 0.96875, 0.74609375, 1} --left, right, top, bottom
		},
		flair = {
			Texture = 'Interface\\addons\\SpartanUI\\Images\\war\\UnitFrames',
			Coords = {0.541015625, 1, 0, 0.421875}
		}
	}
}
local BarTexture = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'
local NameplateList = {}
local ElementList = {
	'Auras',
	'ClassIcon',
	'Health',
	'Power',
	'Castbar',
	'RareElite',
	'RaidTargetIndicator',
	'QuestIndicator',
	'PvPIndicator',
	'ThreatIndicator'
}

local UpdateElementState = function(frame)
	local elements = module.DB.elements

	frame.PvPIndicator.Override(frame, nil, frame.unit)

	-- Disable or enable elements that should not be enabled
	for _, item in ipairs(ElementList) do
		if frame[item] and elements[item].enabled then
			frame:EnableElement(item)
		else
			frame:DisableElement(item)
		end
	end

	-- Position Updates
	if (InCombatLockdown()) then
		return
	end
	-- Power
	frame.Power:ClearAllPoints()
	if elements.Health.enabled then
		frame.Power:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
	else
		frame.Power:SetPoint('BOTTOM', frame)
	end
	-- Castbar
	frame.Castbar:ClearAllPoints()
	if elements.Power.enabled then
		frame.Castbar:SetPoint('TOP', frame.Power, 'BOTTOM', 0, 0)
	elseif elements.Health.enabled then
		frame.Castbar:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
	else
		frame.Castbar:SetPoint('BOTTOM', frame)
	end
end

local PlayerPowerIcons = function(frame, attachPoint)
	--Runes
	if select(2, UnitClass('player')) == 'DEATHKNIGHT' then
		frame.Runes = {}
		frame.Runes.colorSpec = true

		for i = 1, 6 do
			frame.Runes[i] = CreateFrame('StatusBar', frame:GetName() .. '_Runes' .. i, frame)
			frame.Runes[i]:SetSize((frame.Health:GetWidth() - 10) / 6, 4)
			if (i == 1) then
				frame.Runes[i]:SetPoint('TOPLEFT', frame[attachPoint], 'BOTTOMLEFT', 0, 0)
			else
				frame.Runes[i]:SetPoint('TOPLEFT', frame.Runes[i - 1], 'TOPRIGHT', 2, 0)
			end
			frame.Runes[i]:SetStatusBarTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')
			frame.Runes[i]:SetStatusBarColor(0, .39, .63, 1)

			frame.Runes[i].bg = frame.Runes[i]:CreateTexture(nil, 'BORDER')
			frame.Runes[i].bg:SetPoint('TOPLEFT', frame.Runes[i], 'TOPLEFT', -0, 0)
			frame.Runes[i].bg:SetPoint('BOTTOMRIGHT', frame.Runes[i], 'BOTTOMRIGHT', 0, -0)
			frame.Runes[i].bg:SetTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')
			frame.Runes[i].bg:SetVertexColor(0, 0, 0, 1)
			frame.Runes[i].bg.multiplier = 0.64
			frame.Runes[i]:Hide()

			DeathKnightResourceOverlayFrame:HookScript(
				'OnShow',
				function()
					DeathKnightResourceOverlayFrame:Hide()
				end
			)
		end
	else
		frame.ComboPoints = frame:CreateFontString(nil, 'BORDER')
		frame.ComboPoints:SetPoint('TOPLEFT', frame[attachPoint], 'BOTTOMLEFT', 0, -2)
		local MaxPower, ClassPower = 5, {}

		if (select(2, UnitClass('player')) == 'MONK') then
			MaxPower = 6
		end

		for index = 1, MaxPower do
			local Bar = CreateFrame('StatusBar', nil, frame)
			Bar:SetStatusBarTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')

			-- Position and size.
			Bar:SetSize(((frame.Health:GetWidth() - 10) / MaxPower), 6)
			if (index == 1) then
				Bar:SetPoint('TOPLEFT', frame.ComboPoints, 'TOPLEFT')
			else
				Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 2, 0)
			end
			Bar:Hide()

			ClassPower[index] = Bar
		end

		-- Register with oUF
		frame.ClassPower = ClassPower
	end
end

local NamePlateFactory = function(frame, unit)
	if unit:match('nameplate') then
		local blizzPlate = frame:GetParent().UnitFrame
		if blizzPlate then
			frame.blizzPlate = blizzPlate
			frame.widget = blizzPlate.WidgetContainer
		end

		frame.unitGUID = UnitGUID(unit)
		frame.npcID = frame.unitGUID and select(6, strsplit('-', frame.unitGUID))

		local elementsDB = module.DB.elements
		local height = 0
		if elementsDB.Health.enabled then
			height = height + elementsDB.Health.height
		end
		if elementsDB.Power.enabled then
			height = height + elementsDB.Power.height
		end
		if elementsDB.Castbar.enabled then
			height = height + elementsDB.Castbar.height
		end

		frame:SetSize(module.DB.width, height)
		frame:SetPoint('CENTER', 0, 0)

		frame.bg = {}
		frame.bg.artwork = {}
		frame.bg.solid = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.bg.solid:SetAllPoints()
		frame.bg.solid:SetTexture(BarTexture)
		frame.bg.solid:SetVertexColor(0, 0, 0, .5)

		frame.bg.artwork.Neutral = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.bg.artwork.Neutral:SetAllPoints()
		frame.bg.artwork.Neutral:SetTexture(BarTexture)
		frame.bg.artwork.Neutral:SetVertexColor(0, 0, 0, .6)

		frame.bg.artwork.Alliance = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.bg.artwork.Alliance:SetAllPoints()
		frame.bg.artwork.Alliance:SetTexture(Images.Alliance.bg.Texture)
		frame.bg.artwork.Alliance:SetTexCoord(unpack(Images.Alliance.bg.Coords))
		frame.bg.artwork.Alliance:SetSize(frame:GetSize())

		frame.bg.artwork.Horde = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.bg.artwork.Horde:SetAllPoints()
		frame.bg.artwork.Horde:SetTexture(Images.Horde.bg.Texture)
		frame.bg.artwork.Horde:SetTexCoord(unpack(Images.Horde.bg.Coords))
		frame.bg.artwork.Horde:SetSize(frame:GetSize())

		-- Name
		local nameString = ''
		if module.DB.ShowLevel then
			nameString = '[difficulty][level]'
		end
		if module.DB.ShowName then
			nameString = nameString .. ' [SUI_ColorClass][name]'
		end
		if nameString ~= '' then
			frame.Name = frame:CreateFontString(nil, 'OVERLAY')
			SUI:FormatFont(frame.Name, 10, 'Nameplate')
			frame.Name:SetSize(frame:GetWidth(), 12)
			frame.Name:SetJustifyH(elementsDB.Name.SetJustifyH)
			frame.Name:SetPoint('BOTTOM', frame, 'TOP')
			frame:Tag(frame.Name, nameString)
		end

		-- health bar
		UF.Elements:Build(frame, 'Castbar', elementsDB.Castbar)
		UF.Elements:Build(frame, 'Health', elementsDB.Health)
		UF.Elements:Build(frame, 'Power', elementsDB.Power)
		UF.Elements:Build(frame, 'PvPIndicator', elementsDB.PvPIndicator)
		UF.Elements:Build(frame, 'ThreatIndicator', elementsDB.ThreatIndicator)

		-- ClassIcon
		frame.ClassIcon = frame:CreateTexture(nil, 'BORDER')
		frame.ClassIcon:SetSize(elementsDB.ClassIcon.size, elementsDB.ClassIcon.size)
		frame.ClassIcon:SetPoint(
			elementsDB.ClassIcon.position.anchor,
			frame,
			elementsDB.ClassIcon.position.anchor,
			elementsDB.ClassIcon.position.x,
			elementsDB.ClassIcon.position.y
		)

		-- Hots/Dots
		local Auras = CreateFrame('Frame', unit .. 'Auras', frame)
		Auras:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 2)
		Auras:SetSize(frame:GetWidth(), 16)
		if UnitReaction(unit, 'player') <= 2 then
			if (module.DB.onlyShowPlayer and module.DB.showStealableBuffs) then
				Auras.showStealableBuffs = module.DB.showStealableBuffs
			else
				Auras.onlyShowPlayer = module.DB.onlyShowPlayer
				Auras.showStealableBuffs = module.DB.showStealableBuffs
			end
		else
			Auras.onlyShowPlayer = module.DB.onlyShowPlayer
		end

		frame.Auras = Auras

		-- Raid Icon
		frame.RaidTargetIndicator = frame:CreateTexture(nil, 'OVERLAY')
		frame.RaidTargetIndicator:SetSize(15, 15)
		frame.RaidTargetIndicator:SetPoint('BOTTOM', frame.Health, 'TOPLEFT', 0, 0)

		-- Target Indicator
		local TargetIndicator = CreateFrame('Frame', 'BACKGROUND', frame)
		TargetIndicator.bg1 = frame:CreateTexture(nil, 'BACKGROUND', TargetIndicator)
		TargetIndicator.bg2 = frame:CreateTexture(nil, 'BACKGROUND', TargetIndicator)
		TargetIndicator.bg1:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\DoubleArrow')
		TargetIndicator.bg2:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\DoubleArrow')
		TargetIndicator.bg1:SetPoint('RIGHT', frame, 'LEFT')
		TargetIndicator.bg2:SetPoint('LEFT', frame, 'RIGHT')
		TargetIndicator.bg2:SetTexCoord(1, 0, 1, 0)
		TargetIndicator.bg1:SetSize(10, frame:GetHeight())
		TargetIndicator.bg2:SetSize(10, frame:GetHeight())

		TargetIndicator.bg1:Hide()
		TargetIndicator.bg2:Hide()
		frame.TargetIndicator = TargetIndicator

		-- Quest Indicator
		local QuestIndicator = frame:CreateTexture(nil, 'OVERLAY')
		QuestIndicator:SetSize(16, 16)
		QuestIndicator:SetPoint('TOPRIGHT', frame)
		frame.QuestMobIndicator = QuestIndicator

		-- Rare Elite indicator
		local RareElite = frame:CreateTexture(nil, 'BACKGROUND', nil, -2)
		RareElite:SetTexture('Interface\\Addons\\SpartanUI\\Images\\status-glow')
		RareElite:SetAlpha(.6)
		RareElite:SetAllPoints(frame)
		frame.RareElite = RareElite

		-- WidgetXPBar
		if SUI.IsRetail then
			local WidgetXPBar = CreateFrame('StatusBar', frame:GetDebugName() .. 'WidgetXPBar', frame)
			-- WidgetXPBar:SetFrameStrata(frame:GetFrameStrata())
			WidgetXPBar:SetFrameLevel(5)
			WidgetXPBar:SetStatusBarTexture(BarTexture)
			WidgetXPBar:SetSize(frame:GetWidth(), elementsDB.XPBar.height)
			WidgetXPBar:SetPoint('TOP', frame, 'BOTTOM', 0, elementsDB.XPBar.Offset)
			WidgetXPBar:SetStatusBarColor(0, .5, 1, .7)

			WidgetXPBar.bg = WidgetXPBar:CreateTexture(nil, 'BACKGROUND', WidgetXPBar)
			WidgetXPBar.bg:SetAllPoints()
			WidgetXPBar.bg:SetTexture(BarTexture)
			WidgetXPBar.bg:SetVertexColor(0, 0, 0, .5)

			WidgetXPBar.Rank = WidgetXPBar:CreateFontString()
			WidgetXPBar.Rank:SetJustifyH('LEFT')
			WidgetXPBar.Rank:SetJustifyV('MIDDLE')
			WidgetXPBar.Rank:SetAllPoints(WidgetXPBar)
			SUI:FormatFont(WidgetXPBar.Rank, 7, 'Nameplate')

			WidgetXPBar.ProgressText = WidgetXPBar:CreateFontString()
			WidgetXPBar.ProgressText:SetJustifyH('CENTER')
			WidgetXPBar.ProgressText:SetJustifyV('MIDDLE')
			WidgetXPBar.ProgressText:SetAllPoints(WidgetXPBar)
			SUI:FormatFont(WidgetXPBar.ProgressText, 7, 'Nameplate')

			frame.WidgetXPBar = WidgetXPBar
		end

		-- Setup Player Icons
		if module.DB.ShowPlayerPowerIcons then
			local attachPoint = 'Castbar'
			if not elementsDB.Castbar.enabled then
				if elementsDB.Power.enabled then
					attachPoint = 'Power'
				else
					attachPoint = 'Health'
				end
			end

			PlayerPowerIcons(frame, attachPoint)
		end

		-- Setup Scale
		frame:SetScale(module.DB.Scale)
	end
end

local NameplateCallback = function(self, event, unit)
	if not self or not unit or event == 'NAME_PLATE_UNIT_REMOVED' then
		return
	end

	local elementDB = module.DB.elements
	if event == 'NAME_PLATE_UNIT_ADDED' then
		local blizzPlate = self:GetParent().UnitFrame
		if blizzPlate then
			self.blizzPlate = blizzPlate
			self.widget = blizzPlate.WidgetContainer
		end
		self.unitGUID = UnitGUID(unit)
		self.npcID = self.unitGUID and select(6, strsplit('-', self.unitGUID))

		NameplateList[self:GetName()] = true

		self:UpdateAllElements('ForceUpdate')
	elseif event == 'NAME_PLATE_UNIT_REMOVED' then
		NameplateList[self:GetName()] = false
	end

	-- Update target Indicator
	if UnitIsUnit(unit, 'target') and module.DB.ShowTarget then
		-- the frame is the new target
		self.TargetIndicator.bg1:Show()
		self.TargetIndicator.bg2:Show()
	elseif self.TargetIndicator.bg1:IsShown() then
		self.TargetIndicator.bg1:Hide()
		self.TargetIndicator.bg2:Hide()
	end

	for _, item in ipairs(ElementList) do
		if self[item] and elementDB[item].enabled then
			self:EnableElement(item)
		else
			self:DisableElement(item)
		end
	end

	-- Update elements
	UpdateElementState(self)

	-- Update class icons
	local VisibleOn = module.DB.elements.ClassIcon.visibleOn
	local reaction = UnitReaction(unit, 'player')

	if
		((reaction <= 2 and VisibleOn == 'hostile') or (reaction >= 3 and VisibleOn == 'friendly') or
			(UnitPlayerControlled(unit) and VisibleOn == 'PlayerControlled') or
			VisibleOn == 'all') and
			module.DB.elements.ClassIcon.enabled
	 then
		self:EnableElement('ClassIcon')
		self.ClassIcon:SetSize(elementDB.ClassIcon.size, elementDB.ClassIcon.size)
		self.ClassIcon:SetPoint(
			elementDB.ClassIcon.position.anchor,
			self,
			elementDB.ClassIcon.position.anchor,
			elementDB.ClassIcon.position.x,
			elementDB.ClassIcon.position.y
		)
	else
		self:DisableElement('ClassIcon')
	end

	-- Update Player Icons
	if UnitIsUnit(unit, 'player') and event == 'NAME_PLATE_UNIT_ADDED' then
		if self.Runes then
			self:EnableElement('Runes')
			self.Runes:ForceUpdate()
		elseif self.ClassPower then
			self:EnableElement('ClassPower')
			self.ClassPower:ForceUpdate()
		end
	else
		if self.Runes then
			self:DisableElement('Runes')
		elseif self.ClassPower then
			self:DisableElement('ClassPower')
		end
	end

	-- Set the Scale of the nameplate
	self:SetScale(module.DB.Scale)
end

function module:UpdateNameplates()
	for k, v in pairs(NameplateList) do
		if v then
			UpdateElementState(_G[k])
		end
	end
end

function module:OnInitialize()
	local defaults = {
		profile = {
			ShowThreat = true,
			ShowName = true,
			ShowLevel = true,
			ShowTarget = true,
			ShowRaidTargetIndicator = true,
			onlyShowPlayer = true,
			showStealableBuffs = false,
			Scale = 1,
			width = 128,
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
					FrameLevel = nil,
					FrameStrata = nil,
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
				Auras = {},
				Background = {
					type = 'solid',
					colorMode = 'reaction',
					alpha = 0.35
				},
				DispelHighlight = {},
				RareElite = {},
				Name = {
					SetJustifyH = 'CENTER'
				},
				QuestMobIndicator = {},
				Health = {
					enabled = true,
					height = 5,
					offset = 0,
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
							enabled = false,
							text = '[health:current-formatted] [perhp]%',
							position = {
								anchor = 'CENTER',
								x = 0,
								y = 0
							}
						}
					}
				},
				Power = {
					enabled = true,
					height = 3,
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
				PvPIndicator = {},
				ThreatIndicator = {},
				Castbar = {
					enabled = true,
					height = 5,
					offset = -6,
					interruptable = true,
					FlashOnInterruptible = true,
					latency = false,
					InterruptSpeed = .1,
					bg = {
						enabled = true,
						color = {1, 1, 1, .2}
					},
					Icon = {
						enabled = false,
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
				ClassIcon = {
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
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Nameplates', defaults)
	module.DB = module.Database.profile

	-- Migrate old settings
	if SUI.DB.Nameplates then
		print('Nameplate DB Migration')
		module.DB = SUI:MergeData(module.DB, SUI.DB.Nameplates, true)
		SUI.DB.Nameplates = nil
	end

	SUIUF:RegisterStyle('Spartan_NamePlates', NamePlateFactory)
end

function module:OnDisable()
	SUI.opt.args.ModSetting.args.Nameplates.enabled = false
end

function module:OnEnable()
	if SUI.DB.DisabledComponents.Nameplates then
		return
	end
	module:BuildOptions()

	if (not oUF_NamePlateDriver) then
		SUIUF:SetActiveStyle('Spartan_NamePlates')
		SUIUF:SpawnNamePlates(nil, NameplateCallback)

		-- oUF is not hiding the mana bar. So we need to hide it.
		if ClassNameplateManaBarFrame then
			ClassNameplateManaBarFrame:HookScript(
				'OnShow',
				function()
					ClassNameplateManaBarFrame:Hide()
				end
			)
		end
	end
end

function module:BuildOptions()
	local anchorPoints = {
		['TOPLEFT'] = 'TOP LEFT',
		['TOP'] = 'TOP',
		['TOPRIGHT'] = 'TOP RIGHT',
		['RIGHT'] = 'RIGHT',
		['CENTER'] = 'CENTER',
		['LEFT'] = 'LEFT',
		['BOTTOMLEFT'] = 'BOTTOM LEFT',
		['BOTTOM'] = 'BOTTOM',
		['BOTTOMRIGHT'] = 'BOTTOM RIGHT'
	}

	local function toInt(val)
		if val then
			return 1
		end
		return 0
	end
	local function toBool(val)
		if tonumber(val) == 1 then
			return true
		else
			return false
		end
	end

	SUI.opt.args.ModSetting.args.Nameplates = {
		type = 'group',
		name = L['Nameplates'],
		childGroups = 'tab',
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
			module:UpdateNameplates()
		end,
		args = {
			width = {
				name = L['Frame width'],
				type = 'input'
			},
			Scale = {
				name = L['Scale'],
				type = 'range',
				width = 'full',
				min = .01,
				max = 3,
				step = .01,
				order = 1
			},
			General = {
				name = L['General Apperance'],
				type = 'group',
				order = 10,
				childGroups = 'tree',
				args = {
					Background = {
						name = L['Background'],
						type = 'group',
						order = 1,
						get = function(info)
							return module.DB.elements.Background[info[#info]]
						end,
						set = function(info, val)
							module.DB.elements.Background[info[#info]] = val
							module:UpdateNameplates()
						end,
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1
							},
							type = {
								name = L['Type'],
								order = 2,
								type = 'select',
								values = {['artwork'] = 'Artwork', ['solid'] = 'Solid'}
							},
							colorMode = {
								name = L['Color mode'],
								type = 'select',
								order = 3,
								values = {
									['faction'] = 'Faction',
									['reaction'] = 'Reaction'
								}
							},
							alpha = {
								name = L['Alpha'],
								type = 'range',
								width = 'full',
								order = 4,
								min = 0,
								max = 1,
								step = .01
							}
						}
					},
					HealthBar = {
						name = L['Health bar'],
						type = 'group',
						order = 3,
						get = function(info)
							return module.DB.elements.Health[info[#info]]
						end,
						set = function(info, val)
							module.DB.elements.Health[info[#info]] = val
							module:UpdateNameplates()
						end,
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1
							},
							height = {
								name = L['Height'],
								type = 'range',
								width = 'full',
								min = 1,
								max = 30,
								step = 1,
								order = 10
							},
							colorTapping = {
								name = L['Grey out tapped targets'],
								type = 'toggle',
								width = 'full',
								order = 20
							},
							colorReaction = {
								name = L['Color based on reaction'],
								type = 'toggle',
								width = 'full',
								order = 30
							},
							colorSmooth = {
								name = L['Color by health remaning'],
								type = 'toggle',
								width = 'full',
								order = 30
							},
							colorClass = {
								name = L['Color based on class'],
								type = 'toggle',
								width = 'full',
								order = 40
							},
							offset = {
								name = L['Offset'],
								type = 'range',
								order = 3,
								min = -30,
								max = 30,
								step = .5
							}
						}
					},
					PowerBar = {
						name = L['Power bar'],
						type = 'group',
						order = 4,
						get = function(info)
							return module.DB.elements.Power[info[#info]]
						end,
						set = function(info, val)
							module.DB.elements.Power[info[#info]] = val
							module:UpdateNameplates()
						end,
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1
							},
							height = {
								name = L['Height'],
								type = 'range',
								width = 'full',
								min = 1,
								max = 15,
								step = 1,
								order = 10
							}
						}
					},
					CastBar = {
						name = L['Cast bar'],
						type = 'group',
						order = 5,
						get = function(info)
							return module.DB.elements.Castbar[info[#info]]
						end,
						set = function(info, val)
							module.DB.elements.Castbar[info[#info]] = val
							module:UpdateNameplates()
						end,
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1
							},
							height = {
								name = L['Height'],
								type = 'range',
								width = 'full',
								min = 1,
								max = 15,
								step = 1,
								order = 10
							},
							text = {
								name = L['Show text'],
								type = 'toggle',
								width = 'full',
								order = 20
							},
							FlashOnInterruptible = {
								name = L['Flash on interruptible cast'],
								type = 'toggle',
								width = 'full',
								order = 30
							},
							InterruptSpeed = {
								name = L['Interrupt flash speed'],
								type = 'range',
								min = .01,
								max = 1,
								step = .01
							}
						}
					}
				}
			},
			Indicator = {
				name = L['Indicators'],
				type = 'group',
				order = 20,
				childGroups = 'tree',
				args = {
					Name = {
						name = L['Name'],
						type = 'group',
						order = 1,
						args = {
							ShowLevel = {
								name = L['Show level'],
								type = 'toggle',
								order = 1,
								get = function(info)
									return module.DB.ShowLevel
								end,
								set = function(info, val)
									module.DB.ShowLevel = val
								end
							},
							ShowName = {
								name = L['Show name'],
								type = 'toggle',
								order = 2,
								get = function(info)
									return module.DB.elements.Name.enabled
								end,
								set = function(info, val)
									--Update the DB
									module.DB.elements.Name.enabled = val
								end
							},
							JustifyH = {
								name = L['Horizontal alignment'],
								type = 'select',
								order = 3,
								values = {
									['LEFT'] = 'Left',
									['CENTER'] = 'Center',
									['RIGHT'] = 'Right'
								},
								get = function(info)
									return module.DB.elements.Name.SetJustifyH
								end,
								set = function(info, val)
									--Update the DB
									module.DB.elements.Name.SetJustifyH = val
									--Update the screen
									-- module.frames[frameName][key]:SetJustifyH(val)
								end
							}
						}
					},
					QuestIndicator = {
						name = L['Quest icon'],
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return module.DB.elements.QuestIndicator.enabled
								end,
								set = function(info, val)
									module.DB.elements.QuestIndicator.enabled = val
								end
							}
						}
					},
					RareElite = {
						name = L['Rare/Elite background'],
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return module.DB.elements.RareElite.enabled
								end,
								set = function(info, val)
									module.DB.elements.RareElite.enabled = val
								end
							}
						}
					},
					TargetIndicator = {
						name = L['Target indicator'],
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return module.DB.ShowTarget
								end,
								set = function(info, val)
									module.DB.ShowTarget = val
								end
							}
						}
					},
					ClassIcon = {
						name = L['Class icon'],
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'double',
								order = 1,
								get = function(info)
									return module.DB.elements.ClassIcon.enabled
								end,
								set = function(info, val)
									module.DB.elements.ClassIcon.enabled = val
									module:UpdateNameplates()
								end
							},
							visibleOn = {
								name = L['Show on'],
								type = 'select',
								order = 2,
								values = {
									['friendly'] = 'Friendly',
									['hostile'] = 'Hostile',
									['PlayerControlled'] = 'Player controlled',
									['all'] = 'All'
								},
								get = function(info)
									return module.DB.elements.ClassIcon.visibleOn
								end,
								set = function(info, val)
									module.DB.elements.ClassIcon.visibleOn = val
									module:UpdateNameplates()
								end
							},
							size = {
								name = L['Size'],
								type = 'range',
								order = 3,
								min = 1,
								max = 100,
								step = 1,
								get = function(info)
									return module.DB.elements.ClassIcon.size
								end,
								set = function(info, val)
									--Update the DB
									module.DB.elements.ClassIcon.size = val
								end
							},
							position = {
								name = L['Position'],
								type = 'group',
								order = 50,
								inline = true,
								args = {
									x = {
										name = L['X Axis'],
										type = 'range',
										order = 1,
										min = -100,
										max = 100,
										step = 1,
										get = function(info)
											return module.DB.elements.ClassIcon.position.x
										end,
										set = function(info, val)
											--Update the DB
											module.DB.elements.ClassIcon.position.x = val
										end
									},
									y = {
										name = L['Y Axis'],
										type = 'range',
										order = 2,
										min = -100,
										max = 100,
										step = 1,
										get = function(info)
											return module.DB.elements.ClassIcon.position.y
										end,
										set = function(info, val)
											--Update the DB
											module.DB.elements.ClassIcon.position.y = val
										end
									},
									anchor = {
										name = L['Anchor point'],
										type = 'select',
										order = 3,
										values = anchorPoints,
										get = function(info)
											return module.DB.elements.ClassIcon.position.anchor
										end,
										set = function(info, val)
											--Update the DB
											module.DB.elements.ClassIcon.position.anchor = val
										end
									}
								}
							}
						}
					},
					Auras = {
						name = L['Auras'],
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								order = 1,
								width = 'double',
								get = function(info)
									return module.DB.elements.Auras.enabled
								end,
								set = function(info, val)
									module.DB.elements.Auras.enabled = val
									module:UpdateNameplates()
								end
							},
							onlyShowPlayer = {
								name = L['Show only auras created by player'],
								type = 'toggle',
								order = 2,
								width = 'double',
								get = function(info)
									return module.DB.onlyShowPlayer
								end,
								set = function(info, val)
									module.DB.onlyShowPlayer = val
									module:UpdateNameplates()
								end
							},
							showStealableBuffs = {
								name = L['Show Stealable/Dispellable buffs'],
								type = 'toggle',
								order = 3,
								width = 'double',
								get = function(info)
									return module.DB.showStealableBuffs
								end,
								set = function(info, val)
									module.DB.showStealableBuffs = val
									module:UpdateNameplates()
								end
							},
							notice = {
								name = L['With both of these options active your DOTs will not appear on enemies.'],
								type = 'description',
								order = 4,
								fontSize = 'small'
							}
						}
					},
					XPBar = {
						name = L['XP Bar'],
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return module.DB.elements.XPBar.enabled
								end,
								set = function(info, val)
									module.DB.elements.XPBar.enabled = val
								end
							},
							size = {
								name = L['Size'],
								type = 'range',
								order = 2,
								min = 1,
								max = 30,
								step = 1,
								get = function(info)
									return module.DB.elements.XPBar.size
								end,
								set = function(info, val)
									module.DB.elements.XPBar.size = val
								end
							},
							Offset = {
								name = L['Offset'],
								type = 'range',
								order = 3,
								min = -30,
								max = 30,
								step = .5,
								get = function(info)
									return module.DB.elements.XPBar.Offset
								end,
								set = function(info, val)
									module.DB.elements.XPBar.Offset = val
								end
							}
						}
					}
				}
			},
			Display = {
				name = L['Blizzard display options'],
				type = 'group',
				order = 300,
				args = {
					nameplateShowAll = {
						name = UNIT_NAMEPLATES_AUTOMODE,
						desc = OPTION_TOOLTIP_UNIT_NAMEPLATES_AUTOMODE,
						type = 'toggle',
						width = 'double',
						get = function(info)
							return toBool(GetCVar('nameplateShowAll'))
						end,
						set = function(info, val)
							SetCVar('nameplateShowAll', toInt(val))
						end
					},
					nameplateShowSelf = {
						name = DISPLAY_PERSONAL_RESOURCE,
						desc = OPTION_TOOLTIP_UNIT_NAMEPLATES_AUTOMODE,
						type = 'toggle',
						width = 'double',
						get = function(info)
							return toBool(GetCVar('nameplateShowSelf'))
						end,
						set = function(info, val)
							SetCVar('nameplateShowSelf', toInt(val))
						end
					},
					nameplateMotion = {
						name = UNIT_NAMEPLATES_TYPES,
						desc = function(info)
							if GetCVar('nameplateMotion') == '1' then
								return UNIT_NAMEPLATES_TYPE_TOOLTIP_2
							else
								return UNIT_NAMEPLATES_TYPE_TOOLTIP_1
							end
						end,
						type = 'select',
						values = {['1'] = UNIT_NAMEPLATES_TYPE_2, ['0'] = UNIT_NAMEPLATES_TYPE_1},
						get = function(info)
							return GetCVar('nameplateMotion')
						end,
						set = function(info, val)
							SetCVar('nameplateMotion', tonumber(val))
						end
					}
				}
			}
		}
	}
end
