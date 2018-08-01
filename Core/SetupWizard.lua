local SUI = SUI
local module = SUI:NewModule('SetupWizard')
local StdUi = LibStub('StdUi'):NewInstance()

local SetupWindow, DisplayRequired, InitDone, ReloadNeeded = nil, false, false, false
local TotalPageCount, PageDisplayOrder, PageDisplayed = 0, 1, 0
local PriorityPageList, StandardPageList, FinalPageList, PageID, CurrentDisplay = {}, {}, {}, {}, {}
local ReloadPage = {
	ID = 'ReloadPage',
	Name = 'Reload required',
	SubTitle = 'Reload required',
	Desc1 = 'Setup finished!',
	Desc2 = 'This completes the setup wizard, a reload of the UI is required to finish the setup.',
	Display = function()
		SetupWindow.WelcomePage = CreateFrame('Frame', nil)
		SetupWindow.WelcomePage:SetParent(SetupWindow.content)
		SetupWindow.WelcomePage:SetAllPoints(SetupWindow.content)

		SetupWindow.WelcomePage.Helm =
			StdUi:Texture(SetupWindow.WelcomePage, 150, 150, 'Interface\\AddOns\\SpartanUI\\media\\Spartan-Helm')
		SetupWindow.WelcomePage.Helm:SetPoint('CENTER')

		SetupWindow.Next:SetText('RELOAD UI')
	end,
	Next = function()
		ReloadUI()
	end
}

local LoadWatcherEvent = function()
	module:ShowWizard()
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
	SetupWindow.ProgressBar:SetMinMaxValues(1, TotalPageCount)

	--Find the next undisplayed page
	if FinalPageList[(PageDisplayed + 1)] then
		PageDisplayed = PageDisplayed + 1
		local ID = FinalPageList[PageDisplayed]

		-- Find what kind of page this is
		if PriorityPageList[ID] then
			module:DisplayPage(PriorityPageList[ID])
		elseif StandardPageList[ID] then
			module:DisplayPage(StandardPageList[ID])
		end
	elseif ReloadNeeded and PageDisplayed == TotalPageCount then
		module:DisplayPage(ReloadPage)
	end
end

function module:DisplayPage(PageData)
	CurrentDisplay = PageData
	if PageData.title then
		SetupWindow.titleHolder:SetText(PageData.title)
	end
	if PageData.SubTitle then
		SetupWindow.SubTitle:SetText(PageData.SubTitle)
	else
		SetupWindow.SubTitle:SetText('')
	end
	if PageData.Desc1 then
		SetupWindow.Desc1:SetText(PageData.Desc1)
	else
		SetupWindow.Desc1:SetText('')
	end
	if PageData.Desc2 then
		SetupWindow.Desc2:SetText(PageData.Desc2)
	else
		SetupWindow.Desc2:SetText('')
	end
	if PageData.Display then
		PageData.Display()
	end
	if PageData.Skip ~= nil then
		SetupWindow.Skip:Show()
	else
		SetupWindow.Skip:Hide()
	end

	-- Update the Status Counter & Progress Bar
	SetupWindow.Status:SetText(PageDisplayed .. ' /  ' .. TotalPageCount)
	if SetupWindow.ProgressBar then
		SetupWindow.ProgressBar:SetValue((100 / TotalPageCount) * PageDisplayed)
	end
end

function module:ShowWizard()
	SetupWindow = StdUi:Window(nil, 'SpartanUI setup wizard', 650, 500)
	SetupWindow:SetPoint('CENTER', 0, 0)
	SetupWindow:SetFrameStrata('DIALOG')
	SetupWindow.closeBtn:Hide()

	-- Setup the Top text fields
	SetupWindow.SubTitle = StdUi:Label(SetupWindow, '', 16, nil, SetupWindow:GetWidth(), 20)
	SetupWindow.SubTitle:SetPoint('TOP', SetupWindow.titlePanel, 'BOTTOM', 0, -5)
	SetupWindow.SubTitle:SetTextColor(.29, .18, .96, 1)

	SetupWindow.Desc1 = StdUi:Label(SetupWindow, '', 13, nil, SetupWindow:GetWidth())
	-- SetupWindow.Desc1 = SetupWindow:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
	SetupWindow.Desc1:SetPoint('TOP', SetupWindow.SubTitle, 'BOTTOM', 0, -5)
	SetupWindow.Desc1:SetTextColor(1, 1, 1, .8)
	SetupWindow.Desc1:SetWidth(SetupWindow:GetWidth() - 40)

	SetupWindow.Desc2 = StdUi:Label(SetupWindow, '', 13, nil, SetupWindow:GetWidth())
	-- SetupWindow.Desc2 = SetupWindow:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
	SetupWindow.Desc2:SetPoint('TOP', SetupWindow.Desc1, 'BOTTOM', 0, -3)
	SetupWindow.Desc2:SetTextColor(1, 1, 1, .8)
	SetupWindow.Desc2:SetWidth(SetupWindow:GetWidth() - 40)

	SetupWindow.Status = StdUi:Label(SetupWindow, '', 9, nil, 40, 15)
	SetupWindow.Status:SetPoint('TOPRIGHT', SetupWindow, 'TOPRIGHT', -2, -2)
	SetupWindow.Status:SetText('0  /  ' .. TotalPageCount)

	-- Setup the Buttons
	SetupWindow.Skip = StdUi:Button(SetupWindow, 150, 20, 'SKIP')
	SetupWindow.Next = StdUi:Button(SetupWindow, 150, 20, 'CONTINUE')

	-- If we have more than one page to show then add a progress bar, and a selection tree on the side.
	if TotalPageCount > 1 then
		-- Add a Progress bar to the bottom
		local ProgressBar = StdUi:ProgressBar(SetupWindow, (SetupWindow:GetWidth() - 4), 20)
		ProgressBar:SetMinMaxValues(0, TotalPageCount)
		ProgressBar:SetValue(0)
		ProgressBar:SetPoint('BOTTOM', SetupWindow, 'BOTTOM', 0, 2)
		SetupWindow.ProgressBar = ProgressBar

		--Position the Buttons
		SetupWindow.Skip:SetPoint('BOTTOMLEFT', SetupWindow.ProgressBar, 'TOPLEFT', 0, 2)
		SetupWindow.Next:SetPoint('BOTTOMRIGHT', SetupWindow.ProgressBar, 'TOPRIGHT', 0, 2)

		-- Adjust the content area to account for the new layout
		SetupWindow.content = CreateFrame('Frame', 'SUI_Window_Content', Window)
		SetupWindow.content:SetPoint('TOP', SetupWindow.Desc2, 'BOTTOM', 0, -2)
		SetupWindow.content:SetPoint('BOTTOMLEFT', SetupWindow.Skip, 'TOPLEFT', 0, 2)
		SetupWindow.content:SetPoint('BOTTOMRIGHT', SetupWindow.Next, 'TOPRIGHT', 0, 2)
	else
		--Position the Buttons
		SetupWindow.Skip:SetPoint('BOTTOMLEFT', SetupWindow, 'BOTTOMLEFT', 0, 2)
		SetupWindow.Next:SetPoint('BOTTOMRIGHT', SetupWindow, 'BOTTOMRIGHT', 0, 2)
	end

	SetupWindow.Skip:SetScript(
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

	SetupWindow.Next:SetScript(
		'OnClick',
		function(this)
			-- Perform the Page's Custom Next action
			if CurrentDisplay.Next then
				CurrentDisplay.Next()
			end

			--Destory anything attached to the Content frame
			for i, v in pairs(SetupWindow.content) do
				v:Hide()
				if SetupWindow.content[i] then
					SetupWindow.content[i] = nil
				end
			end

			-- If Reload is needed by the page flag it for latter.
			if CurrentDisplay.RequireReload then
				ReloadNeeded = true
			end

			-- Show the next page
			module:FindNextPage()
		end
	)

	SetupWindow.Status = StdUi:Label(SetupWindow, '', 9, nil, 60, 15)
	SetupWindow.Status:SetPoint('TOPRIGHT', SetupWindow, 'TOPRIGHT', -2, -2)

	-- Display first page
	module:FindNextPage()
	SetupWindow:Show()
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
	local WelcomePage = {
		ID = 'WelcomePage',
		Name = 'Welcome',
		SubTitle = '',
		Desc1 = "Welcome to SpartanUI, This setup wizard help guide you through the inital setup of the UI and it's modules.",
		Desc2 = 'This setup wizard may be re-ran at any time via the SUI settings screen. You can access the SUI settings via the /sui chat command. For a full list of chat commands as well as common questions visit our wiki at http://wiki.spartanui.net',
		Display = function()
			SetupWindow.WelcomePage = CreateFrame('Frame', nil)
			SetupWindow.WelcomePage:SetParent(SetupWindow.content)
			SetupWindow.WelcomePage:SetAllPoints(SetupWindow.content)

			SetupWindow.WelcomePage.Helm =
				StdUi:Texture(SetupWindow.WelcomePage, 150, 150, 'Interface\\AddOns\\SpartanUI\\media\\Spartan-Helm')
			SetupWindow.WelcomePage.Helm:SetPoint('CENTER')
		end,
		RequireDisplay = SUI.DB.SetupWizard.FirstLaunch,
		Priority = true
	}
	module:AddPage(WelcomePage)
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
