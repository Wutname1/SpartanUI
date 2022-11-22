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
				frame.CloseBtn = child
			else
				child:Hide()
			end
		end
	end
end

function Ace3_SkinDropdown(self)
	if self and self.obj then
		local pullout = self.obj.dropdown -- Don't ask questions.. Just FUCKING ACCEPT IT
		if pullout then
			if pullout.frame then
				pullout.frame:SetTemplate(nil, true)
			else
				pullout:SetTemplate(nil, true)
			end

			if pullout.slider then
				pullout.slider:SetTemplate()
				pullout.slider:SetThumbTexture(E.Media.Textures.White8x8)

				local t = pullout.slider:GetThumbTexture()
				t:SetVertexColor(1, .82, 0, 0.8)
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
	local classId = select(3, UnitClass('player'))

	local regWidget = AceGUI.RegisterAsWidget
	local regContainer = AceGUI.RegisterAsContainer
	local nextPrevColor = {r = 1, g = .8, b = 0}

	--Skin main window elements
	RegisterAsWidget = function(self, widget)
		local widgetType = widget.type

		if widgetType == 'LSM30_Font' or widgetType == 'LSM30_Sound' or widgetType == 'LSM30_Border' or widgetType == 'LSM30_Background' or widgetType == 'LSM30_Statusbar' then
			-- local frame = widget.frame
			-- local button = frame.dropButton
			-- local text = frame.text
			-- frame:StripTextures()
			-- SUI.Skins.SkinObj('Dropdown', frame)
			-- frame:CreateBackdrop(nil, nil, nil, nil, nil, nil, nil, nil, true)
			-- frame.backdrop:Point('TOPLEFT', 0, -21)
			-- frame.backdrop:Point('BOTTOMRIGHT', -4, -1)
			-- frame.label:ClearAllPoints()
			-- frame.label:Point('BOTTOMLEFT', frame.backdrop, 'TOPLEFT', 2, 0)
			-- frame.text:ClearAllPoints()
			-- frame.text:Point('RIGHT', button, 'LEFT', -2, 0)
			-- frame.text:Point('LEFT', frame.backdrop, 'LEFT', 2, 0)
			-- button:ClearAllPoints()
			-- button:Point('TOPLEFT', frame.backdrop, 'TOPRIGHT', -22, -2)
			-- button:Point('BOTTOMRIGHT', frame.backdrop, 'BOTTOMRIGHT', -2, 2)
			-- if widgetType == 'LSM30_Sound' then
			-- 	widget.soundbutton:SetParent(frame.backdrop)
			-- 	widget.soundbutton:ClearAllPoints()
			-- 	widget.soundbutton:Point('LEFT', frame.backdrop, 'LEFT', 2, 0)
			-- 	Skin:HandleNextPrevButton(button, nil, nextPrevColor)
			-- elseif widgetType == 'LSM30_Statusbar' then
			-- 	widget.bar:SetParent(frame.backdrop)
			-- 	widget.bar:ClearAllPoints()
			-- 	widget.bar:Point('TOPLEFT', frame.backdrop, 'TOPLEFT', 1, -1)
			-- 	widget.bar:Point('BOTTOMRIGHT', frame.backdrop, 'BOTTOMRIGHT', -1, 1)
			-- 	Skin:HandleNextPrevButton(button, nil, nextPrevColor, true)
			-- else
			-- 	Skin:HandleNextPrevButton(button, nil, nextPrevColor)
			-- end
			-- button:SetParent(frame.backdrop)
			-- text:SetParent(frame.backdrop)
			-- button:HookScript('OnClick', Ace3_SkinDropdown)
		elseif widgetType == 'CheckBox' then
			local check = widget.check
			local checkbg = widget.checkbg
			local highlight = widget.highlight
			hooksecurefunc(
				widget,
				'SetType',
				function(self, mode)
					checkbg:SetSize(28, 28)
					local rowTop = (1 / 16) * (classId - 1)
					local rowBottom = (1 / 16) * classId
					checkbg:SetTexture([[Interface\Addons\SpartanUI\images\UI-CheckBox-ByClass]])
					check:SetTexture([[Interface\Addons\SpartanUI\images\UI-CheckBox-ByClass]])
					highlight:SetTexture([[Interface\Addons\SpartanUI\images\UI-CheckBox-ByClass]])
					if mode == 'radio' then
						checkbg:SetTexCoord(0, 0.25, rowTop, rowBottom)
						check:SetTexCoord(0.75, 1, rowTop, rowBottom)
						highlight:SetTexCoord(0.25, 0.5, rowTop, rowBottom)
					else
						checkbg:SetTexCoord(0, 0.25, rowTop, rowBottom)
						check:SetTexCoord(0.5, 0.75, rowTop, rowBottom)
						highlight:SetTexCoord(0.25, 0.5, rowTop, rowBottom)
					end
				end
			)
			Skin(widgetType, widget, 'Light', 'Ace3')
		elseif widgetType == 'Button' then
			local frame = widget.frame
			Skin(widgetType, frame, 'Light', 'Ace3')
		else
			print(widgetType)
		end
		return regWidget(self, widget)
	end
	AceGUI.RegisterAsWidget = RegisterAsWidget

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

				local closeBtn = StdUi:HighlightButton(AppBar, 28, 20, 'X')
				closeBtn.text:SetFontSize(15)
				closeBtn:SetPoint('TOPRIGHT', -1, -1)
				closeBtn:SetFrameLevel(501)
				closeBtn:SetScript(
					'OnClick',
					function()
						frame.CloseBtn:Click()
					end
				)
				AppBar.closeBtn = closeBtn

				-- local minimizeBtn = StdUi:HighlightButton(AppBar, 28, 20, '_')
				-- minimizeBtn.text:SetFontSize(13)
				-- minimizeBtn:SetPoint('TOPRIGHT', -30, -1)
				-- minimizeBtn:SetFrameLevel(501)
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
				-- AppBar.minimizeBtn = minimizeBtn

				-- Re-Create FontString to change its frame level
				widget.titletext = AppBar:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
				widget.titletext:SetPoint('TOP', AppBar, 'TOP', 0, -5)
				SUI.Font:Format(widget.titletext, 13)

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
					RemoveTextures(childFrame)
					Skin('Button', childFrame, 'Light', 'Ace3')
					if childFrame:GetText() == CLOSE then
						frame.CloseBtn = childFrame
					end
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
	local skinner = LibStub('AceAddon-3.0'):GetAddon('Skinner', true)
	if skinner then
		---@diagnostic disable-next-line: undefined-field
		skinner.prdb.ChatEditBox.skin = false
		---@diagnostic disable-next-line: undefined-field
		skinner.prdb.DisabledSkins['AceGUI-3.0 (Lib)'] = true
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
