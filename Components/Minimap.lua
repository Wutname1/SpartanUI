local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_Minimap");
----------------------------------------------------------------------------------------------------
local BlizzButtons = { "MiniMapTracking", "MiniMapVoiceChatFrame", "MiniMapWorldMapButton", "QueueStatusMinimapButton", "MinimapZoomIn", "MinimapZoomOut", "MiniMapMailFrame", "MiniMapBattlefieldFrame", "GameTimeFrame", "FeedbackUIButton" };
local BlizzUI = { "ActionBar", "BonusActionButton", "MainMenu", "ShapeshiftButton", "MultiBar", "KeyRingButton", "PlayerFrame", "TargetFrame", "PartyMemberFrame", "ChatFrame", "ExhaustionTick", "TargetofTargetFrame", "WorldFrame", "ActionButton", "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", "QuestLogMicroButton", "SocialsMicroButton", "LFGMicroButton", "HelpMicroButton", "CharacterBag", "PetFrame",  "MinimapCluster", "MinimapBackdrop", "UIParent", "WorldFrame", "Minimap", "BuffButton", "BuffFrame", "TimeManagerClockButton", "CharacterFrame" };
local BlizzParentStop = { "WorldFrame", "Minimap", "MinimapBackdrop", "UIParent", "MinimapCluster" }
local SUIMapChangesActive = false
local SkinProtect = { "TutorialFrameAlertButton", "MiniMapMailFrame", "MinimapBackdrop", "MiniMapVoiceChatFrame","TimeManagerClockButton", "MinimapButtonFrameDragButton", "GameTimeFrame", "MiniMapTracking", "MiniMapVoiceChatFrame", "MiniMapWorldMapButton", "QueueStatusMinimapButton", "MinimapZoomIn", "MinimapZoomOut", "MiniMapMailFrame", "MiniMapBattlefieldFrame", "GameTimeFrame", "FeedbackUIButton" };

local MinimapUpdater = CreateFrame("Frame")

local IsMouseOver = function()
	local MouseFocus = GetMouseFocus()
	if MouseFocus and not MouseFocus:IsForbidden() and ((MouseFocus:GetName() == "Minimap") or (MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find("Mini[Mm]ap"))) then		
		DB.MiniMap.MouseIsOver = true
	else
		DB.MiniMap.MouseIsOver = false
	end
	return DB.MiniMap.MouseIsOver
end

local MiniMapBtnScrape = function()
	-- Hook Minimap Icons
	for i, child in ipairs({Minimap:GetChildren()}) do
		module:SetupButton(child)
	end
	if CensusButton ~= nil then
		module:SetupButton(CensusButton);
	end
	
end

local PerformFullBtnUpdate = function()
	IsMouseOver() --update mouse location
	MiniMapBtnScrape(); --look for new icons
	module:updateButtons(); --update existing
end

local OnEnter = function()
	-- print("OnEnter")
	if DB.MiniMap.MouseIsOver then return end
	
	--don't use PerformFullBtnUpdate as we want to perform the actions in reverse. since any new unknown icons will already be shown.
	module:updateButtons();
	MiniMapBtnScrape();
end

local OnLeave = function()
	--Check in half a second that the mouse actually left
	C_Timer.After(.5, PerformFullBtnUpdate)
end

