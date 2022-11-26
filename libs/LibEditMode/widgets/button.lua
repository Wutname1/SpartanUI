local MINOR = 2
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

lib.internal:CreatePool('button', function()
	return CreateFrame('Button', nil, UIParent, 'EditModeSystemSettingsDialogExtraButtonTemplate')
end)
