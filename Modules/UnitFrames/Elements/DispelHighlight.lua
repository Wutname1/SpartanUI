local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.DispelHighlight = frame.Health:CreateTexture(nil, 'OVERLAY')
	frame.DispelHighlight:SetAllPoints(frame.Health:GetStatusBarTexture())
	frame.DispelHighlight:SetTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')
	frame.DispelHighlight:Hide()
end

---@param frame table
local function Update(frame)
	local element = frame.DispelHighlight
	local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.DispelHighlight[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.DispelHighlight[option] = val
		--Update the screen
		UF.Frames[unitName]:ElementUpdate('DispelHighlight')
	end
	--local DB = UF.CurrentSettings[unitName].elements.DispelHighlight
end

UF.Elements:Register('DispelHighlight', Build, Update, Options)
