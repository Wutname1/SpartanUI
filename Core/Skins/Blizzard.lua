---@class SUI
local SUI = SUI

local gameMenuLastButtons = {
	[_G['GAMEMENU_OPTIONS']] = 1,
	[_G.BLIZZARD_STORE] = 2,
}

local function SUI_PositionGameMenuButton()
	if not GameMenuFrame.SUI then return end

	local anchorIndex = (C_StorePublic.IsEnabled and C_StorePublic.IsEnabled() and 2) or 1
	for button in GameMenuFrame.buttonPool:EnumerateActive() do
		local text = button:GetText()
		GameMenuFrame.MenuButtons[text] = button -- export these

		local lastIndex = gameMenuLastButtons[text]
		if lastIndex == anchorIndex and GameMenuFrame.SUI then
			GameMenuFrame.SUI:SetPoint('TOPLEFT', button, 'BOTTOMLEFT', 0, -10)
		elseif not lastIndex then
			local point, anchor, point2, x, y = button:GetPoint()
			button:SetPoint(point, anchor, point2, x, y - 35)
		end
	end

	GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 35)

	if GameMenuFrame.Header then GameMenuFrame.Header.Text:SetTextColor(1, 1, 1) end

	GameMenuFrame.SUI:SetFormattedText('|cffffffffSpartan|cffe21f1fUI|r')
end

local function OnEnable()
	if SUI:IsAddonDisabled('Skinner') and SUI:IsAddonDisabled('ConsolePortUI_Menu') then
		if GameMenuFrame.SUI then return end

		if SUI:IsAddonDisabled('Skinner') and SUI:IsAddonDisabled('ConsolePortUI_Menu') then
			local button = CreateFrame('Button', 'SUI_GameMenuButton', GameMenuFrame, 'MainMenuFrameButtonTemplate')
			button:SetScript('OnClick', function()
				SUI:GetModule('Handler.Options'):ToggleOptions()
				if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
			end)
			button:SetSize(200, 35)

			GameMenuFrame.SUI = button
			GameMenuFrame.MenuButtons = GameMenuFrame.MenuButtons or {}

			---@class SUI.Module.Handler.Skins
			local SkinModule = SUI:GetModule('Handler.Skins')
			if not SkinModule.DB.Blizzard then SkinModule.DB.Blizzard = {} end
			if not SkinModule.DB.Blizzard.GameMenuScale then SkinModule.DB.Blizzard.GameMenuScale = 0.8 end
			GameMenuFrame:SetScale(SkinModule.DB.Blizzard.GameMenuScale)

			hooksecurefunc(GameMenuFrame, 'Layout', SUI_PositionGameMenuButton)
		end
	end
end

---@param optTable AceConfig.OptionsTable
local function Options(optTable)
	---@type SUI.Module.Handler.Skins
	local SkinModule = SUI:GetModule('Handler.Skins')

	optTable.args.gameMenuScale = {
		type = 'range',
		name = 'Game Menu Scale',
		desc = 'Adjust the scale of the Game Menu',
		min = 0.5,
		max = 1.5,
		step = 0.05,
		get = function()
			return SkinModule.DB.Blizzard.GameMenuScale
		end,
		set = function(_, value)
			SkinModule.DB.Blizzard.GameMenuScale = value
			if GameMenuFrame then GameMenuFrame:SetScale(value) end
		end,
		order = 10,
	}
end

SUI.Skins:Register('Blizzard', OnEnable, nil, Options)
