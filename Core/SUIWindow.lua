local SUI, L = SUI, SUI.L
local module = SUI:NewModule('SUIWindow')
local StdUi = LibStub('StdUi'):NewInstance()
---------------------------------------------------------------------------
local Page_Cur = 1
local PageCnt = 0
local PageList = {}
local Win = nil
local RequireReload = 0
local CurData = nil

local ReloadNeeded = function(mode)
	if mode == 'add' then
		RequireReload = RequireReload + 1
	elseif mode == 'remove' then
		RequireReload = RequireReload - 1
	end
	if RequireReload ~= 0 then
		return true
	else
		return false
	end
end

--[[
	AddPage(PageData)
	Allows you to display multiple pages of information that will be shown to the user.

	PageData follows the Same schema as DisplayPage
]]

function module:AddPage(PageData)
	if Win == nil then
		Win = module:CreateWindow('SUI_Win')
	end

	PageCnt = PageCnt + 1
	PageList[PageCnt] = PageData

	--If something already displayed the window update the text
	if SUI_Win:IsVisible() then
		SUI_Win.Status:SetText(Page_Cur .. '  /  ' .. PageCnt)
	end
end

--[[
	DisplayPage(CustomData)
	Allows you to display a sinlge page of information to the user. That will not page.
]]
function module:DisplayPage(CustomData)
	if Win == nil then
		Win = module:CreateWindow('SUI_Win')
	end
	if CustomData then
		if CustomData.WipePage then
			SUI_Win:Hide()
			SUI_Win = nil
			Win = nil
			Win = module:CreateWindow('SUI_Win')
		end
	end
	
	if (PageList[Page_Cur] == nil and not CustomData) then
		return
	end

	if not CustomData then
		CurData = PageList[Page_Cur]
	else
		Page_Cur = 1
		PageCnt = 1
		PageList[Page_Cur] = CustomData
		CurData = CustomData
	end

	Win.Status:SetText(Page_Cur .. '  /  ' .. PageCnt)
	-- Reset Buttons just incase
	Win.Skip:SetSize(90, 25)
	Win.Skip:SetPoint('BOTTOMLEFT', 5, 5)
	Win.Skip:SetText('SKIP')
	Win.Next:SetSize(90, 25)
	Win.Next:SetPoint('BOTTOMRIGHT', -5, 5)
	Win.Next:SetText('CONTINUE')
	--modify next button
	if Page_Cur == PageCnt and not ReloadNeeded() then
		Win.Next:SetText('FINISH')
	else
		Win.Next:SetText('CONTINUE')
	end
	if SUI_Win:IsVisible() and PageList[Page_Cur].Displayed ~= nil then
		return
	end

	if CurData.title ~= nil then
		Win.titleHolder:SetText(CurData.title)
	end
	if CurData.RequireReload ~= nil and CurData.RequireReload then
		ReloadNeeded('add')
	end
	if CurData.SubTitle ~= nil then
		Win.SubTitle:SetText(CurData.SubTitle)
	else
		Win.SubTitle:SetText('')
	end
	if CurData.Desc1 ~= nil then
		Win.Desc1:SetText(CurData.Desc1)
	else
		Win.Desc1:SetText('')
	end
	if CurData.Desc2 ~= nil then
		Win.Desc2:SetText(CurData.Desc2)
	else
		Win.Desc2:SetText('')
	end
	if CurData.Display ~= nil then
		CurData.Display()
	end

	if CurData.Skip ~= nil then
		Win.Skip:Show()
	else
		Win.Skip:Hide()
	end

	--Track that we are showing this window.
	CurData.Displayed = true
	Win:Show()
end

function module:ReloadPage()
	Win.Status:SetText('')
	Win.Next:SetText('FINISH')

	Win.SubTitle:SetText('Setup Finished!')
	Win.Desc1:SetText('A Reload of the UI is required to finalize your selections. Click FINISH to reload the UI.')

	Win.Desc1:ClearAllPoints()
	Win.Desc1:SetPoint('CENTER', 0, 50)

	Win.Next:ClearAllPoints()
	Win.Next:SetPoint('CENTER', 0, -50)

	Win.Next:SetScript(
		'OnClick',
		function(this)
			ReloadUI()
		end
	)
end

local ClearPage = function()
	Win.Desc1:SetText('')
	Win.Desc2:SetText('')
end

