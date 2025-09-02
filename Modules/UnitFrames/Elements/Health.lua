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
		if not key.enabled then health.TextElements[i]:Hide() end
	end

	-- TWW Added a Temp health Loss bar
	local tempLoss = CreateFrame('StatusBar', nil, frame.Health)
	tempLoss:SetFrameLevel(DB.FrameLevel or 3)
	tempLoss:SetPoint('TOP')
	tempLoss:SetPoint('BOTTOM')
	tempLoss:SetPoint('RIGHT', frame.Health, 'LEFT')
	tempLoss:SetWidth(10)
	tempLoss:Hide()

	frame.Health = health

	frame.Health.frequentUpdates = true
	frame.Health.colorDisconnected = DB.colorDisconnected or true
	frame.Health.colorTapping = DB.colorTapping or true
	frame.Health.colorReaction = DB.colorReaction or true
	frame.Health.colorSmooth = DB.colorSmooth or true
	frame.Health.colorClass = DB.colorClass or false

	frame.colors.smooth = { 1, 0, 0, 1, 1, 0, 0, 1, 0 }
	frame.Health.colorHealth = true

	frame.Health.DataTable = DB.text

	-- Position and size
	local myBar = CreateFrame('StatusBar', nil, frame.Health)
	myBar:SetPoint('TOP')
	myBar:SetPoint('BOTTOM')
	myBar:SetPoint('LEFT', frame.Health:GetStatusBarTexture(), 'RIGHT')
	myBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.shieldTexture or DB.texture))
	myBar:SetStatusBarColor(0, 1, 0.5, 0.45)
	myBar:SetSize(150, 16)
	myBar:Hide()

	local otherBar = CreateFrame('StatusBar', nil, myBar)
	otherBar:SetPoint('TOP')
	otherBar:SetPoint('BOTTOM')
	otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
	otherBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.shieldTexture or DB.texture))
	otherBar:SetStatusBarColor(0, 0.5, 1, 0.35)
	otherBar:SetSize(150, 16)
	otherBar:Hide()

	local absorbBar = CreateFrame('StatusBar', nil, frame.Health)
	absorbBar:SetPoint('TOP')
	absorbBar:SetPoint('BOTTOM')
	absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
	absorbBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.absorbTexture or DB.texture))
	absorbBar:SetWidth(10)
	absorbBar:Hide()

	local healAbsorbBar = CreateFrame('StatusBar', nil, frame.Health)
	healAbsorbBar:SetPoint('TOP')
	healAbsorbBar:SetPoint('BOTTOM')
	healAbsorbBar:SetPoint('RIGHT', frame.Health:GetStatusBarTexture())
	healAbsorbBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.absorbTexture or DB.texture))
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
		maxOverflow = 2,
	}
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.Health
	local DB = settings or element.DB

	--Update Health items
	element.colorDisconnected = DB.colorDisconnected
	element.colorTapping = DB.colorTapping
	element.colorReaction = DB.colorReaction
	element.colorSmooth = DB.colorSmooth
	element.colorClass = DB.colorClass

	element:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	element.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
	element.bg:SetVertexColor(unpack(DB.bg.color or { 1, 1, 1, 0.2 }))

	-- Update HealthPrediction bar textures
	if frame.HealthPrediction then
		if frame.HealthPrediction.myBar then frame.HealthPrediction.myBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.shieldTexture or DB.texture)) end
		if frame.HealthPrediction.otherBar then frame.HealthPrediction.otherBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.shieldTexture or DB.texture)) end
		if frame.HealthPrediction.absorbBar then frame.HealthPrediction.absorbBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.absorbTexture or DB.texture)) end
		if frame.HealthPrediction.healAbsorbBar then frame.HealthPrediction.healAbsorbBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.absorbTexture or DB.texture)) end
	end

	for i, key in pairs(DB.text) do
		if element.TextElements[i] then
			local TextElement = element.TextElements[i]
			TextElement:SetDrawLayer('OVERLAY', 7) -- Ensure text is above all bars
			TextElement:SetJustifyH(key.SetJustifyH)
			TextElement:SetJustifyV(key.SetJustifyV)
			TextElement:ClearAllPoints()
			TextElement:SetPoint(key.position.anchor, element, key.position.anchor, key.position.x, key.position.y)
			frame:Tag(TextElement, key.text)

			if key.enabled then
				TextElement:Show()
			else
				TextElement:Hide()
			end
		end
	end

	element:ClearAllPoints()
	element:SetSize(DB.width or frame:GetWidth(), DB.height or 20)
	element:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, DB.offset or 0)
	element:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, DB.offset or 0)
