local SUI = SUI
local PartyFrames = SUI.PartyFrames
----------------------------------------------------------------------------------------------------

function PartyFrames:UpdatePartyPosition()
	PartyFrames.offset = SUI.DB.yoffset
	if SUI.DBMod.PartyFrames.moved then
		SUI.PartyFrames:SetMovable(true)
		SUI.PartyFrames:SetUserPlaced(false)
	else
		SUI.PartyFrames:SetMovable(false)
	end
	-- User Moved the PartyFrame, so we shouldn't be moving it
	if not SUI.DBMod.PartyFrames.moved then
		SUI.PartyFrames:ClearAllPoints()
		-- SpartanUI_PlayerFrames are loaded
		if SUI:GetModule("PlayerFrames", true) then
			-- SpartanUI_PlayerFrames isn't loaded
			SUI.PartyFrames:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -20 - (SUI.DB.BuffSettings.offset))
		else
			SUI.PartyFrames:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -140 - (SUI.DB.BuffSettings.offset))
		end
	else
		local Anchors = {}
		for k, v in pairs(SUI.DBMod.PartyFrames.Anchors) do
			Anchors[k] = v
		end
		SUI.PartyFrames:ClearAllPoints()
		SUI.PartyFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
end

function PartyFrames:OnEnable()
	local pf
	if (SUI.DBMod.PartyFrames.Style == "theme") and (SUI.DBMod.Artwork.Style ~= "Classic") then
		pf = SUI:GetModule("Style_" .. SUI.DBMod.Artwork.Style):PartyFrames()
	elseif (SUI.DBMod.PartyFrames.Style == "Classic") then
		pf = PartyFrames:Classic()
	elseif (SUI.DBMod.PartyFrames.Style == "plain") then
		pf = PartyFrames:Plain()
	else
		pf = SUI:GetModule("Style_" .. SUI.DBMod.PartyFrames.Style):PartyFrames()
	end

	if SUI.DB.Styles[SUI.DBMod.PartyFrames.Style].Movable.PartyFrames then
		pf.mover = CreateFrame("Frame")
		pf.mover:SetPoint("TOPLEFT", pf, "TOPLEFT")
		pf.mover:SetPoint("BOTTOMRIGHT", pf, "BOTTOMRIGHT")
		pf.mover:EnableMouse(true)
		pf.mover:SetFrameStrata("LOW")

		pf.mover.bg = pf.mover:CreateTexture(nil, "BACKGROUND")
		pf.mover.bg:SetAllPoints(pf.mover)
		pf.mover.bg:SetTexture("Interface\\BlackMarket\\BlackMarketBackground-Tile")
		pf.mover.bg:SetVertexColor(1, 1, 1, 0.5)

		pf.mover:SetScript(
			"OnEvent",
			function(self, event, ...)
				PartyFrames.locked = 1
				self:Hide()
			end
		)
		pf.mover:RegisterEvent("VARIABLES_LOADED")
		pf.mover:RegisterEvent("PLAYER_REGEN_DISABLED")
		pf.mover:Hide()
	end

	pf:SetParent("SpartanUI")
	PartyMemberBackground.Show = function()
		return
	end
	PartyMemberBackground:Hide()

	SUI.PartyFrames = pf

	function PartyFrames:UpdateParty(event, ...)
		if InCombatLockdown() then
			return
		end
		local inParty = IsInGroup() -- ( numGroupMembers () > 0 )

		SUI.PartyFrames:SetAttribute("showParty", SUI.DBMod.PartyFrames.showParty)
		SUI.PartyFrames:SetAttribute("showPlayer", SUI.DBMod.PartyFrames.showPlayer)
		SUI.PartyFrames:SetAttribute("showSolo", SUI.DBMod.PartyFrames.showSolo)

		if SUI.DBMod.PartyFrames.showParty or SUI.DBMod.PartyFrames.showSolo then
			if IsInRaid() then
				if SUI.DBMod.PartyFrames.showPartyInRaid then
					SUI.PartyFrames:Show()
				else
					SUI.PartyFrames:Hide()
				end
			elseif inParty then
				SUI.PartyFrames:Show()
			elseif SUI.DBMod.PartyFrames.showSolo then
				SUI.PartyFrames:Show()
			elseif SUI.PartyFrames:IsShown() then
				SUI.PartyFrames:Hide()
			end
		else
			SUI.PartyFrames:Hide()
		end

		PartyFrames:UpdatePartyPosition()
		SUI.PartyFrames:SetScale(SUI.DBMod.PartyFrames.scale)
	end

	local partyWatch = CreateFrame("Frame")
	partyWatch:RegisterEvent("PLAYER_LOGIN")
	partyWatch:RegisterEvent("PLAYER_ENTERING_WORLD")
	partyWatch:RegisterEvent("RAID_ROSTER_UPDATE")
	partyWatch:RegisterEvent("PARTY_LEADER_CHANGED")
	--partyWatch:RegisterEvent('PARTY_MEMBERS_CHANGED');
	--partyWatch:RegisterEvent('PARTY_CONVERTED_TO_RAID');
	partyWatch:RegisterEvent("CVAR_UPDATE")
	partyWatch:RegisterEvent("PLAYER_REGEN_ENABLED")
	partyWatch:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	--partyWatch:RegisterEvent('FORCE_UPDATE');

	partyWatch:SetScript(
		"OnEvent",
		function(self, event, ...)
			if InCombatLockdown() then
				return
			end
			PartyFrames:UpdateParty(event)
		end
	)
end
