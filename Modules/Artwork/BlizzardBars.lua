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

function module:GetBagBar()
	return self.bars.bagframe
	-- return MicroButtonAndBagsBar
end

function module:GetStanceBar()
	return StanceBarFrame
end

function module:GetPetBar()
	return PetActionBarFrame
end

function module:GetMicroMenuBar()
	return self.bars.microframe
	-- return MicroButtonAndBagsBar.MicroBagBar
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

 	self.bars.microframe = CreateFrame('Frame', nil)
 	self.bars.microframe:SetScale(0.50)
 	UpdateMicroButtonsParent(self.bars.microframe)

 	self.bars.bagframe = CreateFrame('Frame', nil)
 	self.bars.bagframe:SetScale(0.75)
 	
 	MainMenuBarBackpackButton:SetParent(self.bars.bagframe)
 	CharacterBag1Slot:SetParent(self.bars.bagframe)
 	CharacterBag2Slot:SetParent(self.bars.bagframe)
 	CharacterBag3Slot:SetParent(self.bars.bagframe)
 	MicroButtonAndBagsBar:Hide()

	MainMenuBar:SetFrameLevel(MainMenuBar:GetFrameLevel()-1)
	MainMenuBarArtFrame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel()-1)
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
    MultiActionBar_UpdateGridVisibility()
    for i = 1, 12 do
    	local bottomRightButton = _G['MultiBarBottomRightButton' .. i]
    	local mainButton = _G['ActionButton' .. i]
    	-- Make sure grid shows when it should.
    	bottomRightButton.noGrid = nil
    end

    hooksecurefunc('InterfaceOptions_UpdateMultiActionBars', function()
    	-- TODO: This code actually works on reload in combat, but it fails
    	-- if we try to go into Interface Options and change it while in combat.
    	-- A bit of an edge case, so I'm tempted to just leave it, as it's nice
    	-- to be able to immediately update even in a disconnect scenario.

    	-- if not InCombatLockdown() then
	    for i = 1, 12 do
	    	local mainButton = _G['ActionButton' .. i]
	    	-- Make sure grid shows when it should.  Main Bar seems to have a bug
	    	-- in the default Blizzard code.
	    	if MultibarGrid_IsVisible() then
		    	mainButton:SetAttribute("showgrid", mainButton:GetAttribute('showgrid') + 1)
		    	ActionButton_ShowGrid(mainButton)
			else
		    	mainButton:SetAttribute("showgrid", mainButton:GetAttribute('showgrid') - 1)
				ActionButton_HideGrid(mainButton)
		    end
	    end
	    -- end
    end)
   -- MultiBarBottomLeft:SetScale(0.725)
    -- MainMenuBarArtFrameBackground:SetScale(0.725)
    -- for i = 1, 12 do
    -- 	_G['ActionButton' .. i]:SetScale(0.725)
    -- end
    -- ActionBarUpButton:SetScale(0.725)
    -- ActionBarDownButton:SetScale(0.725)
-- end
	hooksecurefunc(
		'UpdateContainerFrameAnchors',
		function()
 	-- CharacterMicroButton:ClearAllPoints()
 	-- CharacterMicroButton:SetPoint("LEFT", self.bars.microframe, "LEFT", 0, 0)
	-- UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomLeft"] = {baseY = 2, xOffset = 5, watchBar = 1, maxLevel = 1, anchorTo = "Blizzard_Bar1", point = "BOTTOMLEFT", rpoint = "BOTTOMLEFT"};
	-- MultiBarBottomLeft:ClearAllPoints()
    -- MultiBarBottomLeft:SetPoint("LEFT", Blizzard_Bar1, "LEFT", 5, 20)
		end
	)

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
