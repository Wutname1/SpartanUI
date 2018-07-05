local _G, SUI = _G, SUI
local RaidFrames = SUI.RaidFrames
----------------------------------------------------------------------------------------------------

function RaidFrames:UpdateRaidPosition()
	RaidFrames.offset = SUI.DB.yoffset
	if SUI.DBMod.RaidFrames.moved then
		SUI.RaidFrames:SetMovable(true)
		SUI.RaidFrames:SetUserPlaced(false)
	else
		SUI.RaidFrames:SetMovable(false)
	end
	if not SUI.DBMod.RaidFrames.moved then
		SUI.RaidFrames:ClearAllPoints()
		if SUI:GetModule("PartyFrames", true) then
			SUI.RaidFrames:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -140 - (RaidFrames.offset))
		else
			SUI.RaidFrames:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -20 - (RaidFrames.offset))
		end
	else
		local Anchors = {}
		for k, v in pairs(SUI.DBMod.RaidFrames.Anchors) do
			Anchors[k] = v
		end
		SUI.RaidFrames:ClearAllPoints()
		SUI.RaidFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
	end
end

function RaidFrames:UpdateRaid(event, ...)
	if SUI.RaidFrames == nil then
		return
	end

	if SUI.DBMod.RaidFrames.showRaid and IsInRaid() then
		SUI.RaidFrames:Show()
	elseif SUI.DBMod.RaidFrames.showParty and inParty then
		--Something keeps hiding it on us when solo so lets force it. Messy but oh well.
		SUI.RaidFrames.HideTmp = SUI.RaidFrames.Hide
		SUI.RaidFrames.Hide = SUI.RaidFrames.Show
		--Now Display
		SUI.RaidFrames:Show()
	elseif SUI.DBMod.RaidFrames.showSolo and not inParty and not IsInRaid() then
		--Something keeps hiding it on us when solo so lets force it. Messy but oh well.
		SUI.RaidFrames.HideTmp = SUI.RaidFrames.Hide
		SUI.RaidFrames.Hide = SUI.RaidFrames.Show
		--Now Display
		SUI.RaidFrames:Show()
	elseif SUI.RaidFrames:IsShown() then
		--Swap back hide function if needed
		if SUI.RaidFrames.HideTmp then
			SUI.RaidFrames.Hide = SUI.RaidFrames.HideTmp
		end

	-- SUI.RaidFrames:Hide()
	end

	RaidFrames:UpdateRaidPosition()

	SUI.RaidFrames:SetAttribute("showRaid", SUI.DBMod.RaidFrames.showRaid)
	SUI.RaidFrames:SetAttribute("showParty", SUI.DBMod.RaidFrames.showParty)
	SUI.RaidFrames:SetAttribute("showPlayer", SUI.DBMod.RaidFrames.showPlayer)
	SUI.RaidFrames:SetAttribute("showSolo", SUI.DBMod.RaidFrames.showSolo)

	SUI.RaidFrames:SetAttribute("groupBy", SUI.DBMod.RaidFrames.mode)
	SUI.RaidFrames:SetAttribute("maxColumns", SUI.DBMod.RaidFrames.maxColumns)
	SUI.RaidFrames:SetAttribute("unitsPerColumn", SUI.DBMod.RaidFrames.unitsPerColumn)
	SUI.RaidFrames:SetAttribute("columnSpacing", SUI.DBMod.RaidFrames.columnSpacing)

	SUI.RaidFrames:SetScale(SUI.DBMod.RaidFrames.scale)
end

