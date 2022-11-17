local UF, L = SUI.UF, SUI.L

---@param frame table
---@param DB table
local function Build(frame, DB)
	if frame.unitOnCreate ~= 'player' then
		return
	end
	frame.CPAnchor = frame:CreateFontString(nil, 'BORDER')
	frame.CPAnchor:SetPoint('TOPLEFT', frame.Name, 'BOTTOMLEFT', 40, -5)
	local ClassPower = {}
	for index = 1, 10 do
		local Bar = CreateFrame('StatusBar', nil, frame)
		Bar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))

		-- Position and size.
		if (index == 1) then
			Bar:SetPoint('LEFT', frame.CPAnchor, 'RIGHT', (index - 1) * Bar:GetWidth(), -1)
		else
			Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 3, 0)
		end
		ClassPower[index] = Bar
	end

	-- Register with oUF
	frame.ClassPower = ClassPower
end

---@param frame table
local function Update(frame)
	local element = frame.ClassPower
	local DB = element.DB

	if DB.position.relativeTo == 'Frame' then
		element[1]:SetPoint(DB.position.anchor, frame, DB.position.relativePoint or DB.position.anchor, DB.position.x, DB.position.y)
	else
		element[1]:SetPoint(DB.position.anchor, frame[DB.position.relativeTo], DB.position.relativePoint or DB.position.anchor, DB.position.x, DB.position.y)
	end

	for i = 1, #element do
		element[i]:SetSize(DB.width, DB.height)
		element[i]:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	end
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	OptionSet.args.texture = {
		type = 'select',
		dialogControl = 'LSM30_Statusbar',
		order = 2,
		width = 'double',
		name = 'Bar Texture',
		values = AceGUIWidgetLSMlists.statusbar
	}
	OptionSet.args.display.args.size = nil
	OptionSet.args.display.args.height = {
		type = 'range',
		order = 1,
		name = L['Height'],
		min = 1,
		max = 100,
		step = 1
	}
end

---@type SUI.UnitFrame.Elements.Settings
local Settings = {
	enabled = true,
	width = 16,
	height = 5,
	position = {
		anchor = 'TOPLEFT',
		relativeTo = 'Name',
		relativePoint = 'BOTTOMLEFT',
		y = -5
	},
	config = {
		NoBulkUpdate = true,
		type = 'Indicator',
		DisplayName = 'Class Power',
		Description = 'Controls the display of Combo Points, Arcane Charges, Chi Orbs, Holy Power, and Soul Shards'
	}
}

UF.Elements:Register('ClassPower', Build, Update, Options, Settings)
