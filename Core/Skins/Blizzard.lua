---@class SUI
local SUI = SUI

local function OnEnable()
	if SUI:IsAddonDisabled('Skinner') and SUI:IsAddonDisabled('ConsolePortUI_Menu') then
		local suiButton = CreateFrame('Button', 'SUI_GameMenuButton', GameMenuFrame, 'MainMenuFrameButtonTemplate')
		suiButton:SetScript('OnClick', function()
			---@diagnostic disable-next-line: undefined-field
			SUI:GetModule('Handler.Options'):ToggleOptions()
			if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
		end)
		suiButton:SetSize(200, 35)

		GameMenuFrame.SUI = suiButton
		GameMenuFrame.MenuButtons = {}

		local gameMenuLastButtons = {
			[_G['GAMEMENU_OPTIONS']] = 1,
			[_G['BLIZZARD_STORE']] = 2,
		}
		local anchorIndex = (C_StorePublic.IsEnabled and C_StorePublic.IsEnabled() and 2) or 1
		for button in GameMenuFrame.buttonPool:EnumerateActive() do
			local text = button:GetText()
			print(text)
			GameMenuFrame.MenuButtons[text] = button -- export these

			local lastIndex = gameMenuLastButtons[text]
			if button:GetText() == _G['BLIZZARD_STORE'] and GameMenuFrame.SUI then
				GameMenuFrame.SUI:SetPoint('TOPLEFT', button, 'BOTTOMLEFT', 0, -10)
			elseif not lastIndex then
				local point, anchor, point2, x, y = button:GetPoint()
				button:SetPoint(point, anchor, point2, x, y - 35)
			end
		end

		GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 35)

		GameMenuFrame.Header:ClearAllPoints()
		GameMenuFrame.Header:SetPoint('TOP', GameMenuFrame, 0, 0)
		GameMenuFrame.Header:SetSize(GameMenuFrame:GetWidth(), 25)
		GameMenuFrame.Header.Text:ClearAllPoints()
		GameMenuFrame.Header.Text:SetPoint('CENTER', GameMenuFrame.Header)
		GameMenuFrame.Header.Text:SetTextColor(1, 1, 1)

		GameMenuFrame:SetScale(0.8)
		-- SUI.Skins.RemoveAllTextures(GameMenuFrame)
		-- GameMenuFrame.Header:ClearAllPoints()
		-- GameMenuFrame.Header:SetPoint('TOP', GameMenuFrame, 0, 0)
		-- GameMenuFrame.Header:SetSize(GameMenuFrame:GetWidth(), 25)
		-- GameMenuFrame.Header.Text:ClearAllPoints()
		-- GameMenuFrame.Header.Text:SetPoint('CENTER', GameMenuFrame.Header)
		-- GameMenuFrame.Header.Text:SetTextColor(1, 1, 1)

		-- SUI.Skins.SkinObj('Frame', GameMenuFrame, 'Dark')
		-- -- GameMenuFrame:CreateBackdrop('Transparent')

		-- hooksecurefunc(GameMenuFrame, 'InitButtons', function(menu)
		-- 	if not menu.buttonPool then return end

		-- 	for Button in menu.buttonPool:EnumerateActive() do
		-- 		if not Button.IsSkinned then
		-- 			-- S:HandleButton(button, nil, nil, nil, true)
		-- 			if not Button.SetBackdrop then
		-- 				_G.Mixin(Button, _G.BackdropTemplateMixin)
		-- 				Button:HookScript('OnSizeChanged', Button.OnBackdropSizeChanged)
		-- 			end
		-- 			SUI.Skins.SkinObj('Button', Button)

		-- 			local point, relativeTo, relativePoint, xOfs, yOfs = Button:GetPoint()
		-- 			if point then
		-- 				-- Shift Button Down
		-- 				Button:ClearAllPoints()
		-- 				Button:SetPoint(point, relativeTo, relativePoint, (xOfs or 0), (yOfs or 0) - 2)
		-- 			end
		-- 		end
		-- 	end
		-- end)
	end
end

---@param optTable AceConfig.OptionsTable
local function Options(optTable) end

SUI.Skins:Register('Blizzard', OnEnable, nil, Options)
