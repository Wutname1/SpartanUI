---@class SUI
local SUI = SUI
local L = SUI.L
---@class SUI.Handler.SetupWizard
local module = SUI:NewModule('Handler.SetupWizard') ---@type SUI.Module
local StdUi = SUI.StdUi
module.window = nil

local DisplayRequired, WelcomeAdded = false, false
local TotalPageCount, PageDisplayOrder, PageDisplayed = 0, 1, 0
local RequiredPageCount, RequiredDisplayOrder, RequiredPageDisplayed = 0, 1, 0
---@type table<string, SUI.SetupWizard.PageData>
local PriorityPageList, StandardPageList, FinalPageList, RequiredPageList, PageID, CurrentDisplay = {}, {}, {}, {}, {}, {}

---@type SUI.SetupWizard.PageData
local FinishedPage = {
	ID = 'FinishedPage',
	SubTitle = L['Setup Finished!'],
	Desc1 = 'This completes the setup wizard.',
	Desc2 = 'Thank you for trying SpartanUI.',
	Display = function()
		local FinishedPage = CreateFrame('Frame', nil)
		FinishedPage:SetParent(module.window.content)
		FinishedPage:SetAllPoints(module.window.content)

		FinishedPage.Helm = StdUi:Texture(FinishedPage, 190, 190, 'Interface\\AddOns\\SpartanUI\\images\\Spartan-Helm')
		FinishedPage.Helm:SetPoint('CENTER')
		FinishedPage.Helm:SetAlpha(0.6)
		module.window.Next:SetText('FINISH')

		module.window.content.FinishedPage = FinishedPage
	end,
	Next = function()
		module.window:Hide()
	end,
}

---@class SUI.SetupWizard.PageData
---@field ID string
---@field SubTitle? string
---@field Desc1? string
---@field Desc2? string
---@field RequireDisplay? boolean
---@field Priority? boolean
---@field Display function
---@field Next function
---@field Skip? function

local LoadWatcherEvent = function()
	if not module.window or not module.window:IsShown() then
		if SUI.DB.SetupWizard.FirstLaunch then
			module:SetupWizard()
		elseif DisplayRequired then
			module:SetupWizard(true)
		end
	end
end

---@param PageData SUI.SetupWizard.PageData
function module:AddPage(PageData)
	-- Make sure SetupWizard does it's initalization before any pages other are added
	if not WelcomeAdded and PageData.ID ~= 'WelcomePage' then module:OnInitialize() end

	-- Do not allow more than 1 page with a specific ID
	if PriorityPageList[PageData.ID] or StandardPageList[PageData.ID] then return end

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
		Required = PageData.RequireDisplay,
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
			if RequiredPageCount == 1 then
				module.window:Hide()
			else
				module:DisplayPage(FinishedPage)
			end
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
				if CurPage > (TotalPage + 1) then module.window:Hide() end
			else
				module.window.ProgressBar:SetValue((100 / TotalPage) * (CurPage - 1))
			end
		end
	end
end

