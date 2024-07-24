local MINOR = 8
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

local function get(data)
	return data.get(lib.activeLayoutName) == data.value
end

local function set(data)
	data.set(lib.activeLayoutName, data.value)
end

local dropdownMixin = {}
function dropdownMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)

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
				if value.isRadio then
					rootDescription:CreateRadio(value.text, get, set, {
						get = data.get,
						set = data.set,
						value = value.text,
					})
				else
					rootDescription:CreateCheckbox(value.text, get, set, {
						get = data.get,
						set = data.set,
						value = value.text
					})
				end
			end
		end)
	end
end

lib.internal:CreatePool(lib.SettingType.Dropdown, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame')
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
