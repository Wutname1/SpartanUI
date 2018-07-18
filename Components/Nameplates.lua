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
		health:SetStatusBarTexture('Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga')
		-- health.colorHealth = true
		health.colorTapping = true
		health.colorReaction = true
		frame.Health = health

		frame.bgHealth = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.bgHealth:SetAllPoints()
		frame.bgHealth:SetTexture('Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga')
		frame.bgHealth:SetVertexColor(0, 0, 0, .5)

		-- Name
		frame.Name = health:CreateFontString()
		SUI:FormatFont(frame.Name, 10, 'Player')
		frame.Name:SetSize(frame:GetWidth(), 12)
		frame.Name:SetJustifyH('LEFT')
		frame.Name:SetPoint('BOTTOMLEFT', frame.Health, 'TOPLEFT', 0, 0)
		frame:Tag(frame.Name, '[difficulty][level] [SUI_ColorClass][name]')

		-- Hots/Dots
		local Auras = CreateFrame('Frame', nil, frame)
		Auras:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 2)
		Auras:SetSize(frame:GetWidth(), 16)
		Auras.onlyShowPlayer = true
		frame.Auras = Auras

		-- frame background
		frame.artwork = CreateFrame('Frame', 'BACKGROUND', frame)
		frame.artwork:SetAllPoints()

		frame.artwork.bgNeutral = frame:CreateTexture(nil, 'BACKGROUND', frame)
		frame.artwork.bgNeutral:SetAllPoints()
		frame.artwork.bgNeutral:SetTexture('Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga')
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
	if SUI.DBMod.NamePlates == nil then
		SUI.DBMod.NamePlates = {
			showThreat = true,
			FlashOnInterruptibleCast = true
		}
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
			ad = {
				name = '-Show/Hide name',
				type = 'description',
				order = 405,
				fontSize = 'small'
			},
			ae = {
				name = '-Show/Hide level',
				type = 'description',
				order = 406,
				fontSize = 'small'
			},
			af = {
				name = '-Target indicator',
				type = 'description',
				order = 406,
				fontSize = 'small'
			}
		}
	}
end