function RaidFrames:OnEnable()
	if SUI.DBMod.RaidFrames.HideBlizzFrames and CompactRaidFrameContainer ~= nil then
		CompactRaidFrameContainer:UnregisterAllEvents()
		CompactRaidFrameContainer:Hide()

		local function hideRaid()
			CompactRaidFrameContainer:UnregisterAllEvents()
			if (InCombatLockdown()) then
				return
			end
			local shown = CompactRaidFrameManager_GetSetting("IsShown")
			if (shown and shown ~= "0") then
				CompactRaidFrameManager_SetSetting("IsShown", "0")
			end
		end

		hooksecurefunc(
			"CompactRaidFrameManager_UpdateShown",
			function()
				hideRaid()
			end
		)

		hideRaid()
		CompactRaidFrameContainer:HookScript("OnShow", hideRaid)
	end

	if (SUI.DBMod.RaidFrames.Style == "theme") and (SUI.DBMod.Artwork.Style ~= "Classic") then
		SUI.RaidFrames = SUI:GetModule("Style_" .. SUI.DBMod.Artwork.Style):RaidFrames()
	elseif (SUI.DBMod.RaidFrames.Style == "Classic") or (SUI.DBMod.Artwork.Style == "Classic") then
		SUI.RaidFrames = RaidFrames:Classic()
	elseif (SUI.DBMod.RaidFrames.Style == "plain") then
		SUI.RaidFrames = RaidFrames:Plain()
	else
		SUI.RaidFrames = SUI:GetModule("Style_" .. SUI.DBMod.RaidFrames.Style):RaidFrames()
	end

	SUI.RaidFrames.mover = CreateFrame("Frame")
	SUI.RaidFrames.mover:SetSize(20, 20)
	SUI.RaidFrames.mover:SetPoint("TOPLEFT", SUI.RaidFrames, "TOPLEFT")
	SUI.RaidFrames.mover:SetPoint("BOTTOMRIGHT", SUI.RaidFrames, "BOTTOMRIGHT")
	SUI.RaidFrames.mover:EnableMouse(true)
	SUI.RaidFrames.mover:SetFrameStrata("LOW")

	SUI.RaidFrames:EnableMouse(enable)
	SUI.RaidFrames:SetScript(
		"OnMouseDown",
		function(self, button)
			if button == "LeftButton" and IsAltKeyDown() then
				SUI.RaidFrames.mover:Show()
				SUI.DBMod.RaidFrames.moved = true
				SUI.RaidFrames:SetMovable(true)
				SUI.RaidFrames:StartMoving()
			end
		end
	)
	SUI.RaidFrames:SetScript(
		"OnMouseUp",
		function(self, button)
			SUI.RaidFrames.mover:Hide()
			SUI.RaidFrames:StopMovingOrSizing()
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = SUI.RaidFrames:GetPoint()
			for k, v in pairs(Anchors) do
				SUI.DBMod.RaidFrames.Anchors[k] = v
			end
		end
	)

	SUI.RaidFrames.mover.bg = SUI.RaidFrames.mover:CreateTexture(nil, "BACKGROUND")
	SUI.RaidFrames.mover.bg:SetAllPoints(SUI.RaidFrames.mover)
	SUI.RaidFrames.mover.bg:SetTexture("Interface\\BlackMarket\\BlackMarketBackground-Tile")
	SUI.RaidFrames.mover.bg:SetVertexColor(1, 1, 1, 0.5)

	SUI.RaidFrames.mover:SetScript(
		"OnEvent",
		function()
			RaidFrames.locked = 1
			SUI.RaidFrames.mover:Hide()
		end
	)
	SUI.RaidFrames.mover:RegisterEvent("VARIABLES_LOADED")
	SUI.RaidFrames.mover:RegisterEvent("PLAYER_REGEN_DISABLED")
	SUI.RaidFrames.mover:Hide()

	local raidWatch = CreateFrame("Frame")
	raidWatch:RegisterEvent("GROUP_ROSTER_UPDATE")
	raidWatch:RegisterEvent("PLAYER_ENTERING_WORLD")

	raidWatch:SetScript(
		"OnEvent",
		function(self, event, ...)
			if (InCombatLockdown()) then
				self:RegisterEvent("PLAYER_REGEN_ENABLED")
			else
				self:UnregisterEvent("PLAYER_REGEN_ENABLED")
				RaidFrames:UpdateRaid(event)
			end
		end
	)
end
