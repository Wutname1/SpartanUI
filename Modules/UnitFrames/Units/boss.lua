if not SUI.IsRetail then
	return
end

local UF = SUI.UF

local function GroupBuilder(holder)
	for i = 1, (MAX_BOSS_FRAMES or 5) do
		holder.frames[i] = SUIUF:Spawn('boss' .. i, 'SUI_boss' .. i)
		if i == 1 then
			holder.frames[i]:SetPoint('TOPLEFT', holder, 'TOPLEFT', 0, 0)
		else
			holder.frames[i]:SetPoint('TOP', holder.frames[i - 1], 'BOTTOM', 0, -10)
		end
	end
end

local function Builder(frame)
	local elementDB = frame.elementDB
	local ElementsToBuild = {
		---Basic
		'Name',
		'Health',
		'Castbar',
		'Power',
		'Portrait',
		'SpartanArt',
		'Buffs',
		'Debuffs,',
		'RaidTargetIndicator',
		'Range',
		'ThreatIndicator',
		'RaidRoleIndicator'
	}

	for _, elementName in pairs(ElementsToBuild) do
		UF.Elements:Build(frame, elementName, elementDB[elementName])
	end
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

UF.Unit:Add('boss', Builder, Settings, Options, GroupBuilder)
