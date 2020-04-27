local SUI, L = SUI, SUI.L
local module = SUI:NewModule('SetupWizard')
local StdUi = LibStub('StdUi'):NewInstance()
module.window = nil

local DisplayRequired, InitDone = false, false
local TotalPageCount, PageDisplayOrder, PageDisplayed = 0, 1, 0
local RequiredPageCount, RequiredDisplayOrder, RequiredPageDisplayed = 0, 1, 0
local PriorityPageList, StandardPageList, FinalPageList, RequiredPageList, PageID, CurrentDisplay = {},
	{},
	{},
	{},
	{},
	{}
local FinishedPage = {
	ID = 'FinishedPage',
	Name = 'Setup Finished!',
	Desc1 = 'This completes the setup wizard.',
	Desc2 = 'Thank you for trying SpartanUI.',
	Display = function()
		local FinishedPage = CreateFrame('Frame', nil)
		FinishedPage:SetParent(module.window.content)
		FinishedPage:SetAllPoints(module.window.content)

		FinishedPage.Helm = StdUi:Texture(FinishedPage, 190, 190, 'Interface\\AddOns\\SpartanUI\\images\\Spartan-Helm')
		FinishedPage.Helm:SetPoint('CENTER')
		FinishedPage.Helm:SetAlpha(.6)
		module.window.Next:SetText('FINISH')

		module.window.content.FinishedPage = FinishedPage
	end,
	Next = function()
		module.window:Hide()
	end
}

local LoadWatcherEvent = function()
	if (not module.window or not module.window:IsShown()) then
		if SUI.DB.SetupWizard.FirstLaunch then
			module:SetupWizard()
		elseif DisplayRequired then
			module:SetupWizard(true)
		end
	end
end

function module:AddPage(PageData)
	-- Make sure SetupWizard does it's initalization before any pages other are added
	if not InitDone then
		module:OnInitialize()
	end

	-- Incriment the page count/id by 1
	TotalPageCount = TotalPageCount + 1

	-- Store the Page's Data in a local table for latter
	-- If the page is flagged as priorty then we want it at the top of the list.
	if PageData.Priority then
		PriorityPageList[PageData.ID] = PageData
	else
		StandardPageList[PageData.ID] = PageData
	end
	if PageData.RequireDisplay then
		DisplayRequired = true
		RequiredPageCount = RequiredPageCount + 1
	end

	-- Track the Pages defined ID to the generated ID, this allows us to display pages in the order they were added to the system
	PageID[TotalPageCount] = {
		ID = PageData.ID,
		DisplayOrder = nil,
		Required = PageData.RequireDisplay
	}
end

