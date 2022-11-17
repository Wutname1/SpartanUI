local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.DispelHighlight = frame:CreateTexture(nil, 'OVERLAY')
	frame.DispelHighlight:SetTexture('Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2')
	frame.DispelHighlight:Hide()
end

---@param frame table
local function Update(frame)
	local element = frame.DispelHighlight
	local DB = element.DB
	frame.DispelHighlight:SetAllPoints(frame)
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
		UF.Unit[unitName]:ElementUpdate('DispelHighlight')
	end
	--local DB = UF.CurrentSettings[unitName].elements.DispelHighlight
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	position = {
		anchor = nil
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Dispel Highlight'
	}
}
UF.Elements:Register('DispelHighlight', Build, Update, Options, Settings)
