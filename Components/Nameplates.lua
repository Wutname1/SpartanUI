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
	if self.notInterruptible == false and SUI.DBMod.NamePlates.FlashOnInterruptibleCast and UnitIsEnemy('player', unit) then
		_G[self.PName].Castbar:SetStatusBarColor(0, 0, 0)
		module:ScheduleTimer('Flash', .1, _G[self.PName])
	else
		_G[self.PName].Castbar:SetStatusBarColor(1, 0.7, 0)
	end
end

local PostCastStop = function(self)
	if SUI.DBMod.NamePlates.FlashOnInterruptibleCast then
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
		health.colorTapping = true
		health.colorReaction = true
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

		-- Castbar
		if SUI.DBMod.NamePlates.ShowCastbar then
			local cast = CreateFrame('StatusBar', nil, frame)
			cast:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
			cast:SetSize(frame:GetWidth(), SUI.DBMod.NamePlates.Castbar.height)
			cast:SetStatusBarTexture(BarTexture)
			cast:SetStatusBarColor(1, 0.7, 0)
			if SUI.DBMod.NamePlates.ShowCastbarText then
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
		ThreatIndicator:SetTexture('Interface\\RaidFrame\\Raid-FrameHighlights')
		ThreatIndicator:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750)
		ThreatIndicator:SetAllPoints(frame)
		-- overlay:SetVertexColor(1, 0, 0)
		-- overlay:Hide()
		-- frame.ThreatIndicatorOverlay = overlay
		frame.ThreatIndicator = ThreatIndicator

		-- Things to do if this is the players display
		if (UnitIsUnit(unit, 'player')) then
			local attachPoint = 'Castbar'
			if not SUI.DBMod.NamePlates.ShowCastbar then
				attachPoint = 'Health'
			end
			-- Setup Player Icons
			if SUI.DBMod.NamePlates.ShowPlayerPowerIcons then
				SUI:PlayerPowerIcons(frame, attachPoint)
			end
		end

		-- Setup Scale
		frame:SetScale(SUI.DBMod.NamePlates.Scale)
	end
end

function module:OnInitialize()
	local Defaults = {
		ShowThreat = true,
		ShowName = true,
		ShowLevel = true,
		ShowCastbar = true,
		ShowCastbarText = true,
		ShowTarget = true,
		ShowRaidTargetIndicator = true,
		ShowPlayerPowerIcons = true,
		FlashOnInterruptibleCast = true,
		Scale = 1,
		Health = {
			height = 5
		},
		Castbar = {
			height = 5
		}
	}
	if not SUI.DBMod.NamePlates then
		SUI.DBMod.NamePlates = Defaults
	else
		SUI.DBMod.NamePlates = SUI:MergeData(SUI.DBMod.NamePlates, Defaults, false)
	end

	SpartanoUF:RegisterStyle('Spartan_NamePlates', NamePlateFactory)
end

function module:OnDisable()
	SUI.opt.args['ModSetting'].args['Nameplates'].enabled = false
end

function module:OnEnable()
	if not SUI.DB.EnabledComponents.Nameplates then
		return
	end
	module:BuildOptions()
	SpartanoUF:SetActiveStyle('Spartan_NamePlates')
	SpartanoUF:SpawnNamePlates()
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
			ShowCastbar = {
				name = L['Show castbar'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DBMod.NamePlates.ShowCastbar
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.ShowCastbar = val
				end
			},
			ShowCastbarText = {
				name = L['Show castbar text'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DBMod.NamePlates.ShowCastbarText
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.ShowCastbarText = val
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
			FlashOnInterruptibleCast = {
				name = L['Flash on interruptible cast'],
				type = 'toggle',
				order = 5,
				get = function(info)
					return SUI.DBMod.NamePlates.FlashOnInterruptibleCast
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.FlashOnInterruptibleCast = val
				end
			},
			Scale = {
				name = L['Nameplate scale'],
				type = 'range',
				min = -20,
				max = 20,
				step = 1,
				order = 100,
				get = function(info)
					return SUI.DBMod.NamePlates.Scale
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.Scale = val
				end
			},
			HealthbarHeight = {
				name = L['Health bar height'],
				type = 'range',
				min = 1,
				max = 30,
				step = 1,
				order = 101,
				get = function(info)
					return SUI.DBMod.NamePlates.Health.height
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.Health.height = val
				end
			},
			CastbarHeight = {
				name = L['Cast bar height'],
				type = 'range',
				min = 1,
				max = 20,
				step = 1,
				order = 102,
				get = function(info)
					return SUI.DBMod.NamePlates.Castbar.height
				end,
				set = function(info, val)
					SUI.DBMod.NamePlates.Castbar.height = val
				end
			}
		}
	}
end
