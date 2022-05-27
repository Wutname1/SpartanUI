local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.SUI_RaidGroup = frame:CreateTexture(nil, 'BORDER')

	frame.SUI_RaidGroup.Text = frame:CreateFontString(nil, 'BORDER')
	frame.SUI_RaidGroup.Text:SetPoint('CENTER', frame.SUI_RaidGroup, 'CENTER', 0, 0)
	SUI:FormatFont(frame.SUI_RaidGroup.Text, DB.size, 'UnitFrames')
	frame:Tag(frame.SUI_RaidGroup.Text, '[group]')
end

---@param frame table
local function Update(frame)
	local DB = frame.SUI_RaidGroup.DB
	SUI:FormatFont(frame.SUI_RaidGroup.Text, DB.size, 'UnitFrames')
	frame.SUI_RaidGroup.Text:SetJustifyH(DB.SetJustifyH)
	frame.SUI_RaidGroup.Text:SetJustifyV(DB.SetJustifyV)
end

UF.Elements:Register('SUI_RaidGroup', Build, Update)
