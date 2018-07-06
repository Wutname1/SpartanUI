local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI")
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true)
local module = spartan:NewModule("SetupWindow")
---------------------------------------------------------------------------
local Page_Cur = 1
local PageCnt = 0
local PageList = {}
local WinShow, Win = false, nil
local RequireReload = 0
local CurData = nil

local ReloadNeeded = function(mode)
	if mode == "add" then
		RequireReload = RequireReload + 1
	elseif mode == "remove" then
		RequireReload = RequireReload - 1
	end
	if RequireReload ~= 0 then
		return true
	else
		return false
	end
end

function module:AddPage(PageData)
	if Win == nil then
		module:CreateInstallWindow()
	end

	PageCnt = PageCnt + 1
	PageList[PageCnt] = PageData

	--If something already displayed the window update the text
	if SUI_Win:IsVisible() then
		SUI_Win.Status:SetText(Page_Cur .. "  /  " .. PageCnt)
	end
end

function module:DisplayPage(CustomData)
	if Win == nil then
		module:CreateInstallWindow()
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

	Win.Status:SetText(Page_Cur .. "  /  " .. PageCnt)
	-- Reset Buttons just incase
	Win.Skip:SetSize(90, 25)
	Win.Skip:SetPoint("BOTTOMLEFT", 5, 5)
	Win.Skip:SetText("SKIP")
	Win.Next:SetSize(90, 25)
	Win.Next:SetPoint("BOTTOMRIGHT", -5, 5)
	Win.Next:SetText("CONTINUE")
	--modify next button
	if Page_Cur == PageCnt and not ReloadNeeded() then
		Win.Next:SetText("FINISH")
	else
		Win.Next:SetText("CONTINUE")
	end
	if SUI_Win:IsVisible() and PageList[Page_Cur].Displayed ~= nil then
		return
	end

	if CurData.title ~= nil then
		Win.titleHolder:SetText(CurData.title)
	end
	if CurData.RequireReload ~= nil and CurData.RequireReload then
		ReloadNeeded("add")
	end
	if CurData.SubTitle ~= nil then
		Win.SubTitle:SetText(CurData.SubTitle)
	else
		Win.SubTitle:SetText("")
	end
	if CurData.Desc1 ~= nil then
		Win.Desc1:SetText(CurData.Desc1)
	else
		Win.Desc1:SetText("")
	end
	if CurData.Desc2 ~= nil then
		Win.Desc2:SetText(CurData.Desc2)
	else
		Win.Desc2:SetText("")
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
	WinShow = true
	Win:Show()
end

function module:ReloadPage()
	Win.Status:SetText("")
	Win.Next:SetText("FINISH")

	Win.SubTitle:SetText("Setup Finished!")
	Win.Desc1:SetText("A Reload of the UI is required to finalize your selections. Click FINISH to reload the UI.")

	Win.Desc1:ClearAllPoints()
	Win.Desc1:SetPoint("CENTER", 0, 50)

	Win.Next:ClearAllPoints()
	Win.Next:SetPoint("CENTER", 0, -50)

	Win.Next:SetScript(
		"OnClick",
		function(this)
			ReloadUI()
		end
	)
end

local ClearPage = function()
	Win.Desc1:SetText("")
	Win.Desc2:SetText("")
end

