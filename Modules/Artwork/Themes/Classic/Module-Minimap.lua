local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Artwork_Classic");
---------------------------------------------------------------------------
local Minimap_Conflict_msg = true
local TribalArt
local BlizzButtons = { "MiniMapTracking", "MiniMapVoiceChatFrame", "MiniMapWorldMapButton", "QueueStatusMinimapButton", "MinimapZoomIn", "MinimapZoomOut", "MiniMapMailFrame", "MiniMapBattlefieldFrame", "GameTimeFrame", "FeedbackUIButton" };
local BlizzUI = { "ActionBar", "BonusActionButton", "MainMenu", "ShapeshiftButton", "MultiBar", "KeyRingButton", "PlayerFrame", "TargetFrame", "PartyMemberFrame", "ChatFrame", "ExhaustionTick", "TargetofTargetFrame", "WorldFrame", "ActionButton", "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", "QuestLogMicroButton", "SocialsMicroButton", "LFGMicroButton", "HelpMicroButton", "CharacterBag", "PetFrame",  "MinimapCluster", "MinimapBackdrop", "UIParent", "WorldFrame", "Minimap", "BuffButton", "BuffFrame", "TimeManagerClockButton", "CharacterFrame" };
local BlizzParentStop = { "WorldFrame", "Minimap", "MinimapBackdrop", "UIParent", "MinimapCluster" }
local SUIMapChangesActive = false
local SkinProtect = { "TutorialFrameAlertButton", "MiniMapMailFrame", "MinimapBackdrop", "MiniMapVoiceChatFrame","TimeManagerClockButton", "MinimapButtonFrameDragButton", "GameTimeFrame", "MiniMapTracking", "MiniMapVoiceChatFrame", "MiniMapWorldMapButton", "QueueStatusMinimapButton", "MinimapZoomIn", "MinimapZoomOut", "MiniMapMailFrame", "MiniMapBattlefieldFrame", "GameTimeFrame", "FeedbackUIButton" };

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
			  and (not Artwork_Core:isInTable(SkinProtect, buttonName))
			  and (not Artwork_Core:isInTable(DB.MiniMap.IgnoredFrames, buttonName)) then
				child:Hide();
				if not Artwork_Core:isInTable(DB.MiniMap.frames, buttonName) then
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
			if buttonName and buttonType == "Button" and (not Artwork_Core:isInTable(SkinProtect, buttonName)) and Artwork_Core:isInTable(DB.MiniMap.frames, buttonName) and (not Artwork_Core:isInTable(DB.MiniMap.IgnoredFrames, buttonName))	then
				child:Show();
			end
		end
		DB.MiniMap.SUIMapChangesActive = false
	else
	end
	
	DraenorZoneAbilityFrame:ClearAllPoints();
	DraenorZoneAbilityFrame:SetScale(.70);
	DraenorZoneAbilityFrame:SetPoint("BOTTOM",SpartanUI,"TOP",0,100);
end

function module:modifyMinimapLayout()
	frame = CreateFrame("Frame","SUI_Minimap",SpartanUI);
	frame:SetSize(156, 156);
	frame:SetPoint("CENTER",0,54);
	
	SUI_MiniMapIcon = CreateFrame("Button","SUI_MiniMapIcon",Minimap);
	SUI_MiniMapIcon:SetSize(35,35);
	
	Minimap:SetParent(frame);
	Minimap:SetSize(frame:GetSize());
	Minimap:SetMaskTexture("Interface\\AddOns\\SpartanUI_Artwork\\Themes\\Classic\\Images\\map-overlay.tga")
	Minimap:ClearAllPoints();
	Minimap:SetPoint("CENTER","SUI_Minimap","CENTER",0,0);
	
	MinimapBackdrop:ClearAllPoints();
	MinimapBackdrop:SetPoint("CENTER",frame,"CENTER",-10,-24);
	
	MinimapZoneTextButton:SetParent(frame);
	MinimapZoneTextButton:ClearAllPoints();
	MinimapZoneTextButton:SetPoint("TOP",frame,"BOTTOM",0,-7);
	
	MinimapBorderTop:Hide();
	MinimapBorder:SetAlpha(0);
	
	MiniMapInstanceDifficulty:SetPoint("TOPLEFT",frame,4,22);
	GuildInstanceDifficulty:SetPoint("TOPLEFT",frame,4,22);
	
	GarrisonLandingPageMinimapButton:ClearAllPoints();
	GarrisonLandingPageMinimapButton:SetSize(35,35);
	GarrisonLandingPageMinimapButton:SetPoint("RIGHT",frame,18,-25);
	
	-- remove current textures
	MiniMapWorldMapButton:SetNormalTexture(nil)
	MiniMapWorldMapButton:SetPushedTexture(nil)
	MiniMapWorldMapButton:SetHighlightTexture(nil)
	-- Create new textures
	MiniMapWorldMapButton:SetNormalTexture("Interface\\AddOns\\SpartanUI_Artwork\\Themes\\Classic\\Images\\WorldMap-Icon.png")
	MiniMapWorldMapButton:SetPushedTexture("Interface\\AddOns\\SpartanUI_Artwork\\Themes\\Classic\\Images\\WorldMap-Icon-Pushed.png")
	MiniMapWorldMapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	
	MiniMapWorldMapButton:ClearAllPoints();
	MiniMapWorldMapButton:SetPoint("TOPRIGHT",MinimapBackdrop,-20,12)
	
	MiniMapMailFrame:ClearAllPoints();
	MiniMapMailFrame:SetPoint("TOPRIGHT",Minimap,"TOPRIGHT",21,-53)
	
	GameTimeFrame:ClearAllPoints();
	GameTimeFrame:SetPoint("TOPRIGHT",Minimap,"TOPRIGHT",20,-16)
	
	MiniMapTracking:ClearAllPoints();
	MiniMapTracking:SetPoint("TOPLEFT",MinimapBackdrop,"TOPLEFT",13,-40)
	MiniMapTrackingButton:ClearAllPoints();
	MiniMapTrackingButton:SetPoint("TOPLEFT",MiniMapTracking,"TOPLEFT",0,0)
	
	frame:EnableMouse(true);
	frame:EnableMouseWheel(true);
	frame:SetScript("OnMouseWheel",function(self,delta)
		if (delta > 0) then Minimap_ZoomIn()
		else Minimap_ZoomOut() end
	end);
	
	frame:SetScript("OnEvent",function(self, event, ...)
		GarrisonLandingPageMinimapButton:Show()
	end);
    frame:RegisterEvent("GARRISON_MISSION_FINISHED");
    frame:RegisterEvent("GARRISON_INVASION_AVAILABLE");
    frame:RegisterEvent("SHIPMENT_UPDATE");
