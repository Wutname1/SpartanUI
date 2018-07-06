local _G, SUI = _G, SUI
local L = SUI.L
local Artwork_Core = SUI:NewModule("Artwork_Core")
local Bartender4Version, BartenderMin = "", "4.7.1"
if select(4, GetAddOnInfo("Bartender4")) then
	Bartender4Version = GetAddOnMetadata("Bartender4", "Version")
end

function Artwork_Core:isPartialMatch(frameName, tab)
	local result = false

	for _, v in ipairs(tab) do
		local startpos = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true
		end
	end

	return result
end

function Artwork_Core:isInTable(tab, frameName)
	for _, v in ipairs(tab) do
		if (strlower(v) == strlower(frameName)) then
			return true
		end
	end
	return false
end

function Artwork_Core:round(num) -- rounds a number to 2 decimal places
	if num then
		return floor((num * 10 ^ 2) + 0.5) / (10 ^ 2)
	end
end

function Artwork_Core:MoveTalkingHeadUI()
	local THUDB = SUI.DB.Styles[SUI.DBMod.Artwork.Style].TalkingHeadUI
	local MoveTalkingHead = CreateFrame("Frame")
	MoveTalkingHead:RegisterEvent("ADDON_LOADED")
	MoveTalkingHead:SetScript(
		"OnEvent",
		function(self, event, ...)
			local addonName = ...
			if addonName and addonName == "Blizzard_TalkingHeadUI" then
				TalkingHeadFrame:SetMovable(true)
				TalkingHeadFrame:SetClampedToScreen(true)
				TalkingHeadFrame.ignoreFramePositionManager = true
				TalkingHeadFrame:ClearAllPoints()
				TalkingHeadFrame:SetPoint(THUDB.point, UIParent, THUDB.relPoint, THUDB.x, THUDB.y)
				if THUDB.scale then -- set scale
					TalkingHeadFrame:SetScale(THUDB.scale)
				end
			end
		end
	)
end

function Artwork_Core:ActionBarPlates(plate)
	local lib = LibStub("LibWindow-1.1", true)
	if not lib then
		return
	end
	function lib.RegisterConfig(frame, storage, names)
		if not lib.windowData[frame] then
			lib.windowData[frame] = {}
		end
		lib.windowData[frame].names = names
		lib.windowData[frame].storage = storage

		-- If no name return, helps avoid other addons that use the library
		if (frame:GetName() == nil) then
			return
		end

		-- Catch if Movedbars is not initalized
		if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars == nil then
			SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
		end

		-- If the name contains Bartender and we have not moved it set the parent to what is in sorage
		-- if (frame:GetName():match("BT4Bar")) and storage.parent and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[frame:GetName()] then
		if (frame:GetName():match("BT4Bar")) and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[frame:GetName()] then
			-- end
			-- end
			-- if (storage.parent) and _G[storage.parent] then
			-- frame:SetParent(storage.parent);
			frame:SetParent(plate)
			-- if storage.parent == plate then
			frame:SetFrameStrata("LOW")
		else
			-- print("---")
			-- print(frame:GetName())
			-- print(SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[frame:GetName()])
			-- print(storage.parent)
			-- print(plate)
			-- print("---")
			storage.parent = UIParent
		end
	end
end

function Artwork_Core:OnInitialize()
	StaticPopupDialogs["BartenderVerWarning"] = {
		text = "|cff33ff99SpartanUI v" ..
			SUI.Version ..
				"|n|r|n|n" ..
					L["Warning"] ..
						": " ..
							L["BartenderOldMSG"] .. " " .. Bartender4Version .. "|n|nSpartanUI requires " .. BartenderMin .. " or higher.",
		button1 = "Ok",
		OnAccept = function()
			SUI.DBG.BartenderVerWarning = SUI.Version
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}
	StaticPopupDialogs["BartenderInstallWarning"] = {
		text = "|cff33ff99SpartanUI v" ..
			SUI.Version .. "|n|r|n|n" .. L["Warning"] .. ": " .. L["BartenderNotFoundMSG1"] .. "|n" .. L["BartenderNotFoundMSG2"],
		button1 = "Ok",
		OnAccept = function()
			SUI.DBG.BartenderInstallWarning = SUI.Version
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false
	}

	if not SUI.DBMod.Artwork.SetupDone then
		Artwork_Core:FirstTime()
	end
	if SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars == nil then
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars = {}
	end
	Artwork_Core:CheckMiniMap()
end

