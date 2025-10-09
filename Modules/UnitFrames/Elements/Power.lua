local UF, L = SUI.UF, SUI.L

---@param frame table
---@param DB table
local function Build(frame, DB)
	local power = CreateFrame('StatusBar', nil, frame)
	power:SetFrameStrata(DB.FrameStrata or frame:GetFrameStrata())
	power:SetFrameLevel(DB.FrameLevel or 2)
	power:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	power:SetHeight(DB.height)

	local bg = power:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(power)
	bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
	bg:SetVertexColor(unpack(DB.bg.color))
	power.bg = bg

	power:SetPoint('TOPLEFT', frame.Health or frame, 'TOPLEFT', 0, DB.offset or -1)
	power:SetPoint('TOPRIGHT', frame.Health or frame, 'TOPRIGHT', 0, DB.offset or -1)

	power.TextElements = {}
	for i, key in pairs(DB.text) do
		local NewString = power:CreateFontString(nil, 'OVERLAY')
		SUI.Font:Format(NewString, key.size, 'UnitFrames')
		NewString:SetJustifyH(key.SetJustifyH)
		NewString:SetJustifyV(key.SetJustifyV)
		NewString:SetPoint(key.position.anchor, power, key.position.anchor, key.position.x, key.position.y)
		frame:Tag(NewString, key.text or '')

		power.TextElements[i] = NewString
		if not key.enabled then
			power.TextElements[i]:Hide()
		end
	end

	frame.Power = power
	frame.Power.colorPower = true
	frame.Power.frequentUpdates = true
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.Power
	local DB = settings or element.DB
	if DB.PowerPrediction then
		frame:EnableElement('PowerPrediction')
	else
		frame:DisableElement('PowerPrediction')
	end

	-- Handle custom coloring
	if DB.customColors and DB.customColors.useCustom then
		-- Disable automatic coloring when using custom colors
		element.colorPower = false
		-- Set custom color
		element:SetStatusBarColor(unpack(DB.customColors.barColor))
	else
		-- Enable automatic coloring
		element.colorPower = true
	end

	-- Basic Bar updates
	element:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	element.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))

	-- Set background color (class color or custom color)
	if DB.bg.useClassColor then
		local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[select(2, UnitClass('player'))]) or _G.RAID_CLASS_COLORS[select(2, UnitClass('player'))]
		local alpha = DB.bg.classColorAlpha or 0.2
		if color then
			element.bg:SetVertexColor(color.r, color.g, color.b, alpha)
		else
			element.bg:SetVertexColor(1, 1, 1, alpha)
		end
	else
		element.bg:SetVertexColor(unpack(DB.bg.color or {1, 1, 1, 0.2}))
	end

	for i, key in pairs(DB.text) do
		if element.TextElements[i] then
			local TextElement = element.TextElements[i]
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
		args = {}
	}

	if frameName == 'player' then
		if SUI.IsRetail then
			OptionSet.args.PowerPrediction = {
				name = L['Enable power prediction'],
				desc = L['Used to represent cost of spells on top of the Power bar'],
				type = 'toggle',
				width = 'double',
				order = 10
			}
		end
	end
	UF.Options:AddDynamicText(frameName, OptionSet, 'Power')
end

