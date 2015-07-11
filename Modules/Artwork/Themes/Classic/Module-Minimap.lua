local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Classic");
---------------------------------------------------------------------------
local Minimap_Conflict_msg = true
local TribalArt

function module:MiniMap()
	Minimap:SetSize(140, 140);
	MinimapZoneText:Show()
	Minimap.coords:Hide()
	
	Minimap:ClearAllPoints();
	Minimap:SetPoint("CENTER",SpartanUI,"CENTER",0,50);

	Minimap.ZoneText:ClearAllPoints();
	Minimap.ZoneText:SetPoint("TOP",Minimap,"BOTTOM",5,-7);
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
		frame.DownButton = _G["ChatFrame"..i.."ButtonFrameDownButton"];
		frame.BottomButton = _G["ChatFrame"..i.."ButtonFrameBottomButton"];
		frame.MinimizeButton = _G["ChatFrame"..i.."ButtonFrameMinimizeButton"];
		frame.EditBox = _G["ChatFrame"..i.."EditBox"];

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
