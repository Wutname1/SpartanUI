local unpack, SUI, L = unpack, SUI, SUI.L
local module = SUI:NewModule('Component_Nameplates', 'AceTimer-3.0')
local Images = {
	Alliance = {
		bg = {
			Texture = 'Interface\\addons\\SpartanUI_Style_War\\Images\\UnitFrames',
			Coords = {0, 0.458984375, 0.74609375, 1} --left, right, top, bottom
		},
		flair = {
			Texture = 'Interface\\addons\\SpartanUI_Style_War\\Images\\UnitFrames',
			Coords = {0.03125, 0.427734375, 0, 0.421875}
		}
	},
	Horde = {
		bg = {
			Texture = 'Interface\\addons\\SpartanUI_Style_War\\Images\\UnitFrames',
			Coords = {0.572265625, 0.96875, 0.74609375, 1} --left, right, top, bottom
		},
		flair = {
			Texture = 'Interface\\addons\\SpartanUI_Style_War\\Images\\UnitFrames',
			Coords = {0.541015625, 1, 0, 0.421875}
		}
	}
}
local BarTexture = 'Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga'
local Timers = {}
local factionColor = {
	['Alliance'] = {0, 0, 1, 0.3},
	['Horde'] = {1, 0, 0, 0.3},
	['Neutral'] = {0, 0, 0, 0.5}
}
local NameplateList = {}

local pvpIconWar = function(self, event, unit)
	if (unit ~= self.unit) then
		return
	end
	local settings = SUI.DBMod.NamePlates.elements
	self.bg.solid:Hide()
	self.bg.artwork.Neutral:Hide()
	self.bg.artwork.Alliance:Hide()
	self.bg.artwork.Horde:Hide()

	if not settings.Background.enabled then
		return
	end

	local factionGroup = UnitFactionGroup(unit)
	if settings.Background.type == 'solid' then
		self.bg.solid:Show()
		if settings.Background.colorMode == 'faction' and factionGroup then
			self.bg.solid:SetVertexColor(unpack(factionColor[factionGroup]))
		elseif settings.Background.colorMode == 'reaction' then
			local colors = SUIUF.colors.reaction[UnitReaction(unit, 'player')]
			if colors then
				self.bg.solid:SetVertexColor(colors[1], colors[2], colors[3])
			else
				self.bg.solid:SetVertexColor(0, 0, 0)
			end
		else
			self.bg.solid:SetVertexColor(0, 0, 0)
		end
		self.bg.solid:SetAlpha(settings.Background.alpha)
	else
		if (factionGroup) then
			self.bg.artwork[factionGroup]:Show()
			self.bg.artwork[factionGroup]:SetAlpha(settings.Background.alpha)
		else
			self.bg.artwork.Neutral:Show()
			self.bg.artwork.Neutral:SetAlpha(settings.Background.alpha)
		end
	end
end

function module:Flash(self)
	if self.Castbar.casting and self.Castbar.notInterruptible == false and self:IsVisible() then
		local _, g, b = self.Castbar:GetStatusBarColor()
		if b ~= 0 and g ~= 0 then
			self.Castbar:SetStatusBarColor(1, 0, 0)
		elseif b == 0 and g == 0 then
			self.Castbar:SetStatusBarColor(1, 1, 0)
		else
			self.Castbar:SetStatusBarColor(1, 1, 1)
		end
		module:ScheduleTimer('Flash', .1, _G[self:GetName()])
	end
end

local PostCastStart = function(self, unit, name)
	if
		self.notInterruptible == false and SUI.DBMod.NamePlates.elements.Castbar.FlashOnInterruptible and
			UnitIsEnemy('player', unit)
	 then
		_G[self.PName].Castbar:SetStatusBarColor(0, 0, 0)
		module:ScheduleTimer('Flash', .1, _G[self.PName])
	else
		_G[self.PName].Castbar:SetStatusBarColor(1, 0.7, 0)
	end