end

function module:createMinimapCoords()
	-- SpartanUI_Tribal:SetVertexColor(1, 0, 0);
	local map = CreateFrame("Frame",nil,SpartanUI);
	map.coords = map:CreateFontString(nil,"BACKGROUND","GameFontNormalSmall");
	map.coords:SetSize(128, 12);
	map.coords:SetPoint("TOP","MinimapZoneTextButton","BOTTOM",0,-6);
	-- Fix CPU leak, use UpdateInterval
	map.UpdateInterval = 2
	map.TimeSinceLastUpdate = 0
	
	DB.MiniMap.SUIMapChangesActive = false
	DB.MiniMap.frames = {}
	DB.MiniMap.IgnoredFrames = {}
	
	map:HookScript("OnUpdate", function(self,...)
		if DB.MiniMap then
			local elapsed = select(1,...)
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
			if ((self.TimeSinceLastUpdate > self.UpdateInterval) or MouseIsOver(Minimap)) then
				-- Debug
				module:updateButtons();
				do -- update minimap coordinates
					local x,y = GetPlayerMapPosition("player");
					if (not x) or (not y) then return; end
					map.coords:SetText(format("%.1f, %.1f",x*100,y*100));
				end
				
				self.TimeSinceLastUpdate = 0
			end
		end
	end);
	map:HookScript("OnEvent",function(self,event,...)
		if (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA") then
			if IsInInstance() then map.coords:Hide() else map.coords:Show() end
			if (WorldMapFrame:IsVisible()) then SetMapToCurrentZone(); end
		elseif (event == "ADDON_LOADED") then
			print(select(1,...));
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
	end);
	map:RegisterEvent("ZONE_CHANGED");
	map:RegisterEvent("ZONE_CHANGED_INDOORS");
	map:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	map:RegisterEvent("UPDATE_WORLD_STATES");
	map:RegisterEvent("UPDATE_BATTLEFIELD_SCORE");
	map:RegisterEvent("PLAYER_ENTERING_WORLD");
	map:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND");
	map:RegisterEvent("WORLD_STATE_UI_TIMER_UPDATE");
end

function module:MiniMap()
	hooksecurefunc(Minimap,"SetPoint",function(self,input1,input2,input3,input4,input5) -- Check for Changes
		local point, relativeTo, relativePoint, xOffset, yOffset = false
		if input1 then point = input1 end
		if input2 then if type(input2) == "number" then xOffset = input2 else if type(input2) ~= "string" then relativeTo = input2:GetName() else relativeTo = input2 end end end
		if input3 then if type(input3) == "number" then yOffset = input3 else relativePoint = input3 end end
		if (Minimap_Conflict_msg) then
			if (self:GetParent():GetName() ~= 'SUI_Minimap' or relativeTo ~= 'SUI_Minimap') then
				spartan:Print('|cffff0000SetPoint/SetParent was used on Minimap, potential conflict.|r')
				Minimap_Conflict_msg = false
			end
		end
	end);
	
	module:modifyMinimapLayout();
	module:createMinimapCoords();
	
	QueueStatusFrame:ClearAllPoints();
	QueueStatusFrame:SetPoint("BOTTOM",SpartanUI,"TOP",0,100);
	module.handleBuff = true
end

function module:ChatBox()

	if (Prat or ChatMOD_Loaded or ChatSync or Chatter or PhanxChatDB) then
		-- Chat Mod Detected, disable and exit
		DB.ChatSettings.enabled = false
		return;
	end
	--exit if not enabled
	if (DB.ChatSettings.enabled ~= true) then
		return;
	end

	local ChatHoverFunc = function(self,...)
		local elapsed = select(1,...)
		self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
		if (self.TimeSinceLastUpdate > self.UpdateInterval) then
			-- Debug
	--		print(self.TimeSinceLastUpdate)
			if MouseIsOver(self) or MouseIsOver(self.ButtonFrame)then
				self.UpButton:Show();
				self.DownButton:Show();
				if self ~= DEFAULT_CHAT_FRAME then self.MinimizeButton:Show(); end
				if self == DEFAULT_CHAT_FRAME then ChatFrameMenuButton:Show(); end
			else
				self.UpButton:Hide();
				self.DownButton:Hide();
				if self ~= DEFAULT_CHAT_FRAME then self.MinimizeButton:Hide(); end
				if self == DEFAULT_CHAT_FRAME then ChatFrameMenuButton:Hide(); end
			end
			if self:AtBottom() then
				self.BottomButton:Hide();
			else
				self.BottomButton:Show();
			end
			self.TimeSinceLastUpdate = 0
		end
	end;

	-- local noop = function() return; end;
	local hide = function(this) this:Hide(); end;
	local NUM_SCROLL_LINES = 3;

	local scroll = function(this, arg1)
		if arg1 > 0 then
			if IsShiftKeyDown() then
				this:ScrollToTop()
			elseif IsControlKeyDown() then
				this:PageUp()
			else
				for i = 1, NUM_SCROLL_LINES do
					this:ScrollUp()
				end
			end
		elseif arg1 < 0 then
			if IsShiftKeyDown() then
				this:ScrollToBottom()
			elseif IsControlKeyDown() then
				this:PageDown()
			else
				for i = 1, NUM_SCROLL_LINES do
					this:ScrollDown()
				end
			end
		end
	end;

	for i = 1,10 do
		local frame = _G["ChatFrame"..i];
		frame:SetMinResize(64,40); frame:SetFading(0);
		frame:EnableMouseWheel(true);
		frame:SetScript("OnMouseWheel",scroll);
		frame:SetFrameStrata("MEDIUM");
		frame:SetToplevel(false);
		frame:SetFrameLevel(2);
		
		frame.ButtonFrame = _G["ChatFrame"..i.."ButtonFrame"];
		
		frame.UpButton = _G["ChatFrame"..i.."ButtonFrameUpButton"];
--		frame.UpButton:ClearAllPoints(); frame.UpButton:SetScale(0.8);
--		frame.UpButton:SetPoint("BOTTOMRIGHT",frame,"RIGHT",4,0);
		
		frame.DownButton = _G["ChatFrame"..i.."ButtonFrameDownButton"];
--		frame.DownButton:ClearAllPoints(); frame.DownButton:SetScale(0.8);
--		frame.DownButton:SetPoint("TOPRIGHT",frame,"RIGHT",4,0);
		
		frame.BottomButton = _G["ChatFrame"..i.."ButtonFrameBottomButton"];
--		frame.BottomButton:ClearAllPoints(); frame.BottomButton:SetScale(0.8);
--		frame.BottomButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -10);
		
		frame.MinimizeButton = _G["ChatFrame"..i.."ButtonFrameMinimizeButton"];
