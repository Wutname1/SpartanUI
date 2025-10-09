local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local ResurrectIndicator = frame:CreateTexture(nil, 'OVERLAY')
	frame.ResurrectIndicator = ResurrectIndicator
end

---@param frame table
local function Update(frame)
	local element = frame.ResurrectIndicator
	local DB = element.DB
	element:SetSize(DB.size, DB.size)
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.ResurrectIndicator then
		previewFrame.ResurrectIndicator = previewFrame:CreateTexture(nil, 'OVERLAY')
	end

	local element = previewFrame.ResurrectIndicator
	element:SetSize(DB.size, DB.size)
	element:SetPoint('CENTER', previewFrame, 'CENTER', 0, 0)

	-- Show resurrect icon
	element:SetTexture([[Interface\RaidFrame\Raid-Icon-Rez]])
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 20,
	config = {
		type = 'Indicator',
		DisplayName = 'Resurrect'
	},
	showInPreview = false
}

UF.Elements:Register('ResurrectIndicator', Build, Update, nil, Settings, Preview)
