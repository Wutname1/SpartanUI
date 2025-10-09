local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local element = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame.raised)

	frame.PVPSpecIcon = element
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.PVPSpecIcon then
		previewFrame.PVPSpecIcon = CreateFrame('Frame', frameName .. 'PVPSpecIcon', previewFrame)
	end

	local element = previewFrame.PVPSpecIcon
	element:SetSize(DB.size or 24, DB.size or 24)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, 0, 0)

	if not element.icon then
		element.icon = element:CreateTexture(nil, 'ARTWORK')
		element.icon:SetAllPoints()
		-- Use a sample spec icon (Holy Paladin for example)
		element.icon:SetTexture(237542)
	end

	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	position = {
		anchor = 'RIGHT'
	},
	config = {
		NoBulkUpdate = false
	},
	showInPreview = false
}

UF.Elements:Register('PVPSpecIcon', Build, nil, nil, Settings, Preview)
