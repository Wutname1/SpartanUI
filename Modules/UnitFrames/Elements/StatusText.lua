local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.StatusText = frame:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(frame.StatusText, DB.textSize, 'UnitFrames')
	frame:Tag(frame.StatusText, DB.text)
end

---@param frame table
local function Update(frame)
	local element = frame.StatusText
	local DB = element.DB
	SUI:FormatFont(frame.StatusText, DB.textSize, 'UnitFrames')
	frame:Tag(frame.StatusText, DB.text)
end

UF.Elements:Register('StatusText', Build, Update)
