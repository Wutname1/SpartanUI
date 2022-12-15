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
			height = 30,
		},
		Power = {
			height = 5,
			text = {
				['1'] = {
					enabled = false,
				},
			},
		},
		Name = {
			enabled = true,
			height = 10,
			position = {
				y = 0,
			},
		},
	},
}

UF.Unit:Add('pet', Builder, Settings)
