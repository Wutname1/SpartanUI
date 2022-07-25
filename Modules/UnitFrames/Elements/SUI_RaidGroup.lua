local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.SUI_RaidGroup = frame:CreateTexture(nil, 'BORDER')

	frame.SUI_RaidGroup.Text = frame:CreateFontString(nil, 'BORDER')
	frame.SUI_RaidGroup.Text:SetPoint('CENTER', frame.SUI_RaidGroup, 'CENTER', 0, 0)
	SUI:FormatFont(frame.SUI_RaidGroup.Text, DB.textSize, 'UnitFrames')
	frame:Tag(frame.SUI_RaidGroup.Text, DB.content)
end

---@param frame table
local function Update(frame)
	local DB = frame.SUI_RaidGroup.DB
	frame:Tag(frame.SUI_RaidGroup.Text, DB.content)
	frame.SUI_RaidGroup.Text:SetJustifyH(DB.SetJustifyH)
	frame.SUI_RaidGroup.Text:SetJustifyV(DB.SetJustifyV)
end

---@type ElementSettings
local Settings = {
	textSize = 13,
	content = '[group]',
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE',
	position = {
		anchor = 'BOTTOMRIGHT',
		x = 0,
		y = 10
	}
}

UF.Elements:Register('SUI_RaidGroup', Build, Update, nil, Settings)