function module:FindNextPage(RequiredPagesOnly)
	local CurPage, TotalPage = 0, 0

	-- First we will do the standard SetupWizard logic. Then upgrade/new module logic
	if not RequiredPagesOnly then
		-- First make sure our Display Order is up to date
		-- First add any priority pages
		for i = 1, TotalPageCount do
			local key = PageID[i]

			if PriorityPageList[key.ID] and key.DisplayOrder == nil then
				FinalPageList[PageDisplayOrder] = key.ID
				PageID[i][PageDisplayOrder] = PageDisplayOrder
				PageDisplayOrder = PageDisplayOrder + 1
			end
		end

		-- Now add Standard Pages
		for i = 1, TotalPageCount do
			local key = PageID[i]

			if StandardPageList[key.ID] and key.DisplayOrder == nil then
				FinalPageList[PageDisplayOrder] = key.ID
				PageID[i][PageDisplayOrder] = PageDisplayOrder
				PageDisplayOrder = PageDisplayOrder + 1
			end
		end

		--Find the next undisplayed page
		if PageDisplayed == TotalPageCount then
			PageDisplayed = PageDisplayed + 1
			module.window.Status:Hide()
			module:DisplayPage(FinishedPage)
		elseif FinalPageList[(PageDisplayed + 1)] then
			PageDisplayed = PageDisplayed + 1
			local ID = FinalPageList[PageDisplayed]

			-- Find what kind of page this is
			if PriorityPageList[ID] then
				module:DisplayPage(PriorityPageList[ID])
			elseif StandardPageList[ID] then
				module:DisplayPage(StandardPageList[ID])
			end
		end

		-- Update the Status Counter & Progress Bar
		CurPage = PageDisplayed
		TotalPage = TotalPageCount
	else
		-- First make sure our Display Order is up to date
		-- First add any priority pages
		for i = 1, TotalPageCount do
			local key = PageID[i]

			if PriorityPageList[key.ID] and key.DisplayOrder == nil and key.Required then
				RequiredPageList[RequiredDisplayOrder] = key.ID
				PageID[i][RequiredDisplayOrder] = RequiredDisplayOrder
				RequiredDisplayOrder = RequiredDisplayOrder + 1
			end
		end

		-- Now add Standard Pages
		for i = 1, TotalPageCount do
			local key = PageID[i]

			if StandardPageList[key.ID] and key.DisplayOrder == nil and key.Required then
				RequiredPageList[RequiredDisplayOrder] = key.ID
				PageID[i][RequiredDisplayOrder] = RequiredDisplayOrder
				RequiredDisplayOrder = RequiredDisplayOrder + 1
			end
		end

		--Find the next undisplayed page
		if RequiredPageDisplayed == RequiredPageCount then
			RequiredPageDisplayed = RequiredPageDisplayed + 1
			module.window.Status:Hide()
			module:DisplayPage(FinishedPage)
		elseif RequiredPageList[(RequiredPageDisplayed + 1)] then
			RequiredPageDisplayed = RequiredPageDisplayed + 1
			local ID = RequiredPageList[RequiredPageDisplayed]
			-- Find what kind of page this is
			if PriorityPageList[ID] then
				module:DisplayPage(PriorityPageList[ID])
			elseif StandardPageList[ID] then
				module:DisplayPage(StandardPageList[ID])
			end
		end

		-- Update the Status Counter & Progress Bar
		CurPage = RequiredPageDisplayed
		TotalPage = RequiredPageCount
	end

	-- Update the Status Counter & Progress Bar
	if module.window then
		module.window.Status:SetText(CurPage .. ' /  ' .. TotalPage)
		if module.window.ProgressBar then
			if CurPage > TotalPage then
				module.window.ProgressBar:SetValue(100)
			else
				module.window.ProgressBar:SetValue((100 / TotalPage) * (CurPage - 1))
			end
		end
	end
end

function module:DisplayPage(PageData)
	CurrentDisplay = PageData
	if PageData.title then
		module.window.titleHolder:SetText(PageData.title)
	end
	if PageData.SubTitle then
		module.window.SubTitle:SetText(PageData.SubTitle)
	else
		module.window.SubTitle:SetText('')
	end
	if PageData.Desc1 then
		module.window.Desc1:SetText(PageData.Desc1)
	else
		module.window.Desc1:SetText('')
	end
	if PageData.Desc2 then
		module.window.Desc2:SetText(PageData.Desc2)
	else
		module.window.Desc2:SetText('')
	end
	if PageData.Display then
		PageData.Display()
	end
	if PageData.Skip ~= nil then
		module.window.Skip:Show()
	else
		module.window.Skip:Hide()
	end
end

