std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

-- see https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
-- and https://luacheck.readthedocs.io/en/stable/cli.html#patterns
ignore = {
	'212/self', -- unused argument self
	'212/event', -- unused argument event
	'212/unit', -- unused argument unit
	'312/event', -- unused value of argument event
	'312/unit', -- unused value of argument unit
	'431', -- shadowing an upvalue
	'631', -- line is too long
}

read_globals = {
	'debugstack',
	'geterrorhandler',
	string = {fields = {'join', 'split', 'trim'}},
	table = {fields = {'removemulti', 'wipe'}},

	-- FrameXML
	'ColorMixin',
	'ComboFrame',
	'CreateColor',
	'Enum',
	'FocusFrame',
	'GameTooltip',
	'GameTooltip_SetDefaultAnchor',
	'Mixin',
	'MonkStaggerBar',
	'NamePlateDriverFrame',
	'PetCastingBarFrame',
	'PetCastingBarFrame_OnLoad',
	'PetFrame',
	'PlayerCastingBarFrame',
	'PlayerFrame',
	'PlayerPowerBarAlt',
	'TargetFrame',
	'TargetFrameToT',
	'TargetofFocusFrame',
	'TotemFrame',
	'UIParent',

	-- namespaces
	'C_IncomingSummon',
	'C_NamePlate',
	'C_PvP',
	'C_UnitAuras',

	-- API
	'CopyTable',
	'CreateFrame',
	'GetAddOnMetadata',
	'GetArenaOpponentSpec',
	'GetNetStats',
	'GetNumArenaOpponentSpecs',
	'GetPartyAssignment',
	'GetRaidTargetIndex',
	'GetReadyCheckStatus',
	'GetRuneCooldown',
	'GetSpecialization',
	'GetSpecializationInfoByID',
	'GetSpellPowerCost',
	'GetTexCoordsForRoleSmallCircle',
	'GetThreatStatusColor',
	'GetTime',
	'GetTotemInfo',
	'GetUnitChargedPowerPoints',
	'GetUnitEmpowerHoldAtMaxTime',
	'GetUnitEmpowerStageDuration',
	'GetUnitPowerBarInfo',
	'GetUnitPowerBarInfoByID',
	'GetUnitPowerBarStringsByID',
	'HasLFGRestrictions',
	'InCombatLockdown',
	'IsLoggedIn',
	'IsPlayerSpell',
	'IsResting',
	'PartyUtil',
	'PlayerVehicleHasComboPoints',
	'PowerBarColor',
	'RegisterAttributeDriver',
	'RegisterStateDriver',
	'RegisterUnitWatch',
	'SecureButton_GetModifiedUnit',
	'SecureButton_GetUnit',
	'SecureHandlerSetFrameRef',
	'SetCVar',
	'SetPortraitTexture',
	'SetRaidTargetIconTexture',
	'ShowBossFrameWhenUninteractable',
	'UnitAffectingCombat',
	'UnitAuraSlots',
	'UnitCastingInfo',
	'UnitChannelInfo',
	'UnitClass',
	'UnitClassBase',
	'UnitExists',
	'UnitFactionGroup',
	'UnitGetIncomingHeals',
	'UnitGetTotalAbsorbs',
	'UnitGetTotalHealAbsorbs',
	'UnitGroupRolesAssigned',
	'UnitGUID',
	'UnitHasIncomingResurrection',
	'UnitHasVehiclePlayerFrameUI',
	'UnitHasVehicleUI',
	'UnitHealth',
	'UnitHealthMax',
	'UnitHonorLevel',
	'UnitInParty',
	'UnitInRaid',
	'UnitInRange',
	'UnitIsConnected',
	'UnitIsGroupAssistant',
	'UnitIsGroupLeader',
	'UnitIsMercenary',
	'UnitIsOwnerOrControllerOfUnit',
	'UnitIsPlayer',
	'UnitIsPVP',
	'UnitIsPVPFreeForAll',
	'UnitIsQuestBoss',
	'UnitIsTapDenied',
	'UnitIsUnit',
	'UnitIsVisible',
	'UnitPhaseReason',
	'UnitPlayerControlled',
	'UnitPower',
	'UnitPowerBarID',
	'UnitPowerDisplayMod',
	'UnitPowerMax',
	'UnitPowerType',
	'UnitPvpClassification',
	'UnitRace',
	'UnitReaction',
	'UnitSelectionType',
	'UnitStagger',
	'UnitThreatSituation',
	'UnitWatchRegistered',
	'UnregisterUnitWatch',
}
