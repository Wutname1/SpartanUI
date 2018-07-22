local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Artwork_BlizzardBars')
module.bars = {}
module.DB = SUI.DBMod.BlizzardBars
local StyleSettings


function module:Initialize(Settings)
	StyleSettings = Settings

	--Create Bars
	module:factory()
	module:BuildOptions()
end

function module:SetupProfile(Settings)
end

function module:ResetMovedBars()
end

function module:SetupMovedBars()
end

function module:ResetDB()
end

function module:UseBlizzardVehicleUI(shouldUse)
end

function module:factory()
	local style = SUI.DBMod.Artwork.Style
	-- if (not InCombatLockdown()) then
 	-- UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomLeft"] = {baseY = 20, xOffset = 5, watchBar = 1, maxLevel = 1, anchorTo = "Blizzard_Bar1", point = "BOTTOMLEFT", rpoint = "BOTTOMLEFT"};
 	-- UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomLeft"].anchorTo = "Blizzard_Bar1"
	MainMenuBarArtFrame.LeftEndCap:Hide()
	MainMenuBarArtFrame.RightEndCap:Hide()
	MainMenuBarArtFrameBackground:Hide()
	StatusTrackingBarManager:Hide()
    MainMenuBarArtFrameBackground:ClearAllPoints()
    MainMenuBarArtFrameBackground:SetPoint("LEFT", _G[style .. '_Bar2'], "LEFT", -3, 2)
    MainMenuBarArtFrame:SetScale(0.725)
    MainMenuBar:EnableMouse(false)
    MultiBarBottomLeftButton1:ClearAllPoints()
    MultiBarBottomLeftButton1:SetPoint("LEFT", _G[style .. '_Bar1'], "LEFT", 5, 0)
    MultiBarBottomRightButton1:ClearAllPoints()
    MultiBarBottomRightButton1:SetPoint("LEFT", _G[style .. '_Bar4'], "LEFT", 5, 0)
    MultiBarBottomRightButton7:ClearAllPoints()
    MultiBarBottomRightButton7:SetPoint("LEFT", MultiBarBottomRightButton6, "RIGHT", 5, 0)
   -- MultiBarBottomLeft:SetScale(0.725)
    -- MainMenuBarArtFrameBackground:SetScale(0.725)
    -- for i = 1, 12 do
    -- 	_G['ActionButton' .. i]:SetScale(0.725)
    -- end
    -- ActionBarUpButton:SetScale(0.725)
    -- ActionBarDownButton:SetScale(0.725)
-- end
	-- hooksecurefunc(
		-- 'UpdateContainerFrameAnchors',
		-- function()
	-- UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomLeft"] = {baseY = 2, xOffset = 5, watchBar = 1, maxLevel = 1, anchorTo = "Blizzard_Bar1", point = "BOTTOMLEFT", rpoint = "BOTTOMLEFT"};
	-- MultiBarBottomLeft:ClearAllPoints()
    -- MultiBarBottomLeft:SetPoint("LEFT", Blizzard_Bar1, "LEFT", 5, 20)
		-- end
	-- )

end

function module:CreateProfile(ProfileOverride)
end

function module:BuildOptions()
	-- Build Holder
	-- SUI.opt.args['Artwork'].args['ActionBars'] = {
	-- 	name = L['Action Bars'],
	-- 	type = 'group',
	-- 	args = {}
	-- }

end
