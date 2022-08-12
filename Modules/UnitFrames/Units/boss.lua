local UF = SUI.UF
local elementList = {
	---Basic
	'Name',
	'Health',
	'Castbar',
	'Power',
	'Portrait',
	'SpartanArt',
	'Buffs',
	'Debuffs',
	'RaidTargetIndicator',
	'Range',
	'ThreatIndicator',
	'RaidRoleIndicator'
}

local function GroupBuilder(holder)
	for i = 1, (MAX_BOSS_FRAMES or 5) do
		holder.frames[i] = SUIUF:Spawn('boss' .. i, 'SUI_UF_boss' .. i)
		if i == 1 then
			holder.frames[i]:SetPoint('TOPLEFT', holder, 'TOPLEFT', 0, 0)
		else
			holder.frames[i]:SetPoint('TOP', holder.frames[i - 1], 'BOTTOM', 0, -10)
		end
	end
	holder.elementList = elementList
end

local function Builder(frame)
	local elementDB = frame.elementDB

	for _, elementName in pairs(elementList) do
		UF.Elements:Build(frame, elementName, elementDB[elementName])
	end
end

local function Options(OptionSet)
	UF.Options:AddGroupLayout('boss', OptionSet)
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

UF.Unit:Add('boss', Builder, Settings, Options, GroupBuilder)
