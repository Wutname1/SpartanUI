local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	if frame.unitOnCreate ~= 'player' then
		return
	end
	local playerClass = select(2, UnitClass('player'))
	if playerClass == 'DEATHKNIGHT' then
		frame.Runes = CreateFrame('Frame', nil, frame)
		frame.Runes.colorSpec = true

		for i = 1, 6 do
			frame.Runes[i] = CreateFrame('StatusBar', frame:GetName() .. '_Runes' .. i, frame)
			frame.Runes[i]:SetHeight(6)
			frame.Runes[i]:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
			frame.Runes[i]:SetStatusBarColor(0, 0.39, 0.63, 1)

			frame.Runes[i].bg = frame.Runes[i]:CreateTexture(nil, 'BORDER')
			frame.Runes[i].bg:SetPoint('TOPLEFT', frame.Runes[i], 'TOPLEFT', -0, 0)
			frame.Runes[i].bg:SetPoint('BOTTOMRIGHT', frame.Runes[i], 'BOTTOMRIGHT', 0, -0)
			frame.Runes[i].bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
			frame.Runes[i].bg:SetVertexColor(0, 0, 0, 1)
			frame.Runes[i].bg.multiplier = 0.64
			frame.Runes[i]:Hide()
		end
	end
end

---@param frame table
local function Update(frame)
	local DB = frame.Runes.DB
	for i = 1, 6 do
		frame.Runes[i]:SetWidth((frame.Health:GetWidth() - 10) / 6)
		frame.Runes[i]:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		frame.Runes[i].bg:SetTexture(UF:FindStatusBarTexture(DB.texture))
		if i == 1 then
			frame.Runes[i]:SetPoint('TOPLEFT', frame.Name, 'BOTTOMLEFT', 0, -3)
		else
			frame.Runes[i]:SetPoint('TOPLEFT', frame.Runes[i - 1], 'TOPRIGHT', 2, 0)
		end
	end
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	OptionSet.args.texture = {
		type = 'select',
		dialogControl = 'LSM30_Statusbar',
		order = 2,
		width = 'double',
		name = 'Bar Texture',
		values = AceGUIWidgetLSMlists.statusbar
	}
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	-- Only show for Death Knights
	local playerClass = select(2, UnitClass('player'))
	if playerClass ~= 'DEATHKNIGHT' or frameName ~= 'player' then
		return 0
	end

	if not previewFrame.Runes then
		previewFrame.Runes = CreateFrame('Frame', nil, previewFrame)
		for i = 1, 6 do
			previewFrame.Runes[i] = CreateFrame('StatusBar', nil, previewFrame)
			previewFrame.Runes[i]:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture or 'Smoothv2'))
			previewFrame.Runes[i]:SetHeight(6)

			previewFrame.Runes[i].bg = previewFrame.Runes[i]:CreateTexture(nil, 'BORDER')
			previewFrame.Runes[i].bg:SetAllPoints(previewFrame.Runes[i])
			previewFrame.Runes[i].bg:SetTexture(UF:FindStatusBarTexture(DB.texture or 'Smoothv2'))
			previewFrame.Runes[i].bg:SetVertexColor(0, 0, 0, 1)
		end
	end

	local element = previewFrame.Runes

	-- Show 4 out of 6 runes charged
	for i = 1, 6 do
		element[i]:SetWidth((previewFrame:GetWidth() - 10) / 6)
		element[i]:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture or 'Smoothv2'))

		if i == 1 then
			element[i]:SetPoint('TOPLEFT', previewFrame, 'TOPLEFT', 5, -20)
		else
			element[i]:SetPoint('TOPLEFT', element[i - 1], 'TOPRIGHT', 2, 0)
		end

		if i <= 4 then
			element[i]:SetStatusBarColor(0, 0.39, 0.63, 1)
			element[i]:SetAlpha(1)
		else
			element[i]:SetStatusBarColor(0.3, 0.3, 0.3, 1)
			element[i]:SetAlpha(0.5)
		end

		element[i]:Show()
	end

	return 6
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	config = {
		type = 'Indicator',
		NoBulkUpdate = true
	},
	showInPreview = false
}

UF.Elements:Register('Runes', Build, Update, Options, Settings, Preview)
