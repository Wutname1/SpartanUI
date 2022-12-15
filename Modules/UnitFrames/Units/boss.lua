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
	for i = 1, 8 do
		local frame = SUIUF:Spawn('boss' .. i, 'SUI_UF_boss' .. i)
		frame:SetID(i)
		if i == 1 then
			frame:SetPoint('TOPLEFT', holder, 'TOPLEFT', 0, 0)
		else
			frame:SetPoint('TOP', holder.frames[i - 1], 'BOTTOM', 0, -10)
		end

		holder.frames[i] = frame
	end
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

---@type SUI.UF.Unit.Settings
local Settings = {
	width = 120,
	maxColumns = 1,
	unitsPerColumn = 5,
	columnSpacing = 0,
	yOffset = -10,
	elements = {
		Portrait = {
			enabled = false
		},
		Castbar = {
			enabled = true
		},
		Health = {
			position = {
				anchor = 'TOP',
				relativeTo = 'Castbar',
				relativePoint = 'BOTTOM'
			},
			text = {
				['1'] = {
					text = '[health:current-dynamic] [perhp:conditional]'
				}
			}
		}
	},
	config = {
		IsGroup = true
	}
}

UF.Unit:Add('boss', Builder, Settings, Options, GroupBuilder)
