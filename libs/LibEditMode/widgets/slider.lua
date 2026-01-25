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

local sliderMixin = {}
function sliderMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)
	self:SetEnabled(not data.disabled)

	self.initInProgress = true
	self.formatters = {}
	self.formatters[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, data.formatter)

	local stepSize = data.valueStep or 1
	local steps = (data.maxValue - data.minValue) / stepSize
	self.Slider:Init(data.get(lib:GetActiveLayoutName()) or data.default, data.minValue or 0, data.maxValue or 1, steps, self.formatters)
	self.initInProgress = false
end

function sliderMixin:OnSliderValueChanged(value)
	if not self.initInProgress then
		self.setting.set(lib:GetActiveLayoutName(), value, false)
	end
end

function sliderMixin:SetEnabled(enabled)
	self.Slider:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
	self.EditBox:SetShown(enabled)
end

local function onEditFocus(self)
	local parent = self:GetParent()

	-- hide slider
	parent.Slider:Hide()

	-- resize editbox to take up the available space
	self:ClearAllPoints()
	self:SetPoint('RIGHT', parent.Slider.RightText, 5, 0)
	self:SetPoint('TOPLEFT', parent.Slider)
	self:SetPoint('BOTTOMLEFT', parent.Slider)

	-- set editbox text to current slider value
	-- TODO: maybe flatten the value here
	self:SetText(parent.Slider.Slider:GetValue())
	self:SetCursorPosition(0)
end

local function onEditSubmit(self)
	local parent = self:GetParent()

	-- get bounds and value
	local min, max = parent.Slider.Slider:GetMinMaxValues()
	local value = self:GetText()

	-- trigger change if value is a valid number
	if tonumber(value) then
		-- use bounds when updating value
		parent.Slider:SetValue(math.min(math.max(value, min), max))
	end

	self:ClearFocus()
end

local function onEditReset(self)
	local parent = self:GetParent()
	parent.Slider:Show()

	self:SetText('')
	self:ClearFocus()

	self:ClearAllPoints()
	self:SetPoint('RIGHT', parent.Slider.RightText, 5, 0)
	self:SetPoint('TOPLEFT', parent.Slider.RightText)
	self:SetPoint('BOTTOMLEFT', parent.Slider.RightText)
end

lib.internal:CreatePool(lib.SettingType.Slider, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'EditModeSettingSliderTemplate')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	Mixin(frame, sliderMixin)

	frame:SetHeight(32)
	frame.Slider:SetWidth(200)
	frame.Slider.MinText:Hide()
	frame.Slider.MaxText:Hide()
	frame.Label:SetPoint('LEFT')

	local editBox = CreateFrame('EditBox', nil, frame, 'InputBoxTemplate')
	editBox:SetPoint('TOPLEFT', frame.Slider.RightText)
	editBox:SetPoint('BOTTOMLEFT', frame.Slider.RightText)
	editBox:SetPoint('RIGHT', frame.Slider.RightText, 5, 0)
	editBox:SetAutoFocus(false)
	editBox:SetJustifyH('CENTER')
	editBox:SetScript('OnEditFocusGained', onEditFocus)
	editBox:SetScript('OnEnterPressed', onEditSubmit)
	editBox:SetScript('OnEscapePressed', onEditReset)
	editBox:SetScript('OnEditFocusLost', onEditReset)
	frame.EditBox = editBox

	frame:OnLoad()
	return frame
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
