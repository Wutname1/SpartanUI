local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.StatusText = frame:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(frame.StatusText, DB.textSize, 'UnitFrames')
	frame:Tag(frame.StatusText, DB.text)
end

---@param frame table
local function Update(frame)
	local element = frame.StatusText
	local DB = element.DB
	SUI.Font:Format(frame.StatusText, DB.textSize, 'UnitFrames')
	frame:Tag(frame.StatusText, DB.text)
end

---@param frameName string
---@param OptionSet AceConfigOptionsTable
local function Options(frameName, OptionSet)
	UF.Options:TextBasicDisplay(frameName, OptionSet)
end

---@type SUI.UnitFrame.Elements.Settings
local Settings = {
	textSize = 22,
	width = 70,
	height = 25,
	text = '[afkdnd]',
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE',
	position = {
		anchor = 'CENTER',
		x = 0,
		y = 0
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Status Text'
	}
}

UF.Elements:Register('StatusText', Build, Update, Options, Settings)
