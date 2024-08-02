---@class SUI.Module.Handler.GameMenu : SUI.Module
local SUIGameMenu = SUI:NewModule('Handler.GameMenu', 'AceEvent-3.0')
local GameMenu = GameMenuFrame
---@class SUIMenuSkin : Frame
local MenuSkin = _G['SUIMenuSkin'] or CreateFrame('Frame', 'SUIMenuSkin', UIParent)

function SUIGameMenu:IsDisabled()
	if SUI:IsAddonEnabled('Skinner') or SUI:IsAddonEnabled('ConsolePort') or not SUI.Skins.DB.components['Blizzard'].enabled then return true end
	return false
end

function SUIGameMenu:OnEnable()
	-- Set up hooks
	GameMenu:HookScript('OnShow', function()
		if SUIGameMenu:IsDisabled() then return end

		MenuSkin:OnFrameShown(true)
	end)
	GameMenu:HookScript('OnHide', function()
		if SUIGameMenu:IsDisabled() then return end
		MenuSkin:OnFrameShown(false)
		MenuSkin:ResetAnimation()
	end)

	MenuSkin.Background:SetTexCoord(0, 1, 0, 1)
	-- self.Background:SetAtlas(visual, true)
	MenuSkin.Background:SetAtlas('gearUpdate-BG', true)

	MenuSkin.TopLine:SetTexCoord(0, 1, 1, 0)
	MenuSkin.TopLine:SetAtlas('gearUpdate-glow-filigree', true)
	MenuSkin.TopLine:SetAlpha(0.5)

	MenuSkin.BottomLine:SetAtlas('gearUpdate-glow-filigree', true)
	MenuSkin.BottomLine:SetAlpha(0.5)
end

