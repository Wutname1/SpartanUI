local SUI = SUI
local module = SUI:GetModule('Style_Classic')
---------------------------------------------------------------------------
local PetBattleActive = false
local petbattleWatcher = CreateFrame('Frame')

function module:MiniMap()
	Minimap:SetSize(156, 156)

	Minimap:ClearAllPoints()
	Minimap:SetPoint('CENTER', SpartanUI, 'CENTER', 0, 54)
	Minimap:SetParent(SpartanUI)

	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints()
		Minimap.ZoneText:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -5)
		Minimap.ZoneText:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -5)
		Minimap.ZoneText:Hide()
		MinimapZoneText:Show()

		Minimap.coords:SetTextColor(1, .82, 0, 1)
	end

	-- Minimap.coords:Hide()

	if QueueStatusFrame then
		QueueStatusFrame:ClearAllPoints()
		QueueStatusFrame:SetPoint('BOTTOM', SpartanUI, 'TOP', 0, 100)
	end

	--Shape Change
	local shapechange = function(shape)
		if shape == 'square' then
			Minimap:SetMaskTexture('Interface\\BUTTONS\\WHITE8X8')

			-- Minimap:SetArchBlobRingScalar(0)
			-- Minimap:SetQuestBlobRingScalar(0)

			Minimap.overlay = Minimap:CreateTexture(nil, 'OVERLAY')
			Minimap.overlay:SetTexture('Interface\\AddOns\\SpartanUI\\Media\\map-square-overlay')
			Minimap.overlay:SetAllPoints(Minimap)
			Minimap.overlay:SetBlendMode('ADD')

			-- MinimapZoneTextButton:SetPoint("BOTTOMLEFT",Minimap,"TOPLEFT",0,4);
			-- MinimapZoneTextButton:SetPoint("BOTTOMRIGHT",Minimap,"TOPRIGHT",0,4);
			-- MinimapZoneText:SetTextColor(1,1,1,1);
			-- MinimapZoneText:SetShadowColor(0,0,0,1);
			-- MinimapZoneText:SetShadowOffset(1,-1);

			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', 0, 0)
		else
			Minimap:SetMaskTexture('Interface\\AddOns\\SpartanUI\\media\\map-circle-overlay')
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -5, -5)
			if Minimap.overlay then
				Minimap.overlay:Hide()
			end
		end
	end

	SpartanUI:HookScript(
		'OnHide',
		function(this, event)
			if PetBattleActive then
				return
			end
			Minimap:ClearAllPoints()
			Minimap:SetParent(UIParent)
			Minimap:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
			shapechange('square')
		end
	)

	SpartanUI:HookScript(
		'OnShow',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('CENTER', SpartanUI, 'CENTER', 0, 54)
			Minimap:SetParent(SpartanUI)
			shapechange('circle')
		end
	)

	if not SUI.IsClassic then
		petbattleWatcher:SetScript(
			'OnEvent',
			function(self, event)
				if event == 'PET_BATTLE_CLOSE' then
					PetBattleActive = false
				else
					PetBattleActive = true
				end
			end
		)
		petbattleWatcher:RegisterEvent('PET_BATTLE_OPENING_START')
		--petbattleWatcher:RegisterEvent("PET_BATTLE_TURN_STARTED")
		petbattleWatcher:RegisterEvent('PET_BATTLE_OPENING_DONE')
		petbattleWatcher:RegisterEvent('PET_BATTLE_CLOSE')
	end

	Minimap:SetFrameLevel(120)
end

function module:EnableMinimap()
	if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
		module:MiniMap()
	end
end
