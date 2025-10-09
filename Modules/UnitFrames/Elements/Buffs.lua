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
	--Buff Icons
	local element = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame.raised)
	element.PostUpdateButton = function(self, button, unit, data, position)
		button.data = data
		button.unit = unit
	end
	element.PostCreateButton = function(self, button)
		UF.Auras:PostCreateButton('Buffs', button)
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
	frame.Buffs = element
end

---@param frame table
---@param settings? table
local function Update(frame, settings)
	local element = frame.Buffs
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
	if not previewFrame.Buffs then
		local element = CreateFrame('Frame', frameName .. 'Buffs', previewFrame)
		previewFrame.Buffs = element
	end

	local element = previewFrame.Buffs
	element:Show()

	-- Create sample buff icons
	if not element.previewButtons then
		element.previewButtons = {}
		-- Sample buffs with real spell icons
		local sampleBuffs = {
			{icon = 136081, count = nil}, -- Rejuvenation
			{icon = 135953, count = nil}, -- Renew
			{icon = 136078, count = 3} -- Mark of the Wild with count
		}

		for i, buff in ipairs(sampleBuffs) do
			local button = CreateFrame('Frame', nil, element)
			button:SetSize(DB.size, DB.size)

			button.icon = button:CreateTexture(nil, 'ARTWORK')
			button.icon:SetAllPoints()
			button.icon:SetTexture(buff.icon)

			button.overlay = button:CreateTexture(nil, 'OVERLAY')
			button.overlay:SetAllPoints()
			button.overlay:SetTexture([[Interface\AddOns\SpartanUI\images\border]])

			if buff.count then
				button.count = button:CreateFontString(nil, 'OVERLAY')
				SUI.Font:Format(button.count, 12, 'UnitFrames')
				button.count:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -1, 1)
				button.count:SetText(buff.count)
			end

			element.previewButtons[i] = button
		end
	end

	-- Position buff icons based on growth settings
	for i, button in ipairs(element.previewButtons) do
		button:SetSize(DB.size, DB.size)
		button:ClearAllPoints()

		if i == 1 then
			button:SetPoint(DB.position.anchor, previewFrame, DB.position.relativePoint or DB.position.anchor, 0, 0)
		else
			local prevButton = element.previewButtons[i - 1]
			local xOffset = 0
			local yOffset = 0

			if DB.growthx == 'RIGHT' then
				xOffset = DB.spacing + DB.size
			elseif DB.growthx == 'LEFT' then
				xOffset = -(DB.spacing + DB.size)
			end

			if DB.growthy == 'DOWN' then
				yOffset = -(DB.spacing + DB.size)
			elseif DB.growthy == 'UP' then
				yOffset = DB.spacing + DB.size
			end

			-- Handle rows
			local row = math.floor((i - 1) / (DB.number / DB.rows))
			local col = (i - 1) % (DB.number / DB.rows)

			if col == 0 and i > 1 then
				-- New row
				button:SetPoint(DB.position.anchor, previewFrame, DB.position.relativePoint or DB.position.anchor, 0, yOffset * row)
			else
				button:SetPoint('LEFT', prevButton, 'RIGHT', DB.spacing, 0)
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
		UF.CurrentSettings[unitName].elements.Buffs[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Buffs[option] = val
		--Update the screen
		UF.Unit[unitName]:ElementUpdate('Buffs')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Buffs
end

---@type SUI.UF.Elements.Settings
local Settings = {
	number = 10,
	size = 20,
	spacing = 1,
	showType = true,
	width = false,
	growthx = 'RIGHT',
	growthy = 'DOWN',
	rows = 2,
	position = {
		anchor = 'TOPLEFT',
		relativePoint = 'BOTTOMLEFT'
	},
	config = {
		type = 'Auras'
	},
	rules = {
		duration = {
			enabled = true,
			maxTime = 180,
			minTime = 1
		},
		isBossAura = true,
		showPlayers = true
	},
	showInPreview = false
}
UF.Elements:Register('Buffs', Build, Update, Options, Settings, Preview)
