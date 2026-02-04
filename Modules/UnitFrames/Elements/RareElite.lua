local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	-- Create texture directly on SpartanArt (simplified from container approach)
	frame.RareElite = frame.SpartanArt:CreateTexture(nil, 'BORDER')
	frame.RareElite:SetTexture('Interface\\Addons\\SpartanUI\\images\\blank')

	-- Apply mode from DB if set
	if DB and DB.mode then
		frame.RareElite.mode = DB.mode
	end
	if DB and DB.alpha then
		frame.RareElite.alpha = DB.alpha
	end
end

---@param frame table
local function Update(frame)
	local element = frame.RareElite
	local DB = element.DB
	if not DB then
		return
	end

	-- Update mode on the element for oUF plugin
	element.mode = DB.mode or 'minimal'
	element.alpha = DB.alpha or 0.3

	-- Force update the oUF element
	if element.ForceUpdate then
		element:ForceUpdate()
	end
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.RareElite[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.RareElite[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('RareElite')
	end

	local DB = UF.CurrentSettings[unitName].elements.RareElite

	OptionSet.args.mode = {
		name = 'Display Mode',
		type = 'select',
		order = 10,
		values = {
			['minimal'] = 'Minimal (Color Overlay)',
			['dragon'] = 'Dragon Texture',
		},
		get = function()
			return DB.mode or 'minimal'
		end,
		set = function(_, val)
			OptUpdate('mode', val)
		end,
	}
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	alpha = 0.3,
	mode = 'minimal', -- 'minimal' or 'dragon'
	points = {
		['1'] = {
			anchor = 'TOPLEFT',
			relativeTo = 'Frame',
			x = 0,
			y = 0,
		},
		['2'] = {
			anchor = 'BOTTOMRIGHT',
			relativeTo = 'Frame',
			x = 0,
			y = 0,
		},
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Rare/Elite',
	},
}

UF.Elements:Register('RareElite', Build, Update, Options, Settings)
