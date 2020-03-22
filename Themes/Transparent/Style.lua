local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Transparent')
----------------------------------------------------------------------------------------------------
local InitRan = false

function module:OnInitialize()
	--Enable the in the Core options screen
	SUI.opt.args['General'].args['style'].args['OverallStyle'].args['Transparent'].disabled = false
	SUI.opt.args['General'].args['style'].args['Artwork'].args['Transparent'].disabled = false

	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Transparent = {
		['BT4Bar1'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-349,54',
		['BT4Bar2'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-349,3',
		['BT4Bar3'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,349,54',
		['BT4Bar4'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,349,3',
		['BT4Bar5'] = 'BOTTOMRIGHT,SUI_ActionBarAnchor,BOTTOMLEFT,47,0',
		['BT4Bar6'] = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOMRIGHT,-47,0',
		--
		['BT4BarStanceBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-243,145',
		['BT4BarPetBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-590,145',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,315,146',
		['BT4BarBagBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,638,154',
		--
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_ActionBarAnchor,TOP,0,15',
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_ActionBarAnchor,TOP,0,15'
	}
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Transparent') then
		module:Disable()
	else
		local plate =
			CreateFrame('Frame', 'Transparent_ActionBarPlate', SUI_Art_Transparent, 'Transparent_ActionBarsTemplate')
		plate:SetFrameStrata('BACKGROUND')
		plate:SetFrameLevel(1)
		plate:SetPoint('BOTTOM')

		SUI_Art_Transparent:SetFrameStrata('BACKGROUND')
		SUI_Art_Transparent:SetFrameLevel(1)

		do -- modify strata / levels of backdrops
			for i = 1, 6 do
				_G['Transparent_Bar' .. i]:SetFrameStrata('BACKGROUND')
				_G['Transparent_Bar' .. i]:SetFrameLevel(3)
			end
			for i = 1, 2 do
				_G['Transparent_Popup' .. i]:SetFrameStrata('BACKGROUND')
				_G['Transparent_Popup' .. i]:SetFrameLevel(3)
			end
		end

		if SUI.DB.Artwork.VehicleUI then
			RegisterStateDriver(SUI_Art_Transparent, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
		end

		module:SetColor()
		module:SetupMenus()
	end
end

function module:SetupMenus()
	SUI.opt.args['Artwork'].args['Artwork'] = {
		name = 'Artwork Options',
		type = 'group',
		order = 10,
		args = {
			Color = {
				name = L['ArtColor'],
				type = 'color',
				hasAlpha = true,
				order = 1,
				width = 'full',
				get = function(info)
					return unpack(SUI.DB.Styles.Transparent.Color.Art)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Transparent.Color.Art = {r, b, g, a}
					module:SetColor()
				end
			}
		}
	}
end

function module:OnDisable()
	UnregisterStateDriver(SUI_Art_Transparent, 'visibility')
	SUI_Art_Transparent:Hide()
end

----------------------------------------------------------------------------------------------------

function module:TooltipLoc(self, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'SUI_Art_Transparent', 'TOPRIGHT', 0, 10)
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_Transparent, 'visibility')
	end
end

function module:SetColor()
	local r, b, g, a = unpack(SUI.DB.Styles.Transparent.Color.Art)
	for i = 1, 6 do
		if _G['SUI_Art_Transparent_Base' .. i] then
			_G['SUI_Art_Transparent_Base' .. i]:SetVertexColor(r, b, g, a)
		end
		if SUI.DB.ActionBars['bar' .. i].enable then
			_G['Transparent_Bar' .. i .. 'BG']:SetVertexColor(r, b, g, a)
		end
		if _G['Transparent_Popup' .. i .. 'BG'] then
			_G['Transparent_Popup' .. i .. 'BG']:SetVertexColor(r, b, g, a)
		end
	end
end
