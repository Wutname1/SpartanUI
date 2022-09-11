local UF = SUI.UF

local function Builder(frame)
	local elementDB = frame.elementDB
	UF.Elements:Build(frame, 'Name', elementDB.Name)
	UF.Elements:Build(frame, 'Health', elementDB.Health)
	UF.Elements:Build(frame, 'SpartanArt', elementDB.SpartanArt)
	UF.Elements:Build(frame, 'RaidTargetIndicator', elementDB.RaidTargetIndicator)
	UF.Elements:Build(frame, 'Range', elementDB.Range)
	UF.Elements:Build(frame, 'ThreatIndicator', elementDB.ThreatIndicator)
	frame:SetParent(select(2, frame:GetPoint()))
end

local function Updater(frame)
	local db = frame.DB
	if not InCombatLockdown() then
		if db.enable then
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
	width = 100,
	elements = {
		Health = {
			height = 25,
			text = {
				['1'] = {
					text = '[perhp]%'
				}
			}
		},
		Name = {
			enabled = false,
			height = 10,
			text = '[name]',
			position = {
				y = 0
			}
		}
	},
	config = {
		isChild = true
	}
}

UF.Unit:Add('partypet', Builder, Settings, nil, nil, Updater)