function module:SetupWizard(RequiredPagesOnly)
	module.window = StdUi:Window(nil, 650, 500)
	module.window.StdUi = StdUi
	module.window:SetPoint('CENTER', 0, 0)
	module.window:SetFrameStrata('DIALOG')
	module.window.Title = StdUi:Texture(module.window, 256, 64, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	module.window.Title:SetPoint('TOP')
	module.window.Title:SetAlpha(.8)

	-- Setup the Top text fields
	module.window.SubTitle = StdUi:Label(module.window, '', 16, nil, module.window:GetWidth(), 20)
	module.window.SubTitle:SetPoint('TOP', module.window.titlePanel, 'BOTTOM', 0, -5)
	module.window.SubTitle:SetTextColor(.29, .18, .96, 1)
	module.window.SubTitle:SetJustifyH('CENTER')

	module.window.Desc1 = StdUi:Label(module.window, '', 13, nil, module.window:GetWidth())
	-- module.window.Desc1 = module.window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
	module.window.Desc1:SetPoint('TOP', module.window.SubTitle, 'BOTTOM', 0, -5)
	module.window.Desc1:SetTextColor(1, 1, 1, .8)
	module.window.Desc1:SetWidth(module.window:GetWidth() - 40)
	module.window.Desc1:SetJustifyH('CENTER')

	module.window.Desc2 = StdUi:Label(module.window, '', 13, nil, module.window:GetWidth())
	-- module.window.Desc2 = module.window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
	module.window.Desc2:SetPoint('TOP', module.window.Desc1, 'BOTTOM', 0, -3)
	module.window.Desc2:SetTextColor(1, 1, 1, .8)
	module.window.Desc2:SetWidth(module.window:GetWidth() - 40)
	module.window.Desc2:SetJustifyH('CENTER')

	module.window.Status = StdUi:Label(module.window, '', 9, nil, 40, 15)
	module.window.Status:SetPoint('TOPRIGHT', module.window, 'TOPRIGHT', -2, -2)

	-- Setup the Buttons
	module.window.Skip = StdUi:Button(module.window, 150, 20, 'SKIP')
	module.window.Next = StdUi:Button(module.window, 150, 20, 'CONTINUE')

	-- If we have more than one page to show then add a progress bar, and a selection tree on the side.
	if TotalPageCount > 1 then
		-- Add a Progress bar to the bottom
		local ProgressBar = StdUi:ProgressBar(module.window, (module.window:GetWidth() - 4), 20)
		ProgressBar:SetMinMaxValues(0, 100)
		ProgressBar:SetValue(0)
		ProgressBar:SetPoint('BOTTOM', module.window, 'BOTTOM', 0, 2)
		module.window.ProgressBar = ProgressBar

		--Position the Buttons
		module.window.Skip:SetPoint('BOTTOMLEFT', module.window.ProgressBar, 'TOPLEFT', 0, 2)
		module.window.Next:SetPoint('BOTTOMRIGHT', module.window.ProgressBar, 'TOPRIGHT', 0, 2)

		-- Adjust the content area to account for the new layout
		module.window.content = CreateFrame('Frame', 'SUI_Window_Content', module.window)
		module.window.content:SetPoint('TOP', module.window.Desc2, 'BOTTOM', 0, -2)
		module.window.content:SetPoint('BOTTOMLEFT', module.window.Skip, 'TOPLEFT', 0, 2)
		module.window.content:SetPoint('BOTTOMRIGHT', module.window.Next, 'TOPRIGHT', 0, 2)
	else
		--Position the Buttons
		module.window.Skip:SetPoint('BOTTOMLEFT', module.window, 'BOTTOMLEFT', 0, 2)
		module.window.Next:SetPoint('BOTTOMRIGHT', module.window, 'BOTTOMRIGHT', 0, 2)
	end

	local function LoadNextPage()
		--Hide anything attached to the Content frame
		for _, child in ipairs({module.window.content:GetChildren()}) do
			child:Hide()
		end

		-- Show the next page
		module:FindNextPage(RequiredPagesOnly)
	end

	module.window.Skip:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Skip action
			if CurrentDisplay.Skip then
				CurrentDisplay.Skip()
			end

			LoadNextPage()
		end
	)

	module.window.Next:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Next action
			if CurrentDisplay.Next then
				CurrentDisplay.Next()
			end

			LoadNextPage()
		end
	)

	module.window.Status = StdUi:Label(module.window, '', 9, nil, 60, 15)
	module.window.Status:SetPoint('TOPRIGHT', module.window, 'TOPRIGHT', -2, -2)

	-- Display first page
	module.window.closeBtn:Hide()
	module.window:Show()
	module:FindNextPage(RequiredPagesOnly)
