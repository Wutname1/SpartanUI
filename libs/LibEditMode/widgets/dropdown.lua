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

local function get(data)
	local value = data.get(lib:GetActiveLayoutName())
	if value then
		if data.multiple then
			assert(type(value) == 'table', "multiple choice dropdowns expects a table from 'get'")

			for _, v in next, value do
				if v == data.value then
					return true
				end
			end
		else
			return value == data.value
		end
	end
end

local function set(data)
	data.set(lib:GetActiveLayoutName(), data.value, false)
end

local dropdownMixin = {}
function dropdownMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)
	self:SetEnabled(not data.disabled)

	if data.generator then
		-- let the user have full control
		self.Dropdown:SetupMenu(function(owner, rootDescription)
			pcall(data.generator, owner, rootDescription, data)
		end)
	elseif data.values then
		self.Dropdown:SetupMenu(function(_, rootDescription)
			if data.height then
				rootDescription:SetScrollMode(data.height)
			end

			for _, value in next, data.values do
				if data.multiple then
					rootDescription:CreateCheckbox(value.text, get, set, {
						get = data.get,
						set = data.set,
						value = value.value or value.text,
						multiple = data.multiple,
					})
				else
					rootDescription:CreateRadio(value.text, get, set, {
						get = data.get,
						set = data.set,
						value = value.value or value.text,
						multiple = data.multiple,
					})
				end
			end
		end)
	end
end

function dropdownMixin:SetEnabled(enabled)
	self.Dropdown:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
end

lib.internal:CreatePool(lib.SettingType.Dropdown, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	frame.fixedHeight = 32
	Mixin(frame, dropdownMixin)

	local label = frame:CreateFontString(nil, nil, 'GameFontHighlightMedium')
	label:SetPoint('LEFT')
	label:SetWidth(100)
	label:SetJustifyH('LEFT')
	frame.Label = label

	local dropdown = CreateFrame('DropdownButton', nil, frame, 'WowStyle1DropdownTemplate')
	dropdown:SetPoint('LEFT', label, 'RIGHT', 5, 0)
	dropdown:SetSize(200, 30)
	frame.Dropdown = dropdown

	return frame
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