end

local PostCastStop = function(self)
	if SUI.DBMod.NamePlates.elements.Castbar.FlashOnInterruptible then
		module:CancelTimer(Timers[self:GetName()])
	end
end

local NamePlateFactory = function(frame, unit)
	if unit:match('nameplate') then
		local elements = SUI.DBMod.NamePlates.elements
		frame:SetSize(128, 16)
		frame:SetPoint('CENTER', 0, 0)

		-- health bar
		local health = CreateFrame('StatusBar', nil, frame)
		health:SetPoint('BOTTOM')
		health:SetSize(frame:GetWidth(), elements.Health.height)
		health:SetStatusBarTexture(BarTexture)
		-- health.colorHealth = true
		health.frequentUpdates = true
		health.colorTapping = elements.Health.colorTapping
		health.colorReaction = elements.Health.colorReaction
		health.colorClass = elements.Health.colorClass
		frame.Health = health

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
		if SUI.DBMod.NamePlates.ShowLevel then
			nameString = '[difficulty][level]'
		end
		if SUI.DBMod.NamePlates.ShowName then
			nameString = nameString .. ' [SUI_ColorClass][name]'
		end
		if nameString ~= '' then
			frame.Name = health:CreateFontString(nil, 'BACKGROUND')
			SUI:FormatFont(frame.Name, 10, 'Player')
			frame.Name:SetSize(frame:GetWidth(), 12)
			frame.Name:SetJustifyH(elements.Name.SetJustifyH)
			frame.Name:SetPoint('BOTTOMLEFT', frame.Health, 'TOPLEFT', 0, 0)
			frame:Tag(frame.Name, nameString)
		end

		-- Mana/Energy
		if elements.Power.enabled then
			local power = CreateFrame('StatusBar', nil, frame)
			power:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
			power:SetSize(frame:GetWidth(), elements.Power.height)
			power:SetStatusBarTexture(BarTexture)

			frame.Power = power
			frame.Power.colorPower = true
			frame.Power.frequentUpdates = true
		end

		-- Castbar
		if elements.Castbar.enabled then
			local cast = CreateFrame('StatusBar', nil, frame)
			if elements.Power.enabled then
				cast:SetPoint('TOP', frame.Power, 'BOTTOM', 0, 0)
			else
				cast:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
			end

			cast:SetSize(frame:GetWidth(), elements.Castbar.height)
			cast:SetStatusBarTexture(BarTexture)
			cast:SetStatusBarColor(1, 0.7, 0)
			if elements.Castbar.text then
				cast.Text = cast:CreateFontString()
				SUI:FormatFont(cast.Text, 7, 'Player')
				cast.Text:SetJustifyH('CENTER')
				cast.Text:SetJustifyV('MIDDLE')
				cast.Text:SetAllPoints(cast)
			end

			-- Add latency display
			cast.SafeZone = cast:CreateTexture(nil, 'OVERLAY')

			--Interupt Flash
			cast.PostCastStart = PostCastStart
			cast.PostCastInterruptible = PostCastStart
			cast.PostCastStop = PostCastStop
			cast.PostCastInterrupted = PostCastStop
			cast.PostCastNotInterruptible = PostCastStop
			cast.PName = frame:GetName()

			frame.Castbar = cast
			frame.Castbar:SetParent(frame)
		end

		-- ClassIcon
		frame.SUI_ClassIcon = frame:CreateTexture(nil, 'BORDER')
		frame.SUI_ClassIcon:SetSize(elements.SUI_ClassIcon.size, elements.SUI_ClassIcon.size)
		frame.SUI_ClassIcon:SetPoint(
			elements.SUI_ClassIcon.position.anchor,
			frame,
			elements.SUI_ClassIcon.position.anchor,
			elements.SUI_ClassIcon.position.x,
			elements.SUI_ClassIcon.position.y
		)

		-- Hots/Dots
		local Auras = CreateFrame('Frame', nil, frame)
		Auras:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 2)
		Auras:SetSize(frame:GetWidth(), 16)
		if UnitReaction(unit, 'player') <= 2 then
			if (SUI.DBMod.NamePlates.onlyShowPlayer and SUI.DBMod.NamePlates.showStealableBuffs) then
				Auras.showStealableBuffs = SUI.DBMod.NamePlates.showStealableBuffs
			else
				Auras.onlyShowPlayer = SUI.DBMod.NamePlates.onlyShowPlayer
				Auras.showStealableBuffs = SUI.DBMod.NamePlates.showStealableBuffs
			end
		else
			Auras.onlyShowPlayer = SUI.DBMod.NamePlates.onlyShowPlayer
		end

		frame.Auras = Auras

		-- Raid Icon
		if SUI.DBMod.NamePlates.ShowRaidTargetIndicator then
			frame.RaidTargetIndicator = frame:CreateTexture(nil, 'OVERLAY')
			frame.RaidTargetIndicator:SetSize(15, 15)
			frame.RaidTargetIndicator:SetPoint('BOTTOM', frame.Health, 'TOPLEFT', 0, 0)
		end

		-- Target Indicator
		local TargetIndicator = CreateFrame('Frame', 'BACKGROUND', frame)
		TargetIndicator.bg1 = frame:CreateTexture(nil, 'BACKGROUND', TargetIndicator)
		TargetIndicator.bg2 = frame:CreateTexture(nil, 'BACKGROUND', TargetIndicator)
		TargetIndicator.bg1:SetTexture('Interface\\AddOns\\SpartanUI_Artwork\\Images\\DoubleArrow')
		TargetIndicator.bg2:SetTexture('Interface\\AddOns\\SpartanUI_Artwork\\Images\\DoubleArrow')
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
		frame.QuestIndicator = QuestIndicator

		-- Rare Elite indicator
		local RareElite = frame:CreateTexture(nil, 'OVERLAY', nil, -2)
		RareElite:SetTexture('Interface\\Addons\\SpartanUI_Artwork\\Images\\status-glow')
		RareElite:SetAlpha(.6)
		RareElite:SetAllPoints(frame)
		frame.RareElite = RareElite

		-- frame PvPIndicator
		frame.PvPIndicator = frame:CreateTexture(nil, 'BORDER', frame)
		frame.PvPIndicator:SetSize(1, 1)
		frame.PvPIndicator:SetPoint('BOTTOMLEFT')
		frame.PvPIndicator.Override = pvpIconWar

		-- Threat Display
		local ThreatIndicator = frame:CreateTexture(nil, 'OVERLAY')
		ThreatIndicator:SetTexture('Interface\\AddOns\\SpartanUI_Style_Transparent\\Images\\square')
		ThreatIndicator:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375)
		ThreatIndicator:SetPoint('TOPLEFT', frame, 'TOPLEFT', -2, 2)
		ThreatIndicator:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 2, -2)
		ThreatIndicator.feedbackUnit = 'PLAYER'
		frame.ThreatIndicator = ThreatIndicator

		-- Setup Player Icons
		if SUI.DBMod.NamePlates.ShowPlayerPowerIcons then
			local attachPoint = 'Castbar'
			if not elements.Castbar.enabled then
				if elements.Power.enabled then
					attachPoint = 'Power'
				else
					attachPoint = 'Health'
				end
			end

			SUI:PlayerPowerIcons(frame, attachPoint)
		end

		-- Setup Scale
		frame:SetScale(SUI.DBMod.NamePlates.Scale)
	end
