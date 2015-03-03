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

function module:OnEnable()
	if not DB.EnabledComponents.Minimap then return end
	
	-- Minimap.SUI = CreateFrame("Frame");
	-- Minimap.SUI:EnableMouse(true);
	-- Minimap.SUI:Hide()
	
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
	module:MiniMapButtons()
	
	MinimapUpdater:SetScript("OnEvent", function()
		if MouseFocus and not MouseFocus:IsForbidden() and ((MouseFocus:GetName() == "Minimap") or (MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find("Mini[Mm]ap"))) then		
			DB.MiniMap.MouseIsOver = false
			module:updateButtons();
		end
	end)
	MinimapUpdater:RegisterEvent("ADDON_LOADED")
	MinimapUpdater:RegisterEvent("ZONE_CHANGED")
	MinimapUpdater:RegisterEvent("ZONE_CHANGED_INDOORS")
	MinimapUpdater:RegisterEvent("ZONE_CHANGED_NEW_AREA")
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

	ExtraActionButton1:ClearAllPoints();
	ExtraActionButton1:SetSize(35,35);
	ExtraActionButton1:SetPoint("BOTTOMLEFT",Minimap,0,0);
	
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
	GameTimeFrame:Hide();
	
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
	
	MinimapZoneTextButton:ClearAllPoints();
	MinimapZoneTextButton:SetAllPoints(Minimap.ZoneText);
	
	Minimap.coords = Minimap:CreateFontString(nil,"OVERLAY","SUI_Font9");
	Minimap.coords:SetSize(9, 12);
	Minimap.coords:SetJustifyH("TOP");
	Minimap.coords:SetPoint("TOPLEFT",Minimap.ZoneText,"BOTTOMLEFT",0,0);
	Minimap.coords:SetPoint("TOPRIGHT",Minimap.ZoneText,"BOTTOMRIGHT",0,0);
	Minimap.coords:SetShadowColor(0,0,0,1);
	Minimap.coords:SetShadowOffset(1,-1);
	
	-- Fix CPU leak, use UpdateInterval
	Minimap.UpdateInterval = 2
	Minimap.TimeSinceLastUpdate = 0
	Minimap:HookScript("OnUpdate", function(self,...)
		if DB.MiniMap then
			local elapsed = select(1,...)
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
			if (self.TimeSinceLastUpdate > self.UpdateInterval) then
				do -- update minimap coordinates
					local x,y = GetPlayerMapPosition("player");
					if (not x) or (not y) then return; end
					Minimap.ZoneText:SetText(GetMinimapZoneText());
					Minimap.coords:SetText(format("%.1f, %.1f",x*100,y*100));
				end
				self.TimeSinceLastUpdate = 0
			end
		end
	end);
	Minimap:HookScript("OnEvent",function(self,event,...)
		if (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA") then
			-- if IsInInstance() then Minimap.coords:Hide() else Minimap.coords:Show() end
			-- if (WorldMapFrame:IsVisible()) then SetMapToCurrentZone(); end
		elseif (event == "ADDON_LOADED") then
			--print(select(1,...));
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

local OnEnter = function()
	-- print("OnEnter")
	if DB.MiniMap.MouseIsOver then return end
	
	module:updateButtons();
end

local OnLeave = function()
	-- print("OnLeave")
	local MouseFocus = GetMouseFocus()
	if MouseFocus and not MouseFocus:IsForbidden() and ((MouseFocus:GetName() == "Minimap") or (MouseFocus:GetParent() and MouseFocus:GetParent():GetName() and MouseFocus:GetParent():GetName():find("Mini[Mm]ap"))) then		
		-- print("OnLeave-Cancelled")
		DB.MiniMap.MouseIsOver = true
		return
	end
	-- print("OnLeave-Exec")
	DB.MiniMap.MouseIsOver = false
	module:updateButtons();
end

function module:SetupButton(btn)
	buttonName = btn:GetName();
	buttonType = btn:GetObjectType();
	
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
	
	if not spartan:isInTable(DB.MiniMap.frames, buttonName) then
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

function module:MiniMapButtons()
	-- Hook Minimap Icons
	for i, child in ipairs({Minimap:GetChildren()}) do
		module:SetupButton(child)
	end
	
	-- Fix CPU leak, use UpdateInterval
	Minimap.UpdateInterval = 2
	Minimap.TimeSinceLastUpdate = 0
	Minimap:HookScript("OnEnter", OnEnter)
	Minimap:HookScript("OnLeave", OnLeave)
	
	--Initialize Buttons
	module:updateButtons()
end

function module:updateButtons()
	local ZoomHide = true
	local AllHide = true
	
	if (not MouseIsOver(Minimap)) and (DB.MiniMap.MapButtons) then
		AllHide = true
		ZoomHide = true
	else
		AllHide = false
		if (not DB.MiniMap.MapZoomButtons) then ZoomHide = false end
	end
	
	if (not MouseIsOver(Minimap)) and (not DB.MiniMap.MapButtons) and (DB.MiniMap.MapZoomButtons) then
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
		-- GameTimeFrame:Hide();
		-- MiniMapTracking:Hide();
		-- MiniMapWorldMapButton:Hide();
		-- GarrisonLandingPageMinimapButton:Hide();
		
		--Fix for DBM making its icon even if its not needed
		if DBM ~= nil then 
			if DBM.Options.ShowMinimapButton ~= nil and not DBM.Options.ShowMinimapButton then 
				table.insert(DB.MiniMap.IgnoredFrames, "DBMMinimapButton")
			end
		end
		
		for i, child in ipairs({Minimap:GetChildren()}) do
			-- buttonName = child:GetName();
			-- buttonType = child:GetObjectType();
			
			-- if buttonName
			  -- and buttonType == "Button"
			  -- and (not spartan:isInTable(SkinProtect, buttonName))
			  -- and (not spartan:isInTable(DB.MiniMap.IgnoredFrames, buttonName))
			  -- then
				-- child.FadeOut:Play();
			-- end
			if child.FadeIn ~= nil then
				child.FadeIn:Stop()
				child.FadeOut:Stop()
				
				child.FadeOut:Play();
			end
		end
	else
		for i, child in ipairs({Minimap:GetChildren()}) do
			if child.FadeIn ~= nil then
				child.FadeIn:Stop()
				child.FadeOut:Stop()
				
				child.FadeIn:Play()
			end
		end
		
		-- GameTimeFrame:Show();
		-- MiniMapTracking:Show();
		-- MiniMapWorldMapButton:Show();
		-- GarrisonLandingPageMinimapButton:Show();
		-- for i, child in ipairs({Minimap:GetChildren()}) do
			-- buttonName = child:GetName();
			-- buttonType = child:GetObjectType();
			-- if buttonName and buttonType == "Button" and (not spartan:isInTable(SkinProtect, buttonName)) and spartan:isInTable(DB.MiniMap.frames, buttonName) and (not spartan:isInTable(DB.MiniMap.IgnoredFrames, buttonName))	then
				-- child:Show();
			-- end
		-- end
	end
	DB.MiniMap.SUIMapChangesActive = false
end


