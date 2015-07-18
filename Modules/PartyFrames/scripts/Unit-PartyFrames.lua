local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------
SpartanoUF:SetActiveStyle("Spartan_PartyFrames");

party = SpartanoUF:SpawnHeader("SUI_PartyFrameHeader", nil, nil,
	"showRaid", false,
	"showParty", true,
	"showPlayer", true,
	"showSolo", true,
	"yOffset", -16,
	"xOffset", 0,
	"columnAnchorPoint", "TOPLEFT",
	"initial-anchor", "TOPLEFT"
	,"template", "SUI_PartyMemberTemplate"
	);

do -- party header configuration
--	party:SetPoint("TOPLEFT", 0, -26)
	party:SetParent("SpartanUI");
	party:SetClampedToScreen(true);
	PartyMemberBackground.Show = function() return; end
	PartyMemberBackground:Hide();
end

do -- scripts to make it movable
	party.mover = CreateFrame("Frame");
	party.mover:SetSize(205, 332);
	party.mover:SetPoint("TOPLEFT",party,"TOPLEFT");
	party.mover:EnableMouse(true);
	
	party.bg = party.mover:CreateTexture(nil,"BACKGROUND");
	party.bg:SetAllPoints(party.mover);
	party.bg:SetTexture(1,1,1,0.5);
	
	party.mover:SetScript("OnEvent",function()
		addon.locked = 1;
		party.mover:Hide();
	end);
	party.mover:RegisterEvent("VARIABLES_LOADED");
	party.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
	
	function addon:UpdatePartyPosition()
		addon.offset = DB.yoffset
		if DBMod.PartyFrames.moved then
			party:SetMovable(true);
			party:SetUserPlaced(false);
		else
			party:SetMovable(false);
		end
		-- User Moved the PartyFrame, so we shouldn't be moving it
		if not DBMod.PartyFrames.moved then
			party:ClearAllPoints();
			-- SpartanUI_PlayerFrames are loaded
			if spartan:GetModule("PlayerFrames",true) then
				party:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(DB.BuffSettings.offset));
			-- SpartanUI_PlayerFrames isn't loaded
			else
				party:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(DB.BuffSettings.offset));
			end
		else
			local Anchors = {}
			for k,v in pairs(DBMod.PartyFrames.Anchors) do
				Anchors[k] = v
			end
			party:ClearAllPoints();
			party:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		end
	end
end

do -- hide party frame in raid, if option enabled
	function addon:UpdateParty(event,...)
		local inParty = IsInGroup()  -- ( numGroupMembers () > 0 )
		local bDebug_ShowFrame = true;

		party:SetAttribute('showParty',DBMod.PartyFrames.showParty)
		party:SetAttribute('showPlayer',DBMod.PartyFrames.showPlayer)
		party:SetAttribute('showSolo',DBMod.PartyFrames.showSolo)

		if DBMod.PartyFrames.showParty or DBMod.PartyFrames.showSolo then
			if IsInRaid() then
				if DBMod.PartyFrames.showPartyInRaid then party:Show() else party:Hide() end
			elseif inParty then
					party:Show()
			elseif DBMod.PartyFrames.showSolo then
					party:Show()
			elseif party:IsShown() then
					party:Hide()
			end
		else
			party:Hide();
		end
		
		addon:UpdatePartyPosition()
		party:SetScale(DBMod.PartyFrames.scale);
	end
	
	local partyWatch = CreateFrame("Frame");
	partyWatch:RegisterEvent('PLAYER_LOGIN');
	partyWatch:RegisterEvent('PLAYER_ENTERING_WORLD');
	partyWatch:RegisterEvent('RAID_ROSTER_UPDATE');
	partyWatch:RegisterEvent('PARTY_LEADER_CHANGED');
	partyWatch:RegisterEvent('PARTY_MEMBERS_CHANGED');
	partyWatch:RegisterEvent('PARTY_CONVERTED_TO_RAID');
	partyWatch:RegisterEvent('CVAR_UPDATE');
	partyWatch:RegisterEvent('PLAYER_REGEN_ENABLED');
	partyWatch:RegisterEvent('ZONE_CHANGED_NEW_AREA');
	partyWatch:RegisterEvent('FORCE_UPDATE');
	
	partyWatch:SetScript('OnEvent',function(self,event,...)
		if InCombatLockdown() then
			return;
		end
		addon:UpdateParty(event)
	end);
end