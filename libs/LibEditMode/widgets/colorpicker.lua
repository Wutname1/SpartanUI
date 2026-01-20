local MINOR = 12
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

local function onColorChanged(self)
	local r, g, b = ColorPickerFrame:GetColorRGB()
	if self.colorInfo.hasOpacity then
		local a = ColorPickerFrame:GetColorAlpha()
		self:OnColorChanged(CreateColor(r, g, b, a))
	else
		self:OnColorChanged(CreateColor(r, g, b))
	end
end

local function onColorCancel(self)
	self:OnColorChanged(self.oldValue)
end

local colorPickerMixin = {}
function colorPickerMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)
	self:SetEnabled(not data.disabled)

	local value = data.get(lib:GetActiveLayoutName())
	if value == nil then
		value = data.default
	end

	local r, g, b, a = value:GetRGBA()
	self.colorInfo = {
		swatchFunc = GenerateClosure(onColorChanged, self),
		opacityFunc = GenerateClosure(onColorChanged, self),
		cancelFunc = GenerateClosure(onColorCancel, self),
		r = r,
		g = g,
		b = b,
		opacity = a,
		hasOpacity = data.hasOpacity
	}

	self.Swatch:SetColorRGB(r, g, b)
end

function colorPickerMixin:OnColorChanged(color)
	self.setting.set(lib:GetActiveLayoutName(), color, false)

	local r, g, b, a = color:GetRGBA()
	self.Swatch:SetColorRGB(r, g, b)

	-- update colorInfo for next run
	self.colorInfo.r = r
	self.colorInfo.g = g
	self.colorInfo.b = b
	self.colorInfo.opacity = a
end

function colorPickerMixin:SetEnabled(enabled)
	self.Swatch:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
end

local function onSwatchClick(self)
	local parent = self:GetParent()
	local info = parent.colorInfo

	-- store current/previous colors for reset capabilities
	parent.oldValue = CreateColor(info.r, info.g, info.b, info.opacity)

	ColorPickerFrame:SetupColorPickerAndShow(info)
end

lib.internal:CreatePool(lib.SettingType.ColorPicker, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame')
	frame.fixedHeight = 32 -- default attribute
	frame:Hide() -- default state
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)

	-- recreate EditModeSetting* widgets
	local Label = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightMedium')
	Label:SetPoint('LEFT')
	Label:SetSize(100, 32)
	Label:SetJustifyH('LEFT')
	frame.Label = Label

	local Swatch = CreateFrame('Button', nil, frame, 'ColorSwatchTemplate')
	Swatch:SetSize(32, 32)
	Swatch:SetPoint('LEFT', Label, 'RIGHT', 5, 0)
	Swatch:SetScript('OnClick', onSwatchClick)
	frame.Swatch = Swatch

	return Mixin(frame, colorPickerMixin)
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
