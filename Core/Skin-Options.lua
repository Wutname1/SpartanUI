--Cache global variables and Lua functions
local _G, SUI, Lib, StdUi = _G, SUI, SUI.Lib, SUI.StdUi
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
	object:SetBackdropColor(0.0588, 0.0588, 0, 0.8)
	object:SetBackdropBorderColor(0, 0, 0, 1)
end

local function GetAce3ConfigWindow(name)
	local ConfigOpen = Lib.AceCD and Lib.AceCD.OpenFrames and Lib.AceCD.OpenFrames[name]
	return ConfigOpen and ConfigOpen.frame
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

	--Skin main window elements
	RegisterAsContainer = function(self, widget)
		local widgetType = widget.type
		local widgetParent = widget.content:GetParent()

		if widgetType == 'ScrollFrame' then
			module:Skin('ScrollBar', widget.scrollBar)
		elseif widgetType == 'Frame' then
			local frame = widget.frame

			if not frame.AppBar then
				local AppBar = StdUi:Panel(frame, frame:GetWidth(), 22)
				AppBar:SetFrameLevel(500)
				AppBar:SetPoint('TOPRIGHT', 0, 0)
				AppBar:SetPoint('TOPLEFT', 0, 0)
				AppBar.ignore = true

				local closeBtn = StdUi:HighlightButton(AppBar, 28, 20, 'X')
				closeBtn.text:SetFontSize(15)
				closeBtn:SetPoint('TOPRIGHT', -1, -1)
				closeBtn:SetScript(
					'OnClick',
					function(self)
						frame.CloseBtn:Click()
					end
				)
				AppBar.closeBtn = closeBtn

				-- local minimizeBtn = StdUi:HighlightButton(AppBar, 28, 20, '_')
				-- minimizeBtn.text:SetFontSize(13)
				-- minimizeBtn:SetPoint('TOPRIGHT', -30, -1)
				-- minimizeBtn.IsMinimized = false
				-- minimizeBtn:SetScript(
				-- 	'OnClick',
				-- 	function(self)
				-- 		if minimizeBtn.IsMinimized then
				-- 			widgetParent:Show()
				-- 		else
				-- 			widgetParent:Hide()
				-- 		end
				-- 		self.IsMinimized = not minimizeBtn.IsMinimized
				-- 	end
				-- )
				-- minimizeBtn:SetFrameLevel(5)
				-- AppBar.minimizeBtn = minimizeBtn

				-- Re-Create FontString to change its frame level
				widget.titletext = AppBar:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
				widget.titletext:SetPoint('TOP', AppBar, 'TOP', 0, -5)
				SUI:FormatFont(widget.titletext, 13)

				frame.AppBar = AppBar

				frame:SetMovable(true)
				frame:EnableMouse(true)
				frame:SetClampedToScreen(true)
				frame:RegisterForDrag('LeftButton')
				frame:SetScript('OnDragStart', frame.StartMoving)
				frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
			end

			RemoveTextures(frame)
			module:Skin('Window', frame)

			for i = 1, widgetParent:GetNumChildren() do
				local childFrame = select(i, widgetParent:GetChildren())
				if childFrame:GetObjectType() == 'Button' and childFrame:GetText() then
					-- Widget_ButtonStyle(childFrame)
				elseif not childFrame.ignore then
					RemoveTextures(childFrame)
				end
			end
			module:Skin('Window', widgetParent)
		elseif (ProxyType[widgetType]) then
			if widget.treeframe then
				module:Skin('Frame', widget.border)
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

	--Setup custom buttons
	local frame = GetAce3ConfigWindow()

	local ACD = Lib.AceCD
	if ACD then
		if not ACD.OpenHookedSUISkin then
			hooksecurefunc(Lib.AceCD, 'Open', module.ConfigOpened)
			ACD.OpenHookedSUISkin = true
		end
	end
end

function module:ConfigOpened(name)
	local frame = GetAce3ConfigWindow(name)
	if not frame or frame.Close then
		return
	end

	local Close = StdUi:Button(frame, 150, 20, 'CLOSE')
	Close:HookScript(
		'OnClick',
		function()
			frame.CloseBtn:Click()
		end
	)
	Close:SetPoint('BOTTOMRIGHT', -17, 10)
	Close:SetFrameLevel(500)
	frame.Close = Close

	for i = 1, frame:GetNumChildren() do
		local child = select(i, frame:GetChildren())
		if child:IsObjectType('Button') and child:GetText() == _G.CLOSE then
			frame.CloseBtn = child
			child:Hide()
		-- elseif child:IsObjectType('Frame') or child:IsObjectType('Button') then
		-- 	if child:HasScript('OnMouseUp') then
		-- 		child:HookScript('OnMouseUp', ConfigStopMoving)
		-- 	end
		end
	end
end

local function attemptSkin(AddonName)
	local a = LibStub('AceAddon-3.0'):GetAddon('Skinner', true)
	if a then
		a.prdb.ChatEditBox.skin = false
		a.prdb.DisabledSkins['AceGUI-3.0 (Lib)'] = true
	end

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
