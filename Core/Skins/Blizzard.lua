---@class SUI
local SUI = SUI

local RemoveTextures = SUI.Skins.RemoveTextures
local RemoveAllTextures = SUI.Skins.RemoveAllTextures
local Skin = SUI.Skins.SkinObj

local function OnEnable()
	if SUI:IsAddonDisabled('Skinner') and SUI:IsAddonDisabled('ConsolePortUI_Menu') then
		-- reskin all esc/menu buttons
		for _, Button in pairs({GameMenuFrame:GetChildren()}) do
			if Button.IsObjectType and Button:IsObjectType('Button') then
				Skin('Button', Button)
				local point, relativeTo, relativePoint, xOfs, yOfs = Button:GetPoint()
				if point then
					-- Shift Button Down
					Button:ClearAllPoints()
					Button:SetPoint(point, relativeTo, relativePoint, (xOfs or 0), (yOfs or 0) - 2)
				end
			end
		end

		hooksecurefunc(
			'GameMenuFrame_UpdateVisibleButtons',
			function()
				RemoveAllTextures(GameMenuFrame)
				Skin('Frame', GameMenuFrame, 'Dark')
				if GameMenuFrame.Header then
					RemoveTextures(GameMenuFrame.Header)
					GameMenuFrame.Header:ClearAllPoints()
					GameMenuFrame.Header:SetPoint('TOP', GameMenuFrame, 0, 0)
					GameMenuFrame.Header:SetSize(GameMenuFrame:GetWidth(), 25)
					GameMenuFrame.Header.Text:ClearAllPoints()
					GameMenuFrame.Header.Text:SetPoint('CENTER', GameMenuFrame.Header)
					GameMenuFrame.Header.Text:SetTextColor(1, 1, 1)
					Skin('Frame', GameMenuFrame.Header)
				end
				if GameMenuFrameHeader then
					RemoveTextures(GameMenuFrameHeader)
					GameMenuFrameHeader:SetTexture()
					GameMenuFrameHeader:SetPoint('TOP', GameMenuFrame, 0, 0)
					GameMenuFrameHeader:SetSize(GameMenuFrame:GetWidth(), 25)
				end
			end
		)
	end
end

SUI.Skins:Register('Blizzard', OnEnable)