function Artwork_Core:FirstTime()
	SUI.DBMod.Artwork.SetupDone = false
	local PageData = {
		SubTitle = "Art Style",
		Desc1 = "Please pick an art style from the options below.",
		Display = function()
			--Container
			SUI_Win.Artwork = CreateFrame("Frame", nil)
			SUI_Win.Artwork:SetParent(SUI_Win.content)
			SUI_Win.Artwork:SetAllPoints(SUI_Win.content)

			local RadioButtons = function(self)
				SUI_Win.Artwork.Classic.radio:SetValue(false)
				SUI_Win.Artwork.Transparent.radio:SetValue(false)
				SUI_Win.Artwork.Minimal.radio:SetValue(false)
				SUI_Win.Artwork.Fel.radio:SetValue(false)
				self.radio:SetValue(true)
			end

			local gui = LibStub("AceGUI-3.0")
			local control, radio

			--Classic
			control = gui:Create("Icon")
			control:SetImage("interface\\addons\\SpartanUI_Artwork\\Themes\\Classic\\Images\\base-center")
			control:SetImageSize(120, 60)
			control:SetPoint("TOPRIGHT", SUI_Win.Artwork, "TOP", -30, -30)
			control:SetCallback("OnClick", RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create("CheckBox")
			radio:SetLabel("Classic")
			radio:SetUserData("value", "Classic")
			radio:SetUserData("text", "Classic")
			radio:SetType("radio")
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.4)
			radio:SetHeight(16)
			radio.frame:SetPoint("TOP", control.frame, "BOTTOM", 0, 0)
			radio:SetCallback("OnClick", RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Classic = control

			--Fel
			control = gui:Create("Icon")
			control:SetImage("interface\\addons\\SpartanUI\\media\\Style_Fel")
			control:SetImageSize(120, 60)
			control:SetPoint("TOPLEFT", SUI_Win.Artwork, "TOP", 30, -30)
			control:SetCallback("OnClick", RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create("CheckBox")
			radio:SetLabel("Fel")
			radio:SetUserData("value", "Fel")
			radio:SetUserData("text", "Fel")
			radio:SetType("radio")
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint("TOP", control.frame, "BOTTOM", 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Fel = control

			--Transparent
			control = gui:Create("Icon")
			control:SetImage("interface\\addons\\SpartanUI\\media\\Style_Transparent")
			control:SetImageSize(120, 60)
			control:SetPoint("TOP", SUI_Win.Artwork.Classic.frame, "BOTTOM", 0, -60)
			control:SetCallback("OnClick", RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create("CheckBox")
			radio:SetLabel("Transparent")
			radio:SetUserData("value", "Transparent")
			radio:SetUserData("text", "Transparent")
			radio:SetType("radio")
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint("TOP", control.frame, "BOTTOM", 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Transparent = control

			--Minimal
			control = gui:Create("Icon")
			control:SetImage("interface\\addons\\SpartanUI\\media\\Style_Minimal")
			control:SetImageSize(120, 60)
			control:SetPoint("TOP", SUI_Win.Artwork.Fel.frame, "BOTTOM", 0, -60)
			control:SetCallback("OnClick", RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create("CheckBox")
			radio:SetLabel("Minimal")
			radio:SetUserData("value", "Minimal")
			radio:SetUserData("text", "Minimal")
			radio:SetType("radio")
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint("TOP", control.frame, "BOTTOM", 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Minimal = control

			SUI_Win.Artwork.Classic.radio:SetValue(true)
		end,
		Next = function()
			SUI.DBMod.Artwork.SetupDone = true

			if (SUI_Win.Artwork.Classic.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = "Classic"
			end
			if (SUI_Win.Artwork.Fel.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = "Fel"
			end
			if (SUI_Win.Artwork.Transparent.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = "Transparent"
			end
			if (SUI_Win.Artwork.Minimal.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = "Minimal"
			end

			SUI.DBMod.PlayerFrames.Style = SUI.DBMod.Artwork.Style
			SUI.DBMod.PartyFrames.Style = SUI.DBMod.Artwork.Style
			SUI.DBMod.RaidFrames.Style = SUI.DBMod.Artwork.Style
			SUI.DBMod.Artwork.FirstLoad = true
			SUI.DBG.BartenderChangesActive = true
			Artwork_Core:SetupProfile()

			--Reset Moved bars
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
				SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = false
			end
			SUI.DBG.BartenderChangesActive = false
			SUI_Win.Artwork:Hide()
			SUI_Win.Artwork = nil
		end,
		RequireReload = true,
		Priority = 1,
		Skipable = true,
		NoReloadOnSkip = true,
		Skip = function()
			SUI.DBMod.Artwork.SetupDone = true
			SUI_Win.Artwork:Hide()
			SUI_Win.Artwork = nil
		end
	}
	local SetupWindow = SUI:GetModule("SetupWindow")
	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function Artwork_Core:OnEnable()
	-- No Bartender/out of date Notification
	if (not select(4, GetAddOnInfo("Bartender4")) and (SUI.DBG.BartenderInstallWarning ~= SUI.Version)) then
		if SUI.Version ~= SUI.DBG.Version then
			StaticPopup_Show("BartenderInstallWarning")
		end
	elseif Bartender4Version < BartenderMin then
		if SUI.Version ~= SUI.DBG.Version then
			StaticPopup_Show("BartenderVerWarning")
		end
	end

	Artwork_Core:SetupOptions()

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
					(not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] or v:GetParent():GetName() ~= "UIParent") and
						not SUI.DBG.BartenderChangesActive
				 then
					SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[v:GetName()] = true
					LibStub("LibWindow-1.1").windowData[v].storage.parent = UIParent
					v:SetParent(UIParent)
				end

				LibStub("LibWindow-1.1").SavePosition(v)
			end
		end
	end
end

function Artwork_Core:CheckMiniMap()
	-- Check for Carbonite dinking with the minimap.
	if (NXTITLELOW) then
		SUI:Print(NXTITLELOW .. " is loaded ...Checking settings ...")
		if (Nx.db.profile.MiniMap.Own == true) then
			SUI:Print(NXTITLELOW .. " is controlling the Minimap")
			SUI:Print("SpartanUI Will not modify or move the minimap unless Carbonite is a separate minimap")
			SUI.DB.MiniMap.AutoDetectAllowUse = false
		end
	end

	if select(4, GetAddOnInfo("SexyMap")) then
		SUI:Print(L["SexyMapLoaded"])
		SUI.DB.MiniMap.AutoDetectAllowUse = false
	end

	local _, relativeTo = MinimapCluster:GetPoint()
	if (relativeTo ~= UIParent) then
		SUI:Print("A unknown addon is controlling the Minimap")
		SUI:Print("SpartanUI Will not modify or move the minimap until the addon modifying the minimap is no longer enabled.")
		SUI.DB.MiniMap.AutoDetectAllowUse = false
	end
end

-- Bartender4 Items
function Artwork_Core:SetupProfile(ProfileOverride)
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo("Bartender4"))) then
		return
	end

	--Flag the SUI.DB that we are making changes
	SUI.DBG.BartenderChangesActive = true
	--Load the profile name the art style wants
	local ProfileName = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile
	--Check if we are overriding the art
	if ProfileOverride then
		ProfileName = ProfileOverride
	end

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
	for k, v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = Artwork_Core:MergeData(v.db.profile, BartenderSettings[k])
		end
	end
	SUI.DBG.BartenderChangesActive = false
end

function Artwork_Core:BartenderProfileCheck(Input, Report)
	local profiles, r = Bartender4.db:GetProfiles(), false
	for _, v in pairs(profiles) do
		if v == Input then
			r = true
		end
	end
	if (Report) and (r ~= true) then
		addon:Print(Input .. " " .. L["BartenderProfileCheckFail"])
	end
	return r
end

function Artwork_Core:MergeData(target, source)
	if type(target) ~= "table" then
		target = {}
	end
	for k, v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:MergeData(target[k], v)
		else
			target[k] = v
		end
	end
	return target
end

function Artwork_Core:CreateProfile()
	SUI.DBG.BartenderChangesActive = true
	local ProfileName = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderProfile
	local BartenderSettings = SUI.DB.Styles[SUI.DBMod.Artwork.Style].BartenderSettings
	--If this is set then we have already setup the bars once, and the user changed them
	if
		SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile and SUI.DB.Styles[SUI.DBMod.Artwork.Style].BT4Profile ~= ProfileName
	 then
		return
	end

	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo("Bartender4"))) then
		return
	end

	-- Set/Create our Profile
	Bartender4.db:SetProfile(ProfileName)

	--Load the Profile Data
	for k, v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = Artwork_Core:MergeData(v.db.profile, BartenderSettings[k])
		end
	end

	Bartender4:UpdateModuleConfigs()
	SUI.DBG.BartenderChangesActive = false
end