--[[
	CreateWindowdow(FrameName, width, height)
	Returns a Window Object with the default objects created.
]]
function module:CreateWindowdow(FrameName, width, height)
	if not width then
		width = 500
	end
	if not height then
		height = 400
	end
	
	local Window = CreateFrame('Frame', FrameName, UIParent)
	Window:SetSize(width, height)
	Window:SetPoint('TOP', UIParent, 'TOP', 0, -150)
	Window:SetFrameStrata('DIALOG')

	Window.bg = Window:CreateTexture(nil, 'BORDER')
	Window.bg:SetAllPoints(Window)
	Window.bg:SetTexture('Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga')
	Window.bg:SetVertexColor(0, 0, 0, .7)

	Window.border = Window:CreateTexture(nil, 'BORDER')
	Window.border:SetPoint('TOP', 0, 10)
	Window.border:SetPoint('LEFT', -10, 0)
	Window.border:SetPoint('RIGHT', 10, 0)
	Window.border:SetPoint('BOTTOM', 0, -10)
	Window.border:SetTexture('Interface\\AddOns\\SpartanUI\\media\\smoke.tga')
	Window.border:SetVertexColor(0, 0, 0, .7)

	Window.Status = Window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline12')
	Window.Status:SetSize(100, 15)
	Window.Status:SetJustifyH('RIGHT')
	Window.Status:SetJustifyV('CENTER')
	Window.Status:SetPoint('TOPRIGHT', Window, 'TOPRIGHT', -2, -2)

	Window.titleHolder = Window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline22')
	Window.titleHolder:SetPoint('TOP', Window, 'TOP', 0, -5)
	Window.titleHolder:SetSize(350, 20)
	Window.titleHolder:SetText('SpartanUI setup assistant')
	Window.titleHolder:SetTextColor(.76, .03, .03, 1)

	Window.SubTitle = Window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline16')
	Window.SubTitle:SetPoint('TOP', Window.titleHolder, 'BOTTOM', 0, -5)
	Window.SubTitle:SetTextColor(.29, .18, .96, 1)

	Window.Desc1 = Window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
	Window.Desc1:SetPoint('TOP', Window.SubTitle, 'BOTTOM', 0, -5)
	Window.Desc1:SetTextColor(1, 1, 1, .8)
	Window.Desc1:SetWidth(Window:GetWidth() - 40)

	Window.Desc2 = Window:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline13')
	Window.Desc2:SetPoint('TOP', Window.Desc1, 'BOTTOM', 0, -3)
	Window.Desc2:SetTextColor(1, 1, 1, .8)
	Window.Desc2:SetWidth(Window:GetWidth() - 40)

	Window:HookScript(
		'OnSizeChanged',
		function(self)
			self.Desc1:SetWidth(self:GetWidth() - 40)
			self.Desc2:SetWidth(self:GetWidth() - 40)
		end
	)

	--Holder for items
	Window.content = CreateFrame('Frame', 'SUI_Window_Content', Window)
	Window.content:SetPoint('BOTTOMLEFT', Window, 'BOTTOMLEFT', 0, 30)
	Window.content:SetPoint('BOTTOMRIGHT', Window, 'BOTTOMRIGHT', 0, 30)
	Window.content:SetPoint('TOP', Window.Desc2, 'BOTTOM', 0, -5)

	--Buttons
	Window.Next = CreateFrame('Button', nil, Window, 'UIPanelButtonTemplate')
	Window.Next:SetSize(90, 25)
	Window.Next:SetPoint('BOTTOMRIGHT', -5, 5)
	Window.Next:SetNormalTexture('')
	Window.Next:SetHighlightTexture('')
	Window.Next:SetPushedTexture('')
	Window.Next:SetDisabledTexture('')
	Window.Next:SetFrameLevel(Window.Next:GetFrameLevel() + 1)
	Window.Next:SetText('CONTINUE')

	Window.Next.texture = Window.Next:CreateTexture(nil, 'BORDER')
	Window.Next.texture:SetAllPoints(Window.Next)
	Window.Next.texture:SetTexture('Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga')
	Window.Next.texture:SetVertexColor(0, 0.5, 1)

	-- Window.Next.parent = frame
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
	Window.Next:SetScript(
		'OnEnter',
		function(this)
			this.texture:SetVertexColor(.5, .5, 1, 1)
		end
	)
	Window.Next:SetScript(
		'OnLeave',
		function(this)
			this.texture:SetVertexColor(0, 0.5, 1)
		end
	)

	Window.Skip = CreateFrame('Button', nil, Window, 'UIPanelButtonTemplate')
	Window.Skip:SetSize(90, 25)
	Window.Skip:SetPoint('BOTTOMLEFT', 5, 5)
	Window.Skip:SetNormalTexture('')
	Window.Skip:SetHighlightTexture('')
	Window.Skip:SetPushedTexture('')
	Window.Skip:SetDisabledTexture('')
	Window.Skip:SetFrameLevel(Window.Skip:GetFrameLevel() + 1)
	Window.Skip:SetText('SKIP')

	Window.Skip.texture = Window.Skip:CreateTexture(nil, 'BORDER')
	Window.Skip.texture:SetAllPoints(Window.Skip)
	Window.Skip.texture:SetTexture('Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga')
	Window.Skip.texture:SetVertexColor(.75, 0, 0)

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
	Window.Skip:SetScript(
		'OnEnter',
		function(this)
			this.texture:SetVertexColor(.9, .2, .2, 1)
		end
	)
	Window.Skip:SetScript(
		'OnLeave',
		function(this)
			this.texture:SetVertexColor(.75, 0, 0)
		end
	)
	Window.Skip:Hide()

	Window:SetScript(
		'OnEvent',
		function(self, event)
			if not InCombatLockdown() and Window:IsShown() then
				SUI:Print(L['Hiding setup due to combat'])
				Window:Hide()
			elseif not InCombatLockdown() and not Window:IsShown() and WindowShow then
				Window:Show()
			end
		end
	)

	Window:RegisterEvent('PLAYER_REGEN_DISABLED')
	Window:RegisterEvent('PLAYER_REGEN_ENABLED')

	Window:Hide()
	WindowShow = false
	return Window
end