end

function module:OnEnable()
	-- If First launch, create a watcher frame that will trigger once everything is loaded in.
	if SUI.DB.SetupWizard.FirstLaunch or DisplayRequired then
		local LoadWatcher = CreateFrame('Frame')
		LoadWatcher:SetScript('OnEvent', LoadWatcherEvent)
		LoadWatcher:RegisterEvent('PLAYER_LOGIN')
		LoadWatcher:RegisterEvent('PLAYER_ENTERING_WORLD')
	end
end

local function wutsTweaks()
	local WutsTweaks = {
		ID = 'WutsTweaks',
		Name = "Wutname1's Tweaks",
		SubTitle = '',
		Desc1 = 'Below are a collection of tweaks I find myself making often, so I decided to add them in here.',
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi
			SetCVar('nameplateShowSelf', 0)
			SetCVar('autoLootDefault', 1)
			SetCVar('nameplateShowAll', 1)

			--Container
			local WutsTweaks = CreateFrame('Frame', nil)
			WutsTweaks:SetParent(SUI_Win)
			WutsTweaks:SetAllPoints(SUI_Win)

			local Nameplate = StdUi:Checkbox(WutsTweaks, 'Disable personal nameplate', 240, 20)
			local AutoLoot = StdUi:Checkbox(WutsTweaks, 'Enable AutoLoot', 240, 20)
			local ShowNameplates = StdUi:Checkbox(WutsTweaks, 'Enable Always show nameplates', 240, 20)
			local DisableTutorials = StdUi:Checkbox(WutsTweaks, 'Disable ALL tutorials', 240, 20)
			local DisableTutorialsWarning = StdUi:Label(WutsTweaks, 'WARNING: Experianced players only')
			StdUi:GlueRight(DisableTutorialsWarning, DisableTutorials, -85, 0)

			Nameplate:SetChecked(true)
			AutoLoot:SetChecked(true)
			ShowNameplates:SetChecked(true)
			-- If the user has more than 4 SUI Profile they should be 'experianced' we will check this by default
			if #SUI.SpartanUIDB:GetProfiles(tmpprofiles) >= 4 then
				DisableTutorials:SetChecked(true)
			end

			Nameplate:HookScript(
				'OnClick',
				function()
					if (Nameplate:GetValue() or false) then
						SetCVar('nameplateShowSelf', 0)
					else
						SetCVar('nameplateShowSelf', 1)
					end
				end
			)
			AutoLoot:HookScript(
				'OnClick',
				function()
					if (AutoLoot:GetValue() or false) then
						SetCVar('autoLootDefault', 1)
					else
						SetCVar('autoLootDefault', 0)
					end
				end
			)
			ShowNameplates:HookScript(
				'OnClick',
				function()
					if (ShowNameplates:GetValue() or false) then
						SetCVar('nameplateShowAll', 1)
					else
						SetCVar('nameplateShowAll', 0)
					end
				end
			)

			StdUi:GlueTop(Nameplate, WutsTweaks, 0, -30)
			StdUi:GlueBelow(AutoLoot, Nameplate, 0, -10)
			StdUi:GlueBelow(ShowNameplates, AutoLoot, 0, -10)
			StdUi:GlueBelow(DisableTutorials, ShowNameplates, 0, -10)

			if DBM_MinimapIcon then
				DBM_MinimapIcon.hide = true
				local DBMMinimap = StdUi:Checkbox(WutsTweaks, 'Hide DBM Minimap Icon', 240, 20)
				DBMMinimap:SetChecked(true)
				DBMMinimap:HookScript(
					'OnClick',
					function()
						DBM_MinimapIcon.hide = (not DBMMinimap:GetValue() or false)
						if (DBMMinimap:GetValue() or false) then
							LibStub('LibDBIcon-1.0'):Hide('DBM')
						else
							LibStub('LibDBIcon-1.0'):Show('DBM')
						end
					end
				)
				StdUi:GlueBelow(DBMMinimap, DisableTutorials, 0, -10)
				WutsTweaks.DBMMinimap = DBMMinimap
			end

			if Bartender4 then
				Bartender4.db.profile.minimapIcon.hide = true
				LibStub('LibDBIcon-1.0'):Hide('Bartender4')

				local BT4MiniMap = StdUi:Checkbox(WutsTweaks, 'Hide DBM Minimap Icon', 240, 20)
				BT4MiniMap:SetChecked(true)
				BT4MiniMap:HookScript(
					'OnClick',
					function()
						Bartender4.db.profile.minimapIcon.hide = (not BT4MiniMap:GetValue() or false)
						if (BT4MiniMap:GetValue() or false) then
							LibStub('LibDBIcon-1.0'):Hide('Bartender4')
						else
							LibStub('LibDBIcon-1.0'):Show('Bartender4')
						end
					end
				)
				StdUi:GlueBelow(BT4MiniMap, BT4MiniMap or DisableTutorials, 0, -10)
			end

			WutsTweaks.DisableTutorials = DisableTutorials
			SUI_Win.WutsTweaks = WutsTweaks
		end,
		Next = function()
			local WutsTweaks = SUI:GetModule('SetupWizard').window.content.WutsTweaks
			if (WutsTweaks.DisableTutorials:GetValue() or false) then
				local bitfieldListing = {
					LE_FRAME_TUTORIAL_TOYBOX,
					LE_FRAME_TUTORIAL_TOYBOX_MOUSEWHEEL_PAGING,
					LE_FRAME_TUTORIAL_TOYBOX_FAVORITE,
					LE_FRAME_TUTORIAL_AZERITE_RESPEC,
					LE_FRAME_TUTORIAL_AZERITE_ITEM_IN_BAG,
					LE_FRAME_TUTORIAL_CHAT_CHANNELS,
					LE_FRAME_TUTORIAL_CORRUPTION_CLEANSER,
					LE_FRAME_TUTORIAL_ARTIFACT_APPEARANCE_TAB,
					LE_FRAME_TUTORIAL_ISLANDS_QUEUE_INFO_FRAME,
					LE_FRAME_TUTORIAL_ISLANDS_QUEUE_BUTTON,
					LE_FRAME_TUTORIAL_ISLANDS_QUEUE_INFO_FRAME,
					LE_FRAME_TUTORIAL_HEIRLOOM_JOURNAL,
					LE_FRAME_TUTORIAL_HEIRLOOM_JOURNAL_TAB,
					LE_FRAME_TUTORIAL_TRANSMOG_SETS_VENDOR_TAB,
					LE_FRAME_TUTORIAL_TRANSMOG_SETS_TAB,
					LE_FRAME_TUTORIAL_WORLD_MAP_FRAME,
					LE_FRAME_TUTORIAL_REAGENT_BANK_UNLOCK,
					LE_FRAME_TUTORIAL_TRADESKILL_UNLEARNED_TAB,
					LE_FRAME_TUTORIAL_GAME_TIME_AUCTION_HOUSE,
					LE_FRAME_TUTORIAL_CHAT_CHANNELS,
					LE_FRAME_TUTORIAL_REPUTATION_EXALTED_PLUS,
					LE_FRAME_TUTORIAL_AZERITE_ITEM_IN_SLOT,
					LE_FRAME_TUTORIAL_ARTIFACT_RELIC_MATCH,
					LE_FRAME_TUTORIAL_SPEC,
					LE_FRAME_TUTORIAL_TALENT,
					LE_FRAME_TUTORIAL_PVP_TALENTS_FIRST_UNLOCK,
					LE_FRAME_TUTORIAL_PVP_WARMODE_UNLOCK,
					LE_FRAME_TUTORIAL_TRANSMOG_OUTFIT_DROPDOWN,
					LE_FRAME_TUTORIAL_TRIAL_BANKED_XP,
					LE_FRAME_TUTORIAL_TRANSMOG_MODEL_CLICK,
					LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME,
					LE_FRAME_TUTORIAL_TRADESKILL_RANK_STAR,
					LE_FRAME_TUTORIAL_BONUS_ROLL_ENCOUNTER_JOURNAL_LINK,
					LE_FRAME_TUTORIAL_PVP_SPECIAL_EVENT,
					LE_FRAME_TUTORIAL_PET_JOURNAL,
					LE_FRAME_TUTORIAL_GARRISON_BUILDING,
					LE_FRAME_TUTORIAL_BOOSTED_SPELL_BOOK,
					LE_FRAME_TUTORIAL_SPELLBOOK,
					LE_FRAME_TUTORIAL_PROFESSIONS,
					LE_FRAME_TUTORIAL_REPUTATION_EXALTED_PLUS,
					LE_FRAME_TUTORIAL_INVENTORY_FIXUP_EXPANSION_LEGION,
					LE_FRAME_TUTORIAL_INVENTORY_FIXUP_CHECK_EXPANSION_LEGION,
					LE_FRAME_TUTORIAL_WARFRONT_RESOURCES,
					LE_FRAME_TUTORIAL_BRAWL,
					LE_FRAME_TUTORIAL_FRIENDS_LIST_QUICK_JOIN,
					LE_FRAME_TUTORIAL_BOUNTY_INTRO,
					LE_FRAME_TUTORIAL_BOUNTY_FINISHED
				}
				for i, v in ipairs(bitfieldListing) do
					if v then
						SetCVarBitfield('closedInfoFrames', v, true)
					end
				end
			end
		end
		-- RequireDisplay = true
	}
	module:AddPage(WutsTweaks)