function module:OnEnable()
	if not DB.EnabledComponents.Minimap then return end
	--Reset the List of frames
	DB.MiniMap.frames = {}
	
	if DB.Styles[DBMod.Artwork.Style].Movable.Minimap or (not spartan:GetModule("Artwork_Core", true)) then
		Minimap.mover = CreateFrame("Frame");
		Minimap.mover:SetSize(5, 5);
		Minimap.mover:SetPoint("TOPLEFT",Minimap,"TOPLEFT");
		Minimap.mover:SetPoint("BOTTOMRIGHT",Minimap,"BOTTOMRIGHT");
		Minimap.mover.bg = Minimap.mover:CreateTexture(nil,"BACKGROUND");
		Minimap.mover.bg:SetAllPoints(Minimap.mover);
		Minimap.mover.bg:SetTexture(1,1,1,0.5);
		Minimap.mover:EnableMouse(true);
		Minimap.mover:Hide()
	
		Minimap:HookScript("OnMouseDown",function(self,button)
			if button == "LeftButton" and IsAltKeyDown() then
				Minimap.mover:Show();
				if spartan:GetModule("Artwork_Core", true) then
					DB.Styles[DBMod.Artwork.Style].Movable.MinimapMoved = true
				else
					DB.MiniMap.Moved = true
				end
				Minimap:SetMovable(true);
				Minimap:StartMoving();
			end
		end);
		
		Minimap:HookScript("OnMouseUp",function(self,button)
			Minimap.mover:Hide();
			Minimap:StopMovingOrSizing();
			if spartan:GetModule("Artwork_Core", true) then
				DB.Styles[DBMod.Artwork.Style].Movable.MinimapCords = {Minimap:GetPoint(Minimap:GetNumPoints())}
			else
				DB.MiniMap.Position = {Minimap:GetPoint(Minimap:GetNumPoints())}
			end
		end);

		if spartan:GetModule("Artwork_Core", true) and DB.Styles[DBMod.Artwork.Style].Movable.MinimapMoved and DB.Styles[DBMod.Artwork.Style].Movable.Minimap and DB.Styles[DBMod.Artwork.Style].Movable.MinimapCords ~= nil then
			Minimap:ClearAllPoints()
			Minimap:SetPoint(unpack(DB.Styles[DBMod.Artwork.Style].Movable.MinimapCords))
		elseif DB.MiniMap.Position ~= nil then
			Minimap:ClearAllPoints()
			Minimap:SetPoint(unpack(DB.MiniMap.Position))
		end
	end
	
	module:ModifyMinimapLayout()
	
	--Look for existing buttons
	MiniMapBtnScrape();
	
	-- Fix CPU leak, use UpdateInterval
	Minimap:HookScript("OnEnter", OnEnter)
	Minimap:HookScript("OnLeave", OnLeave)
	
	--Initialize Buttons
	module:updateButtons()
	
	MinimapUpdater:SetScript("OnEvent", function()
		-- if MouseFocus and not MouseFocus:IsForbidden() and ((MouseFocus:GetName() == "Minimap") or (MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find("Mini[Mm]ap"))) then		
			-- DB.MiniMap.MouseIsOver = false
			C_Timer.After(2, PerformFullBtnUpdate)
		-- end
	end)
	MinimapUpdater:RegisterEvent("ADDON_LOADED")
	MinimapUpdater:RegisterEvent("ZONE_CHANGED")
	MinimapUpdater:RegisterEvent("ZONE_CHANGED_INDOORS")
	MinimapUpdater:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	MinimapUpdater:RegisterEvent("MINIMAP_UPDATE_ZOOM")
	MinimapUpdater:RegisterEvent("MINIMAP_UPDATE_TRACKING")
	MinimapUpdater:RegisterEvent("MINIMAP_PING")
	MinimapUpdater:RegisterEvent("PLAYER_REGEN_DISABLED")
	MinimapUpdater:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function module:ModifyMinimapLayout()
	Minimap:EnableMouseWheel(true);
	Minimap:SetScript("OnMouseWheel",function(self,delta)
		if (delta > 0) then Minimap_ZoomIn()
		else Minimap_ZoomOut() end
	end);
	
	Minimap:SetSize(140,140);
	-- Minimap:SetParent(frame);
	if DB.Styles[DBMod.Artwork.Style].Minimap ~= nil then
		if DB.Styles[DBMod.Artwork.Style].Minimap.shape == "square" then
			Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
			
			Minimap:SetArchBlobRingScalar(0)
			Minimap:SetQuestBlobRingScalar(0)
			
			Minimap.overlay = Minimap:CreateTexture(nil,"OVERLAY");
			Minimap.overlay:SetTexture("Interface\\AddOns\\SpartanUI\\Media\\map-square-overlay");
			Minimap.overlay:SetAllPoints(Minimap);
			Minimap.overlay:SetBlendMode("ADD");
			
			MinimapZoneTextButton:SetPoint("BOTTOMLEFT",Minimap,"TOPLEFT",0,4);
			MinimapZoneTextButton:SetPoint("BOTTOMRIGHT",Minimap,"TOPRIGHT",0,4);
			MinimapZoneText:SetTextColor(1,1,1,1);
			MinimapZoneText:SetShadowColor(0,0,0,1);
			MinimapZoneText:SetShadowOffset(1,-1);
			
			MiniMapTracking:ClearAllPoints();
			MiniMapTracking:SetPoint("TOPLEFT",Minimap,"TOPLEFT",0,0)
		else
			Minimap:SetMaskTexture("Interface\\AddOns\\SpartanUI\\media\\map-circle-overlay")
			
			MiniMapTracking:ClearAllPoints();
			MiniMapTracking:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-5,-5)
		end
	else
		
	end
	if not DB.MiniMap.northTag then
		MinimapNorthTag:Hide()
		MinimapNorthTag.oldShow = MinimapNorthTag.Show
		MinimapNorthTag.Show = MinimapNorthTag.Hide
	else
		MinimapNorthTag:Show()
		MinimapNorthTag.Show = MinimapNorthTag.oldShow
		MinimapNorthTag.oldShow = nil
	end
	
	Minimap:ClearAllPoints();
	Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-30,-30);
	
	TimeManagerClockButton:GetRegions():Hide() -- Hide the border
	TimeManagerClockButton:SetBackdrop(nil)
	TimeManagerClockButton:ClearAllPoints()
	TimeManagerClockButton:SetPoint("TOP", Minimap, "BOTTOM", 0, 20)
	TimeManagerClockButton:SetBackdropColor(0, 0, 0, 1)
	TimeManagerClockButton:SetBackdropBorderColor(0, 0, 0, 1)
	
	MinimapBackdrop:ClearAllPoints();
	MinimapBackdrop:SetPoint("CENTER",Minimap,"CENTER",-10,-24);
	
	MinimapBorderTop:Hide();
	MinimapBorder:Hide();
	
	MiniMapInstanceDifficulty:SetPoint("TOPLEFT",Minimap,4,22);
	GuildInstanceDifficulty:SetPoint("TOPLEFT",Minimap,4,22);
	
	GarrisonLandingPageMinimapButton:ClearAllPoints();
	GarrisonLandingPageMinimapButton:SetSize(35,35);
	GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT",Minimap,0,0);
	
	-- Do modifications to MiniMapWorldMapButton
