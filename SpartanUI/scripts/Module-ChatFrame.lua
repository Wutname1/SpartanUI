if (Prat or ChatMOD_Loaded or ChatSync or Chatter or PhanxChatDB) then return; end
local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("ChatFrame");
---------------------------------------------------------------------------
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

function module:OnEnable()
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
	
--	ChatFrameMenuButton:SetParent(DEFAULT_CHAT_FRAME);
--	ChatFrameMenuButton:ClearAllPoints();
--	ChatFrameMenuButton:SetScale(0.8);
--	ChatFrameMenuButton:SetPoint("TOPRIGHT",DEFAULT_CHAT_FRAME,"TOPRIGHT",4,4);
--	FCF_SetButtonSide = noop;
	
end