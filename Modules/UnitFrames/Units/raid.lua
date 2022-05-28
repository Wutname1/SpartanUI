local UF = SUI.UF

local function builder(frame)
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
	UF.Elements:Build(frame, 'DispelHighlight', elementDB.DispelHighlight)
	UF.Elements:Build(frame, 'LeaderIndicator', elementDB.LeaderIndicator)
	UF.Elements:Build(frame, 'GroupRoleIndicator', elementDB.GroupRoleIndicator)
	UF.Elements:Build(frame, 'ResurrectIndicator', elementDB.ResurrectIndicator)

	-- for elementName, _ in pairs(UF.Elements.List) do
	-- 	if not elementDB[elementName] then
	-- 		SUI:Error('MISSING: ' .. elementName .. ' Type:' .. type(elementName))
	-- 	else
	-- 		UF.Elements:Build(frame, elementName, elementDB[elementName])
	-- 	end
	-- end
end

local function config()
end

UF.Frames.Add('raid', builder)
