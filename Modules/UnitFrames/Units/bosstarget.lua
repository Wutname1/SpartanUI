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
	UF.Elements:Build(frame, 'Buffs', elementDB.Buffs)
	UF.Elements:Build(frame, 'Debuffs', elementDB.Debuffs)
end

local function Options()
end

---@type UFrameSettings
local Settings = {
	config = {
		Requires = 'boss'
	}
}

UF.Unit.Add('bosstarget', Builder, Settings)
