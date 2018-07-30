local SUI = SUI
local module = SUI:NewModule('SetupWizard')

local SetupWindow = nil
local TotalPageCount, ItemsRequired = 0, 0
local PriorityPageList = {}
local PageList = {}
local PageID = {}

local LoadWatcherEvent = function()
	module:ShowWizard()
end

function module:AddPage(PageData)
	-- Incriment the page count/id by 1
	TotalPageCount = TotalPageCount + 1
	-- Store the Page's Data in a local tabl for latter
	PageList[TotalPageCount] = PageData
	PageID[TotalPageCount] = PageData.ID

	-- If the page is flagged as priorty then we want it at the top of the list.
	-- The below table is scanned first for display.
	if PageData.Priority then
		PriorityPageList[PageData.ID] = TotalPageCount
	end
end

function module:ShowWizard()
	SetupWindow = SUI:GetModule('SUIWindow'):CreateWindow('SUI_SetupWizard')
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
