local _G, SUI = _G, SUI
local module = SUI:GetModule('Artwork_Core')
module.Trays = false
local settings = {}
local trayIDs = {
	'left',
	'right'
}

local trayWatcherEvents = function()
	-- Make sure we are in the right spot
	module:updateOffset()

	for _, key in ipairs(trayIDs) do
		if SUI.DBMod.Artwork.SlidingTrays[key].collapsed then
			module.Trays[key].expanded:Hide()
			module.Trays[key].collapsed:Show()
			SetBarVisibility(module.Trays[key], 'hide')
		else
			module.Trays[key].expanded:Show()
			module.Trays[key].collapsed:Hide()
			SetBarVisibility(module.Trays[key], 'show')
		end
	end
end

function module:trayWatcherEvents()
	trayWatcherEvents()
end

local SetBarVisibility = function(side, state)
	if side == 'left' and state == 'hide' then
		-- BT4BarStanceBar
		if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarStanceBar and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarStanceBar then
			_G['BT4BarStanceBar']:Hide()
		end
		if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarPetBar and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarPetBar then
			_G['BT4BarPetBar']:Hide()
		end
	elseif side == 'right' and state == 'hide' then
		if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarBagBar and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarBagBar then
			_G['BT4BarBagBar']:Hide()
		end
		if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarMicroMenu and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarMicroMenu then
			_G['BT4BarMicroMenu']:Hide()
		end
	end

	if side == 'left' and state == 'show' then
		-- BT4BarStanceBar
		if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarStanceBar and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarStanceBar then
			_G['BT4BarStanceBar']:Show()
		end
		if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarPetBar and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarPetBar then
			_G['BT4BarPetBar']:Show()
		end
	elseif side == 'right' and state == 'show' then
		if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarBagBar and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarBagBar then
			_G['BT4BarBagBar']:Show()
		end
		if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarMicroMenu and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars.BT4BarMicroMenu then
			_G['BT4BarMicroMenu']:Show()
		end
	end
end

local CollapseToggle = function(self)
	local key = self.key
	if SUI.DBMod.Artwork.SlidingTrays[key].collapsed then
		SUI.DBMod.Artwork.SlidingTrays[key].collapsed = false
		module.Trays[key].expanded:Show()
		module.Trays[key].collapsed:Hide()
		SetBarVisibility(key, 'show')
	else
		SUI.DBMod.Artwork.SlidingTrays[key].collapsed = true
		module.Trays[key].expanded:Hide()
		module.Trays[key].collapsed:Show()
		SetBarVisibility(key, 'hide')
	end
end

-- Artwork Stuff
function module:SlidingTrays(StyleSettings)
	module.Trays = {}
	settings = StyleSettings
	War_MenuBarBG:SetAlpha(0)
	War_StanceBarBG:SetAlpha(0)

	for _, key in ipairs(trayIDs) do
		local tray = CreateFrame('Frame', nil, UIParent)
		tray:SetFrameStrata('BACKGROUND')
		tray:SetAlpha(.8)
		tray:SetSize(400, 45)

		local expanded = CreateFrame('Frame', nil, tray)
		expanded:SetAllPoints()
		local collapsed = CreateFrame('Frame', nil, tray)
		collapsed:SetAllPoints()

		local bg = expanded:CreateTexture(nil, 'BACKGROUND', expanded)
		bg:SetTexture(settings.bg.Texture)
		bg:SetTexCoord(unpack(settings.bg.TexCoord))
		bg:SetAllPoints()

		local bgCollapsed = collapsed:CreateTexture(nil, 'BACKGROUND', collapsed)
		bgCollapsed:SetTexture(settings.bgCollapsed.Texture)
		bgCollapsed:SetTexCoord(unpack(settings.bgCollapsed.TexCoord))
		bgCollapsed:SetPoint('TOPLEFT', tray)
		bgCollapsed:SetPoint('TOPRIGHT', tray)
		bgCollapsed:SetHeight(18)

		local btnUp = CreateFrame('BUTTON', nil, expanded)
		local UpTex = expanded:CreateTexture()
		UpTex:SetTexture(settings.UpTex.Texture)
		UpTex:SetTexCoord(unpack(settings.UpTex.TexCoord))
		UpTex:Hide()
		btnUp:SetSize(130, 9)
		UpTex:SetAllPoints(btnUp)
		btnUp:SetNormalTexture('')
		btnUp:SetHighlightTexture(UpTex)
		btnUp:SetPushedTexture('')
		btnUp:SetDisabledTexture('')
		btnUp:SetPoint('BOTTOM', tray, 'BOTTOM', 1, 2)

		local btnDown = CreateFrame('BUTTON', nil, collapsed)
		local DownTex = collapsed:CreateTexture()
		DownTex:SetTexture(settings.DownTex.Texture)
		DownTex:SetTexCoord(unpack(settings.DownTex.TexCoord))
		DownTex:Hide()
		btnDown:SetSize(130, 9)
		DownTex:SetAllPoints(btnDown)
		btnDown:SetNormalTexture('')
		btnDown:SetHighlightTexture(DownTex)
		btnDown:SetPushedTexture('')
		btnDown:SetDisabledTexture('')
		btnDown:SetPoint('TOP', tray, 'TOP', 2, -6)

		btnUp.key = key
		btnDown.key = key
		btnUp:SetScript('OnClick', CollapseToggle)
		btnDown:SetScript('OnClick', CollapseToggle)

		expanded.bg = bg
		expanded.btnUp = btnUp

		collapsed.bgCollapsed = bgCollapsed
		collapsed.btnDown = btnDown

		tray.expanded = expanded
		tray.collapsed = collapsed

		if SUI.DBMod.Artwork.SlidingTrays[key].collapsed then
			SetBarVisibility(key, 'hide')
		else
			SetBarVisibility(key, 'show')
		end
		module.Trays[key] = tray
	end

	module.Trays.left:SetPoint('TOP', UIParent, 'TOP', -300, 0)
	module.Trays.right:SetPoint('TOP', UIParent, 'TOP', 300, 0)

	trayWatcher:SetScript('OnEvent', trayWatcherEvents)
	trayWatcher:RegisterEvent('PLAYER_LOGIN')
	trayWatcher:RegisterEvent('PLAYER_ENTERING_WORLD')
	trayWatcher:RegisterEvent('ZONE_CHANGED')
	trayWatcher:RegisterEvent('ZONE_CHANGED_INDOORS')
	trayWatcher:RegisterEvent('ZONE_CHANGED_NEW_AREA')

	-- Default movetracker ignores stuff attached to UIParent (Tray items are)
	local FrameList = {
		BT4BarBagBar,
		BT4BarStanceBar,
		BT4BarPetBar,
		BT4BarMicroMenu
	}

	for _, v in ipairs(FrameList) do
		if v then
			v.SavePosition = function()
				if not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] and not SUI.DBG.BartenderChangesActive then
					SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = true
					LibStub('LibWindow-1.1').windowData[v].storage.parent = UIParent
					v:SetParent(UIParent)
				end

				LibStub('LibWindow-1.1').SavePosition(v)
			end
		end
	end
end
