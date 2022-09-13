local UF = SUI.UF
local elementList = {
	'Name',
	'Health',
	'SpartanArt',
	'RaidTargetIndicator',
	'Range',
	'ThreatIndicator'
}

local function Builder(frame)
	local elementDB = frame.elementDB
	for _, elementName in pairs(elementList) do
		UF.Elements:Build(frame, elementName, elementDB[elementName])
	end
	frame:SetParent(select(2, frame:GetPoint()))
end

local function GroupBuilder(holder)
	holder.elementList = elementList
end

local function Updater(frame)
	local db = frame.DB
	if not InCombatLockdown() then
		if db.enabled then
			frame:Enable()
		else
			frame:Disable()
		end
	end
end

local function Options()
end

---@type UFrameSettings
local Settings = {
	width = 80,
	elements = {
		Health = {
			height = 25,
			text = {
				['1'] = {
					text = '[perhp]%',
					position = {}
				}
			}
		},
		Name = {
			enabled = false
		}
	},
	config = {
		isChild = true,
		IsGroup = true
	}
}

UF.Unit:Add('partypet', Builder, Settings, nil, GroupBuilder, Updater)