function module:DisplayPage(PageData)
	CurrentDisplay = PageData
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
	if PageData.Display then PageData.Display() end
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
	module.window.Title:SetAlpha(0.8)

	-- Setup the Top text fields
	module.window.SubTitle = StdUi:Label(module.window, '', 16, nil, module.window:GetWidth(), 20)
	module.window.SubTitle:SetPoint('TOP', module.window.titlePanel, 'BOTTOM', 0, -5)
	module.window.SubTitle:SetTextColor(0.29, 0.18, 0.96, 1)
	module.window.SubTitle:SetJustifyH('CENTER')

	module.window.Desc1 = StdUi:Label(module.window, '', 13, nil, module.window:GetWidth())
	module.window.Desc1:SetPoint('TOP', module.window.SubTitle, 'BOTTOM', 0, -5)
	module.window.Desc1:SetTextColor(1, 1, 1, 0.8)
	module.window.Desc1:SetWidth(module.window:GetWidth() - 40)
	module.window.Desc1:SetJustifyH('CENTER')

	module.window.Desc2 = StdUi:Label(module.window, '', 13, nil, module.window:GetWidth())
	module.window.Desc2:SetPoint('TOP', module.window.Desc1, 'BOTTOM', 0, -3)
	module.window.Desc2:SetTextColor(1, 1, 1, 0.8)
	module.window.Desc2:SetWidth(module.window:GetWidth() - 40)
	module.window.Desc2:SetJustifyH('CENTER')

	module.window.Status = StdUi:Label(module.window, '', 9, nil, 40, 15)
	module.window.Status:SetPoint('TOPRIGHT', module.window, 'TOPRIGHT', -2, -2)

	-- Create the content area to account for the new layout
	module.window.content = CreateFrame('Frame', 'SUI_SetupWindow_Content', module.window)

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
	else
		--Position the Buttons
		module.window.Skip:SetPoint('BOTTOMLEFT', module.window, 'BOTTOMLEFT', 0, 2)
		module.window.Next:SetPoint('BOTTOMRIGHT', module.window, 'BOTTOMRIGHT', 0, 2)
	end

	module.window.content:SetPoint('TOP', module.window.Desc2, 'BOTTOM', 0, -2)
	module.window.content:SetPoint('BOTTOMLEFT', module.window.Skip, 'TOPLEFT', 0, 2)
	module.window.content:SetPoint('BOTTOMRIGHT', module.window.Next, 'TOPRIGHT', 0, 2)

	local function LoadNextPage()
		--Hide anything attached to the Content frame
		for _, child in ipairs({ module.window.content:GetChildren() }) do
			---@diagnostic disable-next-line: undefined-field
			child:Hide()
		end

		-- Show the next page
		module:FindNextPage(RequiredPagesOnly)
	end

	module.window.Skip:SetScript('OnClick', function()
		-- Perform the Page's Custom Skip action
		if CurrentDisplay.Skip then CurrentDisplay.Skip() end

		LoadNextPage()
	end)

	module.window.Next:SetScript('OnClick', function()
		-- Perform the Page's Custom Next action
		if CurrentDisplay.Next then CurrentDisplay.Next() end

		LoadNextPage()
	end)

	module.window.Status = StdUi:Label(module.window, '', 9, nil, 60, 15)
	module.window.Status:SetPoint('TOPRIGHT', module.window, 'TOPRIGHT', -2, -2)

	-- Display first page
	module.window.closeBtn:Hide()
	module.window:Show()
	module.window:HookScript('OnShow', function()
		if PageDisplayed > (TotalPageCount + 1) then module.window:Hide() end
	end)
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
	SUI:AddChatCommand('setup', function()
		if module.window then module.window:Hide() end

		PageDisplayOrder = 1
		PageDisplayed = 0
		module:SetupWizard()
	end, 'Re-run the setup wizard')
end

