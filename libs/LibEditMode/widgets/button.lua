local MINOR = 8
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

lib.internal:CreatePool('button', function()
	return CreateFrame('Button', nil, UIParent, 'EditModeSystemSettingsDialogExtraButtonTemplate')
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
