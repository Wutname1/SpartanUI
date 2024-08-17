local UF = SUI.UF
local L = SUI.L
-- local AuraFilter = UF.AuraFilter

-- function UF:AuraBars_UpdateBar(bar)
-- 	local bars = bar:GetParent()
-- 	bar.db = bars.db

-- 	bar:SetReverseFill(bars.reverseFill)
-- 	bar.spark:ClearAllPoints()
-- 	bar.spark:Point(bars.reverseFill and 'LEFT' or 'RIGHT', bar:GetStatusBarTexture())
-- 	bar.spark:Point('BOTTOM')
-- 	bar.spark:Point('TOP')

-- 	AuraBars.spellTimeFont = SUI.Font:GetFontFace('Player')
-- 	AuraBars.spellNameFont = SUI.Font:GetFontFace('Player')
-- 	UF:Update_FontString(bar.timeText)
-- 	UF:Update_FontString(bar.nameText)
-- end

---@param frame table
---@param DB table
local function Build(frame, DB)
	local element = CreateFrame('Frame', '$parent_AuraBars', frame)

	element.spellTimeFont = SUI.Font:GetFont('Player')
	element.spellNameFont = SUI.Font:GetFont('Player')
	element.PostCreateButton = function(self, button)
		UF.Auras:PostCreateButton('Buffs', button)
	end

	---@param unit UnitId
	---@param data UnitAuraInfo
	local FilterAura = function(element, unit, data)
		return UF.Auras:Filter(element, unit, data, element.DB.rules)
	end
	element.FilterAura = FilterAura

	local function PostCreateBar(_, bar)
		bar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))

		bar.spark:SetTexture(UF:FindStatusBarTexture(DB.texture))
		bar.spark:SetVertexColor(1, 1, 1, 0.4)
		bar.spark:SetSize(2, DB.size)

		bar.bg = bar:CreateTexture(nil, 'BORDER')
		bar.bg:SetAllPoints(bar)
		bar.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
		bar.bg:SetVertexColor(0, 0, 0, 0.4)
		bar.bg:Show()
	end
	element.PostCreateBar = PostCreateBar

	---@param element any
	---@param unit any
	---@param bar any
	---@param auraData AuraData
	element.CustomFilter = function(element, unit, bar, auraData)
		if (auraData.sourceUnit == 'player' or auraData.sourceUnit == 'vehicle' or auraData.isBossAura) and auraData.duration ~= 0 and auraData.duration <= 900 then return true end
	end

	element.displayReasons = {}
	element.initialAnchor = 'BOTTOMRIGHT'

	frame.AuraBars = element
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.AuraBars
	if not frame.AuraBars then return end
	local DB = settings or element.DB

	if DB.enabled then
		element:Show()
	else
		element:Hide()
	end

	element.anchoredBars = DB.anchoredBars or 0
	element.width = (DB.width or frame:GetWidth()) - DB.size
	element.size = DB.size or 14
	element.sparkEnabled = DB.sparkEnabled or true
	element.spacing = DB.spacing or 2
	element.initialAnchor = DB.initialAnchor or 'BOTTOMLEFT'
	element.growth = DB.growth or 'UP'
	element.maxBars = DB.maxBars or 32
	element.barSpacing = DB.barSpacing or 2
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local ElementSettings = UF.CurrentSettings[unitName].elements.AuraBars
	local function OptUpdate(option, val)
		UF.CurrentSettings[unitName].elements.AuraBars[option] = val
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.AuraBars[option] = val
		UF.Unit[unitName]:ElementUpdate('AuraBars')
	end

	OptionSet.args.Layout = {
		name = L['Layout'],
		type = 'group',
		order = 100,
		inline = true,
		args = {
			growth = {
				name = L['Growth Direction'],
				desc = L['Choose the direction in which aura bars grow'],
				type = 'select',
				order = 1,
				values = {
					UP = L['Up'],
					DOWN = L['Down'],
				},
				get = function()
					return ElementSettings.growth
				end,
				set = function(_, val)
					OptUpdate('growth', val)
				end,
			},
			maxBars = {
				name = L['Maximum Bars'],
				desc = L['Set the maximum number of aura bars to display'],
				type = 'range',
				order = 2,
				min = 1,
				max = 40,
				step = 1,
				get = function()
					return ElementSettings.maxBars
				end,
				set = function(_, val)
					OptUpdate('maxBars', val)
				end,
			},
			barSpacing = {
				name = L['Bar Spacing'],
				desc = L['Set the space between aura bars'],
				type = 'range',
				order = 3,
				min = 0,
				max = 20,
				step = 1,
				get = function()
					return ElementSettings.barSpacing
				end,
				set = function(_, val)
					OptUpdate('barSpacing', val)
				end,
			},
		},
	}

	OptionSet.args.Appearance = {
		name = L['Appearance'],
		type = 'group',
		order = 200,
		inline = true,
		args = {
			fgalpha = {
				name = L['Foreground Alpha'],
				desc = L['Set the opacity of the aura bar foreground'],
				type = 'range',
				order = 1,
				min = 0,
				max = 1,
				step = 0.01,
				get = function()
					return ElementSettings.fgalpha
				end,
				set = function(_, val)
					OptUpdate('fgalpha', val)
				end,
			},
			bgalpha = {
				name = L['Background Alpha'],
				desc = L['Set the opacity of the aura bar background'],
				type = 'range',
				order = 2,
				min = 0,
				max = 1,
				step = 0.01,
				get = function()
					return ElementSettings.bgalpha
				end,
				set = function(_, val)
					OptUpdate('bgalpha', val)
				end,
			},
			spellNameSize = {
				name = L['Spell Name Font Size'],
				desc = L['Set the font size for spell names on aura bars'],
				type = 'range',
				order = 3,
				min = 6,
				max = 20,
				step = 1,
				get = function()
					return ElementSettings.spellNameSize
				end,
				set = function(_, val)
					OptUpdate('spellNameSize', val)
				end,
			},
			spellTimeSize = {
				name = L['Spell Time Font Size'],
				desc = L['Set the font size for spell durations on aura bars'],
				type = 'range',
				order = 4,
				min = 6,
				max = 20,
				step = 1,
				get = function()
					return ElementSettings.spellTimeSize
				end,
				set = function(_, val)
					OptUpdate('spellTimeSize', val)
				end,
			},
		},
	}
end

---@type SUI.UF.Elements.Settings
local Settings = {
	size = 14,
	width = false,
	sparkEnabled = true,
	spacing = 2,
	initialAnchor = 'BOTTOMLEFT',
	growth = 'UP',
	maxBars = 32,
	fgalpha = 1,
	bgalpha = 1,
	spellNameSize = 10,
	spellTimeSize = 10,
	gap = 1,
	scaleTime = false,
	icon = true,
	position = {
		anchor = 'BOTTOMLEFT',
		relativePoint = 'TOPLEFT',
		x = 7,
		y = 20,
	},
	rules = {
		showPlayers = true,
	},
	config = {
		type = 'Auras',
		DisplayName = 'Aura Bars',
	},
}

UF.Elements:Register('AuraBars', Build, Update, Options, Settings)
