local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("Minimap");
---------------------------------------------------------------------------
-- Minimap warning msg of potential conflict
local Minimap_Conflict_msg = true

local checkThirdParty, frame = function()
	local point, relativeTo, relativePoint, x, y = MinimapCluster:GetPoint();
	if (NXTITLELOW) then -- Carbonite is loaded, is it using the minimap?
		addon:Print(NXTITLELOW..' is loaded ...Checking settings ...');
		if (NxData.NXGOpts.MapMMOwn == true)
			then addon:Print(NXTITLELOW..' is handling the Minimap') return true;
		else
			addon:Print('All Clear, SpartanUI is handling Minimap')
		end
	end
	if (SexyMap) then
		addon:Print('SexyMap is loaded, and is handling the Minimap')
		return true
	end
	if (relativeTo ~= UIParent) then return true; end -- a third party minimap manager is involved
	--Debug
--	return true
end;

local CheckDefaults = function()
	if suiChar.MapButtons ~= false and suiChar.MapButtons ~= true then suiChar.MapButtons = false end
	if suiChar.MapZoomButtons ~= false and suiChar.MapZoomButtons ~= true then suiChar.MapZoomButtons = true end
end

local updateButtons = function()
	if (not MouseIsOver(Minimap)) and (suiChar.MapButtons) then
		GameTimeFrame:Hide();
		MiniMapTracking:Hide();
		MiniMapWorldMapButton:Hide();
		MinimapZoomIn:Hide();
		MinimapZoomOut:Hide();
	else
		GameTimeFrame:Show();
		MiniMapTracking:Show();
		MiniMapWorldMapButton:Show();
		if (suiChar.MapZoomButtons) then
			MinimapZoomIn:Hide();
			MinimapZoomOut:Hide();
		else
			MinimapZoomIn:Show();
			MinimapZoomOut:Show();
		end
	end
	if (not MouseIsOver(Minimap)) and (not suiChar.MapButtons) then
		if  (suiChar.MapZoomButtons) then
			MinimapZoomIn:Hide();
			MinimapZoomOut:Hide();
		end
	end
end

local modifyMinimapLayout = function()
	frame = CreateFrame("Frame","SUI_Minimap",SpartanUI);
	frame:SetWidth(158); frame:SetHeight(158);
	frame:SetPoint("CENTER",0,54);
	
	Minimap:SetParent(frame); Minimap:SetWidth(158); Minimap:SetHeight(158);
	Minimap:ClearAllPoints(); Minimap:SetPoint("CENTER","SUI_Minimap","CENTER",0,0);
	
	MinimapBackdrop:ClearAllPoints(); MinimapBackdrop:SetPoint("CENTER",frame,"CENTER",-10,-24);
	MinimapZoneTextButton:SetParent(frame); MinimapZoneTextButton:ClearAllPoints(); MinimapZoneTextButton:SetPoint("TOP",frame,"BOTTOM",0,-6);
	MinimapBorderTop:Hide(); MinimapBorder:SetAlpha(0);
	MinimapZoomIn:Hide(); MinimapZoomOut:Hide();
	MiniMapInstanceDifficulty:SetPoint("TOPLEFT",frame,4,22); -- Need handeling, need correcting ?
	GuildInstanceDifficulty:SetPoint("TOPLEFT",frame,4,22); -- Need handeling, need correcting ?

	-- Do modifications to MiniMapWorldMapButton
--	-- remove current textures
	MiniMapWorldMapButton:SetNormalTexture(nil)
	MiniMapWorldMapButton:SetPushedTexture(nil)
	MiniMapWorldMapButton:SetHighlightTexture(nil)
--	-- Create new textures
	
	-- MiniMapWorldMapButton:SetNormalTexture("Interface\\AddOns\\SpartanUI\\media\\UI-World-Icon.png")
	-- MiniMapWorldMapButton:SetPushedTexture("Interface\\AddOns\\SpartanUI\\media\\UI-World-Icon-Pushed.png")
	MiniMapWorldMapButton:SetNormalTexture("Interface\\AddOns\\SpartanUI\\media\\WorldMap-Icon.png")
	MiniMapWorldMapButton:SetPushedTexture("Interface\\AddOns\\SpartanUI\\media\\WorldMap-Icon-Pushed.png")
	MiniMapWorldMapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	
	MiniMapWorldMapButton:ClearAllPoints(); MiniMapWorldMapButton:SetPoint("TOPRIGHT",MinimapBackdrop,-20,12)
	MiniMapMailFrame:ClearAllPoints(); MiniMapMailFrame:SetPoint("TOPRIGHT",Minimap,"TOPRIGHT",21,-53)
	GameTimeFrame:ClearAllPoints(); GameTimeFrame:SetPoint("TOPRIGHT",Minimap,"TOPRIGHT",20,-16)
	MiniMapTracking:ClearAllPoints(); MiniMapTracking:SetPoint("TOPLEFT",MinimapBackdrop,"TOPLEFT",13,-40)
	MiniMapTrackingButton:ClearAllPoints(); MiniMapTrackingButton:SetPoint("TOPLEFT",MiniMapTracking,"TOPLEFT",0,0)
	-- Commented out the below as the MiniMapBattlefieldIcon XML entry was removed in MOP
	-- MiniMapBattlefieldFrame:ClearAllPoints(); MiniMapBattlefieldFrame:SetPoint("BOTTOMLEFT",Minimap,"BOTTOMLEFT",13,-13)
	
	Minimap.overlay = Minimap:CreateTexture(nil,"OVERLAY");
	Minimap.overlay:SetWidth(250); Minimap.overlay:SetHeight(250); 
	Minimap.overlay:SetTexture("Interface\\AddOns\\SpartanUI\\media\\map-overlay");
	Minimap.overlay:SetPoint("CENTER"); Minimap.overlay:SetBlendMode("ADD");
	
	frame:EnableMouse(true);
	frame:EnableMouseWheel(true);
	frame:SetScript("OnMouseWheel",function(self,delta)
		if (delta > 0) then Minimap_ZoomIn()
		else Minimap_ZoomOut() end
	end);
