local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local Totems = CreateFrame('Frame', nil, frame)
	Totems.Destroy = {}
	frame.MAX_CLASS_BAR = 4
	frame.ClassBar = 'Totems'

	for index = 1, 4 do
		-- Position and size of the totem indicator
		local Totem = CreateFrame('Button', nil, frame)
		Totem:SetSize(40, 40)
		Totem:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', index * Totem:GetWidth(), 0)

		local Icon = Totem:CreateTexture(nil, 'OVERLAY')
		Icon:SetAllPoints()

		local Cooldown = CreateFrame('Cooldown', nil, Totem, 'CooldownFrameTemplate')
		Cooldown:SetAllPoints()

		Totem.Icon = Icon
		Totem.Cooldown = Cooldown

		Totems[index] = Totem
	end

	-- Register with oUF
	frame.Totems = Totems
end

---@param frame table
local function Update(frame)
	local element = frame.Totems
	local DB = element.DB
	-- frame.Totems[1]:SetPoint()
	frame.Totems[1]:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 5, 0)
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.Totems[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Totems[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('Totems')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Totems
end

local Config = {
	NoBulkUpdate = true
}

UF.Elements:Register('Totems', Build, Update, nil, Config)
