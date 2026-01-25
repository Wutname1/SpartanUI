local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

local internal = lib.internal

local extensionMixin = {}
function extensionMixin:Update(systemID, subSystemID)
	self.systemID = systemID
	self.subSystemID = subSystemID

	internal.ReleaseAllPools()

	local numSettings = self:UpdateSettings()
	if numSettings == 0 then
		self.Buttons:ClearAllPoints()
		self.Buttons:SetPoint('TOP', 0, -20)
	else
		self.Buttons:ClearAllPoints()
		self.Buttons:SetPoint('TOP', self.Settings, 'BOTTOM', 0, -2)
	end

	self:UpdateButtons(numSettings)

	-- show and update layout
	self:Show()
	self:Layout()
end

function extensionMixin:UpdateSettings()
	local settings, num = internal:GetSystemSettings(self.systemID, self.subSystemID)
	local isEmpty = num == 0
	if not isEmpty then
		for index, data in next, settings do
			local pool = internal:GetPool(data.kind)
			if pool then
				local setting = pool:Acquire(self.Settings)
				setting.layoutIndex = index
				setting:Setup(data)
				setting:Show()
			end
		end
	end

	self.Settings.ignoreInLayout = isEmpty
	self.Settings.ResetButton.layoutIndex = num + 1
	self.Settings.ResetButton.ignoreInLayout = isEmpty
	self.Settings.ResetButton:SetEnabled(not isEmpty)

	return num
end

function extensionMixin:UpdateButtons(numSettings)
	local buttons, num = internal:GetSystemSettingsButtons(self.systemID, self.subSystemID)
	local isEmpty = num == 0
	if not isEmpty then
		if numSettings > 0 then
			local divider = internal:GetPool(lib.SettingType.Divider):Acquire(self.Settings)
			divider.layoutIndex = numSettings + 2 -- + 1 is for the reset button
			divider:Show()
		end

		for index, data in next, buttons do
			local button = internal:GetPool('button'):Acquire(self.Buttons)
			button.layoutIndex = index
			button:SetText(data.text)
			button:SetOnClickHandler(data.click)
			button:Show()
			button:SetEnabled(true) -- reset from pool
		end
	end

	self.Buttons.ignoreInLayout = isEmpty
end

function extensionMixin:ResetSettings()
	local settings, num = internal:GetSystemSettings(self.systemID, self.subSystemID)
	if num > 0 then
		for _, data in next, settings do
			if data.set then
				data.set(lib:GetActiveLayoutName(), data.default)
			end
		end

		self:Update(self.systemID, self.subSystemID)
	end
end

function internal:CreateExtension()
	local extension = Mixin(CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame'), extensionMixin)
	extension:SetSize(64, 64)
	extension:SetPoint('TOP', EditModeSystemSettingsDialog, 'BOTTOM', 0, 0)
	extension:SetFrameStrata('DIALOG')
	extension:SetFrameLevel(300)
	extension:EnableMouse(true)
	extension:Hide()
	extension.widthPadding = 40
	extension.heightPadding = 40

	local extensionBorder = CreateFrame('Frame', nil, extension, 'DialogBorderTranslucentTemplate')
	extensionBorder.ignoreInLayout = true
	extension.Border = extensionBorder

	local extensionSettings = CreateFrame('Frame', nil, extension, 'VerticalLayoutFrame')
	extensionSettings:SetPoint('TOP', 0, -15)
	extensionSettings.spacing = 2
	extension.Settings = extensionSettings

	local resetSettingsButton = CreateFrame('Button', nil, extensionSettings, 'EditModeSystemSettingsDialogButtonTemplate')
	resetSettingsButton:SetText(RESET_TO_DEFAULT)
	resetSettingsButton:SetOnClickHandler(GenerateClosure(extension.ResetSettings, extension))
	extensionSettings.ResetButton = resetSettingsButton

	local extensionButtons = CreateFrame('Frame', nil, extension, 'VerticalLayoutFrame')
	extensionButtons.spacing = 2
	extension.Buttons = extensionButtons

	return extension
end
