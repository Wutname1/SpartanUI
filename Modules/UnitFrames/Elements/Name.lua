local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.Name = frame.raised:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(frame.Name, DB.textSize, 'UnitFrames')
	frame.Name:SetSize(frame:GetWidth(), 12)
	frame.Name:SetJustifyH(DB.SetJustifyH)
	frame.Name:SetJustifyV(DB.SetJustifyV)
	frame:Tag(frame.Name, DB.text)
end

---@param frame table
local function Update(frame)
	local DB = frame.Name.DB
	SUI.Font:Format(frame.Name, DB.textSize, 'UnitFrames')
	frame.Name:SetJustifyH(DB.SetJustifyH)
	frame.Name:SetJustifyV(DB.SetJustifyV)
	frame:Tag(frame.Name, DB.text)
end

---@param frameName string
---@param OptionSet AceConfig.OptionsTable
local function Options(frameName, OptionSet)
	UF.Options:TextBasicDisplay(frameName, OptionSet)
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	width = false,
	height = 12,
	textSize = 12,
	text = '[difficulty][smartlevel] [SUI_ColorClass][name]',
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE',
	position = {
		anchor = 'TOP',
		x = 0,
		y = 15,
	},
	config = {
		type = 'Indicator',
	},
}

UF.Elements:Register('Name', Build, Update, Options, Settings)
