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
---@param OptionSet AceConfig.OptionsTable
local function Options(frameName, OptionSet)
	UF.Options:TextBasicDisplay(frameName, OptionSet)
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.StatusText then
		previewFrame.StatusText = previewFrame:CreateFontString(nil, 'OVERLAY')
		SUI.Font:Format(previewFrame.StatusText, DB.textSize, 'UnitFrames')
	end

	local element = previewFrame.StatusText
	element:SetSize(DB.width or 70, DB.height or 25)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 0, DB.position.y or 0)
	element:SetJustifyH(DB.SetJustifyH)
	element:SetJustifyV(DB.SetJustifyV)

	-- Show sample status text
	element:SetText('AFK')
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
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
	},
	showInPreview = false
}

UF.Elements:Register('StatusText', Build, Update, Options, Settings, Preview)
