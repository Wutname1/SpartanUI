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
		if not key.enabled then power.TextElements[i]:Hide() end
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

	-- Basic Bar updates
	element:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	element.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
	element.bg:SetVertexColor(unpack(DB.bg.color or { 1, 1, 1, 0.2 }))

	element.TextElements = {}
	for i, TextElement in pairs(element.TextElements) do
		local key = DB.text[i]
		TextElement:SetJustifyH(key.SetJustifyH)
		TextElement:SetJustifyV(key.SetJustifyV)
		TextElement:ClearAllPoints()
		TextElement:SetPoint(key.position.anchor, element, key.position.anchor, key.position.x, key.position.y)
		frame:Tag(TextElement, key.text)

		if not key.enabled then element.TextElements[i]:Hide() end
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
		args = {},
	}

	if frameName == 'player' then
		if SUI.IsRetail then
			OptionSet.args.PowerPrediction = {
				name = L['Enable power prediction'],
				desc = L['Used to represent cost of spells on top of the Power bar'],
				type = 'toggle',
				width = 'double',
				order = 10,
			}
		end
	end
	UF.Options:AddDynamicText(frameName, OptionSet, 'Power')
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	height = 10,
	width = false,
	FrameStrata = 'BACKGROUND',
	bg = {
		enabled = true,
		color = { 1, 1, 1, 0.2 },
	},
	text = {
		['1'] = {
			enabled = false,
			text = '[SUIPower(hideDead)][ / $>SUIPower(max,hideDead,hideZero,hideMax)]',
		},
		['2'] = {
			enabled = false,
			text = '[perpp]%',
		},
	},
	position = {
		anchor = 'TOP',
		relativeTo = 'Health',
		relativePoint = 'BOTTOM',
		y = -1,
	},
	config = {
		type = 'StatusBar',
	},
}

UF.Elements:Register('Power', Build, Update, Options, Settings)