end

local NameplateCallback = function(self, event, unit)
	if not self or not unit or event == 'NAME_PLATE_UNIT_REMOVED' then
		return
	end
	if event == 'NAME_PLATE_UNIT_ADDED' then
		NameplateList[self:GetName()] = true
	elseif event == 'NAME_PLATE_UNIT_REMOVED' then
		NameplateList[self:GetName()] = false
	end

	-- Update target Indicator
	if UnitIsUnit(unit, 'target') and SUI.DBMod.NamePlates.ShowTarget then
		-- the frame is the new target
		self.TargetIndicator.bg1:Show()
		self.TargetIndicator.bg2:Show()
	elseif self.TargetIndicator.bg1:IsShown() then
		self.TargetIndicator.bg1:Hide()
		self.TargetIndicator.bg2:Hide()
	end
	if SUI.DBMod.NamePlates.elements.RareElite.enabled then
		self:EnableElement('RareElite')
	else
		self:DisableElement('RareElite')
	end
	if SUI.DBMod.NamePlates.elements.QuestIndicator.enabled then
		self:EnableElement('QuestIndicator')
	else
		self:DisableElement('QuestIndicator')
	end

	-- Update class icons
	local VisibleOn = SUI.DBMod.NamePlates.elements.SUI_ClassIcon.visibleOn
	local reaction = UnitReaction(unit, 'player')

	if
		((reaction <= 2 and (VisibleOn == 'all' or VisibleOn == 'hostile')) or
			(reaction >= 3 and (visibleOn == 'all' or VisibleOn == 'friendly'))) and
			SUI.DBMod.NamePlates.elements.SUI_ClassIcon.enabled
	 then
		self:EnableElement('SUI_ClassIcon')
	else
		self:DisableElement('SUI_ClassIcon')
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
	self:SetScale(SUI.DBMod.NamePlates.Scale)