--	-- remove current textures
	MiniMapWorldMapButton:SetNormalTexture(nil)
	MiniMapWorldMapButton:SetPushedTexture(nil)
	MiniMapWorldMapButton:SetHighlightTexture(nil)
--	-- Create new textures
	MiniMapWorldMapButton:SetNormalTexture("Interface\\AddOns\\SpartanUI\\media\\WorldMap-Icon.png")
	MiniMapWorldMapButton:SetPushedTexture("Interface\\AddOns\\SpartanUI\\media\\WorldMap-Icon-Pushed.png")
	MiniMapWorldMapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	MiniMapWorldMapButton:ClearAllPoints();
	MiniMapWorldMapButton:SetPoint("TOPRIGHT",Minimap,-20,12)
	
	MiniMapMailFrame:ClearAllPoints();
	MiniMapMailFrame:SetPoint("TOPRIGHT",Minimap,"TOPRIGHT",21,-53)
	
	GameTimeFrame:ClearAllPoints();
	GameTimeFrame:SetPoint("TOPRIGHT",Minimap,"TOPRIGHT",20,-16);
	
	SUI_MiniMapIcon = CreateFrame("Button","SUI_MiniMapIcon",Minimap);
	SUI_MiniMapIcon:SetSize(35,35);
	SUI_MiniMapIcon:SetScript("OnEvent",function(self, event, ...)
		GarrisonLandingPageMinimapButton:Show()
		GarrisonLandingPageMinimapButton:SetAlpha(1)
	end);
    SUI_MiniMapIcon:RegisterEvent("GARRISON_MISSION_FINISHED");
    SUI_MiniMapIcon:RegisterEvent("GARRISON_INVASION_AVAILABLE");
    SUI_MiniMapIcon:RegisterEvent("SHIPMENT_UPDATE");
	
	module:MinimapCoords()
end;

