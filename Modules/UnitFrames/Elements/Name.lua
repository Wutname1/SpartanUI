local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.Name = frame:CreateFontString()
	SUI:FormatFont(frame.Name, DB.textSize, 'UnitFrames')
	frame.Name:SetSize(frame:GetWidth(), 12)
	frame.Name:SetJustifyH(DB.SetJustifyH)
	frame.Name:SetJustifyV(DB.SetJustifyV)
	frame:Tag(frame.Name, DB.text)
end

---@param frame table
local function Update(frame)
	local DB = frame.Name.DB
	SUI:FormatFont(frame.Name, DB.textSize, 'UnitFrames')
	frame.Name:SetJustifyH(DB.SetJustifyH)
	frame.Name:SetJustifyV(DB.SetJustifyV)
	frame:Tag(frame.Name, DB.text)
end

UF.Elements:Register('Name', Build, Update)
