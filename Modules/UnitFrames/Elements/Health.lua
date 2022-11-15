local UF, L = SUI.UF, SUI.L

---@param frame table
---@param DB table
local function Build(frame, DB)
	local health = CreateFrame('StatusBar', nil, frame)
	health:SetFrameStrata(DB.FrameStrata or frame:GetFrameStrata())
	health:SetFrameLevel(DB.FrameLevel or 2)
	health:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	health:SetSize(DB.width or frame:GetWidth(), DB.height or 20)

	local bg = health:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(health)
	bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
	bg:SetVertexColor(unpack(DB.bg.color))
	health.bg = bg

	health:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, DB.offset or -1)
	health:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, DB.offset or -1)

	health.TextElements = {}
	for i, key in pairs(DB.text) do
		local NewString = health:CreateFontString(nil, 'OVERLAY')
		SUI.Font:Format(NewString, key.size, 'UnitFrames')
		NewString:SetJustifyH(key.SetJustifyH)
		NewString:SetJustifyV(key.SetJustifyV)
		NewString:SetPoint(key.position.anchor, health, key.position.anchor, key.position.x, key.position.y)
		frame:Tag(NewString, key.text)

		health.TextElements[i] = NewString
		if not key.enabled then
			health.TextElements[i]:Hide()
		end
	end

	frame.Health = health

	frame.Health.frequentUpdates = true
	frame.Health.colorDisconnected = DB.colorDisconnected or true
	frame.Health.colorTapping = DB.colorTapping or true
	frame.Health.colorReaction = DB.colorReaction or true
	frame.Health.colorSmooth = DB.colorSmooth or true
	frame.Health.colorClass = DB.colorClass or false

	frame.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
	frame.Health.colorHealth = true

	frame.Health.DataTable = DB.text

	if SUI.IsRetail then
		-- Position and size
		local myBar = CreateFrame('StatusBar', nil, frame.Health)
		myBar:SetPoint('TOP')
		myBar:SetPoint('BOTTOM')
		myBar:SetPoint('LEFT', frame.Health:GetStatusBarTexture(), 'RIGHT')
		myBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		myBar:SetStatusBarColor(0, 1, 0.5, 0.45)
		myBar:SetSize(150, 16)
		myBar:Hide()

		local otherBar = CreateFrame('StatusBar', nil, myBar)
		otherBar:SetPoint('TOP')
		otherBar:SetPoint('BOTTOM')
		otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
		otherBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		otherBar:SetStatusBarColor(0, 0.5, 1, 0.35)
		otherBar:SetSize(150, 16)
		otherBar:Hide()

		local absorbBar = CreateFrame('StatusBar', nil, frame.Health)
		absorbBar:SetPoint('TOP')
		absorbBar:SetPoint('BOTTOM')
		absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
		absorbBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		absorbBar:SetWidth(10)
		absorbBar:Hide()

		local healAbsorbBar = CreateFrame('StatusBar', nil, frame.Health)
		healAbsorbBar:SetPoint('TOP')
		healAbsorbBar:SetPoint('BOTTOM')
		healAbsorbBar:SetPoint('RIGHT', frame.Health:GetStatusBarTexture())
		healAbsorbBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		healAbsorbBar:SetReverseFill(true)
		healAbsorbBar:SetWidth(10)
		healAbsorbBar:Hide()

		local overAbsorb = frame.Health:CreateTexture(nil, 'OVERLAY')
		overAbsorb:SetPoint('TOP')
		overAbsorb:SetPoint('BOTTOM')
		overAbsorb:SetPoint('LEFT', frame.Health, 'RIGHT')
		overAbsorb:SetWidth(10)
		overAbsorb:Hide()

		local overHealAbsorb = frame.Health:CreateTexture(nil, 'OVERLAY')
		overHealAbsorb:SetPoint('TOP')
		overHealAbsorb:SetPoint('BOTTOM')
		overHealAbsorb:SetPoint('RIGHT', frame.Health, 'LEFT')
		overHealAbsorb:SetWidth(10)
		overHealAbsorb:Hide()

		frame.HealthPrediction = {
			myBar = myBar,
			otherBar = otherBar,
			absorbBar = absorbBar,
			healAbsorbBar = healAbsorbBar,
			overAbsorb = overAbsorb,
			overHealAbsorb = overHealAbsorb,
			maxOverflow = 2
		}
	end
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.Health
	local DB = settings or element.DB

	--Update Health items
	frame.Health.colorDisconnected = DB.colorDisconnected
	frame.Health.colorTapping = DB.colorTapping
	frame.Health.colorReaction = DB.colorReaction
	frame.Health.colorSmooth = DB.colorSmooth
	frame.Health.colorClass = DB.colorClass

	frame.Health:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	frame.Health.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
	frame.Health.bg:SetVertexColor(unpack(DB.bg.color))

	frame.Health:ClearAllPoints()
	frame.Health:SetSize(DB.width or frame:GetWidth(), DB.height or 20)
	frame.Health:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, DB.offset or 0)
	frame.Health:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, DB.offset or 0)
end

---@param frameName string
---@param OptionSet AceConfigOptionsTable
local function Options(frameName, OptionSet)
	OptionSet.args.general = {
		name = '',
		type = 'group',
		inline = true,
		args = {
			healthprediction = {
				name = L['Health prediction'],
				type = 'toggle',
				order = 5
			},
			DispelHighlight = {
				name = L['Dispel highlight'],
				type = 'toggle',
				order = 5
			},
			coloring = {
				name = L['Color health bar by:'],
				desc = L['The below options are in order of wich they apply'],
				order = 10,
				inline = true,
				type = 'group',
				args = {
					colorTapping = {
						name = L['Tapped'],
						desc = "Color's the bar if the unit isn't tapped by the player",
						type = 'toggle',
						order = 1
					},
					colorDisconnected = {
						name = L['Disconnected'],
						desc = L['Color the bar if the player is offline'],
						type = 'toggle',
						order = 2
					},
					colorClass = {
						name = L['Class'],
						desc = L['Color the bar based on unit class'],
						type = 'toggle',
						order = 3
					},
					colorReaction = {
						name = L['Reaction'],
						desc = "color the bar based on the player's reaction towards the player.",
						type = 'toggle',
						order = 4
					},
					colorSmooth = {
						name = L['Smooth'],
						desc = "color the bar with a smooth gradient based on the player's current health percentage",
						type = 'toggle',
						order = 5
					}
				}
			}
		}
	}

	if not UF.Unit:isFriendly(frameName) then
		OptionSet.args.general.args.DispelHighlight.hidden = true
	end

	UF.Options:AddDynamicText(frameName, OptionSet, 'Health')
end

---@type SUI.UnitFrame.Element.Settings
local Settings = {
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
		},
		['2'] = {
			text = '[perhp]%',
			position = {
				anchor = 'RIGHT',
				x = 0,
				y = 0
			}
		}
	},
	position = {
		anchor = 'TOP'
	},
	config = {
		type = 'StatusBar'
	}
}

UF.Elements:Register('Health', Build, Update, Options, Settings)
