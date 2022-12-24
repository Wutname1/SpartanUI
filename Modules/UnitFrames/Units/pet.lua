local UF = SUI.UF

local function Builder(frame)
	local elementDB = frame.elementDB

	UF.Elements:Build(frame, 'Name', elementDB['Name'])
	UF.Elements:Build(frame, 'Health', elementDB['Health'])
	UF.Elements:Build(frame, 'Castbar', elementDB['Castbar'])
	UF.Elements:Build(frame, 'Power', elementDB['Power'])

	UF.Elements:Build(frame, 'Portrait', elementDB['Portrait'])
	UF.Elements:Build(frame, 'DispelHighlight', elementDB['DispelHighlight'])
	UF.Elements:Build(frame, 'SpartanArt', elementDB['SpartanArt'])
	UF.Elements:Build(frame, 'Buffs', elementDB['Buffs'])
	UF.Elements:Build(frame, 'Debuffs', elementDB['Debuffs'])
	UF.Elements:Build(frame, 'ClassIcon', elementDB['ClassIcon'])
	UF.Elements:Build(frame, 'RaidTargetIndicator', elementDB['RaidTargetIndicator'])
	UF.Elements:Build(frame, 'ThreatIndicator', elementDB['ThreatIndicator'])
	UF.Elements:Build(frame, 'Range', elementDB['Range'])

	if not SUI.IsRetail then UF.Elements:Build(frame, 'HappinessIndicator', elementDB['HappinessIndicator']) end
	PetCastingBarFrame:SetUnit(nil)
	PetCastingBarFrame:UnregisterEvent('UNIT_PET')
end

local function Options() end

---@type SUI.UF.Unit.Settings
local Settings = {
	width = 100,
	elements = {
		Health = {
			height = 35,
			colorSmooth = true,
			colorReaction = false,
			text = {
				['1'] = {
					text = '[SUIHealth(short,displayDead)] [($>SUIHealth<$)(percentage,hideDead,hideMax)]',
				},
			},
		},
		Power = {
			height = 2,
			text = {
				['1'] = {
					enabled = false,
				},
			},
			position = {
				y = 0,
			},
		},
		Name = {
			enabled = true,
			height = 8,
			text = '[name]',
			position = {
				y = 1,
				anchor = 'BOTTOM',
				relativePoint = 'TOP',
			},
		},
	},
}

UF.Unit:Add('pet', Builder, Settings)
