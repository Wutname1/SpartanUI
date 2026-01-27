---@class SUI
local SUI = SUI
local MoveIt = SUI.MoveIt
local CustomEditMode = MoveIt.CustomEditMode
local PositionCalculator = MoveIt.PositionCalculator

-- Settings panel frame
local settingsPanel = nil
local currentOverlay = nil

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
		if currentOverlay then
			MoveIt:Reset(currentOverlay.moverName, true)
			-- Update overlay position
			currentOverlay:ClearAllPoints()
			currentOverlay:SetAllPoints(currentOverlay.parent)
			SUI:Print('Reset ' .. (currentOverlay.mover.DisplayName or currentOverlay.moverName) .. ' to default position')
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
		if currentOverlay then
			local mover = currentOverlay.mover
			local parent = currentOverlay.parent
			local name = currentOverlay.moverName

			-- Apply scale
			parent:SetScale(value)
			mover:SetScale(value)

			-- Save scale
			if MoveIt.DB and MoveIt.DB.movers and MoveIt.DB.movers[name] then
				MoveIt.DB.movers[name].AdjustedScale = value
			end

			-- Update overlay
			CustomEditMode:UpdateOverlays()
		end
	end)
	panel.scaleSlider = scaleSlider

	-- SpartanUI Settings Button
	local settingsBtn = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
	settingsBtn:SetSize(200, 25)
	settingsBtn:SetPoint('TOP', scaleSlider, 'BOTTOM', 0, -30)
	settingsBtn:SetText('SpartanUI Settings')
	settingsBtn:SetScript('OnClick', function()
		if currentOverlay then
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

---Show the settings panel for an overlay
---@param overlay Frame The overlay frame
function CustomEditMode:ShowSettingsPanel(overlay)
	if not overlay then
		return
	end

	local panel = CreateSettingsPanel()
	currentOverlay = overlay

	-- Update frame name
	panel.frameName:SetText(overlay.mover.DisplayName or overlay.moverName)

	-- Update scale slider
	local currentScale = overlay.parent:GetScale() or 1.0
	panel.scaleSlider:SetValue(currentScale)

	-- Position panel near the overlay
	panel:ClearAllPoints()

	-- Try to position it to the right of the overlay
	local screenWidth = GetScreenWidth()
	local overlayRight = overlay:GetRight() or 0

	if overlayRight + 260 < screenWidth then
		-- Room on the right
		panel:SetPoint('LEFT', overlay, 'RIGHT', 10, 0)
	else
		-- Position on the left
		panel:SetPoint('RIGHT', overlay, 'LEFT', -10, 0)
	end

	panel:Show()
end

---Hide the settings panel
function CustomEditMode:HideSettingsPanel()
	if settingsPanel then
		settingsPanel:Hide()
		currentOverlay = nil
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
