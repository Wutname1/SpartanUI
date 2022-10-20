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
	BorderColor = {0, 0, 0, 1},
	TxBlank = 'Interface\\Addons\\SpartanUI\\images\\blank',
	bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
	edgeFile = 'Interface\\BUTTONS\\WHITE8X8'
}

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

local function BlizzardRegions(frame, name, kill, zero)
	if not name then
		name = frame.GetName and frame:GetName()
	end
	for _, area in pairs(BlizzardRegionList) do
		local object = (name and _G[name .. area]) or frame[area]
		if object then
			if kill then
				object:Kill()
			elseif zero then
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

local function SetOutside(obj, anchor, xOffset, yOffset, anchor2, noScale)
	if not anchor then
		anchor = obj:GetParent()
	end

	if not xOffset then
		xOffset = 0
	end
	if not yOffset then
		yOffset = 0
	end
	local x = (noScale and xOffset) or 1
	local y = (noScale and yOffset) or 1

	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -x, y)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', x, -y)
end

local function SetInside(obj, anchor, xOffset, yOffset, anchor2, noScale)
	if not anchor then
		anchor = obj:GetParent()
	end

	if not xOffset then
		xOffset = 0
	end
	if not yOffset then
		yOffset = 0
	end
	local x = (noScale and xOffset) or 1
	local y = (noScale and yOffset) or 1

	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', x, -y)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', -x, y)
end

function module.SetTemplate(
	frame,
	template,
	glossTex,
	ignoreUpdates,
	forcePixelMode,
	isUnitFrameElement,
	isNamePlateElement,
	noScale)
	-- GetTemplate(template, isUnitFrameElement)

	frame.template = template or 'Default'
	frame.glossTex = glossTex
	frame.ignoreUpdates = ignoreUpdates
	frame.forcePixelMode = forcePixelMode
	frame.isUnitFrameElement = isUnitFrameElement
	frame.isNamePlateElement = isNamePlateElement

	if not frame.SetBackdrop then
		_G.Mixin(frame, _G.BackdropTemplateMixin)
		frame:HookScript('OnSizeChanged', frame.OnBackdropSizeChanged)
	end

	if template == 'NoBackdrop' then
		frame:SetBackdrop()
	else
		local edgeSize = 1

		frame:SetBackdrop(
			{
				bgFile = Settings.bgFile,
				edgeFile = Settings.edgeFile,
				edgeSize = edgeSize
			}
		)

		if frame.callbackBackdropColor then
			frame:callbackBackdropColor()
		else
			frame:SetBackdropColor(0, 0, 0, 1)
		end

		local notPixelMode = not isUnitFrameElement and not isNamePlateElement
		if notPixelMode and not forcePixelMode then
			local backdrop = {
				edgeFile = Settings.edgeFile,
				edgeSize = 1
			}

			local level = frame:GetFrameLevel()
			if not frame.iborder then
				local border = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
				border:SetBackdrop(backdrop)
				border:SetBackdropBorderColor(0, 0, 0, 1)
				border:SetFrameLevel(level)
				SetInside(border, frame, 1, 1, nil, noScale)
				frame.iborder = border
			end

			if not frame.oborder then
				local border = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
				border:SetBackdrop(backdrop)
				border:SetBackdropBorderColor(0, 0, 0, 1)
				border:SetFrameLevel(level)
				SetOutside(border, frame, 1, 1, nil, noScale)
				frame.oborder = border
			end
		end
	end

	frame:SetBackdropBorderColor(0, 0, 0, 1)

	-- if not frame.ignoreUpdates then
	-- 	if frame.isUnitFrameElement then
	-- 		E.unitFrameElements[frame] = true
	-- 	else
	-- 		E.frames[frame] = true
	-- 	end
	-- end
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
Settings.rgbcolor = module.colors.SetColorTable(Settings.rgbcolor, value)
-- Settings.hexcolor = module.colors.RGBToHex(value.r, value.g, value.b)

module.Objects = {}
function module.Objects.Button(
	button,
	strip,
	isDecline,
	noStyle,
	createBackdrop,
	template,
	noGlossTex,
	overrideTex,
	frameLevel,
	regionsKill,
	regionsZero)
	assert(button, 'doesnt exist!')

	if button.isSkinned then
		return
	end

	if button.SetNormalTexture and not overrideTex then
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

	if strip then
		module.RemoveAllTextures(button)
	end

	BlizzardRegions(button, nil, regionsKill, regionsZero)

	-- if button.Icon then
	-- 	local Texture = button.Icon:GetTexture()
	-- 	if Texture and (type(Texture) == 'string' and strfind(Texture, [[Interface\ChatFrame\ChatFrameExpandArrow]])) then
	-- 		button.Icon:SetTexture(E.Media.Textures.ArrowUp)
	-- 		button.Icon:SetRotation(S.ArrowRotation.right)
	-- 		button.Icon:SetVertexColor(1, 1, 1)
	-- 	end
	-- end

	if isDecline and button.Icon then
	-- button.Icon:SetTexture(E.Media.Textures.Close)
	end

	if createBackdrop then
	-- button:CreateBackdrop(template, not noGlossTex, nil, nil, nil, nil, nil, true, frameLevel)
	end

	if button.Text then
		SUI:FormatFont(button.Text, 12, 'Blizzard')
	end

	local function SetBackdropBorderColor(frame, script)
		if frame.backdrop then
			frame = frame.backdrop
		end
		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(unpack(script == 'OnEnter' and Settings.rgbcolor or Settings.BorderColor))
		end
	end

	function SetModifiedBackdrop(self)
		if self:IsEnabled() then
			SetBackdropBorderColor(self, 'OnEnter')
		end
	end

	function SetOriginalBackdrop(self)
		if self:IsEnabled() then
			SetBackdropBorderColor(self, 'OnLeave')
		end
	end

	function SetDisabledBackdrop(self)
		if self:IsMouseOver() then
			SetBackdropBorderColor(self, 'OnDisable')
		end
	end

	module.SetTemplate(button)

	button:HookScript('OnEnter', SetModifiedBackdrop)
	button:HookScript('OnLeave', SetOriginalBackdrop)
	button:HookScript('OnDisable', SetDisabledBackdrop)

	button.isSkinned = true
end

function module.SkinObj(ObjType, object)
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
	object:SetBackdropColor(unpack(Settings.BackdropColor))
	object:SetBackdropBorderColor(unpack(Settings.BorderColor))
end
