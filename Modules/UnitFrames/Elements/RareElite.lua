local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.RareElite = frame.SpartanArt:CreateTexture(nil, 'BORDER')
	frame.RareElite:SetTexture('Interface\\Addons\\SpartanUI\\images\\blank')
end

---@param frame table
local function Update(frame)
	local element = frame.RareElite
	local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.RareElite[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.RareElite[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('RareElite')
	end
	--local DB = UF.CurrentSettings[unitName].elements.RareElite
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.RareElite then
		if not previewFrame.SpartanArt then
			previewFrame.SpartanArt = CreateFrame('Frame', nil, previewFrame)
		end
		previewFrame.RareElite = previewFrame.SpartanArt:CreateTexture(nil, 'BORDER')
	end

	local element = previewFrame.RareElite
	element:SetTexture([[Interface\Addons\SpartanUI\Themes\Classic\Images\RareElite]])
	element:SetAlpha(DB.alpha or 0.4)
	element:SetPoint(DB.points['1'].anchor, previewFrame, DB.points['1'].anchor, DB.points['1'].x, DB.points['1'].y)
	element:SetPoint(DB.points['2'].anchor, previewFrame, DB.points['2'].anchor, DB.points['2'].x, DB.points['2'].y)
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	alpha = 0.4,
	points = {
		['1'] = {
			anchor = 'TOPLEFT',
			relativeTo = 'Frame',
			x = 0,
			y = 0
		},
		['2'] = {
			anchor = 'BOTTOMRIGHT',
			relativeTo = 'Frame',
			x = 0,
			y = 0
		}
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Rare/Elite'
	},
	showInPreview = false
}

UF.Elements:Register('RareElite', Build, Update, Options, Settings, Preview)
