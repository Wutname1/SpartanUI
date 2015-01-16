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
local frame

function module:OnEnable()
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
end

function module:ModifyMinimapLayout()
	-- frame:SetSize(140, 140);
	-- frame:SetPoint("CENTER",0,-5);
	
	SUI_MiniMapIcon = CreateFrame("Button","SUI_MiniMapIcon",Minimap);
	SUI_MiniMapIcon:SetSize(35,35);
	
	-- Minimap:SetParent(frame);
	Minimap:SetSize(140,140);
	Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
	-- Minimap:ClearAllPoints();
	-- Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-30,-30);
	
	TimeManagerClockButton:GetRegions():Hide() -- Hide the border
	TimeManagerClockButton:SetBackdrop(nil)
	TimeManagerClockButton:ClearAllPoints()
	TimeManagerClockButton:SetPoint("TOP", Minimap, "BOTTOM", 0, 20)
	TimeManagerClockButton:SetBackdropColor(0, 0, 0, 1)
	TimeManagerClockButton:SetBackdropBorderColor(0, 0, 0, 1)
	
	MinimapBackdrop:ClearAllPoints();
	MinimapBackdrop:SetPoint("CENTER",Minimap,"CENTER",-10,-24);
	
	MinimapZoneTextButton:SetParent(Minimap);
	MinimapZoneTextButton:ClearAllPoints();
	MinimapZoneTextButton:SetPoint("BOTTOMLEFT",Minimap,"TOPLEFT",0,4);
	-- MinimapZoneText:SetJustifyH("LEFT");
	MinimapZoneText:Hide();
	
	MinimapBorderTop:Hide();
	MinimapBorder:SetAlpha(0);
	
	MiniMapInstanceDifficulty:SetPoint("TOPLEFT",frame,4,22);
	GuildInstanceDifficulty:SetPoint("TOPLEFT",frame,4,22);
	
	GarrisonLandingPageMinimapButton:ClearAllPoints();
	GarrisonLandingPageMinimapButton:SetSize(35,35);
	GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT",frame,0,0);

	ExtraActionButton1:ClearAllPoints();
	ExtraActionButton1:SetSize(35,35);
	ExtraActionButton1:SetPoint("BOTTOMLEFT",frame,0,0);
	
	-- Do modifications to MiniMapWorldMapButton
--	-- remove current textures
	MiniMapWorldMapButton:SetNormalTexture(nil)
	MiniMapWorldMapButton:SetPushedTexture(nil)
	MiniMapWorldMapButton:SetHighlightTexture(nil)
--	-- Create new textures
	MiniMapWorldMapButton:SetNormalTexture("Interface\\AddOns\\SpartanUI_Style_Minimal\\Images\\WorldMap-Icon.png")
	MiniMapWorldMapButton:SetPushedTexture("Interface\\AddOns\\SpartanUI_Style_Minimal\\Images\\WorldMap-Icon-Pushed.png")
	MiniMapWorldMapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	MiniMapWorldMapButton:ClearAllPoints();
	MiniMapWorldMapButton:SetPoint("TOPRIGHT",MinimapBackdrop,-20,12)
	
	MiniMapMailFrame:ClearAllPoints();
	MiniMapMailFrame:SetPoint("TOPRIGHT",Minimap,"TOPRIGHT",21,-53)
	
	GameTimeFrame:ClearAllPoints();
	GameTimeFrame:SetPoint("TOPRIGHT",Minimap,"TOPRIGHT",20,-16);
	GameTimeFrame:Hide();
	
	MiniMapTracking:ClearAllPoints(); MiniMapTracking:SetPoint("TOPLEFT",MinimapBackdrop,"TOPLEFT",13,-40)
	MiniMapTrackingButton:ClearAllPoints(); MiniMapTrackingButton:SetPoint("TOPLEFT",MiniMapTracking,"TOPLEFT",0,0)
	
	Minimap.overlay = Minimap:CreateTexture(nil,"OVERLAY");
	Minimap.overlay:SetSize(230, 230); 
	Minimap.overlay:SetTexture("Interface\\AddOns\\SpartanUI_Style_Minimal\\Images\\map-overlay");
	Minimap.overlay:SetPoint("CENTER"); Minimap.overlay:SetBlendMode("ADD");
	
	-- frame:EnableMouse(true);
	-- frame:EnableMouseWheel(true);
	-- frame:SetScript("OnMouseWheel",function(self,delta)
		-- if (delta > 0) then Minimap_ZoomIn()
		-- else Minimap_ZoomOut() end
	-- end);
	
	module.frame = frame
end;


function module:MiniMapButtons()
	-- Fix CPU leak, use UpdateInterval
	Minimap.UpdateInterval = 2
	Minimap.TimeSinceLastUpdate = 0
	Minimap:HookScript("OnUpdate", function(self,...)
		if DB.MiniMap then
			local elapsed = select(1,...)
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
			if (self.TimeSinceLastUpdate > self.UpdateInterval) then
				-- Debug
				module:updateButtons();
				self.TimeSinceLastUpdate = 0
			end
		end
	end);
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
	
	if (AllHide) and (SUI_MiniMapIcon:IsShown()) then
		DB.MiniMap.SUIMapChangesActive = true
		GameTimeFrame:Hide();
		MiniMapTracking:Hide();
		MiniMapWorldMapButton:Hide();
		GarrisonLandingPageMinimapButton:Hide();
		--Fix for DBM making its icon even if its not needed
		if DBM ~= nil then 
			if DBM.Options.ShowMinimapButton ~= nil and not DBM.Options.ShowMinimapButton then 
				table.insert(DB.MiniMap.IgnoredFrames, "DBMMinimapButton")
			end
		end
		
		for i, child in ipairs({Minimap:GetChildren()}) do
			buttonName = child:GetName();
			buttonType = child:GetObjectType();
			
			if buttonName
			  and buttonType == "Button"
			  and (not spartan:isInTable(SkinProtect, buttonName))
			  and (not spartan:isInTable(DB.MiniMap.IgnoredFrames, buttonName)) then
				child:Hide();
				if not spartan:isInTable(DB.MiniMap.frames, buttonName) then
					table.insert(DB.MiniMap.frames, buttonName)
					--Hook into the buttons show and hide events to catch for the button being enabled/disabled
					child:HookScript("OnHide",function(self,event,...)
						if not DB.MiniMap.SUIMapChangesActive then
							table.insert(DB.MiniMap.IgnoredFrames, self:GetName())
						end
					end);
					child:HookScript("OnShow",function(self,event,...)
						if not DB.MiniMap.SUIMapChangesActive then
							local foundat = 9999999
							for i=1,table.getn(DB.MiniMap.IgnoredFrames) do
								if DB.MiniMap.IgnoredFrames[i] == child:GetName() then
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
		end
		DB.MiniMap.SUIMapChangesActive = false
	elseif (not AllHide) and (not SUI_MiniMapIcon:IsShown()) then
		DB.MiniMap.SUIMapChangesActive = true
		GameTimeFrame:Show();
		MiniMapTracking:Show();
		MiniMapWorldMapButton:Show();
		GarrisonLandingPageMinimapButton:Show();
		for i, child in ipairs({Minimap:GetChildren()}) do
			buttonName = child:GetName();
			buttonType = child:GetObjectType();
			if buttonName and buttonType == "Button" and (not spartan:isInTable(SkinProtect, buttonName)) and spartan:isInTable(DB.MiniMap.frames, buttonName) and (not spartan:isInTable(DB.MiniMap.IgnoredFrames, buttonName))	then
				child:Show();
			end
		end
		DB.MiniMap.SUIMapChangesActive = false
	else
	end
end
