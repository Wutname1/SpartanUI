local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local Totems = CreateFrame('Frame', nil, frame)
	Totems:SetSize(DB.width * MAX_TOTEMS, DB.height)

	for index = 1, MAX_TOTEMS do
		-- Position and size of the totem indicator
		local Totem = CreateFrame('Button', nil, Totems)
		Totem:SetSize(DB.size, DB.size)
		if index == 1 then
			Totem:SetPoint('TOPLEFT', Totems, 'TOPLEFT', 0, 0)
		else
			Totem:SetPoint('LEFT', Totems[index - 1], 'RIGHT', DB.spacing, 0)
		end

		local Icon = Totem:CreateTexture(nil, 'OVERLAY')
		Icon:SetAllPoints()

		local Cooldown = CreateFrame('Cooldown', nil, Totem, 'CooldownFrameTemplate')
		Cooldown:SetAllPoints()

		Totem.Icon = Icon
		Totem.Cooldown = Cooldown

		Totems[index] = Totem
	end

	Totems.SizeChange = function(self)
		self:SetSize(DB.width * MAX_TOTEMS, DB.height)

		for index = 1, MAX_TOTEMS do
			---@diagnostic disable-next-line: undefined-field
			self[index]:SetSize(self.DB.size, self.DB.size)
		end
	end

	-- Register with oUF
	frame.Totems = Totems
end

---@param frame table
local function Update(frame)
	local element = frame.Totems
	local DB = element.DB
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

---@type SUI.UnitFrame.Element.Settings
local Settings = {
	enabled = true,
	size = 20,
	spacing = 2,
	position = {
		anchor = 'TOPLEFT',
		relativePoint = 'BOTTOMLEFT',
		relativeTo = 'Name',
		y = 0
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Totems'
	}
}

UF.Elements:Register('Totems', Build, Update, nil, Settings)
