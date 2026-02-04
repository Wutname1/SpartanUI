local UF = SUI.UF

--- Builds the tag text with optional custom color prefix
---@param DB table
---@return string
local function GetTagText(DB)
	local text = DB.text or ''

	-- If custom color is enabled, prepend the hex color code
	if DB.textColor and DB.textColor.useCustomColor and DB.textColor.color then
		local r, g, b = unpack(DB.textColor.color)
		local hexColor = ('|cff%02x%02x%02x'):format((r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
		text = hexColor .. text
	end

	return text
end

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.StatusText = frame:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(frame.StatusText, DB.textSize, 'UnitFrames')
	frame:Tag(frame.StatusText, GetTagText(DB))
end

---@param frame table
local function Update(frame)
	local element = frame.StatusText
	local DB = element.DB
	SUI.Font:Format(frame.StatusText, DB.textSize, 'UnitFrames')
	frame:Tag(frame.StatusText, GetTagText(DB))
end

---@param frameName string
---@param OptionSet AceConfig.OptionsTable
local function Options(frameName, OptionSet)
	UF.Options:TextBasicDisplay(frameName, OptionSet, 'StatusText')
end

---@type SUI.UF.Elements.Settings
local Settings = {
	textSize = 22,
	width = 70,
	height = 25,
	text = '[afkdnd]',
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE',
	textColor = {
		useCustomColor = false,
		color = { 1, 1, 1 },
	},
	position = {
		anchor = 'CENTER',
		x = 0,
		y = 0,
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Status Text',
	},
}

UF.Elements:Register('StatusText', Build, Update, Options, Settings)
