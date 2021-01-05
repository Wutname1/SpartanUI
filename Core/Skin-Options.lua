--Cache global variables and Lua functions
local _G, SUI = _G, SUI
local module = SUI:NewModule('Handler_Skinning')

local RegisterAsContainer

local function RemoveTextures(frame, option)
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
						region:SetParent(_purgatory)
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

function module:Skin(ObjType, object)
	if not object then
		return
	end
	if not object.SetBackdropBorderColor then
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
	object:SetBackdropColor(0.0588, 0.0588, 0, 0.8)
	object:SetBackdropBorderColor(0, 0, 0, 1)
end

function module:SkinAce3()
	local AceGUI = LibStub('AceGUI-3.0', true)
	if not AceGUI then
		return
	end

	local ProxyType = {
		['InlineGroup'] = true,
		['TreeGroup'] = true,
		['TabGroup'] = true,
		['SimpleGroup'] = true,
		['DropdownGroup'] = true
	}

	local regWidget = AceGUI.RegisterAsWidget
	local regContainer = AceGUI.RegisterAsContainer

	RegisterAsContainer = function(self, widget)
		local widgetType = widget.type
		local widgetParent = widget.content:GetParent()
		if widgetType == 'ScrollFrame' then
			module:Skin('ScrollBar', widget.scrollBar)
		elseif widgetType == 'Frame' then
			for i = 1, widgetParent:GetNumChildren() do
				local childFrame = select(i, widgetParent:GetChildren())
				if childFrame:GetObjectType() == 'Button' and childFrame:GetText() then
					-- Widget_ButtonStyle(childFrame)
				else
					RemoveTextures(childFrame)
				end
			end
			module:Skin('Window', widgetParent)
		elseif (ProxyType[widgetType]) then
			if widget.treeframe then
				module:Skin('Frame', widget.treeframe)
				widgetParent:SetPoint('TOPLEFT', widget.treeframe, 'TOPRIGHT', 1, 0)
				local oldFunc = widget.CreateButton
				widget.CreateButton = function(self)
					local newButton = oldFunc(self)
					RemoveTextures(newButton.toggle)
					newButton.toggle.SetNormalTexture = NOOP
					newButton.toggle.SetPushedTexture = NOOP
					module:Skin('Button', newButton.toggle)
					return newButton
				end
			elseif (not widgetParent.Panel) then
				module:Skin('Frame', widgetParent)
			end

			if (widgetType == 'TabGroup') then
				local oldFunc = widget.CreateTab
				widget.CreateTab = function(self, arg)
					local newTab = oldFunc(self, arg)
					RemoveTextures(newTab)
					module:Skin('Tab', newTab)
					return newTab
				end
			end

			if widget.scrollbar then
				module:Skin('ScrollBar', widget.scrollBar)
			end
		end
		return regContainer(self, widget)
	end
	AceGUI.RegisterAsContainer = RegisterAsContainer
end

local function attemptSkin()
	local AceGUI = LibStub('AceGUI-3.0', true)
	if AceGUI and (AceGUI.RegisterAsContainer ~= RegisterAsContainer or AceGUI.RegisterAsWidget ~= RegisterAsWidget) then
		if select(4, GetAddOnInfo('ElvUI')) then
			return
		end
		module:SkinAce3()
	end
end

local f = CreateFrame('Frame')
f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', attemptSkin)

SUI.callbacks = LibStub('CallbackHandler-1.0'):New(SUI)
SUI:RegisterCallback('Ace3', attemptSkin)
