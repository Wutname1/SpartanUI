local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Artwork_BartenderBars')
module.bars = {}
module.DB = SUI.DBMod.BartenderBars
local StyleSettings
local Bartender4Version, BartenderMin = '', '4.7.1'
if select(4, GetAddOnInfo('Bartender4')) then
	Bartender4Version = GetAddOnMetadata('Bartender4', 'Version')
end

local function CheckForBartender()
	local isInstalled = true
	-- No Bartender/out of date Notification
	if (not select(4, GetAddOnInfo('Bartender4'))) then
		-- We always want to show it as the user can turn on / off Bartender at will
		isInstalled = false
		StaticPopup_Show('BartenderInstallWarning')
	elseif Bartender4Version < BartenderMin then
		isInstalled = false
		StaticPopup_Show('BartenderVerWarning')
	end

	return isInstalled
end

function module:Initialize(Settings)
	StyleSettings = Settings

	local isSuccessful = false

	StaticPopupDialogs['BartenderVerWarning'] = {
		text = '|cff33ff99SpartanUI v' ..
			SUI.Version ..
				'|n|r|n|n' ..
					L['Warning'] ..
						': ' ..
							L['BartenderOldMSG'] .. ' ' .. Bartender4Version .. '|n|nSpartanUI requires ' .. BartenderMin .. ' or higher.',
		button1 = 'Ok',
		OnAccept = function()
			SUI.DBG.BartenderVerWarning = SUI.Version
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs['BartenderInstallWarning'] = {
		text = '|cff33ff99SpartanUI v' ..
			SUI.Version .. '|n|r|n|n' .. L['Warning'] .. ': ' .. L['BartenderNotFoundMSG1'] .. '|n' .. L['BartenderNotFoundMSG2'],
		button1 = 'Ok',
		OnAccept = function()
			SUI.DBG.BartenderInstallWarning = SUI.Version
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}

	if CheckForBartender() then
		-- TODO: Currently in Core/Framework as needed prior to init - review for later
		-- if SUI.DBG.Bartender4 == nil then
		-- 	SUI.DBG.Bartender4 = {}
		-- end
		-- if SUI.DBG.BartenderChangesActive then
		-- 	SUI.DBG.BartenderChangesActive = false
		-- end

		if (SUI.DBMod.Artwork.FirstLoad) then
			isSuccessful = self:SetupProfile(StyleSettings)

			--Hide Bartender4 Minimap icon.
			Bartender4.db.profile.minimapIcon.hide = true
			local LDBIcon = LibStub('LibDBIcon-1.0', true)
			LDBIcon['Hide'](LDBIcon, 'Bartender4')
		else
			isSuccessful = true
		end

		if Bartender4 then
			--Update to the current profile
			SUI.DB.BT4Profile = Bartender4.db:GetCurrentProfile()
			Bartender4.db.RegisterCallback(self, 'OnProfileChanged', 'BT4RefreshConfig')
			Bartender4.db.RegisterCallback(self, 'OnProfileCopied', 'BT4RefreshConfig')
			Bartender4.db.RegisterCallback(self, 'OnProfileReset', 'BT4RefreshConfig')
		end

		--Create Bars
		self:factory()
		self:BuildOptions()
	end

	return isSuccessful
end

function module:SetupProfile(Settings)
	local isSetup = false

	--If our profile exists activate it.
	if (self:HasProfile(Settings.profile, true)) then
		if (Bartender4.db:GetCurrentProfile() ~= Settings.profile) then
			Bartender4.db:SetProfile(Settings.profile)
		end
		isSetup = true
	else
		self:CreateProfile(Settings.profile)
		isSetup = true
	end

	return isSetup
end

function module:GetBagBar()
	return BT4BarBagBar
end

function module:GetStanceBar()
	return BT4BarStanceBar
end

function module:GetPetBar()
	return BT4BarPetBar
end

function module:GetMicroMenuBar()
	return BT4BarMicroMenu
end

function module:ResetMovedBars()
	SUI.DBG.BartenderChangesActive = true
	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars == nil then
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
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
	for _, v in ipairs(FrameList) do
		if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] then
			SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = false
		end
	end
	SUI.DBG.BartenderChangesActive = false
