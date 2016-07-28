local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:NewModule("SetupWindow");
---------------------------------------------------------------------------
local Page_Cur = 1
local PageCnt = 0
local PageList = {}
local Win = nil
local RequireReload = false
-- local module

function module:AddPage(PageData)
	PageCnt = PageCnt+1
	PageList[PageCnt] = PageData
	
	if PageData.RequireReload then RequireReload = true; end
	
	--If something already displayed the window update the text
	if SUI_Win:IsVisible() then
		SUI_Win.Status:SetText(Page_Cur.."  /  ".. PageCnt)
	end
end

function module:OnInitialize()
	module:CreateInstallWindow()
end

function module:OnEnable()

end

function module:DisplayPage()
	if PageList[Page_Cur] == nil then return end
	
	Win.Status:SetText(Page_Cur.."  /  ".. PageCnt)
	if Page_Cur == PageCnt and not RequireReload then
		Win.Next:SetText("FINISH")
	else
		Win.Next:SetText("CONTINUE")
	end
	
	if SUI_Win:IsVisible() and PageList[Page_Cur].Displayed ~= nil then return end
	local data = PageList[Page_Cur]

	Win.SubTitle:SetText(data.SubTitle)
	if data.Desc1 ~= nil then Win.Desc1:SetText(data.Desc1) end
	if data.Desc2 ~= nil then Win.Desc2:SetText(data.Desc2) end
	if data.Display ~= nil then data.Display() end
	data.Displayed = true
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
	
	Win.Next:SetScript("OnClick", function(this)
		ReloadUI()
	end)
end

local ClearPage = function()
	Win.Desc1:SetText("")
	Win.Desc2:SetText("")
end

function module:CreateInstallWindow()
	Win = CreateFrame("Frame", "SUI_Win", UIParent)
	Win:SetSize(550, 400)
	Win:SetPoint("TOP", UIParent, "TOP", 0, -150)
	Win:SetFrameStrata("TOOLTIP")
	
	Win.bg = Win:CreateTexture(nil, "BORDER")
	Win.bg:SetAllPoints(Win)
	Win.bg:SetTexture([[Interface\AddOns\SpartanUI\media\Smoothv2.tga]])
	Win.bg:SetVertexColor(0, 0, 0, .7)
	
	Win.border = Win:CreateTexture(nil, "BORDER")
	Win.border:SetPoint("TOP", 0, 10)
	Win.border:SetPoint("LEFT", -10, 0)
	Win.border:SetPoint("RIGHT", 10, 0)
	Win.border:SetPoint("BOTTOM", 0, -10)
	Win.border:SetTexture([[Interface\AddOns\SpartanUI\media\smoke.tga]])
	Win.border:SetVertexColor(0, 0, 0, .7)
	
	
	Win.Status = Win:CreateFontString(nil,"OVERLAY","SUI_FontOutline12");
	Win.Status:SetSize(100, 15);
	Win.Status:SetJustifyH("RIGHT");
	Win.Status:SetJustifyV("CENTER");
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
	Win.Desc1:SetPoint("TOP",Win.SubTitle,"BOTTOM", 0, -5)
	Win.Desc1:SetTextColor(1, 1, 1, .8)
	Win.Desc1:SetWidth(Win:GetWidth()-40)
	
	Win.Desc2 = Win:CreateFontString(nil, "OVERLAY", "SUI_FontOutline13")
	Win.Desc2:SetPoint("TOP",Win.Desc1,"BOTTOM", 0, -3)
	Win.Desc2:SetTextColor(1, 1, 1, .8)
	Win.Desc2:SetWidth(Win:GetWidth()-40)
	
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
	Win.Next.texture:SetTexture([[Interface\AddOns\SpartanUI\media\Smoothv2.tga]])
	Win.Next.texture:SetVertexColor(0, 0.5, 1)
	
	-- Win.Next.parent = frame
	Win.Next:SetScript("OnClick", function(this)
		if PageList[Page_Cur]~= nil and PageList[Page_Cur].Next ~= nil then PageList[Page_Cur].Next() end
		
		if Page_Cur == PageCnt and not RequireReload then
			Win:Hide()
		elseif Page_Cur == PageCnt and RequireReload then
			ClearPage()
			module:ReloadPage()
		else
			Page_Cur = Page_Cur + 1
			ClearPage()
			module:DisplayPage()
		end
	end)
	Win.Next:SetScript("OnEnter", function(this)
		this.texture:SetVertexColor(.5, .5, 1, 1)
	end)
	Win.Next:SetScript("OnLeave", function(this)
		this.texture:SetVertexColor(0, 0.5, 1)
	end)
	
	Win:Hide()
end