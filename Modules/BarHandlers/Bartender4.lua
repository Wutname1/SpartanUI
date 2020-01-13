local SUI = SUI
local L = SUI.L
local module = SUI:GetModule('Component_BarHandler')
local BartenderMin = '4.8.5'
local MoveIt = SUI:GetModule('Component_MoveIt')
local scaleData
------------------------------------------------------------

local function Options()
	SUI.opt.args['General'].args['Bartender'] = {
		name = 'Bartender',
		type = 'group',
		order = 500,
		args = {
			MoveBars = {
				name = L['Move ActionBars'],
				type = 'execute',
				order = 1,
				func = function()
					Bartender4:Unlock()
				end
			},
			ResetActionBars = {
				name = L['Reset ActionBars'],
				type = 'execute',
				order = 2,
				func = function()
					--Tell SUI to reload config
					SUI.DBMod.Artwork.FirstLoad = true

					--Strip custom BT4 Profile from config
					if SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile then
						SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile = nil
					end

					--Force Rebuild of primary bar profile
					module.Bartender4:SetupProfile(true)

					--Reset Moved bars
					local FrameList = {
						BT4Bar1,
						BT4Bar2,
						BT4Bar3,
						BT4Bar4,
						BT4Bar5,
						BT4Bar6,
						BT4BarBagBar,
						BT4BarExtraActionBar,
						BT4BarStanceBar,
						BT4BarPetBar,
						BT4BarMicroMenu
					}
					for _, v in ipairs(FrameList) do
						-- if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] then
						SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = false
						-- end
					end

					--go!
					ReloadUI()
				end
			},
			line1 = {name = '', type = 'header', order = 2.5},
			LockButtons = {
				name = L['Lock Buttons'],
				type = 'toggle',
				order = 3,
				get = function(info)
					if Bartender4 then
						return Bartender4.db.profile.buttonlock
					else
						SUI.opt.args['Artwork'].args['Base'].args['LockButtons'].disabled = true
						return false
					end
				end,
				set = function(info, value)
					Bartender4.db.profile.buttonlock = value
					Bartender4.Bar:ForAll('ForAll', 'SetAttribute', 'buttonlock', value)
				end
			},
			kb = {
				order = 4,
				type = 'execute',
				name = L['Key Bindings'],
				func = function()
					LibStub('LibKeyBound-1.0'):Toggle()
					AceConfigDialog:Close('Bartender4')
				end
			},
			line2 = {name = '', type = 'header', order = 5.5},
			VehicleUI = {
				name = L['Use Blizzard Vehicle UI'],
				type = 'toggle',
				order = 6,
				get = function(info)
					return SUI.DBMod.Artwork.VehicleUI
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
						return
					end
					SUI.DBMod.Artwork.VehicleUI = val
					--Make sure bartender knows to do it, or not...
					if Bartender4 then
						Bartender4.db.profile.blizzardVehicle = val
						Bartender4:UpdateBlizzardVehicle()
					end

					if SUI.DBMod.Artwork.VehicleUI then
						if SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style).SetupVehicleUI() ~= nil then
							SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):SetupVehicleUI()
						end
					else
						if SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style).RemoveVehicleUI() ~= nil then
							SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):RemoveVehicleUI()
						end
					end
				end
			},
			-- MoveBars={name = "Move Bars", type = "toggle",order=0.91,
			-- get = function(info) if Bartender4 then return Bartender4.db.profile.buttonlock else SUI.opt.args["Artwork"].args["Base"].args["LockButtons"].disabled=true; return false; end end,
			-- set = function(info, value)
			-- Bartender4.db.profile.buttonlock = value
			-- Bartender4.Bar:ForAll("ForAll", "SetAttribute", "buttonlock", value)
			-- end,
			-- },
			minimapIcon = {
				order = 7,
				type = 'toggle',
				name = L['Minimap Icon'],
				get = function()
					return not Bartender4.db.profile.minimapIcon.hide
				end,
				set = function(info, value)
					Bartender4.db.profile.minimapIcon.hide = not value
					LDBIcon[value and 'Show' or 'Hide'](LDBIcon, 'Bartender4')
				end,
				disabled = function()
					return not LDBIcon
				end
			}
		}
	}

	-- Add to help screen
	SUI.opt.args.Help.args.ResetActionBars = SUI.opt.args['General'].args['Bartender'].args['ResetActionBars']