end

local function WelcomePage()
	local WelcomePage = {
		ID = 'WelcomePage',
		Name = 'Welcome',
		SubTitle = '',
		Desc1 = "Welcome to SpartanUI, This setup wizard help guide you through the inital setup of the UI and it's modules.",
		Desc2 = 'This setup wizard may be re-ran at any time via the SUI settings screen. You can access the SUI settings via the /sui chat command. For a full list of chat commands as well as common questions visit the wiki at http://wiki.spartanui.net or Join the SpartanUI Discord.',
		Display = function()
			local profiles = {}
			local currentProfile = SUI.SpartanUIDB:GetCurrentProfile()
			for _, v in pairs(SUI.SpartanUIDB:GetProfiles(tmpprofiles)) do
				if not (nocurrent and v == currentProfile) then
					profiles[#profiles + 1] = {text = v, value = v}
				end
			end

			local WelcomePage = CreateFrame('Frame', nil)
			WelcomePage:SetParent(module.window.content)
			WelcomePage:SetAllPoints(module.window.content)

			WelcomePage.Helm = StdUi:Texture(WelcomePage, 190, 190, 'Interface\\AddOns\\SpartanUI\\images\\Spartan-Helm')
			WelcomePage.Helm:SetPoint('CENTER', 0, 35)
			WelcomePage.Helm:SetAlpha(.6)

			if not select(4, GetAddOnInfo('Bartender4')) then
				module.window.BT4Warning =
					StdUi:Label(
					module.window,
					L['Bartender4 not detected! Please download and install Bartender4.'],
					25,
					nil,
					module.window:GetWidth(),
					40
				)
				module.window.BT4Warning:SetTextColor(1, .18, .18, 1)
				StdUi:GlueAbove(module.window.BT4Warning, module.window, 0, 20)
			end

			WelcomePage.ProfileCopyLabel =
				StdUi:Label(
				WelcomePage,
				L['If you would like to copy the configuration from another character you may do so below.']
			)

			WelcomePage.ProfileList = StdUi:Dropdown(WelcomePage, 200, 20, profiles)
			WelcomePage.CopyProfileButton = StdUi:Button(WelcomePage, 60, 20, 'COPY')
			WelcomePage.CopyProfileButton:SetScript(
				'OnClick',
				function(this)
					local ProfileSelection = module.window.content.WelcomePage.ProfileList:GetValue()
					if not ProfileSelection or ProfileSelection == '' then
						return
					end
					-- Copy profile
					SUI.SpartanUIDB:CopyProfile(ProfileSelection)
					-- Reload the UI
					ReloadUI()
				end
			)
			if #profiles == 1 then
				WelcomePage.ProfileCopyLabel:Hide()
				WelcomePage.ProfileList:Hide()
				WelcomePage.CopyProfileButton:Hide()
			end

			StdUi:GlueBottom(WelcomePage.ProfileCopyLabel, WelcomePage.Helm, 0, -35)
			StdUi:GlueBottom(WelcomePage.ProfileList, WelcomePage.ProfileCopyLabel, -31, -25)
			StdUi:GlueRight(WelcomePage.CopyProfileButton, WelcomePage.ProfileList, 2, 0)

			module.window.content.WelcomePage = WelcomePage
		end,
		Next = function()
			SUI.DB.SetupWizard.FirstLaunch = false
		end,
		RequireDisplay = SUI.DB.SetupWizard.FirstLaunch,
		Priority = true
	}
	module:AddPage(WelcomePage)
end

local function ModuleSelectionPage()
	local ProfilePage = {
		ID = 'ModuleSelectionPage',
		Name = L['Enabled modules'],
		Priority = true,
		SubTitle = L['Enabled modules'],
		Desc1 = 'Below you can disable modules of SpartanUI',
		RequireDisplay = (not SUI.DB.SetupDone),
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi

			--Container
			SUI_Win.ModSelection = CreateFrame('Frame', nil)
			SUI_Win.ModSelection:SetParent(SUI_Win)
			SUI_Win.ModSelection:SetAllPoints(SUI_Win)

			local itemsMatrix = {}

			-- List Components
			for name, submodule in SUI:IterateModules() do
				if (string.match(name, 'Component_')) then
					local RealName = string.sub(name, 11)
					if SUI.DB.EnabledComponents[RealName] == nil then
						SUI.DB.EnabledComponents[RealName] = true
					end

					local Displayname = string.sub(name, 11)
					if submodule.DisplayName then
						Displayname = submodule.DisplayName
					end
					local checkbox = StdUi:Checkbox(SUI_Win.ModSelection, Displayname, 160, 20)
					checkbox:HookScript(
						'OnClick',
						function()
							SUI.DB.EnabledComponents[RealName] = (checkbox:GetValue() or false)

							if (checkbox:GetValue() or false) then
								submodule:Enable()
							else
								submodule:Disable()
							end
						end
					)
					checkbox:SetChecked(SUI.DB.EnabledComponents[RealName])

					itemsMatrix[(#itemsMatrix + 1)] = checkbox
				end
			end

			StdUi:GlueTop(itemsMatrix[1], SUI_Win.ModSelection, -60, 0)

			local left, leftIndex = false, 1
			for i = 2, #itemsMatrix do
				if left then
					StdUi:GlueBelow(itemsMatrix[i], itemsMatrix[leftIndex], 0, -3)
					leftIndex = i
					left = false
				else
					StdUi:GlueRight(itemsMatrix[i], itemsMatrix[leftIndex], 3, 0)
					left = true
				end
			end
		end,
		Next = function()
			SUI.DB.SetupDone = true
		end,
		Skip = function()
			SUI.DB.SetupDone = true
		end
	}

	module:AddPage(ProfilePage)
end

function module:OnInitialize()
	InitDone = true
	WelcomePage()
	ModuleSelectionPage()
	wutsTweaks()
end
