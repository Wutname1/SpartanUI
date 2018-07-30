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

local CreateSidebarLabel = function(id, data)
	-- Create the Button
	local NewLabel = StdUi:FontString(Window.Sidebar, data.Name);
	NewLabel.ID = PageData.ID

	-- Position that button
	if SidebarID == 0 then
		NewLabel:SetPoint('TOP', Window.Sidebar, 'TOP', 0, 0)
	else
		NewLabel:SetPoint('TOP', Window.Sidebar.Buttons[(SidebarID - 1)], 'BOTTOM', 0, 0)
	end

	-- Store the Button and increase the ID Number
	SidebarID = SidebarID + 1
	Window.Sidebar.Items[SidebarID] = NewLabel
end

function module:ShowWizard()
	SetupWindow = SUI:GetModule('SUIWindow'):CreateWindow('SUI_SetupWizard', 600, 480)

	-- If we have more than one page to show then add a progress bar, and a selection tree on the side.
	if TotalPageCount > 1 then
		-- Create the sidebar
		local Sidebar = CreateFrame('Frame', nil, Window)
		Sidebar:SetPoint('TOPLEFT', Window, 'TOPLEFT', -5, -5)
		Sidebar:SetPoint('BOTTOMRIGHT', Window, 'BOTTOMLEFT', 150, 5)
		Sidebar.Items = {}
		Window.Sidebar = Sidebar

		-- Add a Progress bar to the bottom
		local ProgressBar = StdUi:ProgressBar(SetupWindow, (SetupWindow:GetWidth() - (10 + Window.Sidebar:GetWidth())), 20)
		ProgressBar:SetMinMaxValues(0, TotalPageCount)
		ProgressBar:SetValue(0)
		ProgressBar:SetPoint('BOTTOMLEFT', Window.Sidebar, 'BOTTOMRIGHT')
		SetupWindow.ProgressBar = ProgressBar

		-- Adjust the buttons up
		Window.Skip:ClearAllPoints()
		Window.Skip:SetPoint('BOTTOMLEFT', SetupWindow.ProgressBar, 'TOPLEFT', 0, 2)

		Window.Next:ClearAllPoints()
		Window.Next:SetPoint('BOTTOMRIGHT', SetupWindow.ProgressBar, 'TOPRIGHT', 0, 2)

		-- Adjust the content area to account for the new layout
		Window.content:ClearAllPoints()
		Window.content:SetPoint('TOP', Window.Desc2, 'BOTTOM', 0, -2)
		Window.content:SetPoint('BOTTOMLEFT', Window.Skip, 'TOPLEFT', 0, 2)
		Window.content:SetPoint('BOTTOMRIGHT', Window.Next, 'TOPRIGHT', 0, 2)

		-- Build out the setup order & sidebar list
		for id, data in pairs(PriorityPageList) do
			CreateSidebarLabel(id, data)
		end
		for id, data in pairs(PageList) do
			CreateSidebarLabel(id, data)
		end
	end
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