end

local function BTMover(BarName, DisplayName)
	if not BarName then
		return
	end
	local bar = _G[BarName]
	if bar then
		function bar:LoadPosition()
		end

		if scaleData[BarName] then
			bar:SetScale(scaleData[BarName])
		end
		MoveIt:CreateMover(bar, BarName, DisplayName)
		MoveIt:UpdateMover(BarName, bar.overlay, true)
	end
end

local function AddMovers()
	for i = 1, 10 do
		local bar = _G['BT4Bar' .. i]
		if bar then
			function bar:LoadPosition()
			end

			if scaleData[BarName] then
				bar:SetScale(scaleData[BarName])
			end
			MoveIt:CreateMover(bar, 'BT4Bar' .. i, 'Bar ' .. i)
			MoveIt:UpdateMover('BT4Bar' .. i, bar.overlay, true)
		end
	end
	BTMover('BT4BarBagBar', 'Bag bar')
	BTMover('BT4BarExtraActionBar', 'Extra Action Bar')
	BTMover('BT4BarStanceBar', 'Stance Bar')
	BTMover('BT4BarPetBar', 'Pet Bar')
	BTMover('BT4BarMicroMenu', 'Micro menu')
end

local function OnInitialize()
	--Bartender4
	if SUI.DBG.BartenderChangesActive then
		SUI.DBG.BartenderChangesActive = false
	end
	if Bartender4 then
		--Update to the current profile
		SUI.DB.BT4Profile = Bartender4.db:GetCurrentProfile()
		Bartender4.db.RegisterCallback(SUI, 'OnProfileChanged', 'BT4RefreshConfig')
		Bartender4.db.RegisterCallback(SUI, 'OnProfileCopied', 'BT4RefreshConfig')
		Bartender4.db.RegisterCallback(SUI, 'OnProfileReset', 'BT4RefreshConfig')
	end
	scaleData = module.BarScale.BT4.default
	if SUI.DB.EnabledComponents.Artwork and module.BarScale.BT4[SUI.DBMod.Artwork.Style] then
		scaleData = SUI:MergeData(module.BarScale.BT4[SUI.DBMod.Artwork.Style], module.BarScale.BT4.default)
	end
end

local function RefreshConfig()
	-- Load Position
	local BartenderSettings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderSettings

	local positionData = module.BarPosition.BT4.default
	-- If artwork is enabled load the art's position data if supplied
	if SUI.DB.EnabledComponents.Artwork and module.BarPosition.BT4[SUI.DBMod.Artwork.Style] then
		positionData = SUI:MergeData(module.BarPosition.BT4[SUI.DBMod.Artwork.Style], module.BarPosition.BT4.default)
	end
	scaleData = module.BarScale.BT4.default
	if SUI.DB.EnabledComponents.Artwork and module.BarScale.BT4[SUI.DBMod.Artwork.Style] then
		scaleData = SUI:MergeData(module.BarScale.BT4[SUI.DBMod.Artwork.Style], module.BarScale.BT4.default)
	end

	local FrameList = {
		BT4Bar1,
		BT4Bar2,
		BT4Bar3,
		BT4Bar4,
		BT4Bar5,
		BT4Bar6,
		BT4BarBagBar,
		BT4BarExtraActionBar,
		BT4BarStanceBar,
		BT4BarPetBar,
		BT4BarMicroMenu
	}
	-- Position Bars
	for _, v in ipairs(FrameList) do
		v = v:GetName()

		if _G[v] and positionData[v] ~= '' then
			local f = _G[v]
			if f.mover then
				f = f.mover
			end

			local point, anchor, secondaryPoint, x, y = strsplit(',', positionData[v])
			f:ClearAllPoints()
			f:SetPoint(point, anchor, secondaryPoint, x, y)
			if scaleData[v] then
				f:SetScale(max(SUI.DB.scale * (scaleData[v] * 1.08696), .01))
				_G[v]:SetScale(max(SUI.DB.scale * (scaleData[v] * 1.08696), .01))
			end
		-- MoveIt:UpdateMover(f.name)
		end
	end
end