--		frame.MinimizeButton:ClearAllPoints(); frame.MinimizeButton:SetScale(0.8);
--		frame.MinimizeButton:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 4, -30);
		
		frame.EditBox = _G["ChatFrame"..i.."EditBox"];
--		ChatFrame1EditBox:ClearAllPoints();
--		ChatFrame1EditBox:SetPoint("BOTTOMLEFT",  ChatFrame1, "TOPLEFT", 0, 20);
--		ChatFrame1EditBox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 0, 20);

		-- Fix CPU leak, use UpdateInterval
		frame.UpdateInterval = 0.5
		frame.TimeSinceLastUpdate = 0
		frame:HookScript("OnUpdate",ChatHoverFunc);
	end

end

function module:Buffs()
	if DB.BuffSettings.enabled then
		local BuffHandle = CreateFrame("Frame")
		-- Fix CPU leak, use UpdateInterval
		BuffHandle.UpdateInterval = 0.5
		BuffHandle.TimeSinceLastUpdate = 0
		BuffHandle:SetScript("OnUpdate",function(self,...)
			local elapsed = select(1,...)
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
			if (self.TimeSinceLastUpdate > self.UpdateInterval) then
				-- Debug
	--			print(self.TimeSinceLastUpdate)
				if (InCombatLockdown()) then return; end
				-- this can be improved      if offset have changed then update position - no reason to constantly update the position
				module:updateBuffOffset()
				module:UpdateBuffPosition()
				self.TimeSinceLastUpdate = 0
			end
		end);
	end
end

function module:InitMinimap()

end

function module:EnableMinimap()
	if (DB.MiniMap.AutoDetectAllowUse) or (DB.MiniMap.ManualAllowUse) then module:MiniMap() end
	module:ChatBox();
	module:Buffs();
end
