local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = addon:NewModule("minimap");
---------------------------------------------------------------------------
-- Minimap warning msg of potential conflict
local Minimap_Conflict_msg = true

	local checkThirdParty, frame = function()
		local point, relativeTo, relativePoint, x, y = MinimapCluster:GetPoint();
		if (NXTITLELOW) then -- Carbonite is loaded, is it using the minimap?
			addon:Print(NXTITLELOW..' is loaded ...Checking settings ...');
			if (Nx.db.profile.MiniMap.Own == true)
				then addon:Print(NXTITLELOW..' is handling the Minimap') return true;
			end
		end
		if select(4, GetAddOnInfo("SexyMap")) then
			addon:Print(L["SexyMapLoaded"])
			--return true
		end
		if (relativeTo ~= UIParent) then return true; end -- a third party minimap manager is involved
		--Debug
	--	return true
	end;

	local updateButtons = function()
		if (not MouseIsOver(Minimap)) and (DB.MiniMap.MapButtons) then
			GameTimeFrame:Hide();
			MiniMapTracking:Hide();
			MiniMapWorldMapButton:Hide();
			MinimapZoomIn:Hide();
			MinimapZoomOut:Hide();
		else
			GameTimeFrame:Show();
			MiniMapTracking:Show();
			MiniMapWorldMapButton:Show();
			if (DB.MiniMap.MapZoomButtons) then
				MinimapZoomIn:Hide();
				MinimapZoomOut:Hide();
			else
				MinimapZoomIn:Show();
				MinimapZoomOut:Show();
			end
		end
		if (not MouseIsOver(Minimap)) and (not DB.MiniMap.MapButtons) then
			if  (DB.MiniMap.MapZoomButtons) then
				MinimapZoomIn:Hide();
				MinimapZoomOut:Hide();
			end
		end
	end

	local modifyMinimapLayout = function()
		frame = CreateFrame("Frame","SUI_Minimap",SpartanUI);
		frame:SetSize(158, 158);
		frame:SetPoint("CENTER",0,54);
		
		Minimap:SetParent(frame);
		Minimap:SetSize(158, 158);
		Minimap:ClearAllPoints();
		Minimap:SetPoint("CENTER","SUI_Minimap","CENTER",0,0);
		
		MinimapBackdrop:ClearAllPoints(); MinimapBackdrop:SetPoint("CENTER",frame,"CENTER",-10,-24);
		
		MinimapZoneTextButton:SetParent(frame);
		MinimapZoneTextButton:ClearAllPoints();
		MinimapZoneTextButton:SetPoint("TOP",frame,"BOTTOM",0,-6);
		
		MinimapBorderTop:Hide();
		MinimapBorder:SetAlpha(0);
		
		MiniMapInstanceDifficulty:SetPoint("TOPLEFT",frame,4,22);
		GuildInstanceDifficulty:SetPoint("TOPLEFT",frame,4,22);
		
		GarrisonLandingPageMinimapButton:ClearAllPoints();
		GarrisonLandingPageMinimapButton:SetSize(35,35);
		GarrisonLandingPageMinimapButton:SetPoint("BOTTOMLEFT",frame,0,0);

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
		map.coords:SetSize(128, 12);
		map.coords:SetPoint("TOP","MinimapZoneTextButton","BOTTOM",0,-6);
		-- Fix CPU leak, use UpdateInterval
		map.UpdateInterval = 0.5
		map.TimeSinceLastUpdate = 0
		map:HookScript("OnUpdate", function(self,...)
			if DB.MiniMap then
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

local MiniMap = function()
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
	QueueStatusFrame:ClearAllPoints();
	QueueStatusFrame:SetPoint("BOTTOM",SpartanUI,"TOP",0,100);
	module.handleBuff = true
end

local ChatBox = function()

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

local Buffs = function()
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

function module:UpdateBuffPosition()
	if DB.BuffSettings.enabled then
		if module.handleBuff then
			BuffFrame:ClearAllPoints();
			BuffFrame:SetPoint("TOPRIGHT",-13,-13-(DB.BuffSettings.offset));
			ConsolidatedBuffs:ClearAllPoints();
			ConsolidatedBuffs:SetPoint("TOPRIGHT",-13,-13-(DB.BuffSettings.offset));
			if (ConsolidatedBuffs:IsVisible()) then
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",-5,0);
			else
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",30,0);
			end
		else
			BuffFrame:ClearAllPoints();
			BuffFrame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-205,-13-(DB.BuffSettings.offset))
			ConsolidatedBuffs:ClearAllPoints();
			ConsolidatedBuffs:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-205,-13-(DB.BuffSettings.offset))
			if (ConsolidatedBuffs:IsVisible()) then
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",-5,0);
			else
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",30,0);
			end
		end
	end