end

function module:SetupMovedBars()
	local FrameList = {
		BT4Bar1,
		BT4Bar2,
		BT4Bar3,
		BT4Bar4,
		BT4Bar5,
		BT4Bar6,
		BT4Bar7,
		BT4Bar8,
		BT4Bar9,
		BT4Bar10,
		BT4BarBagBar,
		BT4BarExtraActionBar,
		BT4BarStanceBar,
		BT4BarPetBar,
		BT4BarMicroMenu
	}

	for _, v in ipairs(FrameList) do
		if v then
			v.SavePosition = function()
				if
					(not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] or v:GetParent():GetName() ~= 'UIParent') and
						not SUI.DBG.BartenderChangesActive
				 then
					SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = true
					LibStub('LibWindow-1.1').windowData[v].storage.parent = UIParent
					v:SetParent(UIParent)
				end

				LibStub('LibWindow-1.1').SavePosition(v)
			end
		end
	end
end

function module:ResetDB()
	Bartender4.db:ResetDB()
end

function module:UseBlizzardVehicleUI(shouldUse)
  Bartender4.db.profile.blizzardVehicle = shouldUse
  Bartender4:UpdateBlizzardVehicle()
end

function module:factory()
end


function module:HasProfile(Profile, Report)
	local profiles, r = Bartender4.db:GetProfiles(), false
	for _, v in pairs(profiles) do
		if v == Profile then
			r = true
		end
	end
	if (Report) and (r ~= true) then
		SUI:Print(Profile .. ' ' .. L['BartenderProfileCheckFail'])
	end
	return r
end

function module:BT4ProfileAttach(msg)
	PageData = {
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

			self:CreateProfile(Bartender4.db:GetCurrentProfile())
			ReloadUI()
		end,
		Skip = function()
			-- ReloadUI()
		end
	}
	local SetupWindow = SUI:GetModule('SetupWindow')
	SetupWindow:DisplayPage(PageData)
end

function module:BT4RefreshConfig()
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
			self:BT4ProfileAttach(
				"This bartender profile is currently attached to the style '" ..
					SUI.DBG.Bartender4[SUI.DB.BT4Profile].Style ..
						"' you are currently using " ..
							SUI.DBMod.Artwork.Style .. ' would you like to reassign the profile to this art skin? '
			)
		end
	else
		-- We do not know this profile, ask if we should attach it to this style.
		self:BT4ProfileAttach(
			'This bartender profile is currently NOT attached to any style you are currently using the ' ..
				SUI.DBMod.Artwork.Style .. ' style would you like to assign the profile to this art skin? '
		)
	end
end


function module:CreateProfile(ProfileOverride)
	SUI.DBG.BartenderChangesActive = true
	local ProfileName = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile
	if ProfileOverride then
		ProfileName = ProfileOverride
	end

	local BartenderSettings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderSettings
	--If this is set then we have already setup the bars once, and the user changed them
	if
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile and SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile ~= ProfileName and not ProfileOverride
	 then
		return
	end

	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo('Bartender4'))) then
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

	Bartender4:UpdateModuleConfigs()

	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile then
		Bartender4.db:SetProfile(SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile)
	elseif SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile then
		Bartender4.db:SetProfile(SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile)
	else
		Bartender4.db:SetProfile(SUI.DB.BT4Profile)
	end

	SUI.DBG.BartenderChangesActive = false
end

function module:BuildOptions()
	SUI.opt.args['Artwork'].args['Bar Manager'] = {
		name = 'Bar Manager', -- TODO: L['Bar Manager'],
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
					SUI:GetModule('Style_' .. SUI.DBMod.Artwork.Style):SetupProfile()

					self:ResetMovedBars()

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
	SUI.opt.args['Help'].args['ResetActionBars'] = SUI.opt.args['Artwork'].args['Bar Manager'].args['ResetActionBars']
end