local function CreateMenuSkin()
	MenuSkin:SetSize(330, 450)
	MenuSkin:SetFrameStrata('BACKGROUND')
	MenuSkin:Hide()

	-- Gradient
	MenuSkin.Gradient = MenuSkin:CreateTexture(nil, 'BACKGROUND', nil, 2)
	MenuSkin.Gradient:SetAllPoints()
	MenuSkin.Gradient:SetTexture('Interface\\AddOns\\SpartanUI\\images\\Menu\\Gradient.jpg')
	MenuSkin.Gradient:SetAlpha(0.4)

	-- Background
	MenuSkin.Background = MenuSkin:CreateTexture(nil, 'BACKGROUND')
	MenuSkin.Background:SetPoint('CENTER')

	-- Mask
	MenuSkin.Mask = MenuSkin:CreateMaskTexture()
	MenuSkin.Mask:SetTexture('Interface\\AddOns\\SpartanUI\\images\\Menu\\RingMask.png')
	MenuSkin.Mask:SetAllPoints(MenuSkin.Gradient)
	MenuSkin.Background:AddMaskTexture(MenuSkin.Mask)
	MenuSkin.Gradient:AddMaskTexture(MenuSkin.Mask)

	-- Top Line
	MenuSkin.TopLine = MenuSkin:CreateTexture(nil, 'ARTWORK')
	MenuSkin.TopLine:SetSize(600, 16)
	MenuSkin.TopLine:SetPoint('TOP', 0, 100)

	-- Logo Button
	MenuSkin.LogoButton = CreateFrame('Button', nil, MenuSkin)
	MenuSkin.LogoButton:SetSize(80, 80)
	MenuSkin.LogoButton:SetPoint('BOTTOM', 0, -45)

	MenuSkin.LogoButton.texture = MenuSkin.LogoButton:CreateTexture(nil, 'ARTWORK')
	MenuSkin.LogoButton.texture:SetTexture('Interface\\AddOns\\SpartanUI\\images\\Menu\\SUILogo_white.png')
	MenuSkin.LogoButton.texture:SetAllPoints()
	MenuSkin.LogoButton.texture:AddMaskTexture(MenuSkin.Mask)

	-- Mousedown state texture
	MenuSkin.LogoButton.mousedownTexture = MenuSkin.LogoButton:CreateTexture(nil, 'ARTWORK')
	MenuSkin.LogoButton.mousedownTexture:SetTexture('Interface\\AddOns\\SpartanUI\\images\\Menu\\SUILogo_black.png')
	MenuSkin.LogoButton.mousedownTexture:SetAllPoints()
	MenuSkin.LogoButton.mousedownTexture:AddMaskTexture(MenuSkin.Mask)
	MenuSkin.LogoButton.mousedownTexture:Hide()

	-- Highlight effect
	MenuSkin.LogoButton.highlight = MenuSkin.LogoButton:CreateTexture(nil, 'HIGHLIGHT')
	MenuSkin.LogoButton.highlight:SetTexture('Interface\\AddOns\\SpartanUI\\images\\Menu\\ItemBorderOuterHighlight.jpg')
	MenuSkin.LogoButton.highlight:SetSize(MenuSkin.LogoButton:GetWidth() * 2.4, MenuSkin.LogoButton:GetWidth() * 2.4)
	MenuSkin.LogoButton.highlight:SetPoint('CENTER')
	MenuSkin.LogoButton.highlight:SetBlendMode('ADD')
	MenuSkin.LogoButton.highlight:SetAlpha(0)

	MenuSkin.LogoButton:SetScript('OnEnter', function(self)
		self.highlight:SetAlpha(0.5)
	end)

	MenuSkin.LogoButton:SetScript('OnLeave', function(self)
		self.highlight:SetAlpha(0)
	end)

	MenuSkin.LogoButton:SetScript('OnMouseDown', function(self)
		self.texture:Hide()
		self.highlight:Hide()
		self.mousedownTexture:Show()
	end)

	MenuSkin.LogoButton:SetScript('OnMouseUp', function(self)
		self.texture:Show()
		self.highlight:Hide()
		self.mousedownTexture:Hide()
	end)

	MenuSkin.LogoButton:SetScript('OnClick', function()
		SUI.Options:ToggleOptions()
		if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
	end)

	-- Bottom Line
	MenuSkin.BottomLine = MenuSkin:CreateTexture(nil, 'ARTWORK')
	MenuSkin.BottomLine:SetSize(600, 16)
	MenuSkin.BottomLine:SetPoint('BOTTOM', 0, 0)

	-- Line Mask
	MenuSkin.LineMask = MenuSkin:CreateMaskTexture()
	MenuSkin.LineMask:SetTexture('Interface\\AddOns\\SpartanUI\\images\\Menu\\SquareMask', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
	MenuSkin.LineMask:SetPoint('TOPLEFT', MenuSkin.Gradient, 'TOPLEFT', 100, 0)
	MenuSkin.LineMask:SetPoint('BOTTOMRIGHT', MenuSkin.Gradient, 'BOTTOMRIGHT', -100, 0)
	MenuSkin.TopLine:AddMaskTexture(MenuSkin.LineMask)
	MenuSkin.BottomLine:AddMaskTexture(MenuSkin.LineMask)
	MenuSkin.Gradient:AddMaskTexture(MenuSkin.LineMask)
	MenuSkin.Background:AddMaskTexture(MenuSkin.LineMask)

	return MenuSkin
end

CreateMenuSkin()

MenuSkin:SetFrameStrata(GameMenu:GetFrameStrata())
MenuSkin:SetFrameLevel(GameMenu:GetFrameLevel() - 1)
---------------------------------------------------------------
-- Settings
---------------------------------------------------------------

function MenuSkin:OnDataLoaded()
	self:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', self:GetTargetOffsets(GameMenu))
end

MenuSkin:SetScript('OnEvent', function(event, ...)
	if MenuSkin[event] then MenuSkin[event](MenuSkin, ...) end
end)

function MenuSkin:ResetAnimation()
	self:ClearAllPoints()
	self:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	self.Gradient:ClearAllPoints()
	self.Gradient:SetPoint('TOPLEFT', 0, 0)
	self.Gradient:SetPoint('BOTTOMRIGHT', 0, 0)
	self.TopLine:ClearAllPoints()
	self.TopLine:SetPoint('TOP', 0, 100)
	self.BottomLine:ClearAllPoints()
	self.BottomLine:SetPoint('BOTTOM', 0, -140)
end

function MenuSkin:OnFrameShown(showMenu)
	if showMenu then
		self:ResetAnimation()
		self:OnDataLoaded()
		self:InterpolatePoints(GameMenu)
		self:SkinGameMenu()
		self:Show()
	else
		self:Hide()
		self:SetScript('OnUpdate', nil) -- Stop any ongoing animation
	end
end

function MenuSkin:GetTargetOffsets(target)
	local relScale = self:GetEffectiveScale() / target:GetEffectiveScale()
	local targetX, targetY = target:GetCenter()
	return targetX / relScale, targetY / relScale
end

function MenuSkin:SkinGameMenu()
	GameMenu.Border:SetShown(false)
	GameMenu.Header:SetShown(false)
end

---------------------------------------------------------------
-- Animation
---------------------------------------------------------------
local x, y = 4, 5
function MenuSkin:InterpolatePoints(center)
	if SUIGameMenu:IsDisabled() then return end

	local MainFramePosition = { self:GetPoint() }
	local gradientEndPoint = { self.Gradient:GetPoint(1) }
	local secondGradientPoint = { self.Gradient:GetPoint(2) }
	local topLinePosition = { self.TopLine:GetPoint() }
	local bottomLinePosition = { self.BottomLine:GetPoint() }
	local duration, elapsed = 1.5, 0.0

	local targetX, targetY = self:GetTargetOffsets(center)

	self:SetScript('OnUpdate', function(self, dt)
		elapsed = elapsed + dt
		local t = elapsed / duration
		gradientEndPoint[x] = Lerp(gradientEndPoint[x], -70, t)
		gradientEndPoint[y] = Lerp(gradientEndPoint[y], 120, t)

		secondGradientPoint[x] = Lerp(secondGradientPoint[x], 70, t)
		secondGradientPoint[y] = Lerp(secondGradientPoint[y], -135, t)

		topLinePosition[y] = Lerp(topLinePosition[y], 20, t)
		bottomLinePosition[y] = Lerp(bottomLinePosition[y], -70, t)

		MainFramePosition[x] = Lerp(MainFramePosition[x], targetX, t)
		MainFramePosition[y] = Lerp(MainFramePosition[y], targetY, t)

		self:SetPoint(unpack(MainFramePosition))
		self.Gradient:SetPoint(unpack(gradientEndPoint))
		self.Gradient:SetPoint(unpack(secondGradientPoint))
		self.TopLine:SetPoint(unpack(topLinePosition))
		self.BottomLine:SetPoint(unpack(bottomLinePosition))
		if t >= 1.0 then self:SetScript('OnUpdate', nil) end
	end)
end
