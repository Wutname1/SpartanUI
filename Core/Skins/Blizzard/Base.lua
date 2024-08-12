---@class SUI
local SUI = SUI

local gameMenuLastButtons = {
	[_G['GAMEMENU_OPTIONS']] = 1,
	[_G['BLIZZARD_STORE']] = 2,
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

	GameMenuFrame.SUI:SetFormattedText('SpartanUI')
end

local function OnEnable()
	GameMenuFrame.MenuButtons = GameMenuFrame.MenuButtons or {}
	if not SUI.Skins.DB.Blizzard then SUI.Skins.DB.Blizzard = {
		GameMenu = {},
	} end
	if not SUI.Skins.DB.Blizzard.GameMenu then SUI.Skins.DB.Blizzard.GameMenu = {} end
	if not SUI.Skins.DB.Blizzard.GameMenu.Scale then SUI.Skins.DB.Blizzard.GameMenu.Scale = 0.8 end

	if SUI:IsAddonEnabled('Skinner') or SUI:IsAddonEnabled('ConsolePort') then
		if GameMenuFrame.SUI then return end

		local button = CreateFrame('Button', 'SUI_GameMenuButton', GameMenuFrame, 'MainMenuFrameButtonTemplate')
		button:SetScript('OnClick', function()
			SUI.Options:ToggleOptions()
			if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
		end)
		button:SetSize(200, 35)

		GameMenuFrame.SUI = button
		hooksecurefunc(GameMenuFrame, 'Layout', SUI_PositionGameMenuButton)
	end
end

---@param optTable AceConfig.OptionsTable
local function Options(optTable)
	if not SUI.Skins.DB.components['Blizzard'].GameMenu then SUI.Skins.DB.components['Blizzard'].GameMenu = {} end

	optTable.args.GameMenu = {
		name = 'Game menu',
		type = 'group',
		inline = true,
		get = function(info)
			return SUI.Skins.DB.components['Blizzard'].GameMenu[info[#info]]
		end,
		set = function(info, val)
			SUI.Skins.DB.components['Blizzard'].GameMenu[info[#info]] = val
		end,
		args = {
			Scale = {
				type = 'range',
				name = 'Game Menu Scale',
				desc = 'Adjust the scale of the Game Menu',
				min = 0.5,
				max = 1.5,
				step = 0.05,
				get = function(info)
					return SUI.Skins.DB.components['Blizzard'].GameMenu[info[#info]] or 0.8
				end,
				set = function(info, value)
					SUI.Skins.DB.components['Blizzard'].GameMenu[info[#info]] = value
					if GameMenuFrame then GameMenuFrame:SetScale(value) end
				end,
				order = 10,
			},
		},
	}
end

SUI.Skins:Register('Blizzard', OnEnable, nil, Options)
