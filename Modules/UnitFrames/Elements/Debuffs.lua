local UF = SUI.UF

---@param element any
---@param unit? UnitId
---@param isFullUpdate? boolean
local function updateSettings(element, unit, isFullUpdate)
	local DB = element.DB
	element.size = DB.size or 20
	element.initialAnchor = DB.position.anchor
	element['growth-x'] = DB.growthx
	element['growth-y'] = DB.growthy
	-- Buffs.spacing = DB.spacing
	element.showType = DB.showType
	element.num = DB.number or 10
	element.onlyShowPlayer = DB.onlyShowPlayer
end

---@param element any
local function SizeChange(element)
	local DB = element.DB
	local w = (DB.number / DB.rows)
	if w < 1.5 then
		w = 1.5
	end
	element:SetSize((DB.size + DB.spacing) * w, (DB.spacing + DB.size) * DB.rows)
end

---@param frame table
---@param DB table
local function Build(frame, DB)
	--Debuff Icons
	local element = CreateFrame('Frame', frame.unitOnCreate .. 'Debuffs', frame.raised)
	element.PostUpdateButton = function(self, button, unit, data, position)
		button.data = data
		button.unit = unit
	end
	element.PostCreateButton = function(self, button)
		UF.Auras:PostCreateButton('Debuffs', button)
	end

	---@param unit UnitId
	---@param data UnitAuraInfo
	local FilterAura = function(element, unit, data)
		return UF.Auras:Filter(element, unit, data, element.DB.rules)
	end
	local PreUpdate = function(self)
		updateSettings(element)
	end

	element.displayReasons = {}
	element.FilterAura = FilterAura
	element.PreUpdate = PreUpdate
	element.SizeChange = SizeChange

	frame.Debuffs = element
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.Debuffs
	local DB = settings or element.DB

	if DB.enabled then
		element:Show()
	else
		element:Hide()
	end

	updateSettings(element)
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.Debuffs then
		local element = CreateFrame('Frame', frameName .. 'Debuffs', previewFrame)
		previewFrame.Debuffs = element
	end

	local element = previewFrame.Debuffs
	element:Show()

	-- Create sample debuff icons
	if not element.previewButtons then
		element.previewButtons = {}
		-- Sample debuffs with real spell icons
		local sampleDebuffs = {
			{icon = 136139, type = 'Magic'}, -- Polymorph
			{icon = 132152, type = 'Poison'}, -- Deadly Poison
			{icon = 136093, type = 'Curse'} -- Curse of Agony
		}

		for i, debuff in ipairs(sampleDebuffs) do
			local button = CreateFrame('Frame', nil, element)
			button:SetSize(DB.size, DB.size)

			button.icon = button:CreateTexture(nil, 'ARTWORK')
			button.icon:SetAllPoints()
			button.icon:SetTexture(debuff.icon)

			button.overlay = button:CreateTexture(nil, 'OVERLAY')
			button.overlay:SetAllPoints()
			button.overlay:SetTexture([[Interface\AddOns\SpartanUI\images\border]])

			if DB.showType then
				-- Color border by debuff type
				local color = DebuffTypeColor[debuff.type] or {r = 0.8, g = 0, b = 0}
				button.overlay:SetVertexColor(color.r, color.g, color.b)
			end

			element.previewButtons[i] = button
		end
	end

	-- Position debuff icons
	for i, button in ipairs(element.previewButtons) do
		button:SetSize(DB.size, DB.size)
		button:ClearAllPoints()

		if i == 1 then
			button:SetPoint(DB.position.anchor, previewFrame, DB.position.relativePoint or DB.position.anchor, 0, 0)
		else
			local prevButton = element.previewButtons[i - 1]
			local row = math.floor((i - 1) / (DB.number / DB.rows))
			local col = (i - 1) % (DB.number / DB.rows)

			if col == 0 and i > 1 then
				-- New row
				local yOffset = 0
				if DB.growthy == 'UP' then
					yOffset = (DB.spacing + DB.size) * row
				else
					yOffset = -(DB.spacing + DB.size) * row
				end
				button:SetPoint(DB.position.anchor, previewFrame, DB.position.relativePoint or DB.position.anchor, 0, yOffset)
			else
				local xOffset = DB.spacing
				if DB.growthx == 'LEFT' then
					button:SetPoint('RIGHT', prevButton, 'LEFT', -DB.spacing, 0)
				else
					button:SetPoint('LEFT', prevButton, 'RIGHT', DB.spacing, 0)
				end
			end
		end

		button:Show()
	end

	return (DB.size + DB.spacing) * DB.rows
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.Debuffs[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Debuffs[option] = val
		--Update the screen
		UF.Unit[unitName]:ElementUpdate('Debuffs')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Debuffs
end

---@type SUI.UF.Elements.Settings
local Settings = {
	number = 10,
	size = 20,
	spacing = 1,
	width = false,
	ShowBoss = true,
	showType = true,
	growthx = 'LEFT',
	growthy = 'UP',
	rows = 2,
	position = {
		anchor = 'TOPRIGHT',
		relativePoint = 'BOTTOMRIGHT'
	},
	rules = {
		duration = {
			enabled = true,
			maxTime = 180,
			minTime = 1
		},
		isBossAura = true
	},
	config = {
		type = 'Auras'
	},
	showInPreview = false
}
UF.Elements:Register('Debuffs', Build, Update, Options, Settings, Preview)