local function WelcomePage()
	if WelcomeAdded then return end

	local PageData = {
		ID = 'WelcomePage',
		SubTitle = L['Welcome'],
		Desc1 = "Welcome to SpartanUI, This setup wizard help guide you through the inital setup of the UI and it's modules.",
		Desc2 = 'This setup wizard may be re-ran at any time via the SUI settings screen. You can access the SUI settings via the /sui chat command. For a full list of chat commands as well as common questions visit the wiki at http://wiki.spartanui.net or Join the SpartanUI Discord.',
		Display = function()
			local profiles = {}
			local currentProfile = SUI.SpartanUIDB:GetCurrentProfile()
			for _, v in pairs(SUI.SpartanUIDB:GetProfiles()) do
				if v ~= currentProfile then profiles[#profiles + 1] = { text = v, value = v } end
			end

			local IntroPage = CreateFrame('Frame', nil)
			IntroPage:SetParent(module.window.content)
			IntroPage:SetAllPoints(module.window.content)

			IntroPage.Helm = StdUi:Texture(IntroPage, 190, 190, 'Interface\\AddOns\\SpartanUI\\images\\Spartan-Helm')
			IntroPage.Helm:SetPoint('CENTER', 0, 45)
			IntroPage.Helm:SetAlpha(0.6)

			if not SUI:IsAddonEnabled('Bartender4') then
				module.window.BT4Warning = StdUi:Label(module.window, L['Bartender4 not detected! Please download and install Bartender4.'], 25, nil, module.window:GetWidth(), 40)
				module.window.BT4Warning:SetTextColor(1, 0.18, 0.18, 1)
				StdUi:GlueAbove(module.window.BT4Warning, module.window, 0, 20)
			end

			IntroPage.ProfileCopyLabel = StdUi:Label(IntroPage, L['If you would like to copy the configuration from another character you may do so below.'])

			IntroPage.ProfileList = StdUi:Dropdown(IntroPage, 200, 20, profiles)
			IntroPage.CopyProfileButton = StdUi:Button(IntroPage, 60, 20, 'COPY')
			IntroPage.CopyProfileButton:SetScript('OnClick', function()
				local ProfileSelection = module.window.content.WelcomePage.ProfileList:GetValue()
				if not ProfileSelection or ProfileSelection == '' then return end
				-- Copy profile
				SUI.SpartanUIDB:CopyProfile(ProfileSelection)
				-- Reload the UI
				ReloadUI()
			end)
			if #profiles == 0 then
				IntroPage.ProfileCopyLabel:Hide()
				IntroPage.ProfileList:Hide()
				IntroPage.CopyProfileButton:Hide()
			end

			StdUi:GlueBottom(IntroPage.ProfileCopyLabel, IntroPage.Helm, 0, -25)
			StdUi:GlueBottom(IntroPage.ProfileList, IntroPage.ProfileCopyLabel, -31, -25)
			StdUi:GlueRight(IntroPage.CopyProfileButton, IntroPage.ProfileList, 2, 0)

			IntroPage.Import = StdUi:Button(IntroPage, 200, 20, 'IMPORT SETTINGS')
			IntroPage.Import:SetScript('OnClick', function()
				local Profiles = SUI:GetModule('Handler.Profiles') ---@type SUI.Handler.Profiles
				Profiles:ImportUI()
			end)
			IntroPage.Import:SetPoint('TOP', IntroPage.ProfileList, 'BOTTOM', 31, -5)

			IntroPage.SkipAllButton = StdUi:Button(IntroPage, 150, 20, 'SKIP SETUP')
			IntroPage.SkipAllButton:SetScript('OnClick', function()
				module.window:Hide()
				for _, ID in pairs(FinalPageList) do
					if PriorityPageList[ID] then
						PriorityPageList[ID].Display()
						PriorityPageList[ID].Next()
					elseif StandardPageList[ID] then
						StandardPageList[ID].Display()
						StandardPageList[ID].Next()
					end
				end
				DisplayRequired = false
				module.window:Hide()
			end)
			IntroPage.SkipOr = StdUi:Label(IntroPage, 'OR')
			StdUi:GlueBelow(IntroPage.SkipOr, IntroPage.SkipAllButton, 0, -5)

			module.window.ProgressBar:Hide()
			module.window.Next:SetPoint('BOTTOMRIGHT', module.window, 'BOTTOMRIGHT', 0, 2)
			IntroPage.SkipAllButton:SetPoint('BOTTOMRIGHT', 0, 2)

			module.window.content.WelcomePage = IntroPage
		end,
		Next = function()
			SUI.DB.SetupWizard.FirstLaunch = false
			module.window.ProgressBar:Show()
			module.window.Next:SetPoint('BOTTOMRIGHT', module.window.ProgressBar, 'TOPRIGHT', 0, 2)
		end,
		RequireDisplay = SUI.DB.SetupWizard.FirstLaunch,
		Priority = true,
	}

	module:AddPage(PageData)
	WelcomeAdded = true
end

function module:OnInitialize()
	WelcomePage()
end

SUI.Setup = module
