local SUI = SUI
local module = SUI:NewModule('SetupWizard')
local StdUi = LibStub('StdUi'):NewInstance()
module.window = nil

local DisplayRequired, InitDone, ReloadNeeded = false, false, false
local TotalPageCount, PageDisplayOrder, PageDisplayed = 0, 1, 0
local PriorityPageList, StandardPageList, FinalPageList, PageID, CurrentDisplay = {}, {}, {}, {}, {}
local ReloadPage = {
	ID = 'ReloadPage',
	Name = 'Reload required',
	SubTitle = 'Reload required',
	Desc1 = 'Setup finished!',
	Desc2 = 'This completes the setup wizard, a reload of the UI is required to finish the setup.',
	Display = function()
		module.window.content.WelcomePage = CreateFrame('Frame', nil)
		module.window.content.WelcomePage:SetParent(module.window.content)
		module.window.content.WelcomePage:SetAllPoints(module.window.content)

		module.window.content.WelcomePage.Helm =
			StdUi:Texture(module.window.content.WelcomePage, 150, 150, 'Interface\\AddOns\\SpartanUI\\media\\Spartan-Helm')
		module.window.content.WelcomePage.Helm:SetPoint('CENTER')

		module.window.Next:SetText('RELOAD UI')
	end,
	Next = function()
		ReloadUI()
	end
}

local LoadWatcherEvent = function()
	module:ShowWizard()
	-- module.window.closeBtn:Show()
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
	end

	-- Track the Pages defined ID to the generated ID, this allows us to display pages in the order they were added to the system
	PageID[TotalPageCount] = {
		ID = PageData.ID,
		DisplayOrder = nil
	}
end

function module:FindNextPage()
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
	module.window.ProgressBar:SetMinMaxValues(1, 100)

	--Find the next undisplayed page
	if ReloadNeeded and PageDisplayed == TotalPageCount then
		module:DisplayPage(ReloadPage)
	elseif not ReloadNeeded and PageDisplayed == TotalPageCount then
		module.window:Hide()
		module.window = nil
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

	-- Update the Status Counter & Progress Bar
	module.window.Status:SetText(PageDisplayed .. ' /  ' .. TotalPageCount)
	if module.window.ProgressBar then
		module.window.ProgressBar:SetValue((100 / TotalPageCount) * (PageDisplayed - 1))
	end
end

function module:ShowWizard()
	module.window = StdUi:Window(nil, 'SpartanUI setup wizard', 650, 500)
	module.window.StdUi = StdUi
	module.window:SetPoint('CENTER', 0, 0)
	module.window:SetFrameStrata('DIALOG')

	-- Setup the Top text fields
	module.window.SubTitle = StdUi:Label(module.window, '', 16, nil, module.window:GetWidth(), 20)
	module.window.SubTitle:SetPoint('TOP', module.window.titlePanel, 'BOTTOM', 0, -5)
	module.window.SubTitle:SetTextColor(.29, .18, .96, 1)

	module.window.Desc1 = StdUi:Label(module.window, '', 13, nil, module.window:GetWidth())
	-- module.window.Desc1 = module.window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
	module.window.Desc1:SetPoint('TOP', module.window.SubTitle, 'BOTTOM', 0, -5)
	module.window.Desc1:SetTextColor(1, 1, 1, .8)
	module.window.Desc1:SetWidth(module.window:GetWidth() - 40)

	module.window.Desc2 = StdUi:Label(module.window, '', 13, nil, module.window:GetWidth())
	-- module.window.Desc2 = module.window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
	module.window.Desc2:SetPoint('TOP', module.window.Desc1, 'BOTTOM', 0, -3)
	module.window.Desc2:SetTextColor(1, 1, 1, .8)
	module.window.Desc2:SetWidth(module.window:GetWidth() - 40)

	module.window.Status = StdUi:Label(module.window, '', 9, nil, 40, 15)
	module.window.Status:SetPoint('TOPRIGHT', module.window, 'TOPRIGHT', -2, -2)

	-- Setup the Buttons
	module.window.Skip = StdUi:Button(module.window, 150, 20, 'SKIP')
	module.window.Next = StdUi:Button(module.window, 150, 20, 'CONTINUE')

	-- If we have more than one page to show then add a progress bar, and a selection tree on the side.
	if TotalPageCount > 1 then
		-- Add a Progress bar to the bottom
		local ProgressBar = StdUi:ProgressBar(module.window, (module.window:GetWidth() - 4), 20)
		ProgressBar:SetMinMaxValues(0, TotalPageCount)
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

	module.window.Skip:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Skip action
			if CurrentDisplay.Skip then
				CurrentDisplay.Skip()
			end

			-- If Reload is needed by the page flag it.
			if CurrentDisplay.RequireReload then
				ReloadNeeded = true
			end

			-- Show the next page
			module:FindNextPage()
		end
	)

	module.window.Next:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Next action
			if CurrentDisplay.Next then
				CurrentDisplay.Next()
			end

			--Destory anything attached to the Content frame
			for _, child in ipairs({module.window.content:GetChildren()}) do
				child:Hide()
				child = nil
			end

			-- If Reload is needed by the page flag it for latter.
			if CurrentDisplay.RequireReload then
				ReloadNeeded = true
			end

			-- Show the next page
			module:FindNextPage()
		end
	)

	module.window.Status = StdUi:Label(module.window, '', 9, nil, 60, 15)
	module.window.Status:SetPoint('TOPRIGHT', module.window, 'TOPRIGHT', -2, -2)

	-- Display first page
	module:FindNextPage()
	module.window:Show()
end

