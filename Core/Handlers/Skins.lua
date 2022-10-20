---@class SUI
local SUI = SUI
local module = SUI:NewModule('Handler_Skins')
SUI.Skins = module
local BlizzardRegionList = {
	'Left',
	'Middle',
	'Right',
	'Mid',
	'LeftDisabled',
	'MiddleDisabled',
	'RightDisabled',
	'TopLeft',
	'TopRight',
	'BottomLeft',
	'BottomRight',
	'TopMiddle',
	'MiddleLeft',
	'MiddleRight',
	'BottomMiddle',
	'MiddleMiddle',
	'TabSpacer',
	'TabSpacer1',
	'TabSpacer2',
	'_RightSeparator',
	'_LeftSeparator',
	'Cover',
	'Border',
	'Background',
	'TopTex',
	'TopLeftTex',
	'TopRightTex',
	'LeftTex',
	'BottomTex',
	'BottomLeftTex',
	'BottomRightTex',
	'RightTex',
	'MiddleTex',
	'Center'
}

local Settings = {
	BackdropColor = {0.0588, 0.0588, 0, 0.8},
	BackdropColorDark = {.5, 0.5, .5, .9},
	BackdropColorLight = {.5, 0.5, .5, .4},
	BaseBorderColor = {1, 1, 1, .3},
	ObjBorderColor = {1, 1, 1, .5},
	factionColor = {
		Alliance = {0, .6, 1, .5},
		Horde = {1, .2, .2, .5}
	},
	TxBlank = 'Interface\\Addons\\SpartanUI\\images\\blank',
	bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
	edgeFile = 'Interface\\BUTTONS\\WHITE8X8'
}
---@class AppearanceMode
local AppearanceMode = {
	Default = 'Default',
	Dark = 'Dark',
	Light = 'Light',
	NoBackdrop = 'NoBackdrop'
}

local function GetBaseBorderColor()
	return Settings.BaseBorderColor or Settings.factionColor[UnitFactionGroup('player')]
end

local function GetClassColor()
	local _, class = UnitClass('player')

	local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class]) or _G.RAID_CLASS_COLORS[class]
	if type(color) ~= 'table' then
		return
	end

	if not color.colorStr then
		color.colorStr = module.colors.RGBToHex(color.r, color.g, color.b, 'ff')
	elseif strlen(color.colorStr) == 6 then
		color.colorStr = 'ff' .. color.colorStr
	end

	return color
end

module.colors = {}
function module.colors.SetColorTable(t, data)
	if not data.r or not data.g or not data.b then
		error('SetColorTable: Could not unpack color values.')
	end

	if t and (type(t) == 'table') then
		t[1], t[2], t[3], t[4] = module.colors.UpdateColorTable(data)
	else
		t = module.colors.GetColorTable(data)
	end

	return t
end

function module.colors.UpdateColorTable(data)
	if not data.r or not data.g or not data.b then
		error('UpdateColorTable: Could not unpack color values.')
	end

	if data.r > 1 or data.r < 0 then
		data.r = 1
	end
	if data.g > 1 or data.g < 0 then
		data.g = 1
	end
	if data.b > 1 or data.b < 0 then
		data.b = 1
	end
	if data.a and (data.a > 1 or data.a < 0) then
		data.a = 1
	end

	if data.a then
		return data.r, data.g, data.b, data.a
	else
		return data.r, data.g, data.b
	end
end

function module.colors.GetColorTable(data)
	if not data.r or not data.g or not data.b then
		error('GetColorTable: Could not unpack color values.')
	end

	if data.r > 1 or data.r < 0 then
		data.r = 1
	end
	if data.g > 1 or data.g < 0 then
		data.g = 1
	end
	if data.b > 1 or data.b < 0 then
		data.b = 1
	end
	if data.a and (data.a > 1 or data.a < 0) then
		data.a = 1
	end

	if data.a then
		return {data.r, data.g, data.b, data.a}
	else
		return {data.r, data.g, data.b}
	end
end

function module.colors.RGBToHex(r, g, b, header)
	r = r <= 1 and r >= 0 and r or 1
	g = g <= 1 and g >= 0 and g or 1
	b = b <= 1 and b >= 0 and b or 1
	return format('%02x%02x%02x', header or '|cff', r * 255, g * 255, b * 255)
end

function module.colors.HexToRGB(hex)
	local a, r, g, b = strmatch(hex, '^|?c?(%x%x)(%x%x)(%x%x)(%x?%x?)|?r?$')
	if not a then
		return 0, 0, 0, 0
	end
	if b == '' then
		r, g, b, a = a, r, g, 'ff'
	end

	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16)
end

local value = GetClassColor()
Settings.ClassColor = module.colors.SetColorTable(Settings.ClassColor, value)
Settings.MutedClassColor = module.colors.SetColorTable(Settings.MutedClassColor, value)
Settings.MutedClassColor[4] = 0.3

local function SetClassBorderColor(frame, script)
	if frame.backdrop then
		frame = frame.backdrop
	end
	if frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(unpack(script == 'OnEnter' and Settings.ClassColor or Settings.MutedClassColor))
	end
end

