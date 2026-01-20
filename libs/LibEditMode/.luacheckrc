std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

-- see https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
-- and https://luacheck.readthedocs.io/en/stable/cli.html#patterns
ignore = {
	'212/self', -- unused argument self
	'212/event', -- unused argument event
	'212/unit', -- unused argument unit
	'212/element', -- unused argument element
	'312/event', -- unused value of argument event
	'312/unit', -- unused value of argument unit
	'431', -- shadowing an upvalue
	'614', -- trailing whitespace in a comment
	'631', -- line is too long
}

exclude_files = {
	'tests/*',
}

read_globals = {
	-- FrameXML objects
	'ColorPickerFrame',
	'CreateUnsecuredObjectPool',
	'EditModeManagerFrame',
	'EditModeSystemSettingsDialog',
	'EventRegistry',
	'MinimalSliderWithSteppersMixin',
	'UIParent',
	'SettingsTooltip',
	'DefaultTooltipMixin',

	-- FrameXML functions
	'CopyTable',
	'CreateColor',
	'CreateMinimalSliderFormatter',
	'GenerateClosure',
	'Mixin',

	-- FrameXML constants
	'DISABLED_FONT_COLOR',
	'SOUNDKIT',
	'WHITE_FONT_COLOR',

	-- GlobalStrings
	'HUD_EDIT_MODE_RESET_POSITION',
	'RESET_TO_DEFAULT',

	-- namespaces
	'C_EditMode',
	'Enum',

	-- API
	'CreateFrame',
	'GetBuildInfo',
	'InCombatLockdown',
	'IsShiftKeyDown',
	'PlaySound',
	'hooksecurefunc',
	'securecallfunction',

	-- exposed from other addons
	'LibStub',
}
