if SUI.IsClassic then
	return
end

local UF = SUI.UF

local function GroupBuilder(holder)
	for i = 1, (5) do
		holder.frames[i] = SUIUF:Spawn('arena' .. i, 'SUI_arena' .. i)
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
		'DispelHighlight',
		'SpartanArt',
		'Buffs',
		'Debuffs,',
		'ClassIcon',
		'RaidTargetIndicator',
		'Range',
		--Friendly Only
		'GroupRoleIndicator',
		'RaidRoleIndicator',
		'AuraBars'
	}

	for _, elementName in pairs(ElementsToBuild) do
		UF.Elements:Build(frame, elementName, elementDB[elementName])
	end
end

local function Options()
end

---@type UFrameSettings
local Settings = {
	maxColumns = 1,
	unitsPerColumn = 5,
	columnSpacing = 1,
	yOffset = -25,
	elements = {
		Name = {text = '[SUI_ColorClass][name] [arenaspec]'},
		Power = {
			height = 5
		},
		Castbar = {
			enabled = true,
			height = 15
		},
		Health = {
			position = {
				anchor = 'TOP',
				relativeTo = 'Castbar',
				relativePoint = 'BOTTOM'
			}
		},
		ThreatIndicator = {
			enabled = true,
			points = 'Name'
		},
		ClassIcon = {
			enabled = true
		}
	},
	config = {
		IsGroup = true
	}
}

UF.Unit:Add('arena', Builder, Settings, Options, GroupBuilder)
