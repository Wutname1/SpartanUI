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

local pvpIconWar = function(self, event, unit)
	if (unit ~= self.unit) then
		return
	end
	self.artwork.bgHorde:Hide()
	self.artwork.bgAlliance:Hide()
	self.artwork.bgNeutral:Hide()

	local factionGroup = UnitFactionGroup(unit)

	if (factionGroup and factionGroup ~= 'Neutral') then
		self.artwork['bg' .. factionGroup]:Show()
		if UnitIsPVP(unit) then
			self.artwork['bg' .. factionGroup]:SetAlpha(.7)
		else
			self.artwork['bg' .. factionGroup]:SetAlpha(.35)
		end
	else
		self.artwork.bgNeutral:Show()
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
	if self.notInterruptible == false and SUI.DBMod.NamePlates.Castbar.FlashOnInterruptible and UnitIsEnemy('player', unit) then
		_G[self.PName].Castbar:SetStatusBarColor(0, 0, 0)
		module:ScheduleTimer('Flash', .1, _G[self.PName])
	else
		_G[self.PName].Castbar:SetStatusBarColor(1, 0.7, 0)
	end
end

local PostCastStop = function(self)
	if SUI.DBMod.NamePlates.Castbar.FlashOnInterruptible then
		module:CancelTimer(Timers[self:GetName()])
	end
end

local NamePlateFactory = function(frame, unit)
	if unit:match('nameplate') then
		frame:SetSize(128, 16)
		frame:SetPoint('CENTER', 0, 0)

		-- health bar
		local health = CreateFrame('StatusBar', nil, frame)
		health:SetPoint('BOTTOM')
		health:SetSize(frame:GetWidth(), SUI.DBMod.NamePlates.Health.height)
		health:SetStatusBarTexture(BarTexture)
		-- health.colorHealth = true
		health.frequentUpdates = true
		health.colorTapping = SUI.DBMod.NamePlates.Health.colorTapping
		health.colorReaction = SUI.DBMod.NamePlates.Health.colorReaction
		health.colorClass = SUI.DBMod.NamePlates.Health.colorClass
		frame.Health = health

		frame.bgHealth = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.bgHealth:SetAllPoints()
		frame.bgHealth:SetTexture(BarTexture)
		frame.bgHealth:SetVertexColor(0, 0, 0, .5)

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
			frame.Name:SetJustifyH('LEFT')
			frame.Name:SetPoint('BOTTOMLEFT', frame.Health, 'TOPLEFT', 0, 0)
			frame:Tag(frame.Name, nameString)
		end

		-- Mana/Energy
		if SUI.DBMod.NamePlates.Power.show then
			local power = CreateFrame('StatusBar', nil, frame)
			power:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
			power:SetSize(frame:GetWidth(), SUI.DBMod.NamePlates.Power.height)
			power:SetStatusBarTexture(BarTexture)

			frame.Power = power
			frame.Power.colorPower = true
			frame.Power.frequentUpdates = true
		end

		-- Castbar
		if SUI.DBMod.NamePlates.Castbar.show then
			local cast = CreateFrame('StatusBar', nil, frame)
			if SUI.DBMod.NamePlates.Power.show then
				cast:SetPoint('TOP', frame.Power, 'BOTTOM', 0, 0)
			else
				cast:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
			end

			cast:SetSize(frame:GetWidth(), SUI.DBMod.NamePlates.Castbar.height)
			cast:SetStatusBarTexture(BarTexture)
			cast:SetStatusBarColor(1, 0.7, 0)
			if SUI.DBMod.NamePlates.Castbar.text then
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

		-- Hots/Dots
		local Auras = CreateFrame('Frame', nil, frame)
		Auras:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 2)
		Auras:SetSize(frame:GetWidth(), 16)
		Auras.onlyShowPlayer = true
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

		-- frame background
		frame.artwork = CreateFrame('Frame', 'BACKGROUND', frame)
		frame.artwork:SetAllPoints()

		frame.artwork.bgNeutral = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.artwork.bgNeutral:SetAllPoints()
		frame.artwork.bgNeutral:SetTexture(BarTexture)
		frame.artwork.bgNeutral:SetVertexColor(0, 0, 0, .6)

		frame.artwork.bgAlliance = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.artwork.bgAlliance:SetAllPoints()
		frame.artwork.bgAlliance:SetTexture(Images.Alliance.bg.Texture)
		frame.artwork.bgAlliance:SetTexCoord(unpack(Images.Alliance.bg.Coords))
		frame.artwork.bgAlliance:SetSize(frame:GetSize())

		frame.artwork.bgHorde = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.artwork.bgHorde:SetAllPoints()
		frame.artwork.bgHorde:SetTexture(Images.Horde.bg.Texture)
		frame.artwork.bgHorde:SetTexCoord(unpack(Images.Horde.bg.Coords))
		frame.artwork.bgHorde:SetSize(frame:GetSize())

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
			if not SUI.DBMod.NamePlates.Castbar.show then
				if SUI.DBMod.NamePlates.Power.show then
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
	if not self or not unit then
		return
	end
	-- Update target Indicator
	if UnitIsUnit(unit, 'target') and SUI.DBMod.NamePlates.ShowTarget then
		-- the frame is the new target
		self.TargetIndicator.bg1:Show()
		self.TargetIndicator.bg2:Show()
	end
	if SUI.DBMod.NamePlates.ShowRareElite then
		self:EnableElement('RareElite')
	else
		self:DisableElement('RareElite')
	end
	if SUI.DBMod.NamePlates.ShowQuestIndicator then
		self:EnableElement('QuestIndicator')
	else
		self:DisableElement('QuestIndicator')
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

