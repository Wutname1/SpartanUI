local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Classic");
---------------------------------------------------------------------------
local Minimap_Conflict_msg = true
local TribalArt

-- function module:MinimapCoords()
	-- SpartanUI_Tribal:SetVertexColor(1, 0, 0);
	-- local map = CreateFrame("Frame",nil,SpartanUI);
	-- map.coords = map:CreateFontString(nil,"BACKGROUND","GameFontNormalSmall");
	-- map.coords:SetSize(128, 12);
	-- map.coords:SetPoint("BOTTOM",SpartanUI,"BOTTOM",0,15);
	-- map.coords:SetPoint("TOP","MinimapZoneTextButton","BOTTOM",0,-6);
	
	-- Fix CPU leak, use UpdateInterval
	-- map.UpdateInterval = 2
	-- map.TimeSinceLastUpdate = 0
	-- map:HookScript("OnUpdate", function(self,...)
		-- if DB.MiniMap then
			-- local elapsed = select(1,...)
			-- self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
			-- if ((self.TimeSinceLastUpdate > self.UpdateInterval) or MouseIsOver(Minimap)) then
				-- Debug
				-- do -- update minimap coordinates
					-- local x,y = GetPlayerMapPosition("player");
					-- if (not x) or (not y) then return; end
					-- map.coords:SetText(format("%.1f, %.1f",x*100,y*100));
				-- end
				-- self.TimeSinceLastUpdate = 0
			-- end
		-- end
	-- end);
	
	-- map:HookScript("OnEvent",function(self,event,...)
		-- if (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA") then
			-- if IsInInstance() then map.coords:Hide() else map.coords:Show() end
			-- if (WorldMapFrame:IsVisible()) then SetMapToCurrentZone(); end
		-- end
	-- end);
	-- map:RegisterEvent("ZONE_CHANGED");
	-- map:RegisterEvent("ZONE_CHANGED_INDOORS");
	-- map:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	-- map:RegisterEvent("UPDATE_WORLD_STATES");
	-- map:RegisterEvent("UPDATE_BATTLEFIELD_SCORE");
	-- map:RegisterEvent("PLAYER_ENTERING_WORLD");
	-- map:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND");
	-- map:RegisterEvent("WORLD_STATE_UI_TIMER_UPDATE");
-- end

function module:MiniMap()
	Minimap:SetSize(140, 140);
	MinimapZoneText:Show()
	Minimap.coords:Hide()
	
	Minimap:ClearAllPoints();
	Minimap:SetPoint("CENTER",SpartanUI,"CENTER",0,50);

	Minimap.ZoneText:ClearAllPoints();
	Minimap.ZoneText:SetPoint("TOP",Minimap,"BOTTOM",5,-7);
	-- Minimap.ZoneText:SetPoint("BOTTOM",SpartanUI,"BOTTOM",0,15);
	Minimap.ZoneText:SetTextColor(1,.82,0,1);
	
	Minimap.coords:SetTextColor(1,.82,0,1);
	
	QueueStatusFrame:ClearAllPoints();
	QueueStatusFrame:SetPoint("BOTTOM",SpartanUI,"TOP",0,100);
	
	Minimap.coords:Hide()
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
