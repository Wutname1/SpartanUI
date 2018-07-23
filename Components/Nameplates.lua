local unpack, SUI, L = unpack, SUI, SUI.L
local module = SUI:NewModule('Component_Nameplates')
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

local NamePlateFactory = function(frame, unit)
	if unit:match('nameplate') then
		frame:SetSize(128, 16)
		frame:SetPoint('CENTER', 0, 0)

		-- health bar
		local health = CreateFrame('StatusBar', nil, frame)
		health:SetPoint('BOTTOM')
		health:SetSize(frame:GetWidth(), 5)
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
			frame.Name = health:CreateFontString()
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
			cast:SetSize(frame:GetWidth(), 4)
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

			frame.Castbar = cast
		end

		-- Hots/Dots
		local Auras = CreateFrame('Frame', nil, frame)
		Auras:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 2)
		Auras:SetSize(frame:GetWidth(), 16)
		Auras.onlyShowPlayer = true
		frame.Auras = Auras

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
		FlashOnInterruptibleCast = true
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
			desc0 = {
				name = 'Nameplates are a take it or leave it feature at the moment.',
				type = 'description',
				order = 200,
				fontSize = 'large'
			},
			desc1 = {
				name = 'This is a Preview build of them, rather than disabling them for the Pre-Patch builds i have left them on so you can start providing me feedback on what you would like to see added to them.',
				type = 'description',
				order = 200,
				fontSize = 'medium'
			},
			desc2 = {
				name = 'Nameplates will be finished in SpartanUI 5.0',
				type = 'description',
				order = 300,
				fontSize = 'medium'
			},
			desc3 = {
				name = 'Current plans are:',
				type = 'description',
				order = 400,
				fontSize = 'medium'
			},
			aa = {
				name = '-Flash on interuptable cast',
				type = 'description',
				order = 401,
				fontSize = 'small'
			},
			ab = {
				name = '-Threat glow',
				type = 'description',
				order = 402,
				fontSize = 'small'
			},
			ac = {
				name = '-Customizable size',
				type = 'description',
				order = 403,
				fontSize = 'small'
			},
			af = {
				name = '-Target indicator',
				type = 'description',
				order = 406,
				fontSize = 'small'
			},
			af = {
				name = '-And more! Full list on Github.',
				type = 'description',
				order = 407,
				fontSize = 'small'
			}
		}
	}
end
