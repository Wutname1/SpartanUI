local UF, L = SUI.UF, SUI.L

---@param frame table
---@param DB table
local function Build(frame, DB)
	local power = CreateFrame('StatusBar', nil, frame)
	power:SetFrameStrata(DB.FrameStrata or frame:GetFrameStrata())
	power:SetFrameLevel(DB.FrameLevel or 2)
	power:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	power:SetHeight(DB.height)

	local Background = power:CreateTexture(nil, 'BACKGROUND')
	Background:SetAllPoints(power)
	Background:SetTexture(UF:FindStatusBarTexture(DB.texture))
	Background:SetVertexColor(1, 1, 1, .2)
	power.bg = Background

	power:SetPoint('TOPLEFT', frame.Health or frame, 'TOPLEFT', 0, DB.offset or -1)
	power:SetPoint('TOPRIGHT', frame.Health or frame, 'TOPRIGHT', 0, DB.offset or -1)

	power.TextElements = {}
	for i, key in pairs(DB.text) do
		local NewString = power:CreateFontString(nil, 'OVERLAY')
		SUI:FormatFont(NewString, key.size, 'UnitFrames')
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
local function Update(frame)
	local DB = frame.Power.DB
	if DB.PowerPrediction then
		frame:EnableElement('PowerPrediction')
	else
		frame:DisableElement('PowerPrediction')
	end

	-- frame.Power:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	-- frame.Power.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
end

---@param frameName string
---@param OptionSet AceConfigOptionsTable
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

---@type ElementSettings
local Settings = {
	enabled = true,
	height = 10,
	width = false,
	FrameStrata = 'BACKGROUND',
	bg = {
		enabled = true,
		color = {1, 1, 1, .2}
	},
	text = {
		['1'] = {
			enabled = false,
			text = '[power:current-formatted] / [power:max-formatted]'
		},
		['2'] = {
			enabled = false,
			text = '[perpp]%'
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

UF.Elements:Register('Power', Build, Update, Options, Settings)
