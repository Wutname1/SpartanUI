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
		if index == 1 then
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
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local ElementSettings = UF.CurrentSettings[unitName].elements.ClassPower
	local function OptUpdate(option, val)
		UF.CurrentSettings[unitName].elements.ClassPower[option] = val
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.ClassPower[option] = val
		UF.Unit[unitName]:ElementUpdate('ClassPower')
	end

	OptionSet.args.texture = {
		type = 'select',
		dialogControl = 'LSM30_Statusbar',
		order = 2,
		width = 'double',
		name = L['Bar Texture'],
		desc = L['Select the texture used for the class power bars'],
		values = AceGUIWidgetLSMlists.statusbar,
		get = function()
			return ElementSettings.texture
		end,
		set = function(_, val)
			OptUpdate('texture', val)
		end,
	}

	OptionSet.args.display.args.height = {
		type = 'range',
		order = 1,
		name = L['Height'],
		desc = L['Set the height of the class power bars'],
		min = 1,
		max = 100,
		step = 1,
		get = function()
			return ElementSettings.height
		end,
		set = function(_, val)
			OptUpdate('height', val)
		end,
	}

	OptionSet.args.display.args.width = {
		type = 'range',
		order = 2,
		name = L['Width'],
		desc = L['Set the width of individual class power bars'],
		min = 1,
		max = 100,
		step = 1,
		get = function()
			return ElementSettings.width
		end,
		set = function(_, val)
			OptUpdate('width', val)
		end,
	}

	OptionSet.args.display.args.spacing = {
		type = 'range',
		order = 3,
		name = L['Spacing'],
		desc = L['Set the spacing between class power bars'],
		min = 0,
		max = 20,
		step = 1,
		get = function()
			return ElementSettings.spacing
		end,
		set = function(_, val)
			OptUpdate('spacing', val)
		end,
	}

	OptionSet.args.colors = {
		type = 'group',
		order = 4,
		name = L['Colors'],
		inline = true,
		args = {
			useClassColors = {
				type = 'toggle',
				order = 1,
				name = L['Use Class Colors'],
				desc = L['Use class-specific colors for power bars'],
				get = function()
					return ElementSettings.useClassColors
				end,
				set = function(_, val)
					OptUpdate('useClassColors', val)
				end,
			},
			customColor = {
				type = 'color',
				order = 2,
				name = L['Custom Color'],
				desc = L['Set a custom color for power bars'],
				disabled = function()
					return ElementSettings.useClassColors
				end,
				get = function()
					return unpack(ElementSettings.customColor or { 1, 1, 1 })
				end,
				set = function(_, r, g, b)
					OptUpdate('customColor', { r, g, b })
				end,
			},
		},
	}
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	width = 16,
	height = 5,
	position = {
		anchor = 'TOPLEFT',
		relativeTo = 'Name',
		relativePoint = 'BOTTOMLEFT',
		y = -5,
	},
	config = {
		NoBulkUpdate = true,
		type = 'Indicator',
		DisplayName = 'Class Power',
		Description = 'Controls the display of Combo Points, Arcane Charges, Chi Orbs, Holy Power, and Soul Shards',
	},
}

UF.Elements:Register('ClassPower', Build, Update, Options, Settings)