function module:OnInitialize()
	InitDone = true
	local Defaults = {
		FirstLaunch = true
	}
	if not SUI.DB.SetupWizard then
		SUI.DB.SetupWizard = Defaults
	else
		SUI.DB.SetupWizard = SUI:MergeData(SUI.DB.SetupWizard, Defaults, false)
	end
	module:WelcomePage()
	module:ProfileSetup()
	module:ModuleSelectionPage()
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

function module:WelcomePage()
	local WelcomePage = {
		ID = 'WelcomePage',
		Name = 'Welcome',
		SubTitle = '',
		Desc1 = "Welcome to SpartanUI, This setup wizard help guide you through the inital setup of the UI and it's modules.",
		Desc2 = 'This setup wizard may be re-ran at any time via the SUI settings screen. You can access the SUI settings via the /sui chat command. For a full list of chat commands as well as common questions visit our wiki at http://wiki.spartanui.net',
		Display = function()
			local WelcomePage = CreateFrame('Frame', nil)
			WelcomePage:SetParent(module.window.content)
			WelcomePage:SetAllPoints(module.window.content)

			WelcomePage.Helm = StdUi:Texture(WelcomePage, 150, 150, 'Interface\\AddOns\\SpartanUI\\media\\Spartan-Helm')
			WelcomePage.Helm:SetPoint('CENTER')
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

function module:ProfileSetup()
	local ProfilePage = {
		ID = 'ProfileSetup',
		Name = 'Profile setup',
		SubTitle = 'Profile setup',
		Desc1 = 'Thank you for installing SpartanUI.',
		Desc2 = 'If you would like to copy the configuration from another character you may do so below.',
		RequireDisplay = (not SUI.DB.SetupDone),
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi

			--Container
			SUI_Win.ProfilePage = CreateFrame('Frame', nil)
			SUI_Win.ProfilePage:SetParent(SUI_Win)
			SUI_Win.ProfilePage:SetAllPoints(SUI_Win)

			-- local gui = LibStub('AceGUI-3.0')

			-- --Profiles
			-- local control = gui:Create('Dropdown')
			-- control:SetLabel('Exsisting profiles')
			-- local tmpprofiles = {}
			-- local profiles = {}
			-- -- copy existing profiles into the table
			-- local currentProfile = SUI.DB:GetCurrentProfile()
			-- for _, v in pairs(SUI.DB:GetProfiles(tmpprofiles)) do
			-- 	if not (nocurrent and v == currentProfile) then
			-- 		profiles[v] = v
			-- 	end
			-- end
			-- control:SetList(profiles)
			-- control:SetPoint('TOP', SUI_Win.ProfilePage, 'TOP', 0, -30)
			-- control.frame:SetParent(SUI_Win.ProfilePage)
			-- control.frame:Show()
			-- SUI_Win.ProfilePage.Profiles = control
		end,
		Next = function()
			local SUI_Win = SUI:GetModule('SetupWizard').window.content

			SUI.DB.SetupDone = true

			SUI_Win.ProfilePage:Hide()
			SUI_Win.ProfilePage = nil
		end,
		RequireReload = true,
		Priority = true,
		Skip = function()
			SUI.DB.SetupDone = true
		end
	}
	--Hide Bartender4 Minimap icon.
	if Bartender4 then
		Bartender4.db.profile.minimapIcon.hide = true
		local LDBIcon = LibStub('LibDBIcon-1.0', true)
		LDBIcon['Hide'](LDBIcon, 'Bartender4')
	end

	module:AddPage(ProfilePage)
end

function module:ModuleSelectionPage()
	local ProfilePage = {
		ID = 'ModuleSelectionPage',
		Name = 'Enabled modules',
		RequireReload = true,
		Priority = true,
		SubTitle = 'Enabled modules',
		Desc1 = 'Below you can disable modules of SpartanUI',
		RequireDisplay = (not SUI.DB.SetupDone),
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi

			--Container
			SUI_Win.ModSelection = CreateFrame('Frame', nil)
			SUI_Win.ModSelection:SetParent(SUI_Win.content)
			SUI_Win.ModSelection:SetAllPoints(SUI_Win.content)

			local itemsMatrix = {}

			-- List Components
			for name, submodule in SUI:IterateModules() do
				if (string.match(name, 'Component_')) then
					local RealName = string.sub(name, 11)
					if SUI.DB.EnabledComponents == nil then
						SUI.DB.EnabledComponents = {}
					end
					if SUI.DB.EnabledComponents[RealName] == nil then
						SUI.DB.EnabledComponents[RealName] = true
					end

					local Displayname = string.sub(name, 11)
					if submodule.DisplayName then
						Displayname = submodule.DisplayName
					end
					local checkbox = StdUi:Checkbox(SUI_Win.ModSelection, Displayname, 120, 20)
					checkbox:SetScript(
						'OnValueChanged',
						function()
							SUI.DB.EnabledComponents[RealName] = checkbox:GetValue()
						end
					)

					itemsMatrix[#itemsMatrix] = checkbox
				end
			end

			SUI_Win.ModSelection.itemsMatrix = itemsMatrix
			StdUi:ObjectGrid(SUI_Win.ModSelection, itemsMatrix)
			--Container
			SUI_Win.ModuleSelectionPage = CreateFrame('Frame', nil)
			SUI_Win.ModuleSelectionPage:SetParent(SUI_Win)
			SUI_Win.ModuleSelectionPage:SetAllPoints(SUI_Win)
		end,
		Next = function()
			local SUI_Win = SUI:GetModule('SetupWizard').window.content

			SUI.DB.SetupDone = true

			SUI_Win.ModuleSelectionPage:Hide()
			SUI_Win.ModuleSelectionPage = nil
		end,
		Skip = function()
			SUI.DB.SetupDone = true

			SUI_Win.ModuleSelectionPage:Hide()
			SUI_Win.ModuleSelectionPage = nil
		end
	}

	module:AddPage(ProfilePage)
end