end;

local createMinimapCoords = function()
	local map = CreateFrame("Frame",nil,SpartanUI);
	map.coords = map:CreateFontString(nil,"BACKGROUND","GameFontNormalSmall");
	map.coords:SetWidth(128); map.coords:SetHeight(12);
	map.coords:SetPoint("TOP","MinimapZoneTextButton","BOTTOM",0,-6);
	-- Fix CPU leak, use UpdateInterval
	map.UpdateInterval = 0.5
	map.TimeSinceLastUpdate = 0
	map:HookScript("OnUpdate", function(self,...)
		local elapsed = select(1,...)
		self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
		if (self.TimeSinceLastUpdate > self.UpdateInterval) then
			-- Debug
--			print(self.TimeSinceLastUpdate)
			updateButtons();
			do -- update minimap coordinates
				local x,y = GetPlayerMapPosition("player");
				if (not x) or (not y) then return; end
				map.coords:SetText(format("%.1f, %.1f",x*100,y*100));
			end
			self.TimeSinceLastUpdate = 0
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
---------------------------------------------------------------------------
function module:OnInitialize()
	addon.options.args["minimap"] = {
		name = "toggle Minimap Button Hiding", type="input",
		get = function(info) return suiChar and suiChar.MapButtons; end,
		set = function(info,val)
			if (val == "" and suiChar.MapButtons == true) or (val == "off") then
				suiChar.MapButtons = nil;
				addon:Print("Minimap Button Hiding Disabled");
			elseif (val == "" and not suiChar.MapButtons) or (val == "on") then
				suiChar.MapButtons = true;
				addon:Print("Minimap Button Hiding Enabled");
			end
		end
	};
	addon.options.args["minimapzoom"] = {
		name = "toggle Minimap Zoom Button Hiding", type="input",
		get = function(info) return suiChar and suiChar.MapZoomButtons; end,
		set = function(info,val)
			if (val == "" and suiChar.MapZoomButtons == true) or (val == "off") then
				suiChar.MapZoomButtons = nil;
				addon:Print("Minimap ZoomButton Hiding Disabled");
			elseif (val == "" and not suiChar.MapZoomButtons) or (val == "on") then
				suiChar.MapZoomButtons = true;
				addon:Print("Minimap ZoomButton Hiding Enabled");
			end
		end
	};
end

function module:OnEnable()
	if (checkThirdParty()) then return; end
	hooksecurefunc(Minimap,"SetPoint",function(self,input1,input2,input3,input4,input5) -- Check for Changes
		local point, relativeTo, relativePoint, xOffset, yOffset = false
		if input1 then point = input1 end
		if input2 then if type(input2) == "number" then xOffset = input2 else if type(input2) ~= "string" then relativeTo = input2:GetName() else relativeTo = input2 end end end
		if input3 then if type(input3) == "number" then yOffset = input3 else relativePoint = input3 end end
		if (Minimap_Conflict_msg) then
			if (self:GetParent():GetName() ~= 'SUI_Minimap' or relativeTo ~= 'SUI_Minimap') then
				addon:Print('|cffff0000SetPoint/SetParent was used on Minimap, potential conflict.|r')
				Minimap_Conflict_msg = false
			end
		end
	end);
	modifyMinimapLayout();
	createMinimapCoords();
	CheckDefaults();
	-- LFGSearchStatus:ClearAllPoints();
	-- LFGSearchStatus:SetPoint("BOTTOM",SpartanUI,"TOP",0,100);
	module.handleBuff = true
	-- MinimapWorldMapButton

--	hooksecurefunc("WorldStateFrame_CanShowBattlefieldMinimap",function() -- battle field frame
--		if (( _G[BattlefieldMinimap]:IsShown() ) and (_G[BattlefieldMinimap]:GetScale() ~= "1.5")) then _G[BattlefieldMinimap]:SetScale(1.5); end end);
end

--[[ Debug code for Minimap SetPoint hooksecurefunc
		--Debug
			print(self:GetName());
			if point then print(point) end
			if relativeTo then print(relativeTo) end
			if relativePoint then print(relativePoint) end
			if xOffset then print(xOffset) end
			if yOffset then print(yOffset) end
			if self:GetParent() then print(self:GetParent():GetName()) end
--			print(relativeTo..' is trying to SetPoint on the Minimap')
			if Minimap:GetParent():GetName() == "MinimapCluster" then
				local point, relativeTo, relativePoint, x, y = MinimapCluster:GetPoint();
				print(point)
				print(relativeTo:GetName())
				print(relativePoint)
				print(x)
				print(y)
			end
--]]