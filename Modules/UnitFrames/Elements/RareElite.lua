local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	-- Create a frame container so we can control strata/level for texture mode
	local container = CreateFrame('Frame', nil, frame.SpartanArt)
	container:SetFrameStrata('BACKGROUND')
	container:SetFrameLevel(5)
	container:SetAllPoints(frame.SpartanArt)

	local texture = container:CreateTexture(nil, 'ARTWORK')
	texture:SetTexture('Interface\\Addons\\SpartanUI\\images\\blank')

	-- Store references
	frame.RareElite = texture
	frame.RareElite.container = container

	-- Apply mode setting if available (for oUF plugin)
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
	element.mode = DB.mode or 'background'
	element.alpha = DB.alpha or 0.4

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
			['background'] = 'Background Overlay',
			['texture'] = 'Dragon Texture (Classic)',
		},
		get = function()
			return DB.mode or 'background'
		end,
		set = function(_, val)
			OptUpdate('mode', val)
		end,
	}
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	alpha = 0.4,
	mode = 'background', -- 'background' or 'texture'
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
