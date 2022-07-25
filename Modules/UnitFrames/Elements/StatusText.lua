local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.StatusText = frame:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(frame.StatusText, DB.textSize, 'UnitFrames')
	frame:Tag(frame.StatusText, DB.content)
end

---@param frame table
local function Update(frame)
	local element = frame.StatusText
	local DB = element.DB
	SUI:FormatFont(frame.StatusText, DB.textSize, 'UnitFrames')
	frame:Tag(frame.StatusText, DB.content)
end

---@type ElementSettings
local Settings = {
	textSize = 22,
	width = 70,
	height = 25,
	content = '[afkdnd]',
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE',
	position = {
		anchor = 'CENTER',
		x = 0,
		y = 0
	}
}

UF.Elements:Register('StatusText', Build, Update, nil, Settings)