function module:MinimapCoords()
	MinimapZoneText:Hide();
	
	Minimap.ZoneText = Minimap:CreateFontString(nil,"OVERLAY","SUI_Font10");
	Minimap.ZoneText:SetSize(10, 12);
	Minimap.ZoneText:SetJustifyH("MIDDLE");
	Minimap.ZoneText:SetJustifyV("CENTER");
	Minimap.ZoneText:SetPoint("BOTTOMLEFT",Minimap,"TOPLEFT",0,1);
	Minimap.ZoneText:SetPoint("BOTTOMRIGHT",Minimap,"TOPRIGHT",0,1);
	Minimap.ZoneText:SetShadowColor(0,0,0,1);
	Minimap.ZoneText:SetShadowOffset(1,-1);
	
	MinimapZoneText:ClearAllPoints();
	MinimapZoneText:SetAllPoints(Minimap.ZoneText);
	MinimapZoneTextButton:ClearAllPoints();
	MinimapZoneTextButton:SetAllPoints(Minimap.ZoneText);
	
	Minimap.coords = Minimap:CreateFontString(nil,"OVERLAY","SUI_Font9");
	Minimap.coords:SetSize(9, 12);
	Minimap.coords:SetJustifyH("TOP");
	Minimap.coords:SetPoint("TOPLEFT",Minimap.ZoneText,"BOTTOMLEFT",0,0);
	Minimap.coords:SetPoint("TOPRIGHT",Minimap.ZoneText,"BOTTOMRIGHT",0,0);
	Minimap.coords:SetShadowColor(0,0,0,1);
	Minimap.coords:SetShadowOffset(1,-1);
	
	local Timer = C_Timer.After
	local function UpdateCoords()
		Timer(0.2, UpdateCoords)
		-- update minimap coordinates
		local x,y = GetPlayerMapPosition("player");
		if (not x) or (not y) then return; end
		Minimap.ZoneText:SetText(GetMinimapZoneText());
		Minimap.coords:SetText(format("%.1f, %.1f",x*100,y*100));
	end
	UpdateCoords()
	
	Minimap:HookScript("OnEvent",function(self,event,...)
		if (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA") then
			-- if IsInInstance() then Minimap.coords:Hide() else Minimap.coords:Show() end
			-- if (WorldMapFrame:IsVisible()) then SetMapToCurrentZone(); end
		end
		local LastFrame = UIErrorsFrame;
		for i = 1, NUM_EXTENDED_UI_FRAMES do
			local bar = _G["WorldStateCaptureBar"..i];
			if (bar and bar:IsShown()) then
				bar:ClearAllPoints();
				bar:SetPoint("TOP",LastFrame,"BOTTOM");
				LastFrame = self;
			end
		end
		hasVehicle = UnitHasVehicleUI("player") or UnitHasVehicleUI("player");
	end);
	
	Minimap:RegisterEvent("ZONE_CHANGED");
	Minimap:RegisterEvent("ZONE_CHANGED_INDOORS");
	Minimap:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	Minimap:RegisterEvent("UPDATE_WORLD_STATES");
	Minimap:RegisterEvent("UPDATE_BATTLEFIELD_SCORE");
	Minimap:RegisterEvent("PLAYER_ENTERING_WORLD");
	Minimap:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND");
	Minimap:RegisterEvent("WORLD_STATE_UI_TIMER_UPDATE");
	Minimap:RegisterEvent("UNIT_ENTERING_VEHICLE");
	Minimap:RegisterEvent("UNIT_ENTERED_VEHICLE");
	Minimap:RegisterEvent("UNIT_ENTERING_VEHICLE");
	Minimap:RegisterEvent("UNIT_ENTERED_VEHICLE");
end

function module:SetupButton(btn)
	buttonName = btn:GetName();
	buttonType = btn:GetObjectType();
	
	--Avoid duplicates make sure it's not in the tracking table
	if not spartan:isInTable(DB.MiniMap.frames, buttonName) then
		-- Hook Mouse Events
		btn:HookScript("OnEnter", OnEnter)
		btn:HookScript("OnLeave", OnLeave)
		
		-- Add Fade in and out
		btn.FadeIn = btn:CreateAnimationGroup()
		local FadeIn = btn.FadeIn:CreateAnimation("Alpha")
		FadeIn:SetOrder(1)
		FadeIn:SetDuration(0.2)
		FadeIn:SetFromAlpha(0)
		FadeIn:SetToAlpha(1)
		btn.FadeIn:SetToFinalAlpha(true)

		btn.FadeOut = btn:CreateAnimationGroup()
		local FadeOut = btn.FadeOut:CreateAnimation("Alpha")
		FadeOut:SetOrder(1)
		FadeOut:SetDuration(0.3)
		FadeOut:SetFromAlpha(1)
		FadeOut:SetToAlpha(0)
		FadeOut:SetStartDelay(.5)
		btn.FadeOut:SetToFinalAlpha(true)
		
		--Insert into tracking table
		table.insert(DB.MiniMap.frames, buttonName)
		
		--Hook into the buttons show and hide events to catch for the button being enabled/disabled
		btn:HookScript("OnHide",function(self,event,...)
			if not DB.MiniMap.SUIMapChangesActive then
				table.insert(DB.MiniMap.IgnoredFrames, self:GetName())
			end
		end);
		btn:HookScript("OnShow",function(self,event,...)
			if not DB.MiniMap.SUIMapChangesActive then
				local foundat = 9999999
				for i=1,table.getn(DB.MiniMap.IgnoredFrames) do
					if DB.MiniMap.IgnoredFrames[i] == btn:GetName() then
						foundat = i
					end
				end
				if foundat ~= 9999999 then
					table.remove(DB.MiniMap.IgnoredFrames, foundat)
					DB.MiniMap.SUIMapChangesActive = true
					--self.Hide()
					DB.MiniMap.SUIMapChangesActive = false
				end
			end
		end);
	end
end

function module:updateButtons()
	local ZoomHide = true
	local AllHide = true
	
	if (not IsMouseOver()) and (DB.MiniMap.MapButtons) then
		AllHide = true
		ZoomHide = true
	else
		AllHide = false
		if (not DB.MiniMap.MapZoomButtons) then ZoomHide = false end
	end
	
	if (not IsMouseOver()) and (not DB.MiniMap.MapButtons) and (DB.MiniMap.MapZoomButtons) then
		ZoomHide = true;
	end
	
	if (ZoomHide) then
		MinimapZoomIn:Hide();
		MinimapZoomOut:Hide();
	else
		MinimapZoomIn:Show();
		MinimapZoomOut:Show();
	end
	
	DB.MiniMap.SUIMapChangesActive = true
	if (AllHide) then
		--Fix for DBM making its icon even if its not needed
		if DBM ~= nil then 
			if DBM.Options.ShowMinimapButton ~= nil and not DBM.Options.ShowMinimapButton then 
				table.insert(DB.MiniMap.IgnoredFrames, "DBMMinimapButton")
			end
		end
		
		if CensusButton ~= nil and CensusButton:GetAlpha() == 1 then
			CensusButton.FadeIn:Stop();
			CensusButton.FadeOut:Stop();
			CensusButton.FadeOut:Play();
		end
		
		for i, child in ipairs({Minimap:GetChildren()}) do
			buttonName = child:GetName();
			-- buttonType = child:GetObjectType();
			
			if buttonName
			  -- and buttonType == "Button"
			  and spartan:isInTable(DB.MiniMap.frames, buttonName)
			  -- and (not spartan:isInTable(SkinProtect, buttonName))
			  and (not spartan:isInTable(DB.MiniMap.IgnoredFrames, buttonName))
			  and child:GetAlpha() == 1
			  then
				-- child.FadeOut:Play();
			-- end
			-- if child.FadeIn ~= nil then
				child.FadeIn:Stop()
				child.FadeOut:Stop()
				
				child.FadeOut:Play();
			end
		end
	else
		if CensusButton ~= nil and CensusButton:GetAlpha() == 0 then
			CensusButton.FadeIn:Stop();
			CensusButton.FadeOut:Stop();
			CensusButton.FadeIn:Play();
		end
	
		for i, child in ipairs({Minimap:GetChildren()}) do
			buttonName = child:GetName();
			-- buttonType = child:GetObjectType();
			
			if buttonName
			  -- and buttonType == "Button"
			  and spartan:isInTable(DB.MiniMap.frames, buttonName)
			  -- and (not spartan:isInTable(SkinProtect, buttonName))
			  and (not spartan:isInTable(DB.MiniMap.IgnoredFrames, buttonName))
			  and child:GetAlpha() == 0
			  then
				-- child.FadeOut:Play();
			-- end
			-- if child.FadeIn ~= nil then
				child.FadeIn:Stop()
				child.FadeOut:Stop()
				
				child.FadeIn:Play()
			end
		end
	end
	DB.MiniMap.SUIMapChangesActive = false
end


