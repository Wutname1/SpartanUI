---@class SUI
local SUI = SUI
local MoveIt = SUI.MoveIt
local CustomEditMode = MoveIt.CustomEditMode
local PositionCalculator = MoveIt.PositionCalculator

-- Settings panel frame
local settingsPanel = nil
local currentMover = nil

---Create the settings panel frame
local function CreateSettingsPanel()
	if settingsPanel then
		return settingsPanel
	end

	-- Create main panel frame
	local panel = CreateFrame('Frame', 'SUI_EditMode_SettingsPanel', UIParent, BackdropTemplateMixin and 'BackdropTemplate')
	panel:SetSize(250, 180)
	panel:SetFrameStrata('DIALOG')
	panel:SetFrameLevel(100)
	panel:SetClampedToScreen(true)

	-- Backdrop
	panel:SetBackdrop({
		bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
		edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})

	-- Title
	local title = panel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
	title:SetPoint('TOP', 0, -15)
	title:SetText('Frame Settings')
	panel.title = title

	-- Frame name
	local frameName = panel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	frameName:SetPoint('TOP', title, 'BOTTOM', 0, -5)
	frameName:SetText('')
	panel.frameName = frameName

	-- Reset Position Button
	local resetBtn = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
	resetBtn:SetSize(200, 25)
	resetBtn:SetPoint('TOP', frameName, 'BOTTOM', 0, -15)
	resetBtn:SetText('Reset Position')
	resetBtn:SetScript('OnClick', function()
		if currentMover then
			MoveIt:Reset(currentMover.name, true)
			SUI:Print('Reset ' .. (currentMover.DisplayName or currentMover.name) .. ' to default position')
		end
	end)
	panel.resetBtn = resetBtn

	-- Scale Slider
	local scaleSlider = CreateFrame('Slider', 'SUI_EditMode_ScaleSlider', panel, 'OptionsSliderTemplate')
	scaleSlider:SetPoint('TOP', resetBtn, 'BOTTOM', 0, -20)
	scaleSlider:SetMinMaxValues(0.5, 2.0)
	scaleSlider:SetValueStep(0.05)
	scaleSlider:SetObeyStepOnDrag(true)
	scaleSlider:SetWidth(200)

	-- Slider labels
	_G[scaleSlider:GetName() .. 'Low']:SetText('0.5')
	_G[scaleSlider:GetName() .. 'High']:SetText('2.0')
	_G[scaleSlider:GetName() .. 'Text']:SetText('Scale: 1.00')

	scaleSlider:SetScript('OnValueChanged', function(self, value)
		_G[self:GetName() .. 'Text']:SetText(string.format('Scale: %.2f', value))
		if currentMover then
			local parent = currentMover.parent
			local name = currentMover.name

			-- Apply scale
			if parent then
				parent:SetScale(value)
			end
			currentMover:SetScale(value)

			-- Save scale
			if MoveIt.DB and MoveIt.DB.movers and MoveIt.DB.movers[name] then
				MoveIt.DB.movers[name].AdjustedScale = value
			end
		end
	end)
	panel.scaleSlider = scaleSlider

	-- SpartanUI Settings Button
	local settingsBtn = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
	settingsBtn:SetSize(200, 25)
	settingsBtn:SetPoint('TOP', scaleSlider, 'BOTTOM', 0, -30)
	settingsBtn:SetText('SpartanUI Settings')
	settingsBtn:SetScript('OnClick', function()
		if currentMover then
			-- Hide settings panel
			panel:Hide()
			-- Exit EditMode
			CustomEditMode:Exit()
			-- Open SUI options to Movers page
			SUI.Options:ToggleOptions({ 'Movers' })
		end
	end)
	panel.settingsBtn = settingsBtn

	-- Close button
	local closeBtn = CreateFrame('Button', nil, panel, 'UIPanelCloseButton')
	closeBtn:SetPoint('TOPRIGHT', -5, -5)
	closeBtn:SetScript('OnClick', function()
		panel:Hide()
	end)
	panel.closeBtn = closeBtn

	panel:Hide()
	settingsPanel = panel

	return panel
end

---Show the settings panel for a mover
---@param mover Frame The mover frame
function CustomEditMode:ShowSettingsPanel(mover)
	if not mover then
		return
	end

	local panel = CreateSettingsPanel()
	currentMover = mover

	-- Update frame name
	panel.frameName:SetText(mover.DisplayName or mover.name or 'Unknown')

	-- Update scale slider
	local currentScale = (mover.parent and mover.parent:GetScale()) or mover:GetScale() or 1.0
	panel.scaleSlider:SetValue(currentScale)

	-- Position panel near the mover
	panel:ClearAllPoints()

	-- Try to position it to the right of the mover
	local screenWidth = GetScreenWidth()
	local moverRight = mover:GetRight() or 0

	if moverRight + 260 < screenWidth then
		-- Room on the right
		panel:SetPoint('LEFT', mover, 'RIGHT', 10, 0)
	else
		-- Position on the left
		panel:SetPoint('RIGHT', mover, 'LEFT', -10, 0)
	end

	panel:Show()
end

---Hide the settings panel
function CustomEditMode:HideSettingsPanel()
	if settingsPanel then
		settingsPanel:Hide()
		currentMover = nil
	end
end

-- Hook into Exit to hide panel
local originalExit = CustomEditMode.Exit
function CustomEditMode:Exit()
	CustomEditMode:HideSettingsPanel()
	originalExit(self)
end

if MoveIt.logger then
	MoveIt.logger.info('Settings Panel loaded')
end