local function RemoveBlizzardRegions(frame, name, fadeOut)
	if not name then
		name = frame.GetName and frame:GetName()
	end
	for _, area in pairs(BlizzardRegionList) do
		local object = (name and _G[name .. area]) or frame[area]
		if object then
			if fadeOut then
				object:SetAlpha(0)
			else
				object:Hide()
			end
		end
	end
end

function module.RemoveTextures(frame, option)
	if ((not frame.GetNumRegions) or (frame.Panel and (not frame.Panel.CanBeRemoved))) then
		return
	end
	local region, layer, texture
	for i = 1, frame:GetNumRegions() do
		region = select(i, frame:GetRegions())
		if (region and (region:GetObjectType() == 'Texture')) then
			layer = region:GetDrawLayer()
			texture = region:GetTexture()

			if (option) then
				-- elseif texture ~= 'Interface\\DialogFrame\\UI-DialogBox-Background' then
				if (type(option) == 'boolean') then
					if region.UnregisterAllEvents then
						region:UnregisterAllEvents()
						region:SetParent(nil)
					else
						region.Show = region.Hide
					end
					region:Hide()
				elseif (type(option) == 'string' and ((layer == option) or (texture ~= option))) then
					region:SetTexture('')
				end
			else
				region:SetTexture('')
			end
		end
	end
end

function module.RemoveAllTextures(frame)
	for i = 1, frame:GetNumChildren() do
		local childFrame = select(i, frame:GetChildren())
		if childFrame:GetObjectType() == 'Button' and childFrame:GetText() then
			-- Widget_ButtonStyle(childFrame)
		elseif not childFrame.ignore then
			module.RemoveTextures(childFrame)
		end
	end
end

---comment
---@param frame FrameExpanded
---@param appearanceMode? AppearanceMode
function module.SetTemplate(frame, appearanceMode)
	frame.appearanceMode = appearanceMode or 'Default'

	if not frame.SetBackdrop then
		_G.Mixin(frame, _G.BackdropTemplateMixin)
		frame:HookScript('OnSizeChanged', frame.OnBackdropSizeChanged)
	end

	local edgeSize = 1
	if frame.appearanceMode == AppearanceMode.NoBackdrop then
		frame:SetBackdrop(nil)
	else
		frame:SetBackdrop(
			{
				bgFile = Settings.bgFile,
				edgeFile = Settings.edgeFile,
				edgeSize = edgeSize
			}
		)

		if frame.appearanceMode == AppearanceMode.Dark then
			frame:SetBackdropColor(unpack(Settings.BackdropColorDark))
		elseif frame.appearanceMode == AppearanceMode.Light then
			frame:SetBackdropColor(unpack(Settings.BackdropColorLight))
		else
			frame:SetBackdropColor(unpack(Settings.BackdropColor))
		end
	end

	frame:SetBackdropBorderColor(unpack(Settings.MutedClassColor))
end

module.Objects = {}

function module.Objects.Button(button, clean, NormalTex, regionsToFade)
	if button.isSkinned then
		return
	end

	if button.SetNormalTexture and not NormalTex then
		button:SetNormalTexture('')
	end
	if button.SetHighlightTexture then
		button:SetHighlightTexture(Settings.bgFile)
	end
	if button.SetPushedTexture then
		button:SetPushedTexture(Settings.bgFile)
	end
	if button.SetDisabledTexture then
		button:SetDisabledTexture(Settings.bgFile)
	end

	if clean then
		module.RemoveAllTextures(button)
	end

	RemoveBlizzardRegions(button, nil, regionsToFade)

	if button.Text then
		SUI:FormatFont(button.Text, 12, 'Blizzard')
	end

	function SetModifiedBackdrop(self)
		if self:IsEnabled() then
			SetClassBorderColor(self, 'OnEnter')
		end
	end

	function SetOriginalBackdrop(self)
		if self:IsEnabled() then
			SetClassBorderColor(self, 'OnLeave')
		end
	end

	function SetDisabledBackdrop(self)
		if self:IsMouseOver() then
			SetClassBorderColor(self, 'OnDisable')
		end
	end

	module.SetTemplate(button)

	button:HookScript('OnEnter', SetModifiedBackdrop)
	button:HookScript('OnLeave', SetOriginalBackdrop)
	button:HookScript('OnDisable', SetDisabledBackdrop)

	button.isSkinned = true
end

---Skins a object
---@param ObjType string
---@param object FrameExpanded
---@param mode AppearanceMode
function module.SkinObj(ObjType, object, mode)
	if not object then
		return
	end
	if ObjType and module.Objects[ObjType] then
		module.Objects[ObjType](object)
		return
	end

	if not object.SetBackdrop then
		Mixin(object, BackdropTemplateMixin)
	end

	object:SetBackdrop(
		{
			bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
			edgeFile = 'Interface\\BUTTONS\\WHITE8X8',
			edgeSize = 1,
			TileSize = 20
		}
	)
	if mode and mode == AppearanceMode.Dark then
		object:SetBackdropColor(unpack(Settings.BackdropColorDark))
	elseif mode and mode == AppearanceMode.Light then
		object:SetBackdropColor(unpack(Settings.BackdropColorLight))
	else
		object:SetBackdropColor(unpack(Settings.BackdropColor))
	end

	object:SetBackdropBorderColor(unpack(GetBaseBorderColor()))
end
