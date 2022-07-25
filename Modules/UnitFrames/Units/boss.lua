if not SUI.IsRetail then
	return
end

local UF = SUI.UF

local function Builder(frame)
	local elementDB = frame.elementDB
	UF.Elements:Build(frame, 'Name', elementDB.Name)
	UF.Elements:Build(frame, 'Castbar', elementDB.Castbar)
	UF.Elements:Build(frame, 'Health', elementDB.Health)
	UF.Elements:Build(frame, 'Power', elementDB.Power)
	UF.Elements:Build(frame, 'SpartanArt', elementDB.SpartanArt)
	UF.Elements:Build(frame, 'RaidTargetIndicator', elementDB.RaidTargetIndicator)
	UF.Elements:Build(frame, 'Range', elementDB.Range)
	UF.Elements:Build(frame, 'ThreatIndicator', elementDB.ThreatIndicator)
	UF.Elements:Build(frame, 'Buffs', elementDB.Buffs)
	UF.Elements:Build(frame, 'Debuffs', elementDB.Debuffs)
end

local function GroupBuilder()
end

local function Options()
end

---@type UFrameSettings
local Settings = {
	width = 120,
	maxColumns = 1,
	unitsPerColumn = 5,
	columnSpacing = 0,
	yOffset = -10,
	elements = {
		Castbar = {
			enabled = true
		},
		Health = {
			position = {
				anchor = 'TOP',
				relativeTo = 'Castbar',
				relativePoint = 'BOTTOM'
			}
		}
	},
	config = {
		IsGroup = true
	}
}

UF.Unit.Add('boss', Builder, Settings, Options, GroupBuilder)