---@param previewFrame frame The preview frame to render into
---@param DB table Element settings
---@param frameName UnitFrameName The frame name being previewed
local function Preview(previewFrame, DB, frameName)
	-- Create power bar preview
	local power = previewFrame.Power or CreateFrame('StatusBar', nil, previewFrame)
	power:SetFrameStrata(DB.FrameStrata or 'BACKGROUND')
	power:SetFrameLevel(DB.FrameLevel or 2)
	power:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	power:SetHeight(DB.height)

	-- Set preview value to 60% power
	power:SetMinMaxValues(0, 100)
	power:SetValue(60)

	-- Apply coloring based on settings
	if DB.customColors and DB.customColors.useCustom then
		power:SetStatusBarColor(unpack(DB.customColors.barColor))
	else
		-- Use player's power type color (mana = blue, rage = red, etc.)
		local _, powerType = UnitPowerType('player')
		local powerColor = PowerBarColor[powerType] or {r = 0, g = 0, b = 1}
		power:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
	end

	-- Create background
	if not power.bg then
		local bg = power:CreateTexture(nil, 'BACKGROUND')
		bg:SetAllPoints(power)
		bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
		power.bg = bg
	end

	-- Set background color
	if DB.bg.useClassColor then
		local _, class = UnitClass('player')
		local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class]) or _G.RAID_CLASS_COLORS[class]
		local alpha = DB.bg.classColorAlpha or 0.2
		if color then
			power.bg:SetVertexColor(color.r, color.g, color.b, alpha)
		else
			power.bg:SetVertexColor(1, 1, 1, alpha)
		end
	else
		power.bg:SetVertexColor(unpack(DB.bg.color or {1, 1, 1, 0.2}))
	end

	-- Position the power bar below health
	power:ClearAllPoints()
	if previewFrame.Health then
		power:SetPoint('TOPLEFT', previewFrame.Health, 'BOTTOMLEFT', 0, DB.offset or -1)
		power:SetPoint('TOPRIGHT', previewFrame.Health, 'BOTTOMRIGHT', 0, DB.offset or -1)
	else
		power:SetPoint('TOPLEFT', previewFrame, 'TOPLEFT', 0, DB.offset or 0)
		power:SetPoint('TOPRIGHT', previewFrame, 'TOPRIGHT', 0, DB.offset or 0)
	end

	-- Add text elements
	for i, textConfig in pairs(DB.text) do
		if textConfig.enabled then
			local textElement = power['text' .. i] or power:CreateFontString(nil, 'OVERLAY')
			SUI.Font:Format(textElement, textConfig.size or 5, 'UnitFrames')
			textElement:SetJustifyH(textConfig.SetJustifyH)
			textElement:SetJustifyV(textConfig.SetJustifyV)
			textElement:ClearAllPoints()
			textElement:SetPoint(textConfig.position.anchor, power, textConfig.position.anchor, textConfig.position.x, textConfig.position.y)

			-- Show preview text instead of live tags
			if textConfig.text:find('perpp') then
				textElement:SetText('60%')
			elseif textConfig.text:find('Power') then
				textElement:SetText('12000 / 20000')
			else
				textElement:SetText('Power')
			end

			textElement:Show()
			power['text' .. i] = textElement
		end
	end

	power:Show()
	previewFrame.Power = power

	return power:GetHeight()
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	showInPreview = true, -- Power is always visible
	height = 10,
	width = false,
	FrameStrata = 'BACKGROUND',
	bg = {
		enabled = true,
		color = {1, 1, 1, 0.2},
		useClassColor = false,
		classColorAlpha = 0.2
	},
	customColors = {
		useCustom = false,
		barColor = {0, 0, 1, 1}
	},
	text = {
		['1'] = {
			enabled = false,
			text = '[SUIPower(hideDead)][ / $>SUIPower(max,hideDead,hideZero,hideMax)]',
			size = 10,
			SetJustifyH = 'CENTER',
			SetJustifyV = 'MIDDLE',
			position = {
				anchor = 'CENTER',
				x = 0,
				y = 0
			}
		},
		['2'] = {
			enabled = false,
			text = '[perpp]%',
			size = 10,
			SetJustifyH = 'CENTER',
			SetJustifyV = 'MIDDLE',
			position = {
				anchor = 'CENTER',
				x = 0,
				y = 0
			}
		}
	},
	position = {
		anchor = 'TOP',
		relativeTo = 'Health',
		relativePoint = 'BOTTOM',
		y = -1
	},
	config = {
		type = 'StatusBar'
	}
}

UF.Elements:Register('Power', Build, Update, Options, Settings, Preview)
