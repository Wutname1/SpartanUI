local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PartyFrames = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------

function PartyFrames:UpdatePartyPosition()
	PartyFrames.offset = DB.yoffset
	if DBMod.PartyFrames.moved then
		spartan.PartyFrames:SetMovable(true);
		spartan.PartyFrames:SetUserPlaced(false);
	else
		spartan.PartyFrames:SetMovable(false);
	end
	-- User Moved the PartyFrame, so we shouldn't be moving it
	if not DBMod.PartyFrames.moved then
		spartan.PartyFrames:ClearAllPoints();
		-- SpartanUI_PlayerFrames are loaded
		if spartan:GetModule("PlayerFrames",true) then
			spartan.PartyFrames:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(DB.BuffSettings.offset));
		-- SpartanUI_PlayerFrames isn't loaded
		else
			spartan.PartyFrames:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(DB.BuffSettings.offset));
		end
	else
		local Anchors = {}
		for k,v in pairs(DBMod.PartyFrames.Anchors) do
			Anchors[k] = v
		end
		spartan.PartyFrames:ClearAllPoints();
		spartan.PartyFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
end

function PartyFrames:OnEnable()
	local pf
	if (DBMod.PartyFrames.Style == "theme") and (DBMod.Artwork.Style ~= "Classic") then
		pf = spartan:GetModule("Style_" .. DBMod.Artwork.Style):PartyFrames();
	elseif (DBMod.PartyFrames.Style == "Classic") then
		pf = PartyFrames:Classic()
	elseif (DBMod.PartyFrames.Style == "plain") then
		pf = PartyFrames:Plain();
	else
		pf = spartan:GetModule("Style_" .. DBMod.PartyFrames.Style):PartyFrames();
	end
	
	if DB.Styles[DBMod.PartyFrames.Style].Movable.PartyFrames then
		pf.mover = CreateFrame("Frame");
		pf.mover:SetPoint("TOPLEFT",pf,"TOPLEFT");
		pf.mover:SetPoint("BOTTOMRIGHT",pf,"BOTTOMRIGHT");
		pf.mover:EnableMouse(true);
		pf.mover:SetFrameStrata("LOW");
		
		pf.mover.bg = pf.mover:CreateTexture(nil,"BACKGROUND");
		pf.mover.bg:SetAllPoints(pf.mover);
		pf.mover.bg:SetTexture([[Interface\BlackMarket\BlackMarketBackground-Tile]]);
		pf.mover.bg:SetVertexColor(1,1,1,0.5);
		
		pf.mover:SetScript("OnEvent",function(self, event, ...)
			PartyFrames.locked = 1;
			self:Hide();
		end);
		pf.mover:RegisterEvent("VARIABLES_LOADED");
		pf.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
		pf.mover:Hide();
	end
	
	pf:SetParent("SpartanUI");
	PartyMemberBackground.Show = function() return; end
	PartyMemberBackground:Hide();
	
	spartan.PartyFrames = pf

	function PartyFrames:UpdateParty(event,...)
		if InCombatLockdown() then return end
		local inParty = IsInGroup()  -- ( numGroupMembers () > 0 )
		local bDebug_ShowFrame = true;

		spartan.PartyFrames:SetAttribute('showParty',DBMod.PartyFrames.showParty)
		spartan.PartyFrames:SetAttribute('showPlayer',DBMod.PartyFrames.showPlayer)
		spartan.PartyFrames:SetAttribute('showSolo',DBMod.PartyFrames.showSolo)

		if DBMod.PartyFrames.showParty or DBMod.PartyFrames.showSolo then
			if IsInRaid() then
				if DBMod.PartyFrames.showPartyInRaid then spartan.PartyFrames:Show() else spartan.PartyFrames:Hide() end
			elseif inParty then
					spartan.PartyFrames:Show()
			elseif DBMod.PartyFrames.showSolo then
					spartan.PartyFrames:Show()
			elseif spartan.PartyFrames:IsShown() then
					spartan.PartyFrames:Hide()
			end
		else
			spartan.PartyFrames:Hide();
		end
		
		PartyFrames:UpdatePartyPosition()
		spartan.PartyFrames:SetScale(DBMod.PartyFrames.scale);
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