local function OnEnable()
	-- Build options
	Options()

	-- No Bartender/out of date Notification
	if SUI.Bartender4Version < BartenderMin then
		-- Minimum version warning.
		StaticPopupDialogs['BartenderVerWarning'] = {
			text = '|cff33ff99SpartanUI v' ..
				SUI.Version ..
					'|n|r|n|n' ..
						L['Warning'] ..
							': ' ..
								L['BartenderOldMSG'] ..
									' ' .. SUI.Bartender4Version .. '|n|nSpartanUI requires ' .. BartenderMin .. ' or higher.',
			button1 = 'Ok',
			OnAccept = function()
				SUI.DBG.BartenderVerWarning = SUI.Version
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = false
		}
		StaticPopup_Show('BartenderVerWarning')
	end

	-- Position Bars
	RefreshConfig()

	-- Movement System
	AddMovers()

	-- Eventually this will not be needed until then port this over.
	if (not select(4, GetAddOnInfo('Bartender4')) and not SUI.DB.BT4Warned) then
		local cnt = 1
		local BT4Warning = CreateFrame('Frame')
		BT4Warning:SetScript(
			'OnEvent',
			function()
				if cnt <= 10 then
					StdUi:Dialog(
						L['Warning'],
						L['Bartender4 not detected! Please download and install Bartender4.'] .. ' Warning ' .. cnt .. ' of 10'
					)
				else
					SUI.DB.BT4Warned = true
				end
				cnt = cnt + 1
			end
		)
		BT4Warning:RegisterEvent('PLAYER_LOGIN')
		BT4Warning:RegisterEvent('PLAYER_ENTERING_WORLD')
		BT4Warning:RegisterEvent('ZONE_CHANGED')
		BT4Warning:RegisterEvent('ZONE_CHANGED_INDOORS')
		BT4Warning:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	end

	--Disable BT4 Movement system
	function Bartender4:Unlock()
		print('BT4 Movement System is disabled by SUI. You can move the bars via /sui move')
	end

	function Bartender4:Lock()
	end

	-- Do what Bartender isn't - Make the Bag buttons the same size
	do -- modify CharacterBag(0-3) Scale
		for i = 1, 4 do
			_G['CharacterBag' .. (i - 1) .. 'Slot']:SetScale(1.25)
		end
	end

	--Replace the BT4 Enable function so we know when new objects are created
	local BT4ActionBars = Bartender4:GetModule('ActionBars')
	function BT4ActionBars:EnableBar(id)
		id = tonumber(id)
		local bar = self.actionbars[id]
		local config = self.db.profile.actionbars[id]
		config.enabled = true
		if not bar then
			bar = self:Create(id, config)
			self.actionbars[id] = bar
		else
			bar.disabled = nil
			self:CreateBarOption(id)
			bar:ApplyConfig(config)
		end

		--SUI Stuff
		RefreshConfig()
		local MoveIt = SUI:GetModule('Component_MoveIt')
		MoveIt:CreateMover(bar, bar:GetName(), 'Bar ' .. id)
		MoveIt:UpdateMover(bar:GetName(), bar.overlay, true)

		if not Bartender4.Locked then
			bar:Unlock()
		end
	end
end

