local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:NewModule('Artwork_Core')

local BarModule
local function GetBarSettings()
	-- local barStyle = SUI.DB.Styles['War']
	local barStyle = SUI.DB.Styles[SUI.DBMod.BarManager.Style] 

	return {
		profile = barStyle.BartenderProfile,
		type = barStyle.BarManager.type
	}
end

local function GetBarModule()
	local BarTypes = {
		Blizzard = 'Artwork_BlizzardBars',
		Bartender = 'Artwork_BartenderBars'
	}

	local BarSettings = GetBarSettings()
	barType = BarSettings.type

	-- Does it make sense to just go to Blizzard vs. Bartender
	-- based solely on if the addon is enabled?
	-- The problem is that I don't know if you can tell
	-- Bartender to just leave everything alone.
	-- Putting that in place for now to try it out...
	if (not select(4, GetAddOnInfo('Bartender4'))) then
		barType = 'Blizzard'
	else
		barType = 'Bartender'
	end
	local barModuleName = BarTypes[barType]

	local isSetup = false

	local barModule = null

	if SUI:GetModule(barModuleName, true) then
		barModule = SUI:GetModule(barModuleName)
	else
		SUI:Err('Artwork_Core', 'Missing bar module: ' .. barModuleName)
	end

	return barModule
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
	local MoveTalkingHead = CreateFrame('Frame')
	MoveTalkingHead:RegisterEvent('ADDON_LOADED')
	MoveTalkingHead:SetScript(
		'OnEvent',
		function(self, event, ...)
			local addonName = ...
			if addonName and addonName == 'Blizzard_TalkingHeadUI' then
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

function Artwork_Core:ActionBarPlates(plate, excludelist)
	local lib = LibStub('LibWindow-1.1', true)
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
		local excluded = false
		if excludelist then
			for _, key in ipairs(excludelist) do
				if frame:GetName():match(key) then
					excluded = true
				end
			end
		end

		-- If the name contains Bartender and we have not moved it set the parent to what is in sorage
		-- if (frame:GetName():match("BT4Bar")) and storage.parent and not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[frame:GetName()] then
		if
			(frame:GetName():match('BT4Bar') and not excluded) and
				not SUI.DB.Styles[SUI.DBMod.Artwork.Style].MovedBars[frame:GetName()]
		 then
			-- end
			-- end
			-- if (storage.parent) and _G[storage.parent] then
			-- frame:SetParent(storage.parent);
			frame:SetParent(plate)
			-- if storage.parent == plate then
			frame:SetFrameStrata('LOW')
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
		SubTitle = 'Art Style',
		Desc1 = 'Please pick an art style from the options below.',
		Display = function()
			--Container
			SUI_Win.Artwork = CreateFrame('Frame', nil)
			SUI_Win.Artwork:SetParent(SUI_Win.content)
			SUI_Win.Artwork:SetAllPoints(SUI_Win.content)

			local RadioButtons = function(self)
				SUI_Win.Artwork.Classic.radio:SetValue(false)
				SUI_Win.Artwork.Transparent.radio:SetValue(false)
				SUI_Win.Artwork.Minimal.radio:SetValue(false)
				SUI_Win.Artwork.Fel.radio:SetValue(false)
				SUI_Win.Artwork.War.radio:SetValue(false)
				SUI_Win.Artwork.Digital.radio:SetValue(false)
				self.radio:SetValue(true)
			end

			local gui = LibStub('AceGUI-3.0')
			local control, radio

			--Classic
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI_Artwork\\Themes\\Classic\\Images\\base-center')
			control:SetImageSize(120, 60)
			control:SetPoint('TOPLEFT', SUI_Win.Artwork, 'TOPLEFT', 80, -30)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Classic')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.4)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio:SetCallback('OnClick', RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Classic = control

			--Fel
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Style_Fel')
			control:SetImageSize(120, 60)
			control:SetPoint('LEFT', SUI_Win.Artwork.Classic.frame, 'RIGHT', 30, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Fel')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Fel = control

			--War
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Style_War')
			control:SetImageSize(120, 60)
			control:SetPoint('LEFT', SUI_Win.Artwork.Fel.frame, 'RIGHT', 30, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('War')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.War = control

			--Digital
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Style_Digital')
			control:SetImageSize(120, 60)
			control:SetPoint('TOP', SUI_Win.Artwork.Classic.radio.frame, 'BOTTOM', 0, -30)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Digital')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Digital = control

			--Transparent
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Style_Transparent')
			control:SetImageSize(120, 60)
			control:SetPoint('LEFT', SUI_Win.Artwork.Digital.frame, 'RIGHT', 30, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Transparent')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Transparent = control

			--Minimal
			control = gui:Create('Icon')
			control:SetImage('interface\\addons\\SpartanUI\\media\\Style_Minimal')
			control:SetImageSize(120, 60)
			control:SetPoint('LEFT', SUI_Win.Artwork.Transparent.frame, 'RIGHT', 30, 0)
			control:SetCallback('OnClick', RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()

			radio = gui:Create('CheckBox')
			radio:SetLabel('Minimal')
			radio:SetType('radio')
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth() / 1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint('TOP', control.frame, 'BOTTOM', 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio

			SUI_Win.Artwork.Minimal = control

			SUI_Win.Artwork.Classic.radio:SetValue(true)
		end,
		Next = function()
			SUI.DBMod.Artwork.SetupDone = true

			if (SUI_Win.Artwork.Classic.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = 'Classic'
			end
			if (SUI_Win.Artwork.Fel.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = 'Fel'
				SUI.DBMod.Artwork.SubTheme = 'Fel'
			end
			if (SUI_Win.Artwork.War.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = 'War'
			end
			if (SUI_Win.Artwork.Digital.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = 'Fel'
				SUI.DB.Styles.Fel.SubTheme = 'Digital'
			end
			if (SUI_Win.Artwork.Transparent.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = 'Transparent'
			end
			if (SUI_Win.Artwork.Minimal.radio:GetValue()) then
				SUI.DBMod.Artwork.Style = 'Minimal'
			end

			SUI.DBMod.PlayerFrames.Style = SUI.DBMod.Artwork.Style
			SUI.DBMod.PartyFrames.Style = SUI.DBMod.Artwork.Style
			SUI.DBMod.RaidFrames.Style = SUI.DBMod.Artwork.Style
			SUI.DBMod.BarManager.Style = SUI.DBMod.Artwork.Style
			SUI.DBMod.Artwork.FirstLoad = true
			SUI.DBG.BartenderChangesActive = true
			Artwork_Core:SetupProfile()

			SUI:GetModule('Artwork_Core'):ResetMovedBars()

			SUI_Win.Artwork:Hide()
			SUI_Win.Artwork = nil
		end,
		RequireReload = true,
		Priority = true,
		Skipable = true,
		NoReloadOnSkip = true,
		Skip = function()
			SUI.DBMod.Artwork.SetupDone = true
			SUI_Win.Artwork:Hide()
			SUI_Win.Artwork = nil
		end
	}
	local SetupWindow = SUI:GetModule('SetupWindow')
	SetupWindow:AddPage(PageData)
	SetupWindow:DisplayPage()
end

function Artwork_Core:OnEnable()
	Artwork_Core:SetupOptions()

	local BarModule = GetBarModule()
	if BarModule then
		BarModule:SetupMovedBars()
	end
end

function Artwork_Core:CheckMiniMap()
	-- Check for Carbonite dinking with the minimap.
	if (NXTITLELOW) then
		SUI:Print(NXTITLELOW .. ' is loaded ...Checking settings ...')
		if (Nx.db.profile.MiniMap.Own == true) then
			SUI:Print(NXTITLELOW .. ' is controlling the Minimap')
			SUI:Print('SpartanUI Will not modify or move the minimap unless Carbonite is a separate minimap')
			SUI.DB.MiniMap.AutoDetectAllowUse = false
		end
	end

	if select(4, GetAddOnInfo('SexyMap')) then
		SUI:Print(L['SexyMapLoaded'])
		SUI.DB.MiniMap.AutoDetectAllowUse = false
	end

	local _, relativeTo = MinimapCluster:GetPoint()
	if (relativeTo ~= UIParent) then
		SUI:Print('A unknown addon is controlling the Minimap')
		SUI:Print('SpartanUI Will not modify or move the minimap until the addon modifying the minimap is no longer enabled.')
		SUI.DB.MiniMap.AutoDetectAllowUse = false
	end
end

function Artwork_Core:SetupBars()
	local isSetup = false
	local BarModule = GetBarModule()
	if BarModule then
		local BarSettings = GetBarSettings()
		isSetup = BarModule:Initialize(BarSettings)
	end

	return isSetup
end

function Artwork_Core:SetupProfile()
	local BarModule = GetBarModule()
	if BarModule then
		local BarSettings = GetBarSettings()
		BarModule:CreateProfile(BarSettings.profile)
	end
end

function Artwork_Core:ResetMovedBars()
	local BarModule = GetBarModule()
	if BarModule then
		BarModule:ResetMovedBars()
	end
end

function Artwork_Core:ResetDB()
	local BarModule = GetBarModule()
	if BarModule then
		BarModule:ResetDB()
	end
end

function Artwork_Core:UseBlizzardVehicleUI(shouldUse)
	local BarModule = GetBarModule()
	if BarModule then
		BarModule:UseBlizzardVehicleUI(shouldUse)
	end
end

