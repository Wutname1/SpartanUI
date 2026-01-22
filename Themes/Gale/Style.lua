local SUI, L = SUI, SUI.L
---@class SUI.Theme.Gale : SUI.Theme.StyleBase
local module = SUI:NewModule('Style.Gale')
local Artwork_Core = SUI:GetModule('Artwork') ---@type SUI.Module.Artwork
local unpack = unpack
----------------------------------------------------------------------------------------------------

function module:OnInitialize()
	local BarHandler = SUI.Handlers.BarSystem
	-- Gale theme bar positioning - actionbars together & minimap in top right
	-- Bars 1 and 2 horizontally stacked with #1 on top, bar 4 to the left and 3 to the right
	-- Pet Bar above Bar 1, Bar 6 vertical on right side
	-- Bar 5 positioned to left side but disabled by default
	BarHandler.BarPosition.BT4.Gale = {
		['BT4Bar1'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,0,90', -- Top of main stack
		['BT4Bar2'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,0,45', -- Bottom of main stack
		--
		['BT4Bar3'] = 'BOTTOMRIGHT,BT4Bar1,BOTTOMRIGHT,260,0', -- To the right
		['BT4Bar4'] = 'BOTTOMLEFT,BT4Bar1,BOTTOMLEFT,-260,0', -- To the left
		--
		['BT4Bar5'] = 'LEFT,SUI_BottomAnchor,LEFT,10,0', -- Left side, disabled by default
		['BT4Bar6'] = 'RIGHT,SpartanUI,RIGHT,-10,0', -- Vertical on right side
		--
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,0,130',
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,0,130',
		--
		['BT4BarStanceBar'] = 'TOP,SpartanUI,TOP,-301,0',
		['BT4BarPetBar'] = 'BOTTOM,BT4Bar1,TOP,0,5', -- Above Bar 1
		['MultiCastActionBarFrame'] = 'BOTTOM,BT4Bar1,TOP,0,5',
		--
		['BT4BarMicroMenu'] = 'TOP,SpartanUI,TOP,322,0',
		['BT4BarBagBar'] = 'TOP,SpartanUI,TOP,595,0',
	}
	-- All bars scaled to 1.1 with Pet Bar increased to match
	BarHandler.BarScale.BT4.Gale = {
		['BT4Bar1'] = 1.1,
		['BT4Bar2'] = 1.1,
		['BT4Bar3'] = 1.1,
		['BT4Bar4'] = 1.1,
		['BT4Bar5'] = 1.1,
		['BT4Bar6'] = 1.1,
		['BT4Bar7'] = 1.1,
		['BT4Bar8'] = 1.1,
		['BT4Bar9'] = 1.1,
		['BT4Bar10'] = 1.1,
		['BT4BarBagBar'] = 0.6,
		['BT4BarExtraActionBar'] = 0.8,
		['BT4BarStanceBar'] = 0.6,
		['BT4BarPetBar'] = 1.1, -- Increased to match action bars
		['MultiCastActionBarFrame'] = 1.1,
		['BT4BarMicroMenu'] = 0.6,
	}

	-- Minimap in top right, 1.3 times larger than normal with dark border and class color glow
	local minimapSettings = {
		UnderVehicleUI = false,
		scaleWithArt = false,
		position = 'TOPRIGHT,SpartanUI,TOPRIGHT,-20,-20',
		shape = 'square',
		scale = 1.3,
	}
	SUI.Minimap:Register('Gale', minimapSettings)

	-- Register UnitFrame style for Gale
	if SUI.UF then
		SUI.UF.Style:Register('Gale', {
			displayName = 'Gale',
			setup = {
				image = 'Interface\\AddOns\\SpartanUI\\images\\setup\\Style_Frames_Gale',
			},
		})
	end
end

function module:OnEnable()
	if SUI.DB.Artwork.Style ~= 'Gale' then
		module:Disable()
	else
		module:Options()

		-- Configure default bar visibility - only bars 1-4 & 6 enabled, 5 disabled
		if BT4BarBar5 then
			BT4BarBar5:SetAttribute('state-visibility', 'hide')
		end

		hooksecurefunc('UIParent_ManageFramePositions', function()
			if TutorialFrameAlertButton then
				TutorialFrameAlertButton:SetParent(Minimap)
				TutorialFrameAlertButton:ClearAllPoints()
				TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
			end
			if CastingBarFrame then
				CastingBarFrame:ClearAllPoints()
				CastingBarFrame:SetPoint('BOTTOM', BT4Bar1, 'TOP', 0, 5)
			end
		end)

		--Setup Sliding Trays
		module:SlidingTrays()
		if BT4BarBagBar and BT4BarPetBar.position then
			BT4BarPetBar:position('TOPLEFT', 'SlidingTray_left', 'TOPLEFT', 50, -2)
			BT4BarStanceBar:position('TOPRIGHT', 'SlidingTray_left', 'TOPRIGHT', -50, -2)
			BT4BarMicroMenu:position('TOPLEFT', 'SlidingTray_right', 'TOPLEFT', 50, -2)
			BT4BarBagBar:position('TOPRIGHT', 'SlidingTray_right', 'TOPRIGHT', -100, -2)
		end

		module:SetColor()
		module:ConfigureUnitFrames()

		SUI_Art_Gale:Show()
	end
end

function module:ConfigureUnitFrames()
	-- Configure Party and Raid Frames
	-- Larger size, power bar height 10, health height 40, width 110, centered names
	-- Solid black background with 1px border between health and power bars
	if SUI.UF and SUI.UF.db then
		local db = SUI.UF.db.profile

		-- Party Frame configuration
		if db.party then
			db.party.width = 110
			db.party.health.height = 40
			db.party.power.height = 10
			db.party.name.position = 'CENTER'
			db.party.health.backgroundColor = { 0, 0, 0, 1 } -- Solid black
			db.party.power.backgroundColor = { 0, 0, 0, 1 } -- Solid black
			db.party.health.border = { 1, 1, 1, 1 } -- 1px white border
			db.party.power.border = { 1, 1, 1, 1 } -- 1px white border
		end

		-- Raid Frame configuration
		if db.raid then
			db.raid.width = 110
			db.raid.health.height = 40
			db.raid.power.height = 10
			db.raid.name.position = 'CENTER'
			db.raid.health.backgroundColor = { 0, 0, 0, 1 } -- Solid black
			db.raid.power.backgroundColor = { 0, 0, 0, 1 } -- Solid black
			db.raid.health.border = { 1, 1, 1, 1 } -- 1px white border
			db.raid.power.border = { 1, 1, 1, 1 } -- 1px white border
		end

		-- Player Frame configuration
		-- Width 220, health height 25, disable power text, inverted bar order
		-- Player name on left, total health (no abbreviation) on right
		if db.player then
			db.player.width = 220
			db.player.health.height = 25
			db.player.power.text.enabled = false
			db.player.name.position = 'LEFT'
			db.player.health.text.position = 'RIGHT'
			db.player.health.text.format = '[health:current]' -- No abbreviation
			db.player.health.backgroundColor = { 0, 0, 0, 1 } -- Solid black
			db.player.power.backgroundColor = { 0, 0, 0, 1 } -- Solid black
			db.player.threatglow.enabled = true -- Enable threat glow
			-- Inverted order: power on top, health below, castbar bottom
			db.player.power.position = 'TOP'
			db.player.health.position = 'CENTER'
			db.player.castbar.position = 'BOTTOM'
		end

		-- Target Frame configuration
		-- Same as player but opposite text positioning
		if db.target then
			db.target.width = 220
			db.target.health.height = 25
			db.target.power.text.enabled = false
			db.target.name.position = 'RIGHT' -- Opposite of player
			db.target.health.text.position = 'LEFT' -- Opposite of player
			db.target.health.text.format = '[health:current]' -- No abbreviation
			db.target.health.backgroundColor = { 0, 0, 0, 1 } -- Solid black
			db.target.power.backgroundColor = { 0, 0, 0, 1 } -- Solid black
			db.target.threatglow.enabled = true -- Enable threat glow
			-- Inverted order: power on top, health below, castbar bottom
			db.target.power.position = 'TOP'
			db.target.health.position = 'CENTER'
			db.target.castbar.position = 'BOTTOM'
		end
	end
end

function module:TooltipLoc(tooltip, parent)
	if parent == 'UIParent' then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', SUI_Art_Gale, 'BOTTOMRIGHT', -20, 20)
	end
end

function module:Options()
	SUI.opt.args['Artwork'].args['Art'] = {
		name = L['Artwork Options'],
		type = 'group',
		order = 10,
		args = {
			UseClassColors = {
				name = L['Use Class Colors'],
				type = 'toggle',
				order = 1,
				desc = L['Use your class colors for artwork instead of custom colors'],
				get = function(info)
					return SUI.DB.Styles.Gale.UseClassColors
				end,
				set = function(info, val)
					SUI.DB.Styles.Gale.UseClassColors = val
					module:SetColor()
				end,
			},
			alpha = {
				name = L['Artwork Color'],
				type = 'color',
				hasAlpha = true,
				order = 2,
				width = 'full',
				desc = 'Gale theme uses solid black backgrounds with class-colored borders',
				hidden = function(info)
					return SUI.DB.Styles.Gale.UseClassColors
				end,
				get = function(info)
					return unpack(SUI.DB.Styles.Gale.Color.Art)
				end,
				set = function(info, r, g, b, a)
					SUI.DB.Styles.Gale.Color.Art = { r, g, b, a }
					module:SetColor()
				end,
			},
		},
	}
end

function module:OnDisable()
	SUI_Art_Gale:Hide()
end

function module:SlidingTrays()
	local Settings = {
		trayImage = 'Interface\\AddOns\\SpartanUI\\Themes\\Gale\\Images\\tray-bg',
		-- Uses default coordinates from DefaultTraySettings
	}

	Artwork_Core:SlidingTrays(Settings)
end

function module:SetColor()
	local r, g, b, a

	if SUI.DB.Styles.Gale.UseClassColors then
		-- Get player class colors
		local _, class = UnitClass('player')
		local classColor = RAID_CLASS_COLORS[class]
		if classColor then
			r, g, b, a = classColor.r, classColor.g, classColor.b, 1
		else
			-- Fallback to default if class color not found
			r, g, b, a = unpack(SUI.DB.Styles.Gale.Color.Art or { 0, 0, 0, 1 })
		end
	else
		-- Use custom colors - Gale uses solid black backgrounds with class-colored elements
		r, g, b, a = unpack(SUI.DB.Styles.Gale.Color.Art or { 0, 0, 0, 1 })
	end

	-- Apply coloring to main artwork elements
	if SUI_Art_Gale_Base1 then
		SUI_Art_Gale_Base1:SetVertexColor(r, g, b, a)
	end

	-- Apply to sliding trays
	for _, v in pairs(Artwork_Core.Trays) do
		v.expanded.bg:SetVertexColor(r, g, b, a)
		v.collapsed.bg:SetVertexColor(r, g, b, a)
	end
end
