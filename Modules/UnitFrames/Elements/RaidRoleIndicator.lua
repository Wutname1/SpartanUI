local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RaidRoleIndicator = frame.raised:CreateTexture(nil, 'BORDER')
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.RaidRoleIndicator then
		previewFrame.RaidRoleIndicator = previewFrame:CreateTexture(nil, 'BORDER')
	end

	local element = previewFrame.RaidRoleIndicator
	element:SetSize(DB.size, DB.size)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 20, DB.position.y or -10)

	-- Show main tank icon
	element:SetTexture([[Interface\GroupFrame\UI-Group-MainTankIcon]])
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 20,
	position = {
		anchor = 'TOP',
		x = 20,
		y = -10
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Raid Role',
		Description = 'Raid assignment (main tank or main assist)'
	},
	showInPreview = false
}

UF.Elements:Register('RaidRoleIndicator', Build, nil, nil, Settings, Preview)
