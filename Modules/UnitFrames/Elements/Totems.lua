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

	if SUI.IsRetail and frame.unitOnCreate == 'player' then
		--Totem Bar
		for index = 1, 4 do
			_G['TotemFrameTotem' .. index]:SetFrameStrata('MEDIUM')
			_G['TotemFrameTotem' .. index]:SetFrameLevel(4)
			_G['TotemFrameTotem' .. index]:SetScale(.8)
		end
		hooksecurefunc(
			'TotemFrame_Update',
			function()
				TotemFrameTotem1:ClearAllPoints()
				TotemFrameTotem1:SetParent(frame)
				TotemFrameTotem1:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 20, 0)
			end
		)
	end
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
		UF.Unit[unitName]:ElementUpdate('Totems')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Totems
end

local Settings = {config = {NoBulkUpdate = true}}

UF.Elements:Register('Totems', Build, Update, nil, Settings)
