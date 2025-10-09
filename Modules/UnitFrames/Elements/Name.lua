local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.Name = frame.raised:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(frame.Name, DB.textSize, 'UnitFrames')
	frame.Name:SetSize(frame:GetWidth(), 12)
	frame.Name:SetJustifyH(DB.SetJustifyH)
	frame.Name:SetJustifyV(DB.SetJustifyV)

	-- Position the name element based on position settings
	if DB.position then
		local relativeTo = frame
		local relativePoint = DB.position.anchor

		-- Handle nameplate-style positioning with relativeTo and relativePoint
		if DB.position.relativeTo and DB.position.relativePoint then
			if DB.position.relativeTo == 'Frame' then
				relativeTo = frame
			end
			relativePoint = DB.position.relativePoint
		end

		frame.Name:SetPoint(DB.position.anchor, relativeTo, relativePoint, DB.position.x or 0, DB.position.y or 0)
	end

	frame:Tag(frame.Name, DB.text)
end

---@param frame table
local function Update(frame)
	local DB = frame.Name.DB
	SUI.Font:Format(frame.Name, DB.textSize, 'UnitFrames')
	frame.Name:SetJustifyH(DB.SetJustifyH)
	frame.Name:SetJustifyV(DB.SetJustifyV)

	-- Update positioning
	if DB.position then
		local relativeTo = frame
		local relativePoint = DB.position.anchor

		-- Handle nameplate-style positioning with relativeTo and relativePoint
		if DB.position.relativeTo and DB.position.relativePoint then
			if DB.position.relativeTo == 'Frame' then
				relativeTo = frame
			end
			relativePoint = DB.position.relativePoint
		end

		frame.Name:ClearAllPoints()
		frame.Name:SetPoint(DB.position.anchor, relativeTo, relativePoint, DB.position.x or 0, DB.position.y or 0)
	end

	frame:Tag(frame.Name, DB.text)
end

---@param frameName string
---@param OptionSet AceConfig.OptionsTable
local function Options(frameName, OptionSet)
	UF.Options:TextBasicDisplay(frameName, OptionSet)
end

---@param previewFrame frame The preview frame to render into
---@param DB table Element settings
---@param frameName UnitFrameName The frame name being previewed
local function Preview(previewFrame, DB, frameName)
	-- Create name text preview
	local name = previewFrame.Name or previewFrame:CreateFontString(nil, 'OVERLAY')
	SUI.Font:Format(name, DB.textSize, 'UnitFrames')
	name:SetSize(previewFrame:GetWidth(), 12)
	name:SetJustifyH(DB.SetJustifyH)
	name:SetJustifyV(DB.SetJustifyV)

	-- Position the name element
	name:ClearAllPoints()
	if DB.position then
		local relativeTo = previewFrame
		local relativePoint = DB.position.anchor

		if DB.position.relativeTo and DB.position.relativePoint then
			if DB.position.relativeTo == 'Frame' then
				relativeTo = previewFrame
			end
			relativePoint = DB.position.relativePoint
		end

		name:SetPoint(DB.position.anchor, relativeTo, relativePoint, DB.position.x or 0, DB.position.y or 0)
	end

	-- Set preview text based on frame name
	local previewText = frameName:gsub('^%l', string.upper) -- Capitalize first letter
	if frameName == 'player' then
		previewText = UnitName('player')
	elseif frameName == 'target' then
		previewText = 'Target Dummy'
	elseif frameName == 'pet' then
		previewText = 'Pet'
	elseif frameName == 'boss' or frameName:match('^boss%d') then
		previewText = 'Boss Name'
	elseif frameName:match('^party%d') then
		previewText = 'Party Member'
	elseif frameName:match('^raid%d') then
		previewText = 'Raid Member'
	end

	-- Apply class coloring if the tag includes SUI_ColorClass
	if DB.text and DB.text:find('SUI_ColorClass') then
		local _, class = UnitClass('player')
		local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class]) or _G.RAID_CLASS_COLORS[class]
		if color then
			name:SetTextColor(color.r, color.g, color.b)
		end
	else
		name:SetTextColor(1, 1, 1)
	end

	name:SetText(previewText)
	name:Show()

	previewFrame.Name = name

	return 0 -- Name doesn't contribute to height calculation
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	showInPreview = true, -- Name is always visible
	width = false,
	height = 12,
	textSize = 12,
	text = '[difficulty][smartlevel] [SUI_ColorClass][name]',
	SetJustifyH = 'CENTER',
	SetJustifyV = 'MIDDLE',
	position = {
		anchor = 'TOP',
		x = 0,
		y = 15
	},
	config = {
		type = 'Indicator'
	}
}

UF.Elements:Register('Name', Build, Update, Options, Settings, Preview)
