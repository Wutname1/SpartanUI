local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------
oUF:SetActiveStyle("Spartan_PartyFrames");

-- local party = oUF:SpawnHeader("SUI_PartyFrameHeader", nil, "party,solo",
local party = oUF:SpawnHeader("SUI_PartyFrameHeader", nil, nil,
	"showRaid", false,
	"showParty", true,
	"showPlayer", true,
	"showSolo", true,
	"yOffset", -16,
	"xOffset", 0,
	"columnAnchorPoint", "TOPLEFT",
	"initial-anchor", "TOPLEFT",
	"template", "SUI_PartyMemberTemplate");

do -- party header configuration
--	party:SetPoint("TOPLEFT", 0, -26)
	party:SetParent("SpartanUI");
	party:SetClampedToScreen(true);
	PartyMemberBackground.Show = function() return; end
	PartyMemberBackground:Hide();
end

do -- scripts to make it movable
	party.mover = CreateFrame("Frame");
	party.mover:SetWidth(205); party.mover:SetHeight(332);
	party.mover:SetPoint("TOPLEFT",party,"TOPLEFT");
	party.mover:EnableMouse(true);
	
	party.bg = party.mover:CreateTexture(nil,"BACKGROUND");
	party.bg:SetAllPoints(party.mover);
	party.bg:SetTexture(1,1,1,0.5);
	
	party.mover:SetScript("OnMouseDown",function()
		party.isMoving = true;
		suiChar.PartyFrames.partyMoved = true;
		party:SetMovable(true);
		party:StartMoving();
	end);
	party.mover:SetScript("OnMouseUp",function()
		if party.isMoving then
			party.isMoving = nil;
			party:StopMovingOrSizing();
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = party:GetPoint()
			for k,v in pairs(Anchors) do
				suiChar.PartyFrames.Anchors[k] = v
			end
			party:SetUserPlaced(false);
		end
	end);
	party.mover:SetScript("OnHide",function()
		party.isMoving = nil;
		party:StopMovingOrSizing();
		party:SetMovable(true);
		party:SetUserPlaced(false);
		party:SetMovable(false);
	end);
	party.mover:SetScript("OnEvent",function()
		addon.locked = 1;
		party.mover:Hide();
	end);
	party.mover:RegisterEvent("VARIABLES_LOADED");
	party.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
	
	addon.offset = 0;
	function addon:updatePartyOffset() -- handles SpartanUI offset based on setting or fubar / titan
		local fubar,titan,offset = 0,0;
		for i = 1,4 do
			if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
				local bar = _G["FuBarFrame"..i];
				local point = bar:GetPoint(1);
				if point == "TOPLEFT" then fubar = fubar + bar:GetHeight(); end
			end
		end
		if (_G["Titan_Bar__Display_Bar"] and TitanPanelGetVar("Bar_Show")) then
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["Titan_Bar__Display_Bar"]
			titan = titan + (PanelScale * bar:GetHeight());
		end
		if (_G["Titan_Bar__Display_Bar2"] and TitanPanelGetVar("Bar2_Show")) then
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["Titan_Bar__Display_Bar2"]
			titan = titan + (PanelScale * bar:GetHeight());
		end
		offset = max(fubar + titan,1);
		return offset;
	end
	
	function addon:UpdatePartyPosition()
		-- Debug
--		print("update")
		addon.offset = addon:updatePartyOffset()
		if suiChar.PartyFrames.partyMoved then
			party:SetMovable(true);
			party:SetUserPlaced(false);
		else
			party:SetMovable(false);
		end
		-- User Moved the PartyFrame, so we shouldn't be moving it
		if not suiChar.PartyFrames.partyMoved then
			party:ClearAllPoints();
			-- SpartanUI_PlayerFrames are loaded
			if spartan:GetModule("PlayerFrames",true) then
				party:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(addon.offset));
			-- SpartanUI_PlayerFrames isn't loaded
			else
				party:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(addon.offset));
			end
		else
			local Anchors = {}
			for k,v in pairs(suiChar.PartyFrames.Anchors) do
				Anchors[k] = v
			end
			party:ClearAllPoints();
			party:SetPoint(Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		end
	end
end

StaticPopupDialogs["AlphaNotise"] = {
	text = '|cff33ff99SpartanUI|r|nv '..GetAddOnMetadata("SpartanUI", "Version")..'|n|r|n|nIt'.."'"..'s recomended to reset |cff33ff99SpartanUI|r.|n|nClick "|cff33ff99Yes|r" to Reset |cff33ff99SpartanUI|r & ReloadUI.|n|nAfter this you will need to setup |cff33ff99SpartanUI'.."'"..'s|r custom settings again.|n|nDo you want to reset & ReloadUI ?',
	button1 = "|cff33ff99Yes|r",
	button2 = "No",
	OnAccept = function()
		suiChar ={};
		suiChar.AlphaNotise = true
		ReloadUI();
	end,
	OnCancel = function (_,reason)
		spartan:Print("Leaving old profile intact by user's choice, issues might occur due to this.")
		suiChar.AlphaNotise = true
	end,
	sound = "igPlayerInvite",
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
}

StaticPopupDialogs["Notise"] = {
	text = '|cff33ff99SpartanUI|r|nv '..GetAddOnMetadata("SpartanUI", "Version")..'|n|r|n|nUser attention required|n|nClick "Read" when ready',
	button1 = "Read",
	OnAccept = function()
		StaticPopup_Show ("AlphaNotise")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
}
do -- hide party frame in raid, if option enabled
	function addon:UpdateParty(event,...)
		-- Debug
--		print('event '..event)
--		print(...)
		if (event == 'PLAYER_ENTERING_WORLD') then if not suiChar.AlphaNotise then StaticPopup_Show ("Notise") end end

		local inRaid = IsInRaid()  -- ( numGroupMembers () > 0 )
		local inParty = IsInGroup()  -- ( numGroupMembers () > 0 )
		local bDebug_ShowFrame = true;

		local HideInRaid = suiChar.PartyFrames.HidePartyInRaid;
		if HideInRaid == 1 then party:SetAttribute('showRaid',false) end
		local HideParty = suiChar.PartyFrames.HideParty;
		if HideParty == 1 then party:SetAttribute('showParty',false) end
		local HidePlayer = suiChar.PartyFrames.HidePlayer;
		if HidePlayer == 1 then party:SetAttribute('showPlayer',false) end
		local HideSolo = suiChar.PartyFrames.HideSolo;
		if HideSolo == 1 then party:SetAttribute('showSolo',false) end

		local showRaid = party:GetAttribute('showRaid')
		local showParty = party:GetAttribute('showParty')
		local showPlayer = party:GetAttribute('showPlayer')
		local showSolo = party:GetAttribute('showSolo')
		-- Debug
--		print('inRaid '..tostring(inRaid)..', HideInRaid '..HideInRaid..', showRaid '.. tostring(showRaid))
--		print('inParty '..tostring(inParty)..', HideParty '..HideParty..', showParty '..tostring(showParty))
--		print('HidePlayer '..HidePlayer..', showPlayer '..tostring(showPlayer))
--		print('HideSolo '..HideSolo..', showSolo '..tostring(showSolo))

	-- if bDebug_ShowFrame then
	-- 	party:Show();
	--else
		if showParty then
			if inRaid then if showRaid then party:Show() else party:Hide() end
			elseif inParty then party:Show()
			elseif showSolo then party:Show()
			else if party:IsShown() then party:Hide() end
			end
		else
			party:Hide();
		end
	--end
		
		if ( addon.offset ~= addon:updatePartyOffset() ) then addon:UpdatePartyPosition() end
	end
	
	local partyWatch = CreateFrame("Frame");
	partyWatch:RegisterEvent('PLAYER_LOGIN');
	partyWatch:RegisterEvent('PLAYER_ENTERING_WORLD');
	partyWatch:RegisterEvent('RAID_ROSTER_UPDATE');
	partyWatch:RegisterEvent('PARTY_LEADER_CHANGED');
	partyWatch:RegisterEvent('PARTY_MEMBERS_CHANGED');
	partyWatch:RegisterEvent('PARTY_CONVERTED_TO_RAID');
	partyWatch:RegisterEvent('CVAR_UPDATE');
	partyWatch:RegisterEvent('FORCE_UPDATE'); -- Used by slash-commands
	-- Debug
--	partyWatch:RegisterAllEvents()
--	partyWatch:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED');
	partyWatch:SetScript('OnEvent',function(self,event,...)
		if InCombatLockdown() then
			self:RegisterEvent('PLAYER_REGEN_ENABLED')
			return;
		end
		if (event == 'PLAYER_REGEN_ENABLED') then
			-- we aren't in combat
			self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		end
		addon:UpdateParty(event)
	end);
end