function module:CreateInstallWindow()
	Win = CreateFrame("Frame", "SUI_Win", UIParent)
	Win:SetSize(550, 400)
	Win:SetPoint("TOP", UIParent, "TOP", 0, -150)
	Win:SetFrameStrata("DIALOG")

	Win.bg = Win:CreateTexture(nil, "BORDER")
	Win.bg:SetAllPoints(Win)
	Win.bg:SetTexture("Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga")
	Win.bg:SetVertexColor(0, 0, 0, .7)

	Win.border = Win:CreateTexture(nil, "BORDER")
	Win.border:SetPoint("TOP", 0, 10)
	Win.border:SetPoint("LEFT", -10, 0)
	Win.border:SetPoint("RIGHT", 10, 0)
	Win.border:SetPoint("BOTTOM", 0, -10)
	Win.border:SetTexture("Interface\\AddOns\\SpartanUI\\media\\smoke.tga")
	Win.border:SetVertexColor(0, 0, 0, .7)

	Win.Status = Win:CreateFontString(nil, "OVERLAY", "SUI_FontOutline12")
	Win.Status:SetSize(100, 15)
	Win.Status:SetJustifyH("RIGHT")
	Win.Status:SetJustifyV("CENTER")
	Win.Status:SetPoint("TOPRIGHT", Win, "TOPRIGHT", -2, -2)

	Win.titleHolder = Win:CreateFontString(nil, "OVERLAY", "SUI_FontOutline22")
	Win.titleHolder:SetPoint("TOP", Win, "TOP", 0, -5)
	Win.titleHolder:SetSize(350, 20)
	Win.titleHolder:SetText("SpartanUI setup assistant")
	Win.titleHolder:SetTextColor(.76, .03, .03, 1)

	Win.SubTitle = Win:CreateFontString(nil, "OVERLAY", "SUI_FontOutline16")
	Win.SubTitle:SetPoint("TOP", Win.titleHolder, "BOTTOM", 0, -5)
	Win.SubTitle:SetTextColor(.29, .18, .96, 1)

	Win.Desc1 = Win:CreateFontString(nil, "OVERLAY", "SUI_FontOutline13")
	Win.Desc1:SetPoint("TOP", Win.SubTitle, "BOTTOM", 0, -5)
	Win.Desc1:SetTextColor(1, 1, 1, .8)
	Win.Desc1:SetWidth(Win:GetWidth() - 40)

	Win.Desc2 = Win:CreateFontString(nil, "OVERLAY", "SUI_FontOutline13")
	Win.Desc2:SetPoint("TOP", Win.Desc1, "BOTTOM", 0, -3)
	Win.Desc2:SetTextColor(1, 1, 1, .8)
	Win.Desc2:SetWidth(Win:GetWidth() - 40)

	Win:HookScript(
		"OnSizeChanged",
		function(self)
			self.Desc1:SetWidth(self:GetWidth() - 40)
			self.Desc2:SetWidth(self:GetWidth() - 40)
		end
	)

	--Holder for items
	Win.content = CreateFrame("Frame", "SUI_Win_Content", Win)
	Win.content:SetPoint("BOTTOMLEFT", Win, "BOTTOMLEFT", 0, 30)
	Win.content:SetPoint("BOTTOMRIGHT", Win, "BOTTOMRIGHT", 0, 30)
	Win.content:SetPoint("TOP", Win.Desc2, "BOTTOM", 0, -5)

	--Buttons
	Win.Next = CreateFrame("Button", nil, Win, "UIPanelButtonTemplate")
	Win.Next:SetSize(90, 25)
	Win.Next:SetPoint("BOTTOMRIGHT", -5, 5)
	Win.Next:SetNormalTexture("")
	Win.Next:SetHighlightTexture("")
	Win.Next:SetPushedTexture("")
	Win.Next:SetDisabledTexture("")
	Win.Next:SetFrameLevel(Win.Next:GetFrameLevel() + 1)
	Win.Next:SetText("CONTINUE")

	Win.Next.texture = Win.Next:CreateTexture(nil, "BORDER")
	Win.Next.texture:SetAllPoints(Win.Next)
	Win.Next.texture:SetTexture("Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga")
	Win.Next.texture:SetVertexColor(0, 0.5, 1)

	-- Win.Next.parent = frame
	Win.Next:SetScript(
		"OnClick",
		function(this)
			if PageList[Page_Cur] ~= nil and PageList[Page_Cur].Next ~= nil then
				PageList[Page_Cur].Next()
			end

			PageList[Page_Cur].Displayed = false
			if Page_Cur == PageCnt and not ReloadNeeded() then
				Win:Hide()
				WinShow = false
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
	Win.Next:SetScript(
		"OnEnter",
		function(this)
			this.texture:SetVertexColor(.5, .5, 1, 1)
		end
	)
	Win.Next:SetScript(
		"OnLeave",
		function(this)
			this.texture:SetVertexColor(0, 0.5, 1)
		end
	)

	Win.Skip = CreateFrame("Button", nil, Win, "UIPanelButtonTemplate")
	Win.Skip:SetSize(90, 25)
	Win.Skip:SetPoint("BOTTOMLEFT", 5, 5)
	Win.Skip:SetNormalTexture("")
	Win.Skip:SetHighlightTexture("")
	Win.Skip:SetPushedTexture("")
	Win.Skip:SetDisabledTexture("")
	Win.Skip:SetFrameLevel(Win.Skip:GetFrameLevel() + 1)
	Win.Skip:SetText("SKIP")

	Win.Skip.texture = Win.Skip:CreateTexture(nil, "BORDER")
	Win.Skip.texture:SetAllPoints(Win.Skip)
	Win.Skip.texture:SetTexture("Interface\\AddOns\\SpartanUI\\media\\Smoothv2.tga")
	Win.Skip.texture:SetVertexColor(.75, 0, 0)

	Win.Skip:SetScript(
		"OnClick",
		function(this)
			if PageList[Page_Cur] ~= nil and PageList[Page_Cur].Skip ~= nil then
				PageList[Page_Cur].Skip()
			end

			if CurData.RequireReload ~= nil and CurData.RequireReload then
				ReloadNeeded("remove")
			end

			if Page_Cur == PageCnt and not ReloadNeeded() then
				Win:Hide()
				WinShow = false
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
	Win.Skip:SetScript(
		"OnEnter",
		function(this)
			this.texture:SetVertexColor(.9, .2, .2, 1)
		end
	)
	Win.Skip:SetScript(
		"OnLeave",
		function(this)
			this.texture:SetVertexColor(.75, 0, 0)
		end
	)
	Win.Skip:Hide()

	Win:SetScript(
		"OnEvent",
		function(self, event)
			if not InCombatLockdown() and Win:IsShown() then
				spartan:Print(L["Hiding setup due to combat"])
				Win:Hide()
			elseif not InCombatLockdown() and not Win:IsShown() and WinShow then
				Win:Show()
			end
		end
	)

	Win:RegisterEvent("PLAYER_REGEN_DISABLED")
	Win:RegisterEvent("PLAYER_REGEN_ENABLED")

	Win:Hide()
	WinShow = false
end
