local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

local function showTooltip(self)
	if self.setting and self.setting.desc then
		SettingsTooltip:SetOwner(self, 'ANCHOR_NONE')
		SettingsTooltip:SetPoint('BOTTOMRIGHT', self, 'TOPLEFT')
		SettingsTooltip:SetText(self.setting.name, 1, 1, 1)
		SettingsTooltip:AddLine(self.setting.desc)
		SettingsTooltip:Show()
	end
end

local checkboxMixin = {}
function checkboxMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)
	self:SetEnabled(not data.disabled)

	local value = data.get(lib:GetActiveLayoutName())
	if value == nil then
		value = data.default
	end

	self.checked = value
	self.Button:SetChecked(not not value) -- force boolean
end

function checkboxMixin:OnCheckButtonClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self.checked = not self.checked
	self.setting.set(lib:GetActiveLayoutName(), not not self.checked, false)
end

function checkboxMixin:SetEnabled(enabled)
	self.Button:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
end

lib.internal:CreatePool(lib.SettingType.Checkbox, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'EditModeSettingCheckboxTemplate')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	return Mixin(frame, checkboxMixin)
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