end

function module:updateBuffOffset() -- handles SpartanUI offset based on setting or fubar / titan
	local fubar,titan,ChocolateBar,offset = 0,0,0;
	for i = 1,4 do
		if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
			local bar = _G["FuBarFrame"..i];
			local point = bar:GetPoint(1);
			if point == "TOPLEFT" then fubar = fubar + bar:GetHeight(); 	end
		end
	end
	for i = 1,100 do
		if (_G["ChocolateBar"..i] and _G["ChocolateBar"..i]:IsVisible()) then
			local bar = _G["ChocolateBar"..i];
			local point = bar:GetPoint(1);
			if point == "TOPLEFT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end--top bars
			--if point == "RIGHT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end-- bottom bars
		end
	end
		
	TitanBarOrder = {[1]="Bar", [2]="Bar2"} -- Top 2 bar names
	for i=1,2 do
		if (_G["Titan_Bar__Display_"..TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i].."_Show")) then
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["Titan_Bar__Display_"..TitanBarOrder[i]]
			titan = titan + (PanelScale * bar:GetHeight());
		end
	end
	
	offset = max(fubar + titan + ChocolateBar,1);
	DB.BuffSettings.offset = offset
	return offset;
end




function module:OnInitialize()
	addon.optionsGeneral.args["minimap"] = {
		name = L["MinMapSet"],
		desc = L["MinMapSetConf"],
		type = "group", args = {
			minimapbuttons = {name = L["MinMapHidebtns"], type="toggle", width="full",
				get = function(info) return DB.MiniMap.MapButtons; end,
				set = function(info,val) DB.MiniMap.MapButtons = val; end
			},
			minimapzoom = {name = L["MinMapHideZoom"], type="toggle", width="full",
				get = function(info) return DB.MiniMap.MapZoomButtons; end,
				set = function(info,val) DB.MiniMap.MapZoomButtons = val; end
			}
		}
	}
	addon.optionsGeneral.args["ChatSettings"] = {
		name = L["ChatSettings"],
		desc = L["ChatSettingsDesc"],
		type = "group", args = {
			enabled = {
				name = L["ChatSettingsEnabled"],
				desc = L["ChatSettingsEnabledDesc"],
				type="toggle",
				get = function(info) return DB.ChatSettings.enabled; end,
				set = function(info,val)
					if (val == true) then
					DB.ChatSettings.enabled = true;
						if (Prat or ChatMOD_Loaded or ChatSync or Chatter or PhanxChatDB) then
							-- Chat Mod Detected, disable and exit
							DB.ChatSettings.enabled = false
							return;
						end
					else
						DB.ChatSettings.enabled = false;
					end
				end
			}
		}
	}
	addon.optionsGeneral.args["BuffSettings"] = {
		name = L["BuffOffsetSetting"],
		desc = L["BuffOffsetSettingDesc"],
		type = "group", args = {
			enabled = {name= L["BuffOffsetEnable"],type="toggle",width="full",order = 1,
				desc= L["BuffOffsetEnableDesc"],
				get = function(info) return DB.BuffSettings.enabled; end,
				set = function(info,val)
					DB.BuffSettings.enabled = val;
					if val == true then module:UpdateBuffPosition(); end
				end
			},
			offset = {name = L["BuffOffsetConf"], type = "range", order = 2,
				desc = L["BuffOffsetConfDesc"],
				width="double", min=0, max=200, step=.1,
				get = function(info) return DB.BuffSettings.offset; end,
				set = function(info,val)
					if DB.BuffSettings.Manualoffset == true then DB.BuffSettings.offset = val; end
				end
			},
			ManualOffset = {name=L["BuffOffsetManual"], type="toggle", order = 3,
				get	= function(info) return DB.BuffSettings.Manualoffset; end,
				set = function(info,val)
					DB.BuffSettings.Manualoffset = val;
					if val ~= true then
						DB.BuffSettings.offset = module:updateBuffOffset();
						module:UpdateBuffPosition();
					end
				end
			},
		}
	}
end

function module:OnEnable()
	MiniMap();
	ChatBox();
	Buffs();
end