local function Unlock()
	local MoveIt = SUI:GetModule('Component_MoveIt')
	local MoverList = {}

	-- Generate list of objects to move
	for i = 1, 10 do
		local bar = _G['BT4Bar' .. i]
		if bar then
			MoverList[#MoverList] = 'BT4Bar' .. i
		end
	end

	-- Move them!
	MoveIt:MoveIt(MoverList)
end

local function BT4ProfileAttach(msg)
	local PageData = {
		title = 'SpartanUI',
		Desc1 = msg,
		-- Desc2 = Desc2,
		width = 400,
		height = 150,
		Display = function()
			SUI_Win:ClearAllPoints()
			SUI_Win:SetPoint('TOP', 0, -20)
			SUI_Win:SetSize(400, 150)
			SUI_Win.Status:Hide()

			SUI_Win.Skip:SetText('DO NOT ATTACH')
			SUI_Win.Skip:SetSize(110, 25)
			SUI_Win.Skip:ClearAllPoints()
			SUI_Win.Skip:SetPoint('BOTTOMRIGHT', SUI_Win, 'BOTTOM', -15, 15)

			SUI_Win.Next:SetText('ATTACH')
			SUI_Win.Next:ClearAllPoints()
			SUI_Win.Next:SetPoint('BOTTOMLEFT', SUI_Win, 'BOTTOM', 15, 15)
		end,
		Next = function()
			SUI.DBG.Bartender4[SUI.DB.BT4Profile] = {
				Style = SUI.DBMod.Artwork.Style
			}
			-- Catch if Movedbars is not initalized
			if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars then
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
			end
			--Setup profile
			SUI:GetModule('Component_Artwork'):SetupProfile(Bartender4.db:GetCurrentProfile())
			ReloadUI()
		end,
		Skip = function()
			-- ReloadUI()
		end
	}
	local SetupWindow = SUI:GetModule('SUIWindow')
	SetupWindow:DisplayPage(PageData)
end

function SUI:BT4RefreshConfig()
	if SUI.DBG.BartenderChangesActive or SUI.DBMod.Artwork.FirstLoad then
		return
	end
	-- if SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile == Bartender4.db:GetCurrentProfile() then return end -- Catch False positive)
	SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile = Bartender4.db:GetCurrentProfile()
	SUI.DB.BT4Profile = Bartender4.db:GetCurrentProfile()

	if SUI.DBG.Bartender4 == nil then
		SUI.DBG.Bartender4 = {}
	end

	if SUI.DBG.Bartender4[SUI.DB.BT4Profile] then
		-- We know this profile.
		if SUI.DBG.Bartender4[SUI.DB.BT4Profile].Style == SUI.DBMod.Artwork.Style then
			--Profile is for this style, prompt to ReloadUI; usually un needed can uncomment if needed latter
			-- SUI:reloadui("Your bartender profile has changed, a reload may be required for the bars to appear properly.")
			-- Catch if Movedbars is not initalized
			if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars then
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
			end
		else
			--Ask if we should change to the correct profile or if we should change the profile to be for this style
			BT4ProfileAttach(
				"This bartender profile is currently attached to the style '" ..
					SUI.DBG.Bartender4[SUI.DB.BT4Profile].Style ..
						"' you are currently using " ..
							SUI.DBMod.Artwork.Style .. ' would you like to reassign the profile to this art skin? '
			)
		end
	else
		-- We do not know this profile, ask if we should attach it to this style.
		BT4ProfileAttach(
			'This bartender profile is currently NOT attached to any style you are currently using the ' ..
				SUI.DBMod.Artwork.Style .. ' style would you like to assign the profile to this art skin? '
		)
	end

	SUI:Print('Bartender4 Profile changed to: ' .. Bartender4.db:GetCurrentProfile())
end

module:AddBarSystem('Bartender4', OnInitialize, OnEnable, nil, Unlock, RefreshConfig)

-- Bartender4 Items

-- Creates the SUI BT4 Profile
local function SetupProfile(updateConfig)
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo('Bartender4'))) then
		return
	end

	--Flag the SUI.DB that we are making changes
	SUI.DBG.BartenderChangesActive = true
	--Load the profile name the art style wants
	local ProfileName = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile

	--Load the BT settings used by the art style
	local BartenderSettings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderSettings

	--If this is set then we have already setup the bars once, and the user changed them
	if
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile and SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile ~= ProfileName and
			not ProfileOverride
	 then
		return
	end

	-- Set/Create our Profile
	Bartender4.db:SetProfile(ProfileName)

	--Load the Profile Data
	for k, v in LibStub('AceAddon-3.0'):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = SUI:MergeData(v.db.profile, BartenderSettings[k], true)
		end
	end

	-- Update BT4 Configuration
	if updateConfig then
		Bartender4:UpdateModuleConfigs()
	end

	SUI.DBG.BartenderChangesActive = false
end

-- Returns True if the Inputed profileName is the active one in BT4
local function ProfileCheck(profileName, Report)
	if not Bartender4 then
		return
	end

	local profiles, r = Bartender4.db:GetProfiles(), false
	for _, v in pairs(profiles) do
		if v == profileName then
			r = true
		end
	end
	if (Report) and (r ~= true) then
		SUI:Print(profileName .. ' ' .. L['BartenderProfileCheckFail'])
	end
	return r
end

module.Bartender4 = {
	SetupProfile = SetupProfile,
	ProfileCheck = ProfileCheck
}
