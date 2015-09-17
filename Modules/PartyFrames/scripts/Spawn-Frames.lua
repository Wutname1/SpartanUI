local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PartyFrames = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------

function PartyFrames:UpdatePartyPosition()
	PartyFrames.offset = DB.yoffset
	if DBMod.PartyFrames.moved then
		PartyFrames.party:SetMovable(true);
		PartyFrames.party:SetUserPlaced(false);
	else
		PartyFrames.party:SetMovable(false);
	end
	-- User Moved the PartyFrame, so we shouldn't be moving it
	if not DBMod.PartyFrames.moved then
		PartyFrames.party:ClearAllPoints();
		-- SpartanUI_PlayerFrames are loaded
		if spartan:GetModule("PlayerFrames",true) then
			PartyFrames.party:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(DB.BuffSettings.offset));
		-- SpartanUI_PlayerFrames isn't loaded
		else
			PartyFrames.party:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(DB.BuffSettings.offset));
		end
	else
		local Anchors = {}
		for k,v in pairs(DBMod.PartyFrames.Anchors) do
			Anchors[k] = v
		end
		PartyFrames.party:ClearAllPoints();
		PartyFrames.party:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
end

function PartyFrames:OnEnable()
	if (DBMod.PartyFrames.Style == "theme") and (DBMod.Artwork.Style ~= "Classic") then
		PartyFrames.party = spartan:GetModule("Style_" .. DBMod.Artwork.Style):PartyFrames();
	elseif (DBMod.PartyFrames.Style == "Classic") then
		PartyFrames.party = PartyFrames:Classic()
		PartyFrames:ClassicOptions()
	elseif (DBMod.PartyFrames.Style == "plain") then
		PartyFrames.party = PartyFrames:Plain();
	else
		PartyFrames.party = spartan:GetModule("Style_" .. DBMod.PartyFrames.Style):PartyFrames();
	end
	
	if DB.Styles[DBMod.PartyFrames.Style].Movable.PartyFrames then
		PartyFrames.party.mover = CreateFrame("Frame");
		PartyFrames.party.mover:SetPoint("TOPLEFT",PartyFrames.party,"TOPLEFT");
		PartyFrames.party.mover:SetPoint("BOTTOMRIGHT",PartyFrames.party,"BOTTOMRIGHT");
		PartyFrames.party.mover:EnableMouse(true);
		PartyFrames.party.mover:SetFrameStrata("LOW");
		
		PartyFrames.party.bg = PartyFrames.party.mover:CreateTexture(nil,"BACKGROUND");
		PartyFrames.party.bg:SetAllPoints(PartyFrames.party.mover);
		PartyFrames.party.bg:SetTexture(1,1,1,0.5);
		
		PartyFrames.party.mover:SetScript("OnEvent",function()
			PartyFrames.locked = 1;
			PartyFrames.party.mover:Hide();
		end);
		PartyFrames.party.mover:RegisterEvent("VARIABLES_LOADED");
		PartyFrames.party.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
		PartyFrames.party.mover:Hide();
	end
	

	PartyFrames.party:SetParent("SpartanUI");
	PartyFrames.party:SetClampedToScreen(true);
	PartyMemberBackground.Show = function() return; end
	PartyMemberBackground:Hide();


	function PartyFrames:UpdateParty(event,...)
		if InCombatLockdown() then return end
		local inParty = IsInGroup()  -- ( numGroupMembers () > 0 )
		local bDebug_ShowFrame = true;

		PartyFrames.party:SetAttribute('showParty',DBMod.PartyFrames.showParty)
		PartyFrames.party:SetAttribute('showPlayer',DBMod.PartyFrames.showPlayer)
		PartyFrames.party:SetAttribute('showSolo',DBMod.PartyFrames.showSolo)

		if DBMod.PartyFrames.showParty or DBMod.PartyFrames.showSolo then
			if IsInRaid() then
				if DBMod.PartyFrames.showPartyInRaid then PartyFrames.party:Show() else PartyFrames.party:Hide() end
			elseif inParty then
					PartyFrames.party:Show()
			elseif DBMod.PartyFrames.showSolo then
					PartyFrames.party:Show()
			elseif PartyFrames.party:IsShown() then
					PartyFrames.party:Hide()
			end
		else
			PartyFrames.party:Hide();
		end
		
		PartyFrames:UpdatePartyPosition()
		PartyFrames.party:SetScale(DBMod.PartyFrames.scale);
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
		PartyFrames:UpdateParty(event)
	end);
end