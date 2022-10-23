--Cache global variables and Lua functions
local _G, SUI, Lib, StdUi = _G, SUI, SUI.Lib, SUI.StdUi

local RegisterAsContainer
local RemoveTextures = SUI.Skins.RemoveTextures
local Skin = SUI.Skins.SkinObj

local function GetAce3ConfigWindow(name)
	local ConfigOpen = Lib.AceCD and Lib.AceCD.OpenFrames and Lib.AceCD.OpenFrames[name]
	return ConfigOpen and ConfigOpen.frame
end

local function ConfigOpened(self, name)
	local frame = GetAce3ConfigWindow(name)
	if not frame or frame.Close then
		return
	end
	for i = 1, frame:GetNumChildren() do
		local child = select(i, frame:GetChildren())
		SUI.Debug('Child ' .. (child:GetName() or 'NoName') .. ' ' .. (child:GetObjectType() or 'NoType'), 'Skiner')
		if child:IsObjectType('Button') then
			if child:IsObjectType('Button') and child:GetText() == _G['CLOSE'] then
				SUI.Skins.SkinObj(child:GetObjectType(), child, 'Light')
				child:SetSize(150, 20)
				child:SetPoint('BOTTOMRIGHT', -17, 10)
			else
				child:Hide()
			end
		end
	end
end

local function SkinAce3()
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
			Skin('ScrollBar', widget.scrollBar)
		elseif widgetType == 'Frame' then
			local frame = widget.frame

			if not frame.AppBar then
				local AppBar = StdUi:Panel(frame, frame:GetWidth(), 22)
				AppBar:SetFrameLevel(500)
				AppBar:SetPoint('TOPRIGHT', 0, 0)
				AppBar:SetPoint('TOPLEFT', 0, 0)
				AppBar.ignore = true

				if frame.CloseBtn then
					local closeBtn = StdUi:HighlightButton(AppBar, 28, 20, 'X')
					closeBtn.text:SetFontSize(15)
					closeBtn:SetPoint('TOPRIGHT', -1, -1)
					closeBtn:SetScript(
						'OnClick',
						function()
							frame.CloseBtn:Click()
						end
					)
					AppBar.closeBtn = closeBtn
				end

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
			Skin('Window', frame)

			for i = 1, widgetParent:GetNumChildren() do
				local childFrame = select(i, widgetParent:GetChildren())
				if childFrame:GetObjectType() == 'Button' and childFrame:GetText() then
					-- Widget_ButtonStyle(childFrame)
				elseif not childFrame.ignore then
					RemoveTextures(childFrame)
				end
			end
			Skin('Window', widgetParent)
		elseif (ProxyType[widgetType]) then
			if widget.treeframe then
				Skin('Frame', widget.border)
				Skin('Frame', widget.treeframe)
				widgetParent:SetPoint('TOPLEFT', widget.treeframe, 'TOPRIGHT', 1, 0)
				local oldFunc = widget.CreateButton
				widget.CreateButton = function(self)
					local newButton = oldFunc(self)
					RemoveTextures(newButton.toggle)
					newButton.toggle:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\PlusButton')
					newButton.toggle:SetPushedTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\PushButton')
					hooksecurefunc(
						newButton.toggle,
						'SetNormalTexture',
						function(frame, texture)
							local tex = tostring(frame:GetNormalTexture():GetTexture())
							if tex == '130838' then
								frame:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\PlusButton')
							elseif tex == '130821' then
								frame:SetNormalTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\MinusButton')
							end
						end
					)
					hooksecurefunc(
						newButton.toggle,
						'SetPushedTexture',
						function(frame, texture)
							if not strfind(texture, 'PushButton') then
								frame:SetPushedTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\PushButton')
							end
						end
					)
					Skin('Button', newButton.toggle)
					return newButton
				end
			elseif (not widgetParent.Panel) then
				Skin('Frame', widgetParent)
			end

			if (widgetType == 'TabGroup') then
				local oldFunc = widget.CreateTab
				widget.CreateTab = function(self, arg)
					local newTab = oldFunc(self, arg)
					RemoveTextures(newTab)
					Skin('Tab', newTab)
					return newTab
				end
			end

			if widget.scrollbar then
				Skin('ScrollBar', widget.scrollBar)
			end
		-- else
		-- 	SUI.Debug('No Widget skin ' .. widgetType, 'Skinning')
		end
		return regContainer(self, widget)
	end
	AceGUI.RegisterAsContainer = RegisterAsContainer

	--Setup custom buttons
	local ACD = Lib.AceCD
	if ACD then
		if not ACD.OpenHookedSUISkin then
			hooksecurefunc(Lib.AceCD, 'Open', ConfigOpened)
			ACD.OpenHookedSUISkin = true
		end
	end
end

local function attemptSkin()
	local a = LibStub('AceAddon-3.0'):GetAddon('Skinner', true)
	if a then
		---@diagnostic disable-next-line: undefined-field
		a.prdb.ChatEditBox.skin = false
		---@diagnostic disable-next-line: undefined-field
		a.prdb.DisabledSkins['AceGUI-3.0 (Lib)'] = true
	end

	local AceGUI = LibStub('AceGUI-3.0', true)
	if AceGUI and (AceGUI.RegisterAsContainer ~= RegisterAsContainer or AceGUI.RegisterAsWidget ~= RegisterAsWidget) then
		if select(4, GetAddOnInfo('ElvUI')) then
			return
		end
		SkinAce3()
	end
end

---@param optTable AceConfigOptionsTable
local function Options(optTable)
end

SUI.Skins:Register('Ace3', attemptSkin, nil, Options)