function module:OnInitialize()
	local Defaults = {
		ShowThreat = true,
		ShowName = true,
		ShowLevel = true,
		ShowTarget = true,
		ShowRareElite = true,
		ShowQuestIndicator = true,
		ShowRaidTargetIndicator = true,
		Scale = 1,
		Health = {
			height = 5,
			colorTapping = true,
			colorReaction = true,
			colorClass = true
		},
		Power = {
			show = true,
			ShowPlayerPowerIcons = true,
			height = 3
		},
		Castbar = {
			show = true,
			height = 5,
			text = true,
			FlashOnInterruptible = true
		}
	}
	if not SUI.DBMod.NamePlates then
		SUI.DBMod.NamePlates = Defaults
	else
		SUI.DBMod.NamePlates = SUI:MergeData(SUI.DBMod.NamePlates, Defaults, false)
	end

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

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['Nameplates'] = {
		type = 'group',
		name = L['Nameplates'],
		args = {
			ShowName = {
				name = L['Show name'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DBMod.NamePlates.ShowName
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.ShowName = val
				end
			},
			ShowLevel = {
				name = L['Show level'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return SUI.DBMod.NamePlates.ShowLevel
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.ShowLevel = val
				end
			},
			ShowQuestIndicator = {
				name = L['Show quest indicator'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DBMod.NamePlates.ShowQuestIndicator
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.ShowQuestIndicator = val
				end
			},
			ShowRareElite = {
				name = L['Show rare/elite indicator'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DBMod.NamePlates.ShowRareElite
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.ShowRareElite = val
				end
			},
			ShowTarget = {
				name = L['Show target'],
				type = 'toggle',
				order = 4,
				get = function(info)
					return SUI.DBMod.NamePlates.ShowTarget
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.ShowTarget = val
				end
			},
			Scale = {
				name = L['Nameplate scale'],
				type = 'range',
				width = 'full',
				min = .01,
				max = 3,
				step = .01,
				order = 100,
				get = function(info)
					return SUI.DBMod.NamePlates.Scale
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.Scale = val
				end
			},
			HealthOptions = {
				name = L['Health bar'],
				type = 'group',
				inline = true,
				order = 200,
				args = {
					height = {
						name = L['Height'],
						type = 'range',
						min = 1,
						max = 30,
						step = 1,
						order = 10,
						get = function(info)
							return SUI.DBMod.NamePlates.Health.height
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Health.height = val
						end
					},
					colorTapping = {
						name = L['Grey out tapped targets'],
						type = 'toggle',
						order = 20,
						get = function(info)
							return SUI.DBMod.NamePlates.Health.colorTapping
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Health.colorTapping = val
						end
					},
					colorReaction = {
						name = L['Color based on reaction'],
						type = 'toggle',
						order = 30,
						get = function(info)
							return SUI.DBMod.NamePlates.Health.colorReaction
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Health.colorReaction = val
						end
					},
					colorClass = {
						name = L['Color based on class'],
						type = 'toggle',
						order = 40,
						get = function(info)
							return SUI.DBMod.NamePlates.Health.colorClass
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Health.colorClass = val
						end
					}
				}
			},
			PowerOptions = {
				name = L['Power bar'],
				type = 'group',
				inline = true,
				order = 300,
				args = {
					show = {
						name = L['Enabled'],
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DBMod.NamePlates.Power.show
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Power.show = val
						end
					},
					height = {
						name = L['Height'],
						type = 'range',
						min = 1,
						max = 15,
						step = 1,
						order = 10,
						get = function(info)
							return SUI.DBMod.NamePlates.Power.height
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Power.height = val
						end
					}
				}
			},
			CastOptions = {
				name = L['Cast bar'],
				type = 'group',
				inline = true,
				order = 400,
				args = {
					show = {
						name = L['Enabled'],
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DBMod.NamePlates.Castbar.show
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Castbar.show = val
						end
					},
					Height = {
						name = L['Height'],
						type = 'range',
						min = 1,
						max = 15,
						step = 1,
						order = 10,
						get = function(info)
							return SUI.DBMod.NamePlates.Castbar.height
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Castbar.height = val
						end
					},
					Text = {
						name = L['Show text'],
						type = 'toggle',
						order = 20,
						get = function(info)
							return SUI.DBMod.NamePlates.Castbar.text
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Castbar.text = val
						end
					},
					FlashOnInterruptible = {
						name = L['Flash on interruptible cast'],
						type = 'toggle',
						order = 30,
						get = function(info)
							return SUI.DBMod.NamePlates.Castbar.FlashOnInterruptible
						end,
						set = function(info, val)
							SUI.DBMod.NamePlates.Castbar.FlashOnInterruptible = val
						end
					}
				}
			}
		}
	}
end