end

function module:UpdateNameplates()
	for k, v in pairs(NameplateList) do
		if v then
			_G[k].PvPIndicator.Override(_G[k], nil, _G[k].unit)

			if SUI.DBMod.NamePlates.elements.SUI_ClassIcon.enabled then
				_G[k]:DisableElement('SUI_ClassIcon')
			else
				_G[k]:EnableElement('SUI_ClassIcon')
			end
		end
	end
end

function module:OnInitialize()
	SUIUF:RegisterStyle('Spartan_NamePlates', NamePlateFactory)
end

function module:OnDisable()
	SUI.opt.args['ModSetting'].args['Nameplates'].enabled = false
end

function module:OnEnable()
	if not SUI.DB.EnabledComponents.Nameplates then
		return
	end
	module:BuildOptions()
	SUIUF:SetActiveStyle('Spartan_NamePlates')
	SUIUF:SpawnNamePlates(nil, NameplateCallback)

	-- SUF is not hiding the mana bar. So we need to hide it.
	if ClassNameplateManaBarFrame then
		ClassNameplateManaBarFrame:HookScript(
			'OnShow',
			function()
				ClassNameplateManaBarFrame:Hide()
			end
		)
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

	SUI.opt.args['ModSetting'].args['Nameplates'] = {
		type = 'group',
		name = L['Nameplates'],
		childGroups = 'tab',
		args = {
			Scale = {
				name = 'Scale',
				type = 'range',
				width = 'full',
				min = .01,
				max = 3,
				step = .01,
				order = 1,
				get = function(info)
					return SUI.DBMod.NamePlates.Scale
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.Scale = val
				end
			},
			General = {
				name = 'General Apperance',
				type = 'group',
				order = 10,
				childGroups = 'tree',
				args = {
					Background = {
						name = 'Background',
						type = 'group',
						order = 1,
						args = {
							Enabled = {
								name = 'Enabled',
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Background.enabled
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Background.enabled = val
									module:UpdateNameplates()
								end
							},
							bgtype = {
								name = 'Type',
								order = 2,
								type = 'select',
								values = {['artwork'] = 'Artwork', ['solid'] = 'Solid'},
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Background.type
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Background.type = val
									module:UpdateNameplates()
								end
							},
							colorMode = {
								name = 'Color mode',
								type = 'select',
								order = 3,
								values = {
									['faction'] = 'Faction',
									['reaction'] = 'Reaction'
								},
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Background.colorMode
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Background.colorMode = val
									module:UpdateNameplates()
								end
							},
							alpha = {
								name = 'Alpha',
								type = 'range',
								width = 'full',
								order = 4,
								min = 0,
								max = 1,
								step = .01,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Background.alpha
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Background.alpha = val
									module:UpdateNameplates()
								end
							}
						}
					},
					HealthBar = {
						name = L['Health bar'],
						type = 'group',
						-- inline = true,
						order = 3,
						args = {
							height = {
								name = L['Height'],
								type = 'range',
								width = 'full',
								min = 1,
								max = 30,
								step = 1,
								order = 10,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Health.height
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Health.height = val
								end
							},
							colorTapping = {
								name = L['Grey out tapped targets'],
								type = 'toggle',
								width = 'full',
								order = 20,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Health.colorTapping
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Health.colorTapping = val
								end
							},
							colorReaction = {
								name = L['Color based on reaction'],
								type = 'toggle',
								width = 'full',
								order = 30,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Health.colorReaction
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Health.colorReaction = val
								end
							},
							colorClass = {
								name = L['Color based on class'],
								type = 'toggle',
								width = 'full',
								order = 40,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Health.colorClass
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Health.colorClass = val
								end
							}
						}
					},
					PowerBar = {
						name = L['Power bar'],
						type = 'group',
						-- inline = true,
						order = 4,
						args = {
							show = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Power.enabled
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Power.enabled = val
								end
							},
							height = {
								name = L['Height'],
								type = 'range',
								width = 'full',
								min = 1,
								max = 15,
								step = 1,
								order = 10,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Power.height
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Power.height = val
								end
							}
						}
					},
					CastBar = {
						name = L['Cast bar'],
						type = 'group',
						-- inline = true,
						order = 5,
						args = {
							show = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Castbar.enabled
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Castbar.enabled = val
								end
							},
							Height = {
								name = L['Height'],
								type = 'range',
								width = 'full',
								min = 1,
								max = 15,
								step = 1,
								order = 10,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Castbar.height
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Castbar.height = val
								end
							},
							Text = {
								name = L['Show text'],
								type = 'toggle',
								width = 'full',
								order = 20,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Castbar.text
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Castbar.text = val
								end
							},
							FlashOnInterruptible = {
								name = L['Flash on interruptible cast'],
								type = 'toggle',
								width = 'full',
								order = 30,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Castbar.FlashOnInterruptible
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.Castbar.FlashOnInterruptible = val
								end
							}
						}
					}
				}
			},
			Indicator = {
				name = 'Indicators',
				type = 'group',
				order = 20,
				childGroups = 'tree',
				args = {
					Name = {
						name = 'Name',
						type = 'group',
						order = 1,
						args = {
							ShowLevel = {
								name = L['Show level'],
								type = 'toggle',
								order = 1,
								get = function(info)
									return SUI.DBMod.NamePlates.ShowLevel
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.ShowLevel = val
								end
							},
							ShowName = {
								name = L['Show name'],
								type = 'toggle',
								order = 2,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Name.enabled
								end,
								set = function(info, val)
									--Update the DB
									SUI.DBMod.NamePlates.elements.Name.enabled = val
								end
							},
							JustifyH = {
								name = 'Horizontal alignment',
								type = 'select',
								order = 3,
								values = {
									['LEFT'] = 'Left',
									['CENTER'] = 'Center',
									['RIGHT'] = 'Right'
								},
								get = function(info)
									return SUI.DBMod.NamePlates.elements.Name.SetJustifyH
								end,
								set = function(info, val)
									--Update the DB
									SUI.DBMod.NamePlates.elements.Name.SetJustifyH = val
									--Update the screen
									-- module.frames[frameName][key]:SetJustifyH(val)
								end
							}
						}
					},
					QuestIndicator = {
						name = 'Quest icon',
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.QuestIndicator.enabled
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.QuestIndicator.enabled = val
								end
							}
						}
					},
					RareElite = {
						name = 'Rare/Elite background',
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.RareElite.enabled
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.RareElite.enabled = val
								end
							}
						}
					},
					TargetIndicator = {
						name = 'Target indicator',
						type = 'group',
						args = {
							enabled = {
								name = L['Enabled'],
								type = 'toggle',
								width = 'full',
								order = 1,
								get = function(info)
									return SUI.DBMod.NamePlates.ShowTarget
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.ShowTarget = val
								end
							}
						}
					},
					ClassIcon = {
						name = 'Class icon',
						type = 'group',
						args = {
							enabled = {
								name = 'Enabled',
								type = 'toggle',
								width = 'double',
								order = 1,
								get = function(info)
									return SUI.DBMod.NamePlates.elements.SUI_ClassIcon.enabled
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.SUI_ClassIcon.enabled = val
									module:UpdateNameplates()
								end
							},
							visibleOn = {
								name = 'Show on',
								type = 'select',
								order = 2,
								values = {
									['friendly'] = 'Friendly',
									['hostile'] = 'Hostile',
									['all'] = 'All'
								},
								get = function(info)
									return SUI.DBMod.NamePlates.elements.SUI_ClassIcon.visibleOn
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.elements.SUI_ClassIcon.visibleOn = val
									module:UpdateNameplates()
								end
							},
							position = {
								name = 'Position',
								type = 'group',
								order = 50,
								inline = true,
								args = {
									x = {
										name = 'X Axis',
										type = 'range',
										order = 1,
										min = -100,
										max = 100,
										step = 1,
										get = function(info)
											return SUI.DBMod.NamePlates.elements.SUI_ClassIcon.position.x
										end,
										set = function(info, val)
											--Update the DB
											SUI.DBMod.NamePlates.elements.SUI_ClassIcon.position.x = val
										end
									},
									y = {
										name = 'Y Axis',
										type = 'range',
										order = 2,
										min = -100,
										max = 100,
										step = 1,
										get = function(info)
											return SUI.DBMod.NamePlates.elements.SUI_ClassIcon.position.y
										end,
										set = function(info, val)
											--Update the DB
											SUI.DBMod.NamePlates.elements.SUI_ClassIcon.position.y = val
										end
									},
									anchor = {
										name = 'Anchor point',
										type = 'select',
										order = 3,
										values = anchorPoints,
										get = function(info)
											return SUI.DBMod.NamePlates.elements.SUI_ClassIcon.position.anchor
										end,
										set = function(info, val)
											--Update the DB
											SUI.DBMod.NamePlates.elements.SUI_ClassIcon.position = val
										end
									}
								}
							}
						}
					},
					Auras = {
						name = 'Auras',
						type = 'group',
						args = {
							onlyShowPlayer = {
								name = 'Show only auras created by player',
								type = 'toggle',
								order = 1,
								width = 'double',
								get = function(info)
									return SUI.DBMod.NamePlates.onlyShowPlayer
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.onlyShowPlayer = val
									module:UpdateNameplates()
								end
							},
							showStealableBuffs = {
								name = 'Show Stealable/Dispellable buffs',
								type = 'toggle',
								order = 2,
								width = 'double',
								get = function(info)
									return SUI.DBMod.NamePlates.showStealableBuffs
								end,
								set = function(info, val)
									SUI.DBMod.NamePlates.showStealableBuffs = val
									module:UpdateNameplates()
								end
							},
							notice = {
								name = 'With both of these options active your DOTs will not appear on enemies.',
								type = 'description',
								order = 3,
								fontSize = 'small'
							}
						}
					}
				}
			}
		}
	}
end
