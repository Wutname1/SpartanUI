local UF = SUI.UF

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
		Bar:SetStatusBarTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')

		-- Position and size.
		Bar:SetSize(DB.width, DB.height)
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
		element[1]:SetPoint(
			DB.position.anchor,
			frame,
			DB.position.relativePoint or DB.position.anchor,
			DB.position.x,
			DB.position.y
		)
	else
		element[1]:SetPoint(
			DB.position.anchor,
			frame[DB.position.relativeTo],
			DB.position.relativePoint or DB.position.anchor,
			DB.position.x,
			DB.position.y
		)
	end
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
end

UF.Elements:Register('ClassPower', Build, Update, Options)