end

---@param frameName string
---@param OptionSet AceConfig.OptionsTable
local function Options(frameName, OptionSet)
	OptionSet.args.general = {
		name = '',
		type = 'group',
		inline = true,
		args = {
			healthprediction = {
				name = L['Health prediction'],
				type = 'toggle',
				order = 5,
			},
			DispelHighlight = {
				name = L['Dispel highlight'],
				type = 'toggle',
				order = 5,
			},
			textures = {
				name = L['Bar Textures'],
				type = 'group',
				inline = true,
				order = 6,
				args = {
					texture = {
						type = 'select',
						dialogControl = 'LSM30_Statusbar',
						order = 1,
						width = 'double',
						name = L['Health Bar Texture'],
						values = SUI.Lib.LSM:HashTable('statusbar'),
					},
					shieldTexture = {
						type = 'select',
						dialogControl = 'LSM30_Statusbar',
						order = 2,
						width = 'double',
						name = L['Shield Bar Texture'],
						desc = L['Texture used for shield and incoming heal bars'],
						values = SUI.Lib.LSM:HashTable('statusbar'),
					},
					absorbTexture = {
						type = 'select',
						dialogControl = 'LSM30_Statusbar',
						order = 3,
						width = 'double',
						name = L['Absorb Bar Texture'],
						desc = L['Texture used for absorb and heal absorb bars'],
						values = SUI.Lib.LSM:HashTable('statusbar'),
					},
				},
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
						order = 1,
					},
					colorDisconnected = {
						name = L['Disconnected'],
						desc = L['Color the bar if the player is offline'],
						type = 'toggle',
						order = 2,
					},
					colorClass = {
						name = L['Class'],
						desc = L['Color the bar based on unit class'],
						type = 'toggle',
						order = 3,
					},
					colorReaction = {
						name = L['Reaction'],
						desc = "color the bar based on the player's reaction towards the player.",
						type = 'toggle',
						order = 4,
					},
					colorSmooth = {
						name = L['Smooth'],
						desc = "color the bar with a smooth gradient based on the player's current health percentage",
						type = 'toggle',
						order = 5,
					},
				},
			},
		},
	}

	if not UF.Unit:isFriendly(frameName) then OptionSet.args.general.args.DispelHighlight.hidden = true end

	UF.Options:AddDynamicText(frameName, OptionSet, 'Health')
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	height = 40,
	width = false,
	FrameStrata = 'BACKGROUND',
	texture = 'SpartanUI Default',
	shieldTexture = 'Stripes',
	absorbTexture = 'Thin Stripes',
	colorReaction = true,
	colorSmooth = false,
	colorClass = true,
	colorTapping = true,
	colorDisconnected = true,
	bg = {
		enabled = true,
		color = { 1, 1, 1, 0.2 },
	},
	text = {
		['1'] = {
			enabled = true,
			text = '[SUIHealth(dynamic,displayDead)][ / $>SUIHealth(max,dynamic,hideDead,hideMax)]',
			position = {
				anchor = 'CENTER',
				x = 0,
				y = 0,
			},
		},
		['2'] = {
			text = '[perhp]%',
			position = {
				anchor = 'RIGHT',
				x = 0,
				y = 0,
			},
		},
	},
	position = {
		anchor = 'TOP',
	},
	config = {
		type = 'StatusBar',
	},
}

UF.Elements:Register('Health', Build, Update, Options, Settings)
