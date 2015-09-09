local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:NewModule("Installer");
---------------------------------------------------------------------------
local Pages = 1
-- local module

function module:OnInitialize()
end

function module:OnEnable()
end


function module:CreateInstallWindow()

	if DB.Installer == nil then
		local frame = CreateFrame("Button", "SUI_InstallerFrame", UIParent)
		frame:SetSize(550, 400)
		-- frame:SetStyle("Frame", "Window2")
		frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
		frame:SetFrameStrata("TOOLTIP")

		frame.SetPage = InstallerFrame_SetPage;
		
		-- frame.Finish = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		
		frame.Next = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		-- frame.Next:RemoveTextures()
		frame.Next:SetSize(110, 25)
		frame.Next:SetPoint("BOTTOMRIGHT", 50, 5)
		frame.Next.Left:SetAlpha(0)
		frame.Next.Middle:SetAlpha(0)
		frame.Next.Right:SetAlpha(0)
		frame.Next:SetNormalTexture("")
		frame.Next:SetPushedTexture("")
		frame.Next:SetPushedTexture("")
		frame.Next:SetDisabledTexture("")
		frame.Next:SetFrameLevel(frame.Next:GetFrameLevel() + 1)
		
		frame.Next.texture = frame.Next:CreateTexture(nil, "BORDER")
		frame.Next.texture:SetSize(110, 75)
		frame.Next.texture:SetPoint("RIGHT")
		frame.Next.texture:SetTexture([[Interface\AddOns\SpartanUI\media\arrow.tga]])
		frame.Next.texture:SetVertexColor(0, 0.5, 1)
		frame.Next.text = frame.Next:CreateFontString(nil, "OVERLAY")
		frame.Next.text:SetFont(DB.font.Primary.Face, 18, "OUTLINE")
		frame.Next.text:SetPoint("CENTER")
		frame.Next.text:SetText(CONTINUE)
		-- frame.Next:Disable()
		frame.Next.parent = frame
		frame.Next:SetScript("OnClick", function(this)
		
		
		end)
		frame.Next:SetScript("OnEnter", function(this)
			this.texture:SetVertexColor(1, 0.5, 0)
		end)
		frame.Next:SetScript("OnLeave", function(this)
			this.texture:SetVertexColor(0, 0.5, 1)
		end)
	end
	if DB.Installer == nil then
		SUI_InstallerFrame:Show()
	end
end