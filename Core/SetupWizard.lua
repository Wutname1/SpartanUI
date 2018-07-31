local SUI = SUI
local module = SUI:NewModule('SetupWizard')
local StdUi = LibStub('StdUi'):NewInstance()

local SetupWindow = nil
local TotalPageCount, SidebarID = 0, 0
local PriorityPageList = {}
local PageList = {}
local PageID = {}

local LoadWatcherEvent = function()
	module:ShowWizard()
end

function module:AddPage(PageData)
	-- Incriment the page count/id by 1
	TotalPageCount = TotalPageCount + 1

	-- Store the Page's Data in a local table for latter
	-- If the page is flagged as priorty then we want it at the top of the list.
	if PageData.Priority then
		PriorityPageList[PageData.ID] = PageData
	else
		PageList[PageData.ID] = PageData
	end

	-- Not sure if this will be needed yet, but track the Pages defined ID to the generated ID
	PageID[TotalPageCount] = PageData.ID
end

local CreateSidebarLabel = function(id, PageData)
	-- Create the Button
	local NewLabel = StdUi:FontString(SetupWindow.Sidebar, PageData.Name)
	NewLabel.ID = PageData.ID

	-- Position that button
	if SidebarID == 0 then
		NewLabel:SetPoint('TOP', SetupWindow.Sidebar, 'TOP', 0, 0)
	else
		NewLabel:SetPoint('TOP', SetupWindow.Sidebar.Items[(SidebarID - 1)], 'BOTTOM', 0, 0)
	end

	-- Store the Button and increase the ID Number
	SidebarID = SidebarID + 1
	SetupWindow.Sidebar.Items[SidebarID] = NewLabel
end

function module:ShowWizard()
	SetupWindow = SUI:GetModule('SUIWindow'):CreateWindow('SUI_SetupWizard', 650, 500)

	-- If we have more than one page to show then add a progress bar, and a selection tree on the side.
	if TotalPageCount > 1 then
		-- Create the sidebar
		-- local Sidebar = CreateFrame('Frame', nil, Window)
		-- Sidebar:SetPoint('TOPLEFT', SetupWindow, 'TOPLEFT', -5, -5)
		-- Sidebar:SetPoint('BOTTOMRIGHT', SetupWindow, 'BOTTOMLEFT', 100, 5)
		-- Sidebar.Items = {}
		-- SetupWindow.Sidebar = Sidebar

		-- Build out the setup order & sidebar list
		-- for id, data in pairs(PriorityPageList) do
		-- 	CreateSidebarLabel(id, data)
		-- end
		-- for id, data in pairs(PageList) do
		-- 	CreateSidebarLabel(id, data)
		-- end

		-- Add a Progress bar to the bottom
		local ProgressBar = StdUi:ProgressBar(SetupWindow, (SetupWindow:GetWidth() - 4), 20)
		ProgressBar:SetMinMaxValues(0, TotalPageCount)
		ProgressBar:SetValue(0)
		ProgressBar:SetPoint('BOTTOMLEFT', SetupWindow, 'BOTTOMLEFT', 2, 2)
		SetupWindow.ProgressBar = ProgressBar

		-- Adjust the buttons up
		SetupWindow.Skip:ClearAllPoints()
		SetupWindow.Skip:SetPoint('BOTTOMLEFT', SetupWindow.ProgressBar, 'TOPLEFT', 0, 2)

		SetupWindow.Next:ClearAllPoints()
		SetupWindow.Next:SetPoint('BOTTOMRIGHT', SetupWindow.ProgressBar, 'TOPRIGHT', 0, 2)

		-- Adjust the content area to account for the new layout
		SetupWindow.content:ClearAllPoints()
		SetupWindow.content:SetPoint('TOP', SetupWindow.Desc2, 'BOTTOM', 0, -2)
		SetupWindow.content:SetPoint('BOTTOMLEFT', SetupWindow.Skip, 'TOPLEFT', 0, 2)
		SetupWindow.content:SetPoint('BOTTOMRIGHT', SetupWindow.Next, 'TOPRIGHT', 0, 2)

		Window.Skip:SetScript(
			'OnClick',
			function(this)
				if PageList[Page_Cur] ~= nil and PageList[Page_Cur].Skip ~= nil then
					PageList[Page_Cur].Skip()
				end

				if CurData.RequireReload ~= nil and CurData.RequireReload then
					ReloadNeeded('remove')
				end

				if Page_Cur == PageCnt and not ReloadNeeded() then
					Window:Hide()
					WindowShow = false
				elseif Page_Cur == PageCnt and ReloadNeeded() then
					ClearPage()
					module:ReloadPage()
				else
					Page_Cur = Page_Cur + 1
					ClearPage()
					module:DisplayPage()
				end
			end
		)

		Window.Next:SetScript(
			'OnClick',
			function(this)
				if PageList[Page_Cur] ~= nil and PageList[Page_Cur].Next ~= nil then
					PageList[Page_Cur].Next()
				end

				PageList[Page_Cur].Displayed = false
				if Page_Cur == PageCnt and not ReloadNeeded() then
					Window:Hide()
					WindowShow = false
					--Clear Page List
					PageList = {}
				elseif Page_Cur == PageCnt and ReloadNeeded() then
					ClearPage()
					module:ReloadPage()
				else
					Page_Cur = Page_Cur + 1
					ClearPage()
					module:DisplayPage()
				end
			end
		)
	end

	SetupWindow.Status:SetText('0  /  ' .. TotalPageCount)
	-- SetupWindow:Show()
end

function module:OnInitialize()
	local Defaults = {
		FirstLaunch = true
	}
	if not SUI.DB.SetupWizard then
		SUI.DB.SetupWizard = Defaults
	else
		SUI.DB.SetupWizard = SUI:MergeData(SUI.DB.SetupWizard, Defaults, false)
	end
end

function module:OnEnable()
	-- Check if anything Requires a Display
	local DisplayRequired
	for i, k in pairs(PageList) do
		if k.RequireDisplay then
			DisplayRequired = true
		end
	end

	-- If First launch, create a watcher frame that will trigger once everything is loaded in.
	if SUI.DB.SetupWizard.FirstLaunch or DisplayRequired then
		local LoadWatcher = CreateFrame('Frame')
		LoadWatcher:SetScript('OnEvent', LoadWatcherEvent)
		LoadWatcher:RegisterEvent('PLAYER_LOGIN')
		LoadWatcher:RegisterEvent('PLAYER_ENTERING_WORLD')
	end
end
