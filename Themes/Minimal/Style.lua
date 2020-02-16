local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_Minimal')
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Minimal = {
		['BT4Bar1'] = 'BOTTOMRIGHT,SUI_ActionBarAnchor,BOTTOM,-1,49',
		['BT4Bar2'] = 'BOTTOMRIGHT,SUI_ActionBarAnchor,BOTTOM,-1,2',
		--
		['BT4Bar3'] = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOM,1,49',
		['BT4Bar4'] = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOM,1,2',
		--
		['BT4Bar5'] = 'BOTTOMRIGHT,SUI_ActionBarAnchor,BOTTOM,-480,2',
		['BT4Bar6'] = 'BOTTOMLEFT,SUI_ActionBarAnchor,BOTTOM,480,2',
		--
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,0,120',
		--
		['BT4BarStanceBar'] = 'TOP,SpartanUI,TOP,-309,0',
		['BT4BarPetBar'] = 'TOP,SpartanUI,TOP,-558,0',
		--
		['BT4BarMicroMenu'] = 'TOP,SpartanUI,TOP,369,0',
		['BT4BarBagBar'] = 'TOP,SpartanUI,TOP,680,0'
	}

	--Init if needed
	if (SUI.DB.Artwork.Style == 'Minimal') then
		module:Init()
	end
end

function module:Init()
	module:SetupMenus()
	module:InitFramework()
	InitRan = true
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Minimal') then
		module:Disable()
	else
		if (not InitRan) then
			module:Init()
		end
		module:EnableFramework()
	end
end

function module:SetupMenus()
	SUI.opt.args['Artwork'].args['Art'] = {
		name = L['ArtworkOpt'],
		type = 'group',
		order = 10,
		args = {
			HideCenterGraphic = {
				name = L['Hide center graphic'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.Styles.Minimal.HideCenterGraphic
				end,
				set = function(info, val)
					SUI.DB.Styles.Minimal.HideCenterGraphic = val
					if SUI.DB.Styles.Minimal.HideCenterGraphic then
						SUI_Art_Minimal_Base1:Hide()
					else
						SUI_Art_Minimal_Base1:Show()
					end
				end
			},
			alpha = {
				name = L['ArtColor'],
				type = 'color',
				hasAlpha = true,
				order = 2,
				width = 'full',
				desc = L['TransparencyDesc'],
				get = function(info)
					return unpack(SUI.DB.Styles.Minimal.Color)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Minimal.Color = {r, b, g, a}
					module:SetColor()
				end
			}
		}
	}
end

function module:OnDisable()
	SUI_Art_Minimal:Hide()
end

function module:Options_PartyFrames()
	SUI.opt.args['PartyFrames'].args['MinimalFrameStyle'] = {
		name = L['FrameStyle'],
		type = 'select',
		order = 5,
		values = {['large'] = L['Large'], ['small'] = L['Small']},
		get = function(info)
			return SUI.DB.Styles.Minimal.PartyFramesSize
		end,
		set = function(info, val)
			SUI.DB.Styles.Minimal.PartyFramesSize = val
		end
	}
end
