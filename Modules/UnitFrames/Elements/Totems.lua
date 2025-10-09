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
	-- local element = frame.Totems
	-- local DB = element.DB
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	-- Only show for shamans
	local playerClass = select(2, UnitClass('player'))
	if playerClass ~= 'SHAMAN' or frameName ~= 'player' then
		return 0
	end

	if not previewFrame.Totems then
		local Totems = CreateFrame('Frame', nil, previewFrame)
		for index = 1, MAX_TOTEMS do
			local Totem = CreateFrame('Button', nil, Totems)
			Totem.Icon = Totem:CreateTexture(nil, 'OVERLAY')
			Totem.Icon:SetAllPoints()
			Totems[index] = Totem
		end
		previewFrame.Totems = Totems
	end

	local element = previewFrame.Totems
	element:SetSize(DB.size * MAX_TOTEMS + DB.spacing * (MAX_TOTEMS - 1), DB.size)

	-- Sample totem icons
	local totemIcons = {
		136098, -- Earth totem
		136039, -- Fire totem
		135819, -- Water totem
		136022 -- Air totem
	}

	for index = 1, MAX_TOTEMS do
		local totem = element[index]
		totem:SetSize(DB.size, DB.size)

		if index == 1 then
			totem:SetPoint('LEFT', element, 'LEFT', 0, 0)
		else
			totem:SetPoint('LEFT', element[index - 1], 'RIGHT', DB.spacing, 0)
		end

		if totemIcons[index] then
			totem.Icon:SetTexture(totemIcons[index])
			totem.Icon:SetAlpha(0.7)
			totem:Show()
		else
			totem:Hide()
		end
	end

	element:Show()

	return DB.size
end

---@type SUI.UF.Elements.Settings
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
	},
	showInPreview = false
}

UF.Elements:Register('Totems', Build, Update, nil, Settings, Preview